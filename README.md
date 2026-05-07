
<div align="center">

# 🔍 Parse-Local

**Give it a URL, describe what you want, get back structured JSON.**
*No API keys. No cloud. No data leaves your machine.*

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Model](https://img.shields.io/badge/LLM-Mistral_Nemo_12B-ff6b35?style=for-the-badge)](https://huggingface.co/mistralai/Mistral-Nemo-Instruct-2407)

[Report Bug](https://github.com/oleszyk-ai/parse-local/issues) · [Request Feature](https://github.com/oleszyk-ai/parse-local/issues)

</div>

---

## ⚡ Quick Start

> [!IMPORTANT]
> First run downloads the model (~7 GB). Make sure you have enough disk space.

```bash
git clone https://github.com/oleszyk-ai/parse-local.git
cd parse-local
python start.py
```

One command handles everything — virtual environment, GPU detection, dependencies, model download, and server startup.

Then open **http://localhost:8000**

**Docker alternative:**
```bash
docker-compose up --build
```

---

## 📋 Requirements

| | Minimum | Recommended |
| :--- | :--- | :--- |
| **Python** | 3.10+ | 3.11+ |
| **RAM** | 8 GB | 16 GB+ |
| **Disk** | 8 GB free | NVMe SSD |
| **GPU** | Optional | NVIDIA 8GB+ VRAM |

> [!TIP]
> No GPU? It still works on CPU, just slower. The setup script auto-detects your hardware.

---

## 🔌 API

**Scrape a URL**
```bash
curl -X POST http://localhost:8000/api/scrape/url \
  -H "Content-Type: application/json" \
  -d '{"url": "https://news.ycombinator.com", "prompt": "Extract top 10 story titles and scores"}'
```

**Parse raw HTML**
```bash
curl -X POST http://localhost:8000/api/scrape/html \
  -H "Content-Type: application/json" \
  -d '{"html": "<div>...</div>", "prompt": "Extract all product names and prices"}'
```

**Response**
```json
{
  "success": true,
  "data": { "..." },
  "elapsed_seconds": 14.2
}
```

---

## ⚙️ Configuration

`.env` is created automatically on first run. Edit it to change settings:

```ini
N_GPU_LAYERS=-1     # -1 = GPU, 0 = CPU only
N_CTX=8192          # context window — increase for longer pages
TEMPERATURE=0.1     # lower = more consistent output
PORT=8000           # server port
```

**Available commands:**
```bash
python start.py           # auto-setup + run
python start.py --setup   # force re-run setup
python start.py --run     # skip setup, just run
```

---

## 🔧 Troubleshooting

<details>
<summary><b>Model download failed</b></summary>

Download `Mistral-Nemo-Instruct-2407-Q4_K_M.gguf` manually from
[Hugging Face](https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF)
and place it in the `models/` directory.

</details>

<details>
<summary><b>Out of memory</b></summary>

Set `N_CTX=4096` and `N_GPU_LAYERS=0` in `.env`

</details>

<details>
<summary><b>Port already in use</b></summary>

Set `PORT=8080` in `.env`

</details>

<details>
<summary><b>Windows — script blocked by Device Guard</b></summary>

The setup script uses `python -m pip` instead of `pip.exe` to bypass Device Guard policies.
If you still hit issues, run directly in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

</details>

---

## 🛠️ Built With

[ScrapeGraphAI](https://github.com/ScrapeGraphAI/Scrapegraph-ai) ·
[llama-cpp-python](https://github.com/abetlen/llama-cpp-python) ·
[Mistral Nemo 12B](https://mistral.ai/news/mistral-nemo/) ·
[FastAPI](https://fastapi.tiangolo.com/)

---

<div align="center">

Made with ❤️ by [oleszyk-ai](https://github.com/oleszyk-ai) · *Found this useful? Give it a ⭐*

</div>
```
