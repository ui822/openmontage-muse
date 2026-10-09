#!/usr/bin/env bash
# openmontage-muse 合成脚本：规格统一 + 拼接 + 旁白混音 + 可选字幕
# 用法: compose.sh clips.txt narration.mp3 out.mp4 [subs.srt] [WxH] [fps]
#   clips.txt: 每行一个片段路径；支持空行、# 注释、CRLF、file '...' 包裹
# 修过的坑: 无声片段自动补静音轨；旁白更长时循环画面铺满（不静默截断）；
#           字幕路径含空格/引号/冒号正确转义；统一分辨率/帧率/编码再拼接。
set -euo pipefail

command -v ffmpeg >/dev/null 2>&1 || { echo 'missing ffmpeg' >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo 'missing ffprobe' >&2; exit 1; }

[ $# -ge 3 ] || { echo 'usage: compose.sh clips.txt narration.mp3 out.mp4 [subs.srt] [WxH] [fps]' >&2; exit 1; }
CLIPS_LIST=$1
NARRATION=$2
OUT=$3
SUBS=${4:-}
TARGET_WH=${5:-1280x720}
TARGET_FPS=${6:-30}
W=${TARGET_WH%x*}
H=${TARGET_WH#*x}
[ -f "$NARRATION" ] || { echo 'narration file not found' >&2; exit 1; }

printf -v SCALE_VF 'scale=%s:%s:force_original_aspect_ratio=decrease,pad=%s:%s:(ow-iw)/2:(oh-ih)/2:color=black,fps=%s,format=yuv420p' "$W" "$H" "$W" "$H" "$TARGET_FPS"

has_audio() {
  ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$1" 2>/dev/null | grep -q .
}

duration_of() {
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null || echo 0
}

is_longer() {
  awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'
}

escape_subs() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\'/\\\'}
  s=${s//:/\\:}
  printf '%s' "$s"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

i=0
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%$'\r'}
  line=$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  [ -z "$line" ] && continue
  [[ $line == '#'* ]] && continue
  if [[ $line == 'file '* ]]; then
    inner=${line#file }
    inner=${inner#\'}
    inner=${inner%\'}
    inner=${inner#\"}
    inner=${inner%\"}
    line=$inner
  fi
  [ -f "$line" ] || { echo "clip not found: $line" >&2; exit 1; }

  part=$WORK/part$(printf %03d $i).mp4
  if has_audio "$line"; then
    ffmpeg -y -nostdin -v error -i "$line" -vf "$SCALE_VF" -c:v libx264 -c:a aac -ar 44100 -ac 2 "$part"
  else
    echo "note: no audio in $line, padding silence"
    ffmpeg -y -nostdin -v error -i "$line" -f lavfi -i anullsrc=r=44100:cl=stereo \
      -filter_complex "[0:v]${SCALE_VF}[v]" \
      -map '[v]' -map 1:a -c:v libx264 -c:a aac -ar 44100 -ac 2 -shortest "$part"
  fi
  i=$((i+1))
done < "$CLIPS_LIST"

[ "$i" -eq 0 ] && { echo 'no usable clips in list' >&2; exit 1; }
echo "normalized $i clips to ${W}x${H}@${TARGET_FPS}fps h264/aac"

: > "$WORK/concat.txt"
for p in "$WORK"/part*.mp4; do echo "file '$p'" >> "$WORK/concat.txt"; done
ffmpeg -y -v error -f concat -safe 0 -i "$WORK/concat.txt" -c copy "$WORK/joined.mp4"

vdur=$(duration_of "$WORK/joined.mp4")
ndur=$(duration_of "$NARRATION")
echo "video ${vdur}s, narration ${ndur}s"

VF='format=yuv420p'
if [ -n "$SUBS" ]; then
  [ -f "$SUBS" ] || { echo 'subtitle file not found' >&2; exit 1; }
  if ffmpeg -hide_banner -h filter=subtitles 2>/dev/null | grep -q libass; then
    ESC=$(escape_subs "$SUBS")
    VF="format=yuv420p,subtitles='$ESC'"
  else
    echo 'warning: no libass, skipping subtitles' >&2
  fi
fi

MIX='[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=0[a]'
if is_longer "$ndur" "$vdur"; then
  echo 'narration longer than video, looping video to fit'
  loops=$(awk -v n="$ndur" -v v="$vdur" 'BEGIN{c=(v>0?n/v:1); printf "%d", (c>int(c) ? int(c)+1 : int(c))}')
  [ "$loops" -lt 1 ] && loops=1
  ffmpeg -y -v error -stream_loop "$loops" -i "$WORK/joined.mp4" -i "$NARRATION" \
    -filter_complex "$MIX" -map 0:v -map '[a]' -vf "$VF" -c:v libx264 -c:a aac -t "$ndur" "$OUT"
else
  ffmpeg -y -v error -i "$WORK/joined.mp4" -i "$NARRATION" \
    -filter_complex "$MIX" -map 0:v -map '[a]' -vf "$VF" -c:v libx264 -c:a aac -shortest "$OUT"
fi

echo "done: $OUT"
duration_of "$OUT"
