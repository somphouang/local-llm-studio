# Local LLM Studio 🧠

A fully **offline, self-hosted** LLM environment with built-in **RAG (Retrieval-Augmented Generation)** and a **Vector Database**. Drop in your own documents and chat with your knowledge base entirely on your own hardware — no cloud, no internet required on the target machine.

Powered by `llama.cpp` (GGUF engine) + `ChromaDB` + `sentence-transformers` + `FastAPI`.

---

## 📑 Table of Contents

1. [Architecture Overview](#-architecture-overview)
2. [Prerequisites](#-prerequisites)
3. [Get Started (Developer — Online Machine)](#-get-started-developer--online-machine)
4. [Developer Setup: Running Locally](#-developer-setup-running-locally)
5. [RAG Setup Guide](#-rag-setup-guide)
6. [Setup Guide: Deploying to a Host Machine (Offline)](#-setup-guide-deploying-to-a-host-machine-offline)
7. [Running as a Cluster](#-running-as-a-cluster)
8. [Configuration Reference](#-configuration-reference)
9. [Supported Models](#-supported-models)
10. [Project Structure](#-project-structure)

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
   ├─►│ ChromaDB (disk) │  Vector Search (local)
   │  └─────────────────┘
   │  ┌─────────────────────────────┐
   ├─►│ sentence-transformers (CPU) │  Offline Embeddings
   │  └─────────────────────────────┘
   │
   ▼
[LLM Server — llama_cpp.server]  :8000   OpenAI-Compatible API
   │
   ▼
[.gguf Model File]  (on local disk)
```

Both servers expose OpenAI-compatible API endpoints so any AI Agent framework (LangChain, AutoGen, Open WebUI) can point to them without modification.

---

## 🛑 Prerequisites

### All Environments

| Requirement | Version | Notes |
|---|---|---|
| Python | 3.10+ | Required on staging and host |
| Git | Any | For cloning this repo |
| curl | Any | For testing endpoints |

### Ubuntu 24.04 LTS (Developer or Host)

```bash
sudo apt-get update -y
sudo apt-get install -y python3-venv python3-pip build-essential git curl
```

### RHEL 9.x (Host / Air-gapped)

```bash
sudo dnf install -y python3 python3-pip gcc gcc-c++ make git curl
```
> [!NOTE]
> RHEL 9.x ships with Python 3.9 by default. Install Python 3.11 via SCL or compile from source if needed.

### Windows (Developer Machine Only)

- Python 3.10+ from [python.org](https://python.org) — check **"Add to PATH"** during install.
- Git for Windows from [git-scm.com](https://git-scm.com).
- Optionally: **WSL 2** with Ubuntu 24.04 for the closest parity to production.

### GPU (Optional but Recommended)

| GPU | Min VRAM | Recommended For |
|---|---|---|
| NVIDIA RTX 3060 | 12 GB | 7B–13B models |
| NVIDIA RTX 3090/4090 | 24 GB | 13B–34B models |
| NVIDIA A100 | 80 GB | 70B models |

For NVIDIA GPU support, `llama-cpp-python` must be compiled with CUDA. Set `N_GPU_LAYERS=-1` in `.env`.

---

## 🚀 Get Started (Developer — Online Machine)

This step downloads all model weights and Python wheel files so the entire system can be reproduced completely offline.

### 1. Clone the repository

```bash
git clone https://github.com/somphouang/local-llm-studio.git
cd local-llm-studio
```

### 2. Configure your model selection

Open `.env` and review the default:

```ini
# Default: Meta Llama 3 8B (good balance of speed and quality)
MODEL_PATH=./models/Meta-Llama-3-8B-Instruct.Q4_K_M.gguf

# For multi-model support:
MULTI_MODEL_CONFIG=./config.json
```

Browse [`SUPPORTED_MODELS.md`](SUPPORTED_MODELS.md) for the full catalog with exact repo IDs and filenames.

### 3. Run the packaging script

```bash
chmod +x pack-online.sh
./pack-online.sh
```

This will:
- Download all Python wheels (`requirements.txt` + `requirements-rag.txt`) into `offline_packages/`
- Download the GGUF model into `models/`
- Download and cache the `all-MiniLM-L6-v2` embedding model into `rag_storage/embedding_models/`
- Bundle everything into `local-llm-studio-offline.tar.gz`

Transfer `local-llm-studio-offline.tar.gz` to your air-gapped machine via secure USB or internal network share.

---

## 💻 Developer Setup: Running Locally

For local development and testing on an internet-connected machine.

### 1. Create a virtual environment

```bash
# Linux / macOS / WSL
python3 -m venv venv
source venv/bin/activate

# Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### 2. Install all dependencies

```bash
pip install -r requirements.txt
pip install -r requirements-rag.txt
```

> [!NOTE]
> `llama-cpp-python` requires a C++ compiler. It will compile automatically during install — this takes 5–10 minutes the first time.

### 3. Download a test model (tiny — fast CPU inference)

```bash
python -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
    filename='tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    local_dir='./models',
    local_dir_use_symlinks=False
)
"
```

Then update `.env`:
```ini
MODEL_PATH=./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
MULTI_MODEL_CONFIG=
```

### 4. Run the automated test

```bash
# Linux / WSL
bash test-locally.sh

# Windows PowerShell
.\test-locally.ps1
```

A successful test returns a JSON response from `http://127.0.0.1:8000/v1/chat/completions` and prints the LLM's answer to your terminal.

---

## 📚 RAG Setup Guide

The RAG system lets you upload documents (PDF, DOCX, TXT, Markdown) and have conversations grounded in their content.

### How it works

1. **Ingest** — upload a document → text is extracted and split into chunks → each chunk is embedded into a vector using `sentence-transformers/all-MiniLM-L6-v2` → stored in ChromaDB on disk.
2. **Chat** — your question is embedded → top matching chunks are retrieved from ChromaDB → chunks + question are sent to the LLM → grounded answer returned with source citations.

### Running the full stack locally

Open **two terminals**:

**Terminal 1 — LLM Inference Server:**
```bash
chmod +x start-server.sh
./start-server.sh
# Server running on http://0.0.0.0:8000
# Swagger docs: http://localhost:8000/docs
```

**Terminal 2 — RAG API + Web UI:**
```bash
chmod +x start-rag-server.sh
./start-rag-server.sh
# RAG API running on http://0.0.0.0:8001
# Chat UI: http://localhost:8001/ui
```

### Using the RAG Chat UI

Open `http://localhost:8001/ui` in your browser:

1. **Create a collection** — type a name (e.g., `company-docs`) and click `+`.
2. **Upload documents** — drag and drop or browse. Supported: `.pdf`, `.txt`, `.md`, `.docx`.
3. **Chat** — type a question and hit Enter. The answer cites the relevant source documents.

### RAG REST API

You can also call the RAG API directly for agent integration:

```bash
# Ingest a document
curl -X POST http://localhost:8001/rag/ingest \
  -F "file=@/path/to/report.pdf" \
  -F "collection=my-docs"

# Chat with context
curl -X POST http://localhost:8001/rag/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Summarize the key findings", "collection": "my-docs"}'

# List all documents in a collection
curl http://localhost:8001/rag/documents?collection=my-docs

# Delete a document
curl -X DELETE http://localhost:8001/rag/documents/<doc_id>?collection=my-docs
```

### Adding / Removing Knowledge Documents

- **Add:** Upload via the UI or `POST /rag/ingest`.
- **Remove:** Click the `✕` button in the UI next to a document, or call `DELETE /rag/documents/{doc_id}`.
- **Collections** are independent knowledge bases — create separate ones for different topics (e.g. `hr-policy`, `tech-specs`, `legal`).

---

## 🛠 Setup Guide: Deploying to a Host Machine (Offline)

### 1. Transfer and extract

```bash
tar -xzvf local-llm-studio-offline.tar.gz
cd local-llm-studio-offline
```

### 2. Run the offline deployment script

```bash
chmod +x deploy-offline.sh
./deploy-offline.sh
```

This will:
- Detect your OS (Debian/Ubuntu vs RHEL/other)
- Install `python3-venv`, `python3-pip`, `build-essential` if missing (Ubuntu)
- Create an isolated `venv/`
- Install **all packages from local wheels** — zero PyPI traffic

### 3. Start the LLM Server

```bash
chmod +x start-server.sh
./start-server.sh
```

### 4. (Optional) Start the RAG Server

```bash
chmod +x start-rag-server.sh
./start-rag-server.sh
```

### Connecting AI Clients

Both servers expose OpenAI-compatible APIs:

| Service | URL | Auth |
|---|---|---|
| LLM Chat Completions | `http://HOST:8000/v1/chat/completions` | None |
| LLM Swagger Docs | `http://HOST:8000/docs` | None |
| RAG Chat | `http://HOST:8001/rag/chat` | None |
| RAG Web UI | `http://HOST:8001/ui` | None |

Point any OpenAI-SDK client to `http://HOST:8000/v1` with API key `local`.

---

## 🌐 Running as a Cluster

### Horizontal — Load Balancing Multiple Nodes

Deploy the offline tarball to N identical host machines, then place an Nginx or HAProxy upstream:

```nginx
upstream llm_cluster {
    server node1:8000;
    server node2:8000;
    server node3:8000;
}
server {
    listen 80;
    location /v1/ {
        proxy_pass http://llm_cluster;
    }
}
```

Each node runs `start-server.sh` independently. The RAG server on each node shares its ChromaDB from a network-mounted volume (NFS/CIFS) to keep the vector index in sync.

### Vertical — Large Model GPU Split (llama.cpp RPC)

For models too large for a single GPU (e.g., 70B), `llama.cpp` supports native tensor splitting across machines via RPC. This requires compiling `llama-server` binaries manually with `--rpc` enabled on each node and is documented in the [llama.cpp RPC guide](https://github.com/ggerganov/llama.cpp/blob/master/docs/rpc.md).

---

## ⚙ Configuration Reference

### `.env`

| Variable | Default | Description |
|---|---|---|
| `MODEL_PATH` | `./models/Meta-Llama-3-8B...gguf` | Path to single GGUF model |
| `MULTI_MODEL_CONFIG` | `./config.json` | JSON config for multiple models; leave empty for single-model mode |
| `HOST` | `0.0.0.0` | LLM server bind address |
| `PORT` | `8000` | LLM server port |
| `N_CTX` | `8192` | Context window size (tokens) |
| `N_THREADS` | `4` | CPU threads for inference |
| `N_GPU_LAYERS` | `-1` | GPU layers to offload (`0` = CPU only, `-1` = all to GPU) |
| `LLM_BASE_URL` | `http://127.0.0.1:8000/v1` | RAG server's LLM endpoint |
| `LLM_MODEL` | `llama-3-8b` | Model alias for RAG chat requests |
| `RAG_HOST` | `0.0.0.0` | RAG server bind address |
| `RAG_PORT` | `8001` | RAG server port |
| `CHROMA_DIR` | `./rag_storage/chroma` | ChromaDB persistence directory |
| `EMBED_MODEL` | `sentence-transformers/all-MiniLM-L6-v2` | Local embedding model |

### `config.json` — Multi-Model Setup

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

To add a model: copy one object in the `models` array, update `model` path and `model_alias`, restart `start-server.sh`.

---

## 📋 Supported Models

See the full catalog with download coordinates, hardware requirements, and specialty categories:

🔗 **[SUPPORTED_MODELS.md](SUPPORTED_MODELS.md)**

Includes: Meta Llama 3, Mistral, Qwen, DeepSeek Coder, Microsoft Phi-3, Google Gemma, Dolphin, Mixtral, and more — organized by General Purpose · Coding & Math · Edge/CPU · Heavy GPU.

---

## 📁 Project Structure

```
local-llm-studio/
├── .env                    # Runtime configuration (do not commit secrets)
├── .env.example            # Template — safe to commit
├── .gitignore
├── config.json             # Multi-model server configuration
├── config.example.json     # Example multi-model configuration
├── requirements.txt        # Pinned Python deps for LLM server
├── requirements-rag.txt    # Pinned Python deps for RAG server
│
├── pack-online.sh          # [Run ONLINE] Download wheels + models → tarball
├── deploy-offline.sh       # [Run on HOST] Install wheels offline → venv
├── start-server.sh         # Start LLM inference server (port 8000)
├── start-rag-server.sh     # Start RAG API + Web UI (port 8001)
│
├── test-locally.sh         # Automated test (Linux / WSL)
├── test-locally.ps1        # Automated test (Windows PowerShell)
│
├── models/                 # GGUF model files (git-ignored)
├── rag_storage/            # ChromaDB + embedding cache (git-ignored)
│   ├── chroma/             # Vector database
│   └── embedding_models/   # Cached sentence-transformers model
│
├── rag/
│   ├── app.py              # RAG FastAPI server
│   ├── vectorstore.py      # ChromaDB wrapper
│   ├── ingest.py           # PDF/DOCX/TXT/MD parser and chunker
│   └── ui/
│       └── index.html      # Native dark-mode RAG Chat Web UI
│
├── README.md
├── SUPPORTED_MODELS.md     # Full LLM model catalog
└── implementation_plan.md
```
