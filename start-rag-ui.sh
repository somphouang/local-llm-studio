#!/bin/bash
set -e

echo "=== Deploying AnythingLLM RAG UI Offline ==="

CONTAINER_CMD="docker"
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
fi

if ! command -v $CONTAINER_CMD &> /dev/null; then
    echo "❌ Error: Neither docker nor podman is installed on this host machine."
    echo "For RHEL 9.x, run: sudo dnf install podman"
    echo "For Ubuntu 24.04, run: sudo apt install docker.io"
    exit 1
fi

echo "Using container engine: $CONTAINER_CMD"

if [ ! -f "anythingllm-offline.tar" ]; then
    echo "❌ Error: anythingllm-offline.tar not found! Please run pack-rag-online.sh on an internet-connected machine first and transfer it here."
    exit 1
fi

echo "[1/3] Loading anythingllm image into $CONTAINER_CMD from tarball..."
$CONTAINER_CMD load -i anythingllm-offline.tar

echo "[2/3] Setting up local persistent storage in the current directory..."
export STORAGE_LOCATION="$PWD/anythingllm-storage"
mkdir -p "$STORAGE_LOCATION"
touch "$STORAGE_LOCATION/.env"

# Remove Old container if present to avoid name collisions
$CONTAINER_CMD rm -f anythingllm-rag &> /dev/null || true

echo "[3/3] Starting AnythingLLM Container on port 3001..."

$CONTAINER_CMD run -d -p 3001:3001 \
  --cap-add SYS_ADMIN \
  --name anythingllm-rag \
  -v "${STORAGE_LOCATION}:/app/server/storage" \
  -v "${STORAGE_LOCATION}/.env:/app/server/.env" \
  -e STORAGE_DIR="/app/server/storage" \
  mintplexlabs/anythingllm

echo ""
echo "✅ Deployment successful!"
echo "AnythingLLM (RAG Frontend) is now running natively at http://0.0.0.0:3001"
echo ""
echo "==== CONNECTING TO YOUR LOCAL LLM SERVER ===="
echo "When asked to link an LLM inside the AnythingLLM UI, select 'Generic OpenAI'."
if [ "$CONTAINER_CMD" = "docker" ]; then
    echo "Base URL: http://host.docker.internal:8000/v1"
else
    echo "Base URL: http://host.containers.internal:8000/v1 (if using Podman host routing) or your standard network IP."
fi
echo "============================================="
