#!/usr/bin/env bash
# Chi sua root qdisc cua giao dien ban chi dinh. Nen dung eth0 trong namespace demo.
set -euo pipefail
usage() { echo 'Usage: sudo bash netem.sh IFACE PROFILE [--dry-run]'; echo 'PROFILE: baseline delay100 jitter jitter-corr loss01 loss1 loss5 loss10 loss-corr loss-corr5 duplicate1 duplicate10 corrupt01 corrupt1 reorder show reset'; }
[[ $# -ge 2 && $# -le 3 ]] || { usage; exit 1; }
iface="$1"; profile="$2"; dry=0
[[ "$iface" =~ ^[a-zA-Z0-9_.:-]+$ ]] || { echo 'Invalid interface' >&2; exit 1; }
if [[ $# -eq 3 ]]; then [[ "$3" == --dry-run ]] || { usage; exit 1; }; dry=1; fi
delay=(0ms); loss=(0%); duplicate=0%; corrupt=0%; reorder=(0%)
case "$profile" in
  baseline) ;;
  delay100) delay=(100ms) ;;
  jitter) delay=(100ms 10ms) ;;
  jitter-corr) delay=(100ms 10ms 25%) ;;
  loss01) loss=(0.1%) ;;
  loss1) loss=(1%) ;;
  loss5) loss=(5%) ;;
  loss10) loss=(10%) ;;
  loss-corr) loss=(0.3% 25%) ;;
  loss-corr5) loss=(5% 25%) ;;
  duplicate1) duplicate=1% ;;
  duplicate10) duplicate=10% ;;
  corrupt01) corrupt=0.1% ;;
  corrupt1) corrupt=1% ;;
  reorder) delay=(10ms); reorder=(25% 50%) ;;
  show|reset) ;;
  *) usage; exit 1 ;;
esac
run() { if ((dry)); then printf '%q ' "$@"; printf '\n'; else "$@"; fi; }
if (( ! dry )); then
  command -v tc >/dev/null; command -v ip >/dev/null
  ip link show dev "$iface" >/dev/null
  [[ "$profile" == show || $EUID -eq 0 ]] || { echo 'Hay dung sudo.' >&2; exit 1; }
fi
if [[ "$profile" == show ]]; then run tc -s qdisc show dev "$iface"; exit; fi
if [[ "$profile" == reset ]]; then
  if ((dry)); then run tc qdisc del dev "$iface" root handle 20:; exit; fi
  if tc qdisc show dev "$iface" | grep -Eq '^qdisc netem 20: root'; then
    run tc qdisc del dev "$iface" root handle 20:
  else echo 'Khong co qdisc netem 20: cua bai lab de xoa.'; fi
  exit
fi
if (( ! dry )); then
  # Khong ghi de mot qdisc tu cau hinh cua nguoi dung.
  root=$(tc qdisc show dev "$iface" | awk '/ root / {print $2 " " $3; exit}')
  case "$root" in
    ''|'noqueue 0:'|'fq_codel 0:'|'pfifo_fast 0:'|'mq 0:'|'netem 20:') ;;
    *) echo "Giao dien da co qdisc rieng ($root). Hay dung giao dien demo khac." >&2; exit 1 ;;
  esac
fi
# Chi ro tat ca hieu ung: doi profile se khong giu loss/jitter cua lan thu truoc.
run tc qdisc replace dev "$iface" root handle 20: netem limit 1000 \
  delay "${delay[@]}" loss "${loss[@]}" duplicate "$duplicate" corrupt "$corrupt" reorder "${reorder[@]}"
run tc -s qdisc show dev "$iface"
