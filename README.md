# ⭐ Support This Project

如果这个项目帮你用零成本做出了视频，欢迎点一个 ⭐ Star 支持！

你的每一次 Star，都是持续更新的动力 ❤️

[![GitHub Stars](https://img.shields.io/github/stars/ui822/openmontage-muse?style=for-the-badge)](https://github.com/ui822/openmontage-muse/stargazers) [![GitHub Forks](https://img.shields.io/github/forks/ui822/openmontage-muse?style=for-the-badge)](https://github.com/ui822/openmontage-muse/network/members) [![GitHub Issues](https://img.shields.io/github/issues/ui822/openmontage-muse?style=for-the-badge)](https://github.com/ui822/openmontage-muse/issues)

---

# OpenMontage-Muse 🎬

OpenMontage 的 Muse 适配版：把 agentic 视频生产管线跑在 Muse 原生能力上——自带视频生成做片段、Fish Audio 免费档做配音、ffmpeg 做合成，**全程零 API key、零费用**。

原版上游：[calesthio/OpenMontage](https://github.com/calesthio/OpenMontage)（65k star，第一个开源 agentic 视频生产系统）

## 能力映射

| 原版环节 | 原版（需 key/付费） | 本版替代 |
|---|---|---|
| 视频片段 | Veo / Kling / MiniMax | 自带视频生成（分镜按 ≤6 个场景规划） |
| 配音 | ElevenLabs / Google TTS | Fish Audio 免费档（s2.1-pro-free，$0 至 2026-11-30） |
| 合成 | Remotion | ffmpeg（`scripts/compose.sh`） |

## 快速开始

```sh
# 1. 配音（5 个热门音色按名字选）
scripts/speak.sh "旁白文案" 温柔动听女声 narration.mp3
# 2. 合成（clips.txt 每行一个片段路径）
scripts/compose.sh clips.txt narration.mp3 final.mp4
```

完整生产管线（分镜 → 生成 → 配音 → 合成 → 审片）见 [SKILL.md](SKILL.md)。

## 文件结构

- `SKILL.md` — 完整 skill 说明（管线、硬约束、Fish Audio key 配置）
- `scripts/speak.sh` — 按音色名一键配音（AD学姐 / 贾小军 / 温柔动听女声 / 宣传片大气浑厚 / 女大学生）
- `scripts/compose.sh` — ffmpeg 拼接 + 混音 + 可选字幕
- `fish-audio/` — 打包的 fish-audio skill（`bin/tts.py`、`bin/voices.py`）

## 前置依赖

- ffmpeg
- Fish Audio API key（免费档；不要贴在公开处）
