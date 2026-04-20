#!/bin/bash
set -e

echo "========================================================"
echo "🧠 Ultimate Local LLM Studio Setup & Startup Script 🧠"
echo "========================================================"
echo ""

cd "$(dirname "$0")"

# Step 1: Create and Activate Virtual Environment
if [ ! -d "venv" ] && [ ! -d "venv_linux" ]; then
    echo "▶ Creating Python virtual environment 'venv'..."
    python3 -m venv venv
    echo "✅ Virtual environment created."
fi

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv_linux/bin/activate" ]; then
    source venv_linux/bin/activate
else
    echo "❌ Error: Could not find virtual environment activation script."
    exit 1
fi
echo "✅ Virtual environment activated."

# Step 2: Install Dependencies
echo "▶ Installing/Verifying dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-rag.txt
echo "✅ All dependencies installed."

# Step 3: Handle graceful shutdown
cleanup() {
    echo ""
    echo "🛑 Shutting down servers..."
    kill $LLM_PID $RAG_PID 2>/dev/null || true
    wait $LLM_PID $RAG_PID 2>/dev/null || true
    echo "👋 Shutdown complete."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Step 4: Check or Download Model
echo "▶ Checking model configuration..."
if [ ! -d "models" ] || [ -z "$(ls -A models/*.gguf 2>/dev/null)" ]; then
    echo "⚠️  No GGUF models found in the 'models/' directory."
    echo "Downloading the tiny test model (TinyLlama) so the script works immediately..."
    python3 -c "
from huggingface_hub import hf_hub_download
try:
    hf_hub_download(
        repo_id='TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
        filename='tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
        local_dir='./models',
        local_dir_use_symlinks=False
    )
    print('✅ Test model ready.')
except Exception as e:
    print('❌ Failed to download test model:', e)
"
    
    # Auto-configure .env for the quickstart model to guarantee it runs
    if [ -f .env ]; then
        sed -i 's|MODEL_PATH=.*|MODEL_PATH=./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf|' .env || true
        sed -i 's|MULTI_MODEL_CONFIG=.*|MULTI_MODEL_CONFIG=|' .env || true
    fi
fi

# Step 5: Start LLM server
echo "▶ Starting LLM inference server..."
# Using bash background process
chmod +x start-server.sh
./start-server.sh 2>&1 | sed 's/^/[LLM-Server] /' &
LLM_PID=$!

echo "⏳ Waiting for LLM server to initialize (5 seconds)..."
sleep 5

# Step 6: Start RAG server
echo "▶ Starting RAG framework & Web UI..."
chmod +x start-rag-server.sh
./start-rag-server.sh 2>&1 | sed 's/^/[RAG-Server] /' &
RAG_PID=$!

sleep 2

echo "========================================================"
echo "🚀 ALL SYSTEMS GO! 🚀"
echo "💬 Chat Web UI:     http://localhost:8001/ui "
echo "📝 LLM API Swagger: http://localhost:8000/docs"
echo "Press Ctrl+C to terminate both servers safely at any time."
echo "========================================================"

# Step 7: Wait forever (until interrupted)
wait $LLM_PID $RAG_PID
