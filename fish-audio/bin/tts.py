#!/usr/bin/env python3
"""Fish Audio TTS 合成。凭证经安全机制注入，脚本只接触占位符。

用法:
  python3 tts.py "要合成的文字" out.mp3
  python3 tts.py "要合成的文字" out.mp3 --reference-id <voice_id>
  python3 tts.py "要合成的文字" out.mp3 --model s2.1-pro
"""
import argparse
import json
import sys
import urllib.request

FREE_MODEL = "s2.1-pro-free"


def main() -> int:
    p = argparse.ArgumentParser(description="Fish Audio TTS 合成")
    p.add_argument("text", help="要合成的文字")
    p.add_argument("output", help="输出音频路径")
    p.add_argument("--reference-id", default="", help="音色模型 id（留空用默认音色）")
    p.add_argument("--model", default=FREE_MODEL,
                   help=f"后端模型，默认 {FREE_MODEL}（免费档）")
    p.add_argument("--format", default="mp3", help="输出格式 mp3/wav/opus，默认 mp3")
    p.add_argument("--api-key", default="", help="Fish Audio API key（或设 FISH_API_KEY 环境变量）")
    args = p.parse_args()

    import os
    api_key = args.api_key or os.environ.get("FISH_API_KEY", "")
    if not api_key:
        print("缺少 API key：--api-key 传入或设置 FISH_API_KEY 环境变量", file=sys.stderr)
        return 2

    body = {"text": args.text, "format": args.format}
    if args.reference_id:
        body["reference_id"] = args.reference_id
    data = json.dumps(body, ensure_ascii=False).encode("utf-8")

    req = urllib.request.Request(
        "https://api.fish.audio/v1/tts",
        data=data,
        headers={"Content-Type": "application/json",
                 "Authorization": f"Bearer {api_key}",
                 "model": args.model},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        audio = resp.read()

    with open(args.output, "wb") as f:
        f.write(audio)
    print(f"已保存: {args.output}（{len(audio)} 字节，模型 {args.model}）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
