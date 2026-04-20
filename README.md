# Local LLM Studio 🧠

A fully **offline, self-hosted** LLM environment with built-in **RAG (Retrieval-Augmented Generation)** and a **Vector Database**. Drop in your own documents and chat with your knowledge base entirely on your own hardware — no cloud, no internet required on the target machine.

Powered by `llama.cpp` (GGUF engine) + `LanceDB` + `FastEmbed` + `FastAPI`.

---

## ⚡ Quick Start — Run Everything Now

> **Choose your path below.** Each path is fully sequential — copy and run every command block in order.

---

### Path A — One-Click Auto Setup (Internet-Connected Machine)

Get the full stack (environment, dependencies, models, and servers) running on your laptop/workstation with a single script.

**Step 1: Clone the repo**
```bash
git clone https://github.com/somphouang/local-llm-studio.git
cd local-llm-studio
```

**Step 2: Run the Start-All script**
```bash
chmod +x start-all.sh
./start-all.sh
```
> **Note:** The first run may take 5–10 minutes to compile `llama-cpp-python` from C++ source. If no models are found, it will automatically download a tiny test model.

This script automatically sets up the virtual environment, installs dependencies, loads models, and starts **both** the LLM inference server and the RAG server + Web UI.

**Step 3: Access the UI**
Once the script says "ALL SYSTEMS GO!", open your browser:
- **Chat UI:** http://localhost:8001/ui
- **API Swagger:** http://localhost:8000/docs

---

### Path B — Manual Developer Test (Internet-Connected Machine)

Get the full stack running manually step-by-step.

**Step 1: Clone the repo**
```bash
git clone https://github.com/somphouang/local-llm-studio.git
cd local-llm-studio
```

**Step 2: Create and activate a Python virtual environment**
```bash
# Linux / macOS / WSL
python3 -m venv venv
source venv/bin/activate

# Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**Step 3: Install all dependencies**
```bash
pip install -r requirements.txt
pip install -r requirements-rag.txt
```
> First install compiles `llama-cpp-python` from C++ source — allow 5–10 minutes.

**Step 4: Download a tiny test model (~680 MB)**
```bash
python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
    filename='tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    local_dir='./models',
    local_dir_use_symlinks=False
)
print('Model ready.')
"
```

**Step 5: Point `.env` at the tiny model (for quick local testing)**
```bash
# Linux / macOS / WSL — run this one-liner
sed -i 's|MODEL_PATH=.*|MODEL_PATH=./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf|' .env
sed -i 's|MULTI_MODEL_CONFIG=.*|MULTI_MODEL_CONFIG=|' .env

# Windows PowerShell
(Get-Content .env) -replace 'MODEL_PATH=.*','MODEL_PATH=./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf' |
  Set-Content .env
(Get-Content .env) -replace 'MULTI_MODEL_CONFIG=.*','MULTI_MODEL_CONFIG=' |
  Set-Content .env
```

**Step 6: Start the LLM Inference Server** _(Terminal 1)_
```bash
chmod +x start-server.sh
./start-server.sh
# ✅ Running at http://localhost:8000
# 📖 Swagger: http://localhost:8000/docs
```

**Step 7: Start the RAG Server + Chat UI** _(Terminal 2)_
```bash
chmod +x start-rag-server.sh
./start-rag-server.sh
# ✅ Running at http://localhost:8001
# 💬 Chat UI: http://localhost:8001/ui
```

**Step 8: Verify with a quick curl test**
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "What is 2+2?"}]}'
```
Expected: a JSON response containing `"content": "4"` (or similar).

**Step 9: Open the RAG Chat UI**

Navigate to `http://localhost:8001/ui` in your browser. Upload a document and start chatting!

---

### Path C — Package for an Air-Gapped Host (Run on Internet Machine)

This bundles everything your offline server will ever need into one tarball.

**Step 1: Clone and configure**
```bash
git clone https://github.com/somphouang/local-llm-studio.git
cd local-llm-studio
```

Edit `.env` to select your production model (see [`SUPPORTED_MODELS.md`](SUPPORTED_MODELS.md)).
Default is **Meta Llama 3 8B Instruct** (~4.9 GB).

**Step 2: Run the packaging script**
```bash
chmod +x pack-online.sh
./pack-online.sh
```
This downloads:
- All Python `*.whl` files → `offline_packages/`
- The GGUF model → `models/`
- The embedding model → `rag_storage/embedding_models/`

Then bundles everything into:
```
local-llm-studio-offline.tar.gz
```

**Step 3: Transfer to the air-gapped host**
```bash
# Example: copy via scp to an internal jump host
scp local-llm-studio-offline.tar.gz user@internal-host:/opt/llm/

# Or copy to a USB drive mount
cp local-llm-studio-offline.tar.gz /mnt/usb/
```

---

### Path D — Deploy on an Air-Gapped Host (Ubuntu 24.04 or RHEL 9.x)

Run these commands **on the air-gapped server** after receiving the tarball.

**Step 1: Install OS prerequisites** _(one-time, requires internet or internal mirror)_

Ubuntu 24.04:
```bash
sudo apt-get update -y
sudo apt-get install -y python3-venv python3-pip build-essential git curl
```

RHEL 9.x:
```bash
sudo dnf install -y python3 python3-pip gcc gcc-c++ make git curl
```

**Step 2: Extract the payload**
```bash
tar -xzvf local-llm-studio-offline.tar.gz
cd local-llm-studio-offline
```

**Step 3: Deploy Python environment (fully offline — no PyPI calls)**
```bash
chmod +x deploy-offline.sh
./deploy-offline.sh
# Installs all *.whl from offline_packages/ into venv/
```

**Step 4: Review and finalize configuration**
```bash
# Verify model path is correct
grep MODEL_PATH .env

# Verify multi-model config (default is on)
grep MULTI_MODEL_CONFIG .env

# Optional: disable multi-model and use single model
# edit .env → set MULTI_MODEL_CONFIG=
```

**Step 5: Start the LLM Inference Server** _(Terminal 1 / systemd service)_
```bash
chmod +x start-server.sh
./start-server.sh
# ✅ LLM API: http://0.0.0.0:8000/v1/chat/completions
# 📖 Swagger:  http://0.0.0.0:8000/docs
```

**Step 6: Start the RAG Server + Chat UI** _(Terminal 2 / systemd service)_
```bash
chmod +x start-rag-server.sh
./start-rag-server.sh
# ✅ RAG API: http://0.0.0.0:8001/rag/chat
# 💬 Chat UI: http://0.0.0.0:8001/ui
```

**Step 7: Verify both services are responding**
```bash
# Test LLM server
curl http://localhost:8000/health

# Test RAG server
curl http://localhost:8001/health

# Send a full inference request
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello, are you online?"}]}'
```

**Step 8 (Optional): Run as background services with nohup**
```bash
# Run LLM server in background, log to file
nohup ./start-server.sh > logs/llm-server.log 2>&1 &
echo "LLM Server PID: $!"

# Run RAG server in background
nohup ./start-rag-server.sh > logs/rag-server.log 2>&1 &
echo "RAG Server PID: $!"
```

---

## 📑 Table of Contents

1. [Architecture Overview](#-architecture-overview)
2. [Prerequisites](#-prerequisites)
3. [RAG Setup Guide](#-rag-setup-guide)
4. [Multi-Model Configuration](#-multi-model-configuration)
5. [Running as a Cluster](#-running-as-a-cluster)
6. [Configuration Reference](#-configuration-reference)
7. [Supported Models](#-supported-models)
8. [Project Structure](#-project-structure)

---

## 🏗 Architecture Overview

```
[Browser]
   │
   ├─► http://HOST:8001/ui    ◄── RAG Chat Web UI (native HTML/JS)
   │
   ▼
[RAG Server — rag/app.py]  :8001   FastAPI
   │  ┌─────────────────┐
   ├─►│ LanceDB (disk)  │  Vector Search  (fully local)
   │  └─────────────────┘
   │  ┌──────────────────────────────┐
   ├─►│ FastEmbed / ONNX (CPU) │  Offline Embeddings (no torch)
   │  └──────────────────────────────┘
   │
   ▼
[LLM Server — llama_cpp.server]  :8000   OpenAI-Compatible API
   │
   ▼
[.gguf Model File]  (on local disk — zero network required)
```

---

## 🛑 Prerequisites

### All Environments

| Requirement | Version | Notes |
|---|---|---|
| Python | 3.10+ | Required on staging and host |
| C++ build tools | Any | To compile `llama-cpp-python` |
| Git | Any | For cloning |
| curl | Any | For endpoint testing |

### Ubuntu 24.04 LTS
```bash
sudo apt-get update -y
sudo apt-get install -y python3-venv python3-pip build-essential git curl
```

### RHEL 9.x
```bash
sudo dnf install -y python3 python3-pip gcc gcc-c++ make git curl
```

### Windows (Developer Only)
- Python 3.10+ from [python.org](https://python.org) — check **"Add to PATH"** during install
- [Git for Windows](https://git-scm.com)
- WSL 2 + Ubuntu 24.04 recommended for closest parity to production

### GPU Support (Optional)

| GPU | Min VRAM | Recommended For |
|---|---|---|
| NVIDIA RTX 3060 | 12 GB | 7B–13B models |
| NVIDIA RTX 3090/4090 | 24 GB | 13B–34B models |
| NVIDIA A100 | 80 GB | 70B models |

Set `N_GPU_LAYERS=-1` in `.env` to automatically offload all layers to GPU.

---

## 📚 RAG Setup Guide

### How it works

1. **Ingest** — Upload a document → text extracted & chunked → each chunk embedded with `BAAI/bge-small-en-v1.5` (via FastEmbed/ONNX) → stored in LanceDB on disk.
2. **Chat** — Your question is embedded → top matching chunks fetched from LanceDB → chunks + question sent to LLM → grounded answer with source citations returned.

### RAG REST API

```bash
# Create a knowledge collection
curl -X POST http://localhost:8001/rag/collections \
  -H "Content-Type: application/json" \
  -d '{"name": "company-docs", "description": "Internal policy documents"}'

# Ingest a PDF
curl -X POST http://localhost:8001/rag/ingest \
  -F "file=@/path/to/report.pdf" \
  -F "collection=company-docs"

# Chat with context
curl -X POST http://localhost:8001/rag/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the vacation policy?", "collection": "company-docs"}'

# List all documents
curl "http://localhost:8001/rag/documents?collection=company-docs"

# Delete a document by ID
curl -X DELETE "http://localhost:8001/rag/documents/<doc_id>?collection=company-docs"

# List all collections
curl http://localhost:8001/rag/collections
```

---

## 🔀 Multi-Model Configuration

Set `MULTI_MODEL_CONFIG=./config.json` in `.env` (default). Open `config.json` and add entries to the `models` array:

```json
{
  "host": "0.0.0.0",
  "port": 8000,
  "models": [
    {
      "model": "./models/Meta-Llama-3-8B-Instruct.Q4_K_M.gguf",
      "model_alias": "llama-3-8b",
      "chat_format": "llama-3",
      "n_ctx": 4096,
      "n_gpu_layers": -1
    },
    {
      "model": "./models/Mistral-7B-Instruct-v0.3.Q4_K_M.gguf",
      "model_alias": "mistral-7b",
      "chat_format": "mistral-instruct",
      "n_ctx": 4096,
      "n_gpu_layers": -1
    }
  ]
}
```

Route between models by specifying `"model"` in your API call:
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "mistral-7b", "messages": [{"role": "user", "content": "Hello"}]}'
```

To add a model: download the `.gguf`, add an entry to `config.json`, restart `start-server.sh`.

---

## 🌐 Running as a Cluster

### Horizontal — Load Balancing (Nginx)
```nginx
upstream llm_cluster {
    server node1:8000;
    server node2:8000;
    server node3:8000;
}
server {
    listen 80;
    location /v1/ { proxy_pass http://llm_cluster; }
    location /rag/  { proxy_pass http://rag-node:8001; }
}
```

Deploy the tarball to each node, run `start-server.sh` independently. Share `rag_storage/lancedb/` via NFS for a unified vector index.

### Vertical — Large Model GPU Split
For 70B+ models that exceed single GPU VRAM, use `llama.cpp` native RPC tensor splitting. See the [llama.cpp RPC documentation](https://github.com/ggerganov/llama.cpp/blob/master/docs/rpc.md).

---

## ⚙ Configuration Reference

### `.env` Variables

| Variable | Default | Description |
|---|---|---|
| `MODEL_PATH` | `./models/Meta-Llama-3-8B...gguf` | Single GGUF model path |
| `MULTI_MODEL_CONFIG` | `./config.json` | Multi-model JSON config; empty = single model mode |
| `HOST` | `0.0.0.0` | LLM server bind address |
| `PORT` | `8000` | LLM server port |
| `N_CTX` | `8192` | Context window in tokens |
| `N_THREADS` | `4` | CPU inference threads |
| `N_GPU_LAYERS` | `-1` | GPU offload layers (`0`=CPU only, `-1`=all to GPU) |
| `LLM_BASE_URL` | `http://127.0.0.1:8000/v1` | RAG server → LLM endpoint |
| `LLM_MODEL` | `llama-3-8b` | Model alias for RAG requests |
| `RAG_HOST` | `0.0.0.0` | RAG server bind address |
| `RAG_PORT` | `8001` | RAG server port |
| `LANCE_DIR` | `./rag_storage/lancedb` | LanceDB vector store persistence path |
| `EMBED_MODEL` | `BAAI/bge-small-en-v1.5` | FastEmbed ONNX model for offline vector embeddings |

---

## 📋 Supported Models

See the full catalog with repo IDs, filenames, sizes, and specialty categories:

🔗 **[SUPPORTED_MODELS.md](SUPPORTED_MODELS.md)**

Includes: Meta Llama 3, Mistral, Qwen, DeepSeek Coder, Microsoft Phi-3, Google Gemma, Dolphin, Mixtral — organized by General Purpose · Coding & Math · Edge/CPU · Heavy GPU.

---

## 📁 Project Structure

```
local-llm-studio/
├── .env                    # Runtime configuration (gitignored)
├── .env.example            # Safe reference template
├── config.json             # Multi-model LLM server config
├── config.example.json     # Example multi-model config
│
├── requirements.txt        # Pinned LLM server Python deps
├── requirements-rag.txt    # Pinned RAG server Python deps
│
├── start-all.sh            # ⚡ AUTORUN   — one-click setup & start all services
├── pack-online.sh          # ① RUN ONLINE  — download wheels + models → tarball
├── deploy-offline.sh       # ② RUN ON HOST — install offline from tarball
├── start-server.sh         # ③ START       — LLM inference server  :8000
├── start-rag-server.sh     # ④ START       — RAG API + Web UI      :8001
│
├── test-locally.sh         # Automated smoke test (Linux/WSL)
├── test-locally.ps1        # Automated smoke test (Windows PowerShell)
│
├── models/                 # GGUF model files          (gitignored)
├── rag_storage/            # LanceDB vector data + embedding model cache (gitignored)
│
├── rag/
│   ├── app.py              # RAG FastAPI application
│   ├── vectorstore.py      # LanceDB wrapper + FastEmbed query engine
│   ├── ingest.py           # PDF / DOCX / TXT / MD parser and chunker
│   └── ui/
│       └── index.html      # Dark-mode RAG Chat Web UI
│
├── README.md
├── SUPPORTED_MODELS.md     # Full LLM model catalog
└── implementation_plan.md
```
