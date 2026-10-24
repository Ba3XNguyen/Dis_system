#!/usr/bin/env bash
# Hai may Linux logic tren mot Ubuntu, dung network namespaces va veth.
# Goi bang tai khoan thuong. Script chi xin sudo cho thao tac mang.
set -euo pipefail
base=$(cd "$(dirname "$0")" && pwd)
server=ch2-server; client=ch2-client
exists() { ip netns list | awk '{print $1}' | grep -Fxq "$1"; }
case "${1:-}" in
  setup)
    command -v ip >/dev/null
    if exists "$server" || exists "$client"; then echo 'Namespace da ton tai. Xem status hoac cleanup truoc.'; exit 1; fi
    # Sau khi setup, hai namespace chi co mang rieng cua bai lab, khong co default route.
    sudo ip netns add "$server"
    trap 'sudo ip link del ch2-vs 2>/dev/null || true; sudo ip netns del "$server" 2>/dev/null || true; sudo ip netns del "$client" 2>/dev/null || true' ERR
    sudo ip netns add "$client"
    sudo ip link add ch2-vs type veth peer name ch2-vc
    sudo ip link set ch2-vs netns "$server"
    sudo ip link set ch2-vc netns "$client"
    sudo ip -n "$server" link set ch2-vs name eth0
    sudo ip -n "$client" link set ch2-vc name eth0
    sudo ip -n "$server" addr add 10.202.0.1/24 dev eth0
    sudo ip -n "$client" addr add 10.202.0.2/24 dev eth0
    for ns in "$server" "$client"; do sudo ip -n "$ns" link set lo up; sudo ip -n "$ns" link set eth0 up; done
    trap - ERR
    echo 'Server=10.202.0.1, client=10.202.0.2, interface=eth0 trong moi namespace.' ;;
  status)
    sudo ip -n "$server" -br addr
    sudo ip -n "$client" -br addr ;;
  ping) sudo ip netns exec "$server" ping -c 5 10.202.0.2 ;;
  netem) shift; sudo ip netns exec "$server" bash "$base/netem.sh" eth0 "$@" ;;
  server|client)
    action="$1"; shift
    [[ $EUID -ne 0 ]] || { echo 'Goi one_host.sh bang tai khoan thuong, khong dat sudo o dau.'; exit 1; }
    ns="$server"; [[ "$action" == client ]] && ns="$client"
    # Giu cac bien GUI de VLC co the mo cua so bang Unix socket cua desktop hien tai.
    sudo ip netns exec "$ns" runuser -u "$(id -un)" -- env \
      "PATH=$PATH" "DISPLAY=${DISPLAY:-}" "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}" \
      "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}" "XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}" \
      "DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-}" \
      bash "$base/stream_${action}.sh" "$@" ;;
  cleanup)
    # Dong 2 tien trinh VLC truoc de giai phong network namespace.
    for ns in "$server" "$client"; do
      if exists "$ns"; then
        if [[ -n "$(sudo ip netns pids "$ns")" ]]; then
          echo "Con process trong $ns. Dong VLC/ping cua bai lab truoc khi cleanup." >&2; exit 1
        fi
      fi
    done
    for ns in "$server" "$client"; do if exists "$ns"; then sudo ip netns del "$ns"; fi; done ;;
  *) echo 'Usage: bash one_host.sh setup | status | ping | netem PROFILE | server ... | client ... | cleanup'; exit 1 ;;
esac
