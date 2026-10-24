#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v ffmpeg >/dev/null || { echo 'Can: sudo apt install ffmpeg' >&2; exit 1; }
seconds="${1:-60}"
[[ "$seconds" =~ ^[0-9]+$ && "$seconds" -ge 5 && "$seconds" -le 300 ]] || { echo 'Duration 5..300 seconds'; exit 1; }
mkdir -p media
# Video thu nghiem co chuyen dong, am thanh, khong can tai video ben ngoai.
# -n giu file da tao; neu muon tao lai, doi ten hoac xoa dung file media/sample.*.
for format in ogv ts; do
  [[ -s "media/sample.$format" ]] && { echo "Da co media/sample.$format"; continue; }
  if [[ "$format" == ogv ]]; then codecs=(-c:v libtheora -q:v 5 -c:a libvorbis -q:a 3); else codecs=(-c:v mpeg2video -b:v 1200k -g 25 -c:a mp2 -b:a 96k -f mpegts); fi
  ffmpeg -hide_banner -loglevel warning -n -f lavfi -i testsrc2=size=640x360:rate=25 \
    -f lavfi -i sine=frequency=440:sample_rate=44100 -t "$seconds" "${codecs[@]}" "media/sample.$format"
done
echo 'Da tao sample.ogv (HTTP/OGG) va sample.ts (UDP/MPEG-TS).'
