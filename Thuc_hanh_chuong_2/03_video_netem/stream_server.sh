#!/usr/bin/env bash
set -euo pipefail
mode="${1:-}"; file="${2:-}"
command -v cvlc >/dev/null || { echo 'Can: sudo apt install vlc' >&2; exit 1; }
[[ $EUID -ne 0 ]] || { echo 'VLC khong chay bang root. Hay chay bang tai khoan thuong.' >&2; exit 1; }
[[ -f "$file" ]] || { echo 'Usage: bash stream_server.sh http FILE.ogv | udp FILE.ts CLIENT_IP' >&2; exit 1; }
case "$mode" in
  http) [[ $# -eq 2 ]] || exit 1; sout='#standard{access=http,mux=ogg,dst=:8080}' ;;
  udp)
    [[ $# -eq 3 && "$3" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo 'UDP can IPv4 cua client.' >&2; exit 1; }
    sout="#standard{access=udp,mux=ts,dst=$3:5004}" ;;
  *) echo 'Mode: http hoac udp'; exit 1 ;;
esac
exec cvlc --no-one-instance -vv --loop --no-video-title-show "$file" --sout "$sout" --sout-keep
