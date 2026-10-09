#!/usr/bin/env bash
# openmontage-muse 配音快捷调用：按名字选音色，自动走 Fish Audio 免费档
# 用法: speak.sh "配音文案" <音色名> <输出mp3>
# 音色名: AD学姐 | 贾小军 | 温柔动听女声 | 宣传片大气浑厚 | 女大学生
set -euo pipefail

TEXT="${1:?usage: speak.sh \"文案\" <音色名> <输出mp3>}"
VOICE_NAME="${2:?usage: speak.sh \"文案\" <音色名> <输出mp3>}"
OUT="${3:?usage: speak.sh \"文案\" <音色名> <输出mp3>}"

case "$VOICE_NAME" in
  AD学姐)          REF="7f92f8afb8ec43bf81429cc1c9199cb1" ;;
  贾小军)          REF="80cf680e668c44fc8d5795f80d903f7a" ;;
  温柔动听女声)     REF="faccba1a8ac54016bcfc02761285e67f" ;;
  宣传片大气浑厚)   REF="dd43b30d04d9446a94ebe41f301229b5" ;;
  女大学生)         REF="5c353fdb312f4888836a9a5680099ef0" ;;
  *) echo "未知音色" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../fish-audio/bin/tts.py" ]; then
  TTS_PY="$SCRIPT_DIR/../fish-audio/bin/tts.py"
else
  TTS_PY="$HOME/workspace/skills/fish-audio/bin/tts.py"
fi
[ -f "$TTS_PY" ] || { echo "找不到 tts.py：请确认 fish-audio 已安装" >&2; exit 1; }

python3 "$TTS_PY" "$TEXT" "$OUT" --reference-id "$REF" --model s2.1-pro-free
