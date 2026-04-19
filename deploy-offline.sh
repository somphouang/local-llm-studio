#!/bin/bash
set -e

echo "=== Deploying Local LLM Studio Offline ==="

# Ensure Python 3 system dependencies for Ubuntu/Debian
echo "Checking base OS environment..."
if command -v apt-get &> /dev/null; then
    if ! dpkg -l | grep -q "python3.*venv" || ! dpkg -l | grep -q "build-essential"; then
        echo "Installing OS-level requirements (python3-venv, pip, build-essential)..."
        echo "Note: You may be prompted for your sudo password."
        sudo apt-get update -y
        sudo apt-get install -y python3-venv python3-pip build-essential
    fi
else
    if ! command -v python3 &> /dev/null; then
        echo "python3 could not be found. Please assure Python 3.10+ is accessible."
        exit 1
    fi
fi

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo "Installing Python dependencies from local packages..."
pip install --no-index --find-links=offline_packages -r requirements.txt

echo "✅ Deployment successful!"
echo "Check .env file settings, then run ./start-server.sh to begin inference."
