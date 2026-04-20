#!/bin/bash
set -e

echo "=== Packaging offline dependencies for Local LLM Studio ==="

# Create directories
mkdir -p offline_packages
mkdir -p models

# Download Python dependencies
echo "[1/3] Downloading Python package dependencies..."
# Important: We download Linux wheels for the air-gapped system. If the air-gapped system has a different architecture, 
# you should set the --platform and --python-version args for standard pip download.
pip download -d offline_packages -r requirements.txt
pip download -d offline_packages -r requirements-rag.txt

# Install huggingface_hub globally/venv to execute the Python script locally on the staging machine
pip install huggingface_hub fastembed

# Pre-download the embedding model weights (BAAI/bge-small-en-v1.5) so it is available fully offline
echo "[1b/3] Pre-downloading FastEmbed model..."
python3 -c "
from fastembed import TextEmbedding
model = TextEmbedding(model_name='BAAI/bge-small-en-v1.5', cache_dir='./rag_storage/embedding_models')
print('FastEmbed model cached to ./rag_storage/embedding_models')
"

# Download specific model using huggingface-cli
echo "[2/3] Downloading the GGUF model files..."
# Default to Meta LLaMA 3 8B Instruct (Quantized)
MODEL_REPO="QuantFactory/Meta-Llama-3-8B-Instruct-GGUF"
MODEL_FILE="Meta-Llama-3-8B-Instruct.Q4_K_M.gguf"

echo "Downloading $MODEL_FILE from $MODEL_REPO..."
python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='$MODEL_REPO', filename='$MODEL_FILE', local_dir='./models', local_dir_use_symlinks=False)"

echo "[3/3] Packaging everything into a tarball..."
tar -czvf local-llm-studio-offline.tar.gz \
    offline_packages/ models/ rag/ rag_storage/ \
    .env .env.example deploy-offline.sh start-server.sh start-rag-server.sh \
    README.md requirements.txt requirements-rag.txt SUPPORTED_MODELS.md config.json config.example.json

echo "✅ Done! Transfer 'local-llm-studio-offline.tar.gz' to your air-gapped machine."
