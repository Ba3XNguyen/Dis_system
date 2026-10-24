#!/usr/bin/env bash
set -u
for cmd in node npm java javac docker curl vlc cvlc ffmpeg ip tc ping; do
  if command -v "$cmd" >/dev/null 2>&1; then printf '%-9s %s\n' "$cmd" "$(command -v "$cmd")"; else printf '%-9s CHUA CAI\n' "$cmd"; fi
done
if command -v node >/dev/null; then node --version; fi
if command -v java >/dev/null; then java -version 2>&1 | head -1; fi
if command -v docker >/dev/null; then
  if docker info >/dev/null 2>&1; then echo 'Docker daemon: OK'; else echo 'Docker daemon: chua ket noi duoc (quyen hoac dich vu).'; fi
fi
echo 'Lenh nay chi kiem tra, khong thay doi he thong.'
