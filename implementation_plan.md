# Offline Self-Hosted LLM Environment

This plan outlines the creation of a fully offline, self-hosted Large Language Model (LLM) environment. The solution emphasizes air-gapped deployment compatibility (suitable for Ubuntu 24.04 LTS, RHEL 9.x, and Windows), API integration, and CPU/GPU hardware support.

## User Review Required

> [!IMPORTANT]  
> Please review this overall architecture and the approach for air-gapping. By default, I propose using the widely supported `transformers` package with `FastAPI` (for the runtime) to ensure wide compatibility and ease of custom scripting. 
> 
> *Are you looking to prioritize PyTorch+Transformers, or would you prefer a `llama.cpp` (GGUF) or `vLLM` based backend? `llama.cpp` often provides superior CPU inference speed, but `Transformers` is more straightforward if you want broad compatibility with unmodified Hugging Face models using `huggingface-cli` as you mentioned.*

## Proposed Architecture

1.  **Core Runtime Engine**: Python 3.10+
2.  **API Layer**: FastAPI wrapped with Uvicorn. This provides high-performance endpoints for NLP generation (single and batch), caching, and easily integrates with AI Agents via REST.
3.  **Model Loading**: `transformers` with PyTorch. We will use `device_map="auto"` so the application automatically detects and utilizes GPUs if available, falling back to CPU otherwise. 
4.  **Air-gapped Strategy**:
    *   **Preparation Script**: A script designed to run on an internet-connected terminal to download all pip dependency wheels and model checkpoints (using `huggingface-cli download`).
    *   **Deployment Script**: A script executed on the air-gapped server to install wheels directly from the local directory and set up the models.
5.  **Models Support**: Scripts will support downloading any open-source model (e.g., LLaMA-3, MPT-7B, Falcon). Smaller models and 8-bit quantization (`bitsandbytes`) will be supported to reduce memory consumption.

## Proposed Changes

### Configuration & Documentation
#### [NEW] `README.md`
Complete instructions for pre-flight downloading, offline installation, runtime instructions, adding and removing models, and AI Agent utilization.

#### [NEW] `.env.example`
Environment variables for the runtime (e.g., `MODEL_ID`, `MODEL_DIR`, `PORT`, `HOST`, `ENABLE_CACHING`).

### Air-Gapped Packaging Scripts
#### [NEW] `pack-offline-deps.sh` (Linux/macOS) / `pack-offline-deps.ps1` (Windows)
A script to download all Python dependencies (`pip download`) and the specified LLM models into a portable `.tar.gz` or `.zip` archive.

#### [NEW] `install-offline.sh`
Script to extract the archive on the target air-gapped machine, install the downloaded Python `*.whl` packages offline without querying PyPI, and point the application to the downloaded model weights.

### Runtime Application
#### [NEW] `app/main.py`
The FastAPI application containing:
*   `/generate`: Endpoint for single query completions.
*   `/generate_batch`: Endpoint for parallel/batch completions.
*   `LRU caching`: Using Python's `functools.lru_cache` to cache identical prompts.
*   Runtime model loader capable of specifying CPU/GPU precision.

#### [NEW] `app/model_manager.py`
Utility functions specifically for loading, unloading, and switching Hugging Face models at runtime from local storage, making sure disk storage and memory are handled carefully.

#### [NEW] `start-server.sh`
A convenience script to launch the FastAPI environment easily.

## Open Questions

1.  **Quantization**: Would you like me to include setup for `bitsandbytes` (for 8-bit/4-bit quantization)? This significantly helps large models run on consumer hardware or smaller VRAM GPUs.
2.  **RAG/Embeddings**: You mentioned RAG as an optional feature. Should I include a secondary local endpoint in this API specifically for text embeddings (e.g., using `sentence-transformers`) to generate vector representations offline?
3.  **Backend Preference:** As asked above, do you prefer a standard Huggingface `transformers` approach, or would you prefer a `llama.cpp` + GGUF implementation which can be highly optimized for CPU? Let me know which path aligns best with your needs!

## Verification Plan

### Manual Verification
1.  Run the packing script locally to ensure it successfully downloads weights and wheels.
2.  Review the source code of `main.py` to verify API structure aligns with OpenAI-like API schemas (so it integrates seamlessly with typical AI agents).
3.  Ensure `.env` defaults properly redirect all downloads to local directories to absolutely ensure zero network traffic on the target machine.
