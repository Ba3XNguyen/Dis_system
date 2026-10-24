#!/usr/bin/env bash
set -euo pipefail
mode="${1:-}"; host="${2:-}"; cache="${3:-1000}"
[[ "$cache" =~ ^[0-9]+$ && "$cache" -le 60000 ]] || { echo 'Cache 0..60000 ms'; exit 1; }
command -v vlc >/dev/null || { echo 'Can: sudo apt install vlc'; exit 1; }
[[ $EUID -ne 0 ]] || { echo 'Chay VLC bang tai khoan thuong.' >&2; exit 1; }
case "$mode" in
  http)
    [[ "$host" =~ ^[a-zA-Z0-9.-]+$ ]] || { echo 'Can hostname/IP server'; exit 1; }
    url="http://$host:8080" ;;
  udp) url='udp://@:5004' ;;
  *) echo 'Usage: bash stream_client.sh http SERVER_IP [CACHE_MS] | udp ignored [CACHE_MS]'; exit 1 ;;
esac
exec vlc --no-one-instance --no-video-title-show --network-caching="$cache" --live-caching="$cache" "$url"
