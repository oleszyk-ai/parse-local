# 🔍 Parse-Local

**Like [Parse.bot](https://parse.bot) but runs 100% on your machine.**

AI-powered web scraper that uses a local LLM (Mistral Nemo 12B) to extract
structured data from any webpage. No API keys. No cloud. No data leaves your PC.

![Python](https://img.shields.io/badge/Python-3.10+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🚀 Quick Start

### Linux / macOS
```bash
git clone https://github.com/oleszyk-ai/parse-local.git
cd parse-local
chmod +x setup.sh && ./setup.sh
source .venv/bin/activate
python -m app.main