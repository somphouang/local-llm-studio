#!/bin/bash
set -e

echo "=== Testing Local LLM Studio Setup on WSL (Ubuntu) ==="

# Dependencies already provided by root.


mkdir -p models

echo "Setting up Python environment..."
if [ ! -d "venv_linux" ]; then
    python3 -m venv venv_linux
fi
source venv_linux/bin/activate

echo "Installing LLM dependencies inside venv..."
pip install llama-cpp-python[server] huggingface_hub python-dotenv typing-extensions anyio starlette uvicorn pydantic fastapi sse_starlette pydantic_settings

echo "Downloading small test model (TinyLlama-1.1B) via python script..."
python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF', filename='tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf', local_dir='models', local_dir_use_symlinks=False)"

TEST_MODEL_FILE="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

echo "Starting server in the background for testing..."
python3 -m llama_cpp.server \
    --model "models/$TEST_MODEL_FILE" \
    --host "127.0.0.1" \
    --port "8000" \
    --n_ctx "2048" \
    --n_threads "2" \
    --n_gpu_layers "0" > server.log 2>&1 &
SERVER_PID=$!

echo "Waiting for server to initialize..."
sleep 15

echo -e "\n========================"
echo "Sending test request to model (What is 2 plus 2?)..."
curl -X POST http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "What is 2 plus 2?"
      }
    ]
  }'
echo -e "\n========================"

echo "Test complete. Shutting down server."
kill $SERVER_PID || true
echo "Done."
