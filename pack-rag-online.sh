#!/bin/bash
set -e

echo "=== Packaging AnythingLLM RAG Environment Offline ==="

CONTAINER_CMD="docker"
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
fi

if ! command -v $CONTAINER_CMD &> /dev/null; then
    echo "❌ Error: Neither docker nor podman is installed on this staging machine."
    exit 1
fi

echo "Using container engine: $CONTAINER_CMD"
echo "[1/2] Pulling mintplexlabs/anythingllm image..."
$CONTAINER_CMD pull mintplexlabs/anythingllm

echo "[2/2] Saving image to anythingllm-offline.tar..."
$CONTAINER_CMD save -o anythingllm-offline.tar mintplexlabs/anythingllm

echo "✅ Done! Transfer 'anythingllm-offline.tar' alongside 'local-llm-studio-offline.tar.gz' to your air-gapped machine."
