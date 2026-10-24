// Dung io() de tu lay dia chi server, ke ca khi truy cap bang IP LAN.
const socket = io();
const byId = id => document.getElementById(id);
const status = byId('status');
const input = byId('message');
const error = byId('error');
const typingUsers = new Map();
function renderTyping() {
  byId('feedback').textContent = [...typingUsers.values()].map(x => x.name).join(', ') + (typingUsers.size ? ' đang gõ...' : '');
}
socket.on('connect', () => {
  status.textContent = 'Đã kết nối';
  if (document.body.dataset.stage === 'full' && byId('username').value.trim()) {
    socket.emit('change_username', { username: byId('username').value });
  }
});
socket.on('disconnect', () => {
  status.textContent = 'Mất kết nối, đang thử lại...';
  for (const user of typingUsers.values()) clearTimeout(user.timer);
  typingUsers.clear(); renderTyping();
});
socket.on('connect_error', () => { status.textContent = 'Chưa kết nối được server.'; });
if (document.body.dataset.stage === 'full') {
  byId('username-form').addEventListener('submit', event => {
    event.preventDefault();
    socket.emit('change_username', { username: byId('username').value }, result => {
      error.textContent = result.ok ? '' : result.error;
      if (result.ok) status.textContent = 'Đã kết nối - tên: ' + result.username;
    });
  });
  byId('message-form').addEventListener('submit', event => {
    event.preventDefault();
    if (!socket.connected) { error.textContent = 'Hãy chờ kết nối lại.'; return; }
    socket.emit('new_message', { message: input.value }, result => {
      error.textContent = result.ok ? '' : result.error;
      if (result.ok) input.value = '';
    });
  });
  socket.on('new_message', data => {
    const line = document.createElement('p');
    // textContent giu nguyen van ban, khong chen noi dung nguoi dung thanh HTML.
    line.textContent = data.username + ': ' + data.message;
    byId('chatroom').append(line);
    byId('chatroom').scrollTop = byId('chatroom').scrollHeight;
  });
  let stopTimer;
  let lastTyping = 0;
  input.addEventListener('input', () => {
    if (Date.now() - lastTyping > 300) {
      socket.emit('typing', { active: true }); lastTyping = Date.now();
    }
    clearTimeout(stopTimer);
    stopTimer = setTimeout(() => socket.emit('typing', { active: false }), 1200);
  });
  socket.on('typing', data => {
    if (typingUsers.has(data.id)) clearTimeout(typingUsers.get(data.id).timer);
    typingUsers.delete(data.id);
    if (data.active) {
      typingUsers.set(data.id, { name: data.username, timer: setTimeout(() => {
        typingUsers.delete(data.id); renderTyping();
      }, 1800) });
    }
    renderTyping();
  });
} else {
  byId('username-form').hidden = true;
  byId('message-form').hidden = true;
}
