const { test } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const { io } = require('socket.io-client');
const { createChatServer } = require('../app');
function next(socket, event) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { socket.off(event, handler); reject(new Error('Timeout ' + event)); }, 3000);
    function handler(data) { clearTimeout(timer); resolve(data); }
    socket.once(event, handler);
  });
}
async function setup(t, stage = 'full') {
  const { server, io: serverIO } = createChatServer(stage);
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  const url = 'http://127.0.0.1:' + server.address().port;
  const clients = [];
  t.after(async () => {
    clients.forEach(client => client.disconnect());
    await new Promise(resolve => serverIO.close(resolve));
  });
  return { url, async connect() {
    const client = io(url, { transports: ['websocket'], reconnection: false });
    clients.push(client); await next(client, 'connect'); return client;
  } };
}
function emitAck(socket, event, data) {
  return new Promise((resolve, reject) => socket.timeout(3000).emit(event, data, (err, value) => err ? reject(err) : resolve(value)));
}
test('hello/server-only co Hello world, khong nhung client script', async t => {
  for (const stage of ['hello', 'server-only']) {
    const env = await setup(t, stage);
    assert.equal(await (await fetch(env.url)).text(), 'Hello world');
  }
});
test('giao dien EJS va client bundle duoc phuc vu cung server', async t => {
  const env = await setup(t);
  assert.match(await (await fetch(env.url)).text(), /socket\.io\/socket\.io\.js/);
  assert.equal((await fetch(env.url + '/socket.io/socket.io.js')).status, 200);
});
test('doi ten va gui tin toi ca hai client, ke ca nguoi gui', async t => {
  const env = await setup(t); const a = await env.connect(); const b = await env.connect();
  assert.equal((await emitAck(a, 'change_username', { username: 'Ba' })).ok, true);
  const pa = next(a, 'new_message'); const pb = next(b, 'new_message');
  await emitAck(a, 'new_message', { message: 'Xin chào' });
  for (const data of await Promise.all([pa, pb])) assert.deepEqual(data, { username: 'Ba', message: 'Xin chào' });
  const reply = next(a, 'new_message');
  await emitAck(b, 'new_message', { message: 'Hello' });
  assert.equal((await reply).username, 'Anonymous');
});
test('typing chi broadcast cho nguoi khac', async t => {
  const env = await setup(t); const a = await env.connect(); const b = await env.connect();
  let own = 0; a.on('typing', () => own++);
  const received = next(b, 'typing'); a.emit('typing', { active: true });
  assert.equal((await received).active, true);
  await new Promise(resolve => setTimeout(resolve, 80)); assert.equal(own, 0);
});
test('tu choi ten va tin nhan rong, chap nhan text nhu van ban', async t => {
  const env = await setup(t); const a = await env.connect();
  assert.equal((await emitAck(a, 'change_username', { username: ' ' })).ok, false);
  assert.equal((await emitAck(a, 'new_message', { message: '' })).ok, false);
  assert.equal((await emitAck(a, 'new_message', { message: 'x'.repeat(1001) })).ok, false);
  const msg = next(a, 'new_message'); await emitAck(a, 'new_message', { message: '<b>hello</b>' });
  assert.equal((await msg).message, '<b>hello</b>');
});
