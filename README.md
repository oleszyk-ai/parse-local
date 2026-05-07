

<div align="center">

# 🔍 Parse-Local

**The privacy-focused bridge between the messy web and structured data.**

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Model](https://img.shields.io/badge/LLM-Mistral_Nemo_12B-ff6b35?style=for-the-badge)](https://huggingface.co/mistralai/Mistral-Nemo-Instruct-2407)

**Give it a URL, describe what you want, and get back structured JSON.**
*No API keys. No cloud. No data leaves your machine.*

[Report Bug](https://github.com/oleszyk-ai/parse-local/issues) · [Request Feature](https://github.com/oleszyk-ai/parse-local/issues)

---

### 🌐 [Visit the Web UI](http://localhost:8000) &nbsp;•&nbsp; 🧪 [Try the API](#-api-reference) &nbsp;•&nbsp; 🚀 [Get Started](#-quick-start)

</div>

---

## ✨ Why Parse-Local?

| 🛡️ Privacy First | 🤖 Intelligent | 🔌 Developer Ready |
| :--- | :--- | :--- |
| Runs 100% locally. Your data, your RAM, your business. | Uses Mistral Nemo 12B to understand site context automatically. | Standard REST API that fits into any workflow. |

---

## ⚡ Quick Start

> [!IMPORTANT]
> The first run will download the Mistral model (~7 GB). Ensure you have a stable connection and enough disk space.

### 🐧 Linux & 🍎 macOS

```bash
# Clone the repository
git clone https://github.com/oleszyk-ai/parse-local.git
cd parse-local

# Run the setup script
chmod +x setup.sh && ./setup.sh

# Activate environment and launch
source .venv/bin/activate && python -m app.main
```

### 🪟 Windows

```powershell
# Clone the repository
git clone https://github.com/oleszyk-ai/parse-local.git
cd parse-local

# Run the setup script
./setup.bat

# Activate and launch
.venv\Scripts\activate
python -m app.main
```

### 🐳 Docker (Quickest Way)

```bash
docker-compose up --build
```

---

## 📋 Hardware Requirements

| Resource | Minimum | Recommended |
| :--- | :--- | :--- |
| **Python** | 3.10+ | 3.11+ |
| **RAM** | 8 GB | 16 GB+ |
| **Disk** | 8 GB free | NVMe SSD |
| **GPU** | Optional | NVIDIA 8GB+ VRAM |

---

## 🔌 API Reference

### 1. Scrape a live URL

`POST /api/scrape/url`

```bash
curl -X POST http://localhost:8000/api/scrape/url \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://news.ycombinator.com",
    "prompt": "Extract the top 10 story titles and scores"
  }'
```

### 2. Parse raw HTML

`POST /api/scrape/html`

```bash
curl -X POST http://localhost:8000/api/scrape/html \
  -H "Content-Type: application/json" \
  -d '{
    "html": "<div><h1>Product A</h1><span>$20</span></div>",
    "prompt": "Extract all product names and prices"
  }'
```

---

## ⚙️ Configuration

Create a `.env` file in the project root to tune performance:

```ini
N_GPU_LAYERS=-1     # -1 = All layers on GPU (requires CUDA/Metal)
N_CTX=8192          # Context window (increase for longer pages)
TEMPERATURE=0.1     # Lower = more consistent JSON output
PORT=8000           # Server port
```

---

## 🖥️ GPU Acceleration

> [!TIP]
> Enabling GPU acceleration can speed up inference by **5–10x**.

<details>
<summary><b>NVIDIA (CUDA) Setup</b></summary>

```bash
pip uninstall llama-cpp-python -y
CMAKE_ARGS="-DGGML_CUDA=on" pip install llama-cpp-python --no-cache-dir
```

</details>

<details>
<summary><b>Apple Silicon (Metal) Setup</b></summary>

```bash
pip uninstall llama-cpp-python -y
CMAKE_ARGS="-DGGML_METAL=on" pip install llama-cpp-python --no-cache-dir
```

</details>

---

## 🔧 Troubleshooting

<details>
<summary><b>Model download is too slow or fails</b></summary>

Download <code>Mistral-Nemo-Instruct-2407-Q4_K_M.gguf</code> manually from
<a href="https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF">Hugging Face</a>
and place it in the <code>models/</code> directory.

</details>

<details>
<summary><b>Port 8000 is already in use</b></summary>

Launch with a different port: <code>PORT=8080 python -m app.main</code>

</details>

<details>
<summary><b>Installation errors (C++ Build Tools)</b></summary>

<b>Windows:</b> Install <a href="https://visualstudio.microsoft.com/visual-cpp-build-tools/">VS Build Tools</a> with the "Desktop development with C++" workload.<br>
<b>macOS:</b> Run <code>xcode-select --install</code>.

</details>

---

## 🛠️ Built With

- [ScrapeGraphAI](https://github.com/ScrapeGraphAI/Scrapegraph-ai) — Intelligent scraping logic
- [llama-cpp-python](https://github.com/abetlen/llama-cpp-python) — Local LLM inference
- [Mistral Nemo 12B](https://mistral.ai/news/mistral-nemo/) — State-of-the-art local model
- [FastAPI](https://fastapi.tiangolo.com/) — High-performance backend

---

<div align="center">

Made with ❤️ by [oleszyk-ai](https://github.com/oleszyk-ai)

*Found this useful? Give it a ⭐!*

</div>
