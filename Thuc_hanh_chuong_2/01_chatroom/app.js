// Chat room theo bai thuc hanh, Socket.IO server/client cung phien ban.
const express = require('express');
const http = require('node:http');
const path = require('node:path');
const { Server } = require('socket.io');

function createChatServer(stage = 'full') {
  if (!['hello', 'server-only', 'connect', 'full'].includes(stage)) {
    throw new Error('LAB_STAGE must be hello, server-only, connect or full');
  }
  const app = express();
  app.set('view engine', 'ejs');
  app.set('views', path.join(__dirname, 'views'));
  app.use(express.static(path.join(__dirname, 'public')));
  app.get('/', (_req, res) => {
    if (stage === 'hello' || stage === 'server-only') return res.send('Hello world');
    res.render('index', { stage });
  });
  const server = http.createServer(app);
  const io = new Server(server, { maxHttpBufferSize: 16 * 1024 });
  io.on('connection', socket => {
    console.log(new Date().toISOString(), 'New user connected', socket.id);
    socket.data.username = 'Anonymous';
    if (stage !== 'full') return;
    const respond = (ack, payload) => { if (typeof ack === 'function') ack(payload); };
    socket.on('change_username', (data, ack) => {
      const name = typeof data?.username === 'string' ? data.username.trim() : '';
      if (!name || name.length > 30) return respond(ack, { ok: false, error: 'Tên phải dài 1–30 ký tự.' });
      socket.data.username = name;
      respond(ack, { ok: true, username: name });
    });
    socket.on('new_message', (data, ack) => {
      const message = typeof data?.message === 'string' ? data.message.trim() : '';
      if (!message || message.length > 1000) return respond(ack, { ok: false, error: 'Tin nhắn phải dài 1–1000 ký tự.' });
      // Gui ca cho nguoi gui va nhung nguoi con lai.
      io.emit('new_message', { username: socket.data.username, message });
      socket.broadcast.emit('typing', { id: socket.id, username: socket.data.username, active: false });
      respond(ack, { ok: true });
    });
    socket.on('typing', data => {
      socket.broadcast.emit('typing', { id: socket.id, username: socket.data.username, active: data?.active !== false });
    });
    socket.on('disconnect', () => {
      socket.broadcast.emit('typing', { id: socket.id, username: socket.data.username, active: false });
      console.log(new Date().toISOString(), 'User disconnected', socket.id);
    });
  });
  return { app, server, io };
}

if (require.main === module) {
  const stage = process.env.LAB_STAGE || 'full';
  const port = Number(process.env.PORT || 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid PORT');
  const { server } = createChatServer(stage);
  server.on('error', error => { console.error(error.message); process.exitCode = 1; });
  server.listen(port, '0.0.0.0', () => console.log(`Stage=${stage}; open http://localhost:${port}`));
}
module.exports = { createChatServer };
