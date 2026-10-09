#!/usr/bin/env bash
# openmontage-muse 合成脚本：拼接视频片段 + 混入旁白 + 可选字幕
# 用法: compose.sh <clips.txt> <narration.mp3> <out.mp4> [subs.srt]
set -euo pipefail

CLIPS_LIST="${1:?usage: compose.sh <clips.txt> <narration.mp3> <out.mp4> [subs.srt]}"
NARRATION="${2:?usage: compose.sh <clips.txt> <narration.mp3> <out.mp4> [subs.srt]}"
OUT="${3:?usage: compose.sh <clips.txt> <narration.mp3> <out.mp4> [subs.srt]}"
SUBS="${4:-}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

i=0
while IFS= read -r line; do
  f="${line#file }"
  f="${f#\'}"; f="${f%\'}"
  [ -z "$f" ] && continue
  ffmpeg -y -v error -i "$f" -c:v libx264 -pix_fmt yuv420p -c:a aac -ar 44100 "$WORK/part$(printf %03d $i).mp4"
  i=$((i+1))
done < "$CLIPS_LIST"
[ "$i" -eq 0 ] && { echo "no clips found in $CLIPS_LIST" >&2; exit 1; }

: > "$WORK/concat.txt"
for p in "$WORK"/part*.mp4; do echo "file '$p'" >> "$WORK/concat.txt"; done
ffmpeg -y -v error -f concat -safe 0 -i "$WORK/concat.txt" -c copy "$WORK/joined.mp4"

if [ -n "${SUBS}" ]; then
  SUBVF=",subtitles=${SUBS}"
else
  SUBVF=""
fi
ffmpeg -y -v error -i "$WORK/joined.mp4" -i "$NARRATION" \
  -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=0[a]" \
  -map 0:v -map "[a]" -vf "format=yuv420p${SUBVF}" \
  -c:v libx264 -c:a aac -shortest "$OUT"

echo "done: $OUT"
