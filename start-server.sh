#!/bin/bash
set -e

echo "=== Starting Local LLM Studio Server ==="

source venv/bin/activate

# Load environment variables
if [ -f .env ]; then
  source <(grep -v '^#' .env | sed 's/\r$//')
else
  echo ".env file not found! Falling back to defaults."
fi

MODEL_PATH=${MODEL_PATH:-"./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"}
PORT=${PORT:-8000}
HOST=${HOST:-"0.0.0.0"}
N_CTX=${N_CTX:-8192}
N_THREADS=${N_THREADS:-4}
N_GPU_LAYERS=${N_GPU_LAYERS:--1}

if [ -n "$MULTI_MODEL_CONFIG" ] && [ -f "$MULTI_MODEL_CONFIG" ]; then
  echo "🚀 Multi-Model Mode Detected!"
  echo "Loading from configuration file: $MULTI_MODEL_CONFIG"
  echo "Host: $HOST:$PORT | URL: http://$HOST:$PORT/docs"

  python3 -m llama_cpp.server \
      --config_file "$MULTI_MODEL_CONFIG"
else
  if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Error: Model file not found at $MODEL_PATH."
    echo "Please check your .env file and ensure models/ folder contains the GGUF model, or configure MULTI_MODEL_CONFIG."
    exit 1
  fi

  echo "🚀 Single-Model Mode"
  echo "Model: $MODEL_PATH"
  echo "Host: $HOST:$PORT | Threads: $N_THREADS | URL: http://$HOST:$PORT/docs"

  python3 -m llama_cpp.server \
      --model "$MODEL_PATH" \
      --host "$HOST" \
      --port "$PORT" \
      --n_ctx "$N_CTX" \
      --n_threads "$N_THREADS" \
      --n_gpu_layers "$N_GPU_LAYERS"
fi
