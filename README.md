# Local LLM Studio (Air-gapped & Offline Ready)

This repository provides a self-hosted, offline-ready Large Language Model (LLM) ecosystem. It utilizes the highly efficient `llama.cpp` engine backed by Hugging Face GGUF weights, providing maximum CPU/GPU efficiency. The runtime exposes an OpenAI-compatible API, allowing seamless integration with tools like AI Studio, LangChain, Autogen, and VSCode extensions.

---

## 📑 Table of Contents
1. [Prerequisites](#-prerequisites)
2. [Get Started: Developer Setup (Online)](#-get-started-developer-setup-online)
3. [Setup Guide: Host Machine Deployment (Offline)](#-setup-guide-host-machine-deployment-offline)
4. [How to Run (Single vs. Multi-Model)](#-how-to-run-single-vs-multi-model)
5. [Supported Models Architecture](#-supported-models-architecture)
6. [How to Run as Clusters](#-how-to-run-as-clusters)
7. [Developer & System Changes](#-developer--system-changes)

---

## 🛑 Prerequisites

Before deploying the pipeline, ensure your hardware and software meet these baseline requirements.

### Staging Environment (Internet-Connected Developer Machine)
*   Python **3.10+** environment installed.
*   Command-line permissions (Bash on Linux/WSL or PowerShell on Windows).
*   Adequate disk space to download LLMs (typically 5GB to 50GB depending on model selection).

### Target Host Machine (Air-Gapped / Production Server)
*   **Operating System**: Ubuntu 24.04 LTS, RHEL 9.x, or similar Linux derivatives.
*   **Essential Development Tools**: To securely compile the C++ binaries natively offline, host packages are required. Run this sequence once:
    ```bash
    sudo apt-get update -y
    sudo apt-get install -y python3-venv python3-pip build-essential
    ```
*   **Hardware Validation**: For heavy workloads (34B+ parameter models), a GPU with 24GB+ VRAM (e.g., RTX 3090, 4090, A100) is highly recommended. CPU inference works but is linearly slower.

---

## 🚀 Get Started: Developer Setup (Online)

You must securely capture all model weights and strictly locked Python dependencies (`requirements.txt`) before transferring them to an air-gapped host. 

1.  Review **[.env](.env)** and **[config.json](config.json)** to select your models.
2.  Optionally modify `pack-online.sh` if you prefer to pull different `.gguf` weights natively.
3.  Execute the packaging script from your internet-connected dev machine:
    ```bash
    chmod +x pack-online.sh
    ./pack-online.sh
    ```
4.  Once finished, securely transfer the generated `local-llm-studio-offline.tar.gz` object into your protected production environment.

---

## 🛠️ Setup Guide: Host Machine Deployment (Offline)

Navigate to your target air-gapped machine.

1.  Extract the offline payload:
    ```bash
    tar -xzvf local-llm-studio-offline.tar.gz
    cd local-llm-studio-offline
    ```
2.  Deploy the offline dependencies. This script intelligently assesses your target machine's operating system, isolates a virtual environment (`venv`), and compiles the `llama.cpp` backend using strictly local `.whl` files seamlessly bypassing PyPI architectures:
    ```bash
    chmod +x deploy-offline.sh
    ./deploy-offline.sh
    ```

---

## ⚡ How to Run (Single vs. Multi-Model)

The system gracefully scales between running a core single intelligence, or concurrently multiplexing differing paradigms. 

### Multi-Model Execution (Default)
By default, the `.env` sets `MULTI_MODEL_CONFIG=./config.json`.
1.  Open **[config.json](config.json)** to configure an array of models running identically alongside each other.
2.  Fire up the server:
    ```bash
    chmod +x start-server.sh
    ./start-server.sh
    ```
When utilizing the OpenAI compatible endpoints, your tools can route logic by hitting `/v1/chat/completions` and supplying `"model": "llama-3-8b"` or `"model": "qwen-test"` based on the `model_alias` configuration!

### Single Model Execution
If you wish to force maximum hardware acceleration onto one parameter limit:
1.  Open `.env` and **empty** the configuration: `MULTI_MODEL_CONFIG=` 
2.  It will intelligently default mapping inference directly to `MODEL_PATH`.

Once online, query API documentation at `http://127.0.0.1:8000/docs`!

---

## 📚 Supported Models Architecture

We extensively categorize the greatest open-weight AI algorithms deployable today spanning edge latency testing to extreme Enterprise MoE infrastructures.

**🔗 [Reference the massive SUPPORTED_MODELS.md catalog here.](SUPPORTED_MODELS.md)**
*(Contains Gemini, Meta Llama, Phi-3, Mistral, Grok, Qwen, DeepSeek).*

---

## 🌐 How to Run as Clusters

If your analytical demand outscales individual host architecture, this `llama_cpp.server` ecosystem can be scaled horizontally and vertically through **Clustered Inference**:

### 1. High Availability (HA) Load Balancing (Horizontal)
To dramatically increase throughput for high-volume enterprise API queries:
*   Deploy this `local-llm-studio` offline payload across identical **N** numbers of Host Machines.
*   Deploy an **Nginx** or **HAProxy** load balancer immediately upstream.
*   Configure the load balancer to distribute standard `/v1/chat/completions` POST requests across the worker nodes concurrently via Round-Robin load manipulation.

### 2. Physical Tensor Splitting via RPC (Vertical)
If a single model (e.g., Llama-3 70B parameter) is **too massive** to fit into the VRAM of a single host:
*   Use `llama.cpp`'s bleeding-edge `llama-server` RPC functionality to manually split `.gguf` architecture layers across physical instances utilizing High-Bandwidth networking (10Gbps+).
*   *(Note: This vertical orchestration bypasses Python wrappers. Require manual compilation of binary nodes parsing `--rpc` mappings).*

---

## 🏗️ Developer & System Changes

Core environment files modified in this iteration:
*   **`requirements.txt`**: Completely rigid version pinning for predictable, immutable security validation matching our isolated WSL test vectors.
*   **`config.json`**: New implementation allowing seamless multi-agent model multiplexing.
*   **Python Bindings**: Python's native `from huggingface_hub import hf_hub_download` replaced arbitrary cli utilities solving critical pathing bugs across OS distributions.
