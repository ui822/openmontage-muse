#!/usr/bin/env bash
# openmontage-muse 环境预检：换环境 / 隔段时间后先跑这个
# 用法: scripts/preflight.sh
set -uo pipefail

ok=1
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok: $desc"; else echo "MISSING: $desc"; ok=0; fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== 基础依赖 =="
check "ffmpeg" command -v ffmpeg
check "ffprobe" command -v ffprobe
check "python3" command -v python3
if ffmpeg -hide_banner -h filter=subtitles 2>/dev/null | grep -q libass; then
  echo "ok: 字幕支持 (libass)"
else
  echo "MISSING: 字幕支持 (libass) —— compose.sh 会自动跳过字幕"; ok=0
fi

echo "== 脚本 =="
check "speak.sh 可执行" test -x "$SCRIPT_DIR/speak.sh"
check "compose.sh 可执行" test -x "$SCRIPT_DIR/compose.sh"

echo "== Fish Audio =="
if [ -f "$SCRIPT_DIR/../fish-audio/bin/tts.py" ]; then
  echo "ok: tts.py（包内自带）"
elif [ -f "$HOME/workspace/skills/fish-audio/bin/tts.py" ]; then
  echo "ok: tts.py（skills 目录已安装）"
else
  echo "MISSING: tts.py"; ok=0
fi

echo "== 结论 =="
if [ "$ok" -eq 1 ]; then echo "全部通过，可以生产"; else echo "有未通过项，先修好再生产"; fi
exit $((1 - ok))
