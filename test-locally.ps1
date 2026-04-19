Write-Host "=== Testing Local LLM Studio Setup on Windows ==="

New-Item -ItemType Directory -Force -Path "models"

Write-Host "Downloading small test model (TinyLlama-1.1B) via python script..."
$DownloadScript = "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF', filename='tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf', local_dir='models', local_dir_use_symlinks=False)"
python -c $DownloadScript

$TestModelFile = "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

Write-Host "Starting server in the background for testing..."
$ServerProcess = Start-Process -FilePath "python" -ArgumentList "-m llama_cpp.server --model models\$TestModelFile --host 127.0.0.1 --port 8000 --n_ctx 2048 --n_threads 2 --n_gpu_layers 0" -PassThru -NoNewWindow

Write-Host "Waiting for server to initialize..."
Start-Sleep -Seconds 15

Write-Host "Sending test request to model..."
$Body = @{
    messages = @(
        @{
            role = "user"
            content = "What is 2 plus 2?"
        }
    )
} | ConvertTo-Json

try {
    $Response = Invoke-RestMethod -Uri "http://127.0.0.1:8000/v1/chat/completions" -Method Post -ContentType "application/json" -Body $Body
    Write-Host "`n========================"
    Write-Host "Response from LLM API:"
    Write-Host ($Response.choices[0].message.content)
    Write-Host "========================`n"
} catch {
    Write-Host "Error connecting to the LLM Server. It may still be booting or failed."
}

Write-Host "Test complete. Shutting down server."
if ($ServerProcess -and (-Not $ServerProcess.HasExited)) {
    Stop-Process -Id $ServerProcess.Id -Force
}
Write-Host "Done."
