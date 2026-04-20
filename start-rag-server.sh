#!/bin/bash
set -e

echo "=== Starting Local LLM Studio — RAG Server ==="

cd "$(dirname "$0")"

# Activate the venv (same one as LLM server)
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv_linux/bin/activate" ]; then
    source venv_linux/bin/activate
else
    echo "❌ No virtual environment found. Run deploy-offline.sh first."
    exit 1
fi

# Install RAG-specific deps if not already present
python3 -c "import lancedb" 2>/dev/null || {
    echo "Installing RAG dependencies from requirements-rag.txt..."
    pip install -r requirements-rag.txt
}

# Load .env
if [ -f .env ]; then
    source <(grep -v '^#' .env | sed 's/\r$//' | grep '=')
fi

RAG_HOST=${RAG_HOST:-"0.0.0.0"}
RAG_PORT=${RAG_PORT:-8001}
LLM_BASE_URL=${LLM_BASE_URL:-"http://127.0.0.1:8000/v1"}

echo "RAG Server : http://${RAG_HOST}:${RAG_PORT}"
echo "RAG Chat UI: http://127.0.0.1:${RAG_PORT}/ui"
echo "LLM Backend: ${LLM_BASE_URL}"
echo ""
echo "Make sure start-server.sh is already running!"
echo ""

cd rag
python3 -m uvicorn app:app --host "$RAG_HOST" --port "$RAG_PORT" --reload
