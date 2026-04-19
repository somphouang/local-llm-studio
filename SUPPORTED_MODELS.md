# Supported Local LLM Models

The `llama.cpp` + GGUF backend supports thousands of models. When changing models, you need two key pieces of information:
1.  **Repository ID** (e.g., `QuantFactory/Meta-Llama-3-8B-Instruct-GGUF`)
2.  **Filename** (e.g., `Meta-Llama-3-8B-Instruct.Q4_K_M.gguf`)

Below is a categorized list of excellent models tailored for different specialties. Provide the exact string coordinates into your scripts for rapid offline setup.

---

## 🎨 Creative Writing & General Purpose 

### Meta Llama 3 (8B Instruct)
*The default standard for highly capable, balanced, and generalized reasoning.*
* **Repo:** `QuantFactory/Meta-Llama-3-8B-Instruct-GGUF`
* **File:** `Meta-Llama-3-8B-Instruct.Q4_K_M.gguf`
* **Requirements:** 8GB RAM / 4.9GB Disk

### Mistral (7B Instruct v0.3)  
*Excellent alternative to Llama 3, known for distinct prose style and strong language comprehension.*
* **Repo:** `MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF`
* **File:** `Mistral-7B-Instruct-v0.3.Q4_K_M.gguf`
* **Requirements:** 8GB RAM / 4.3GB Disk

### Cohere Command R (35B)
*Highly specialized for creative tasks, conversational workflows, and structured task instruction.*
* **Repo:** `pmysl/c4ai-command-r-v01-GGUF`
* **File:** `command-r-v01-Q4_K_M.gguf`
* **Requirements:** 32GB RAM / 20.4GB Disk

---

## 💻 Coding & Mathematics (Logic)

### DeepSeek Coder (33B Instruct V1.5)
*Renowned for beating larger models in purely algorithmic tasks and massive context code comprehension.*
* **Repo:** `TheBloke/deepseek-coder-33B-instruct-GGUF`
* **File:** `deepseek-coder-33b-instruct.Q4_K_M.gguf`
* **Requirements:** 32GB RAM / 19.9GB Disk

### Qwen 1.5 (7B Chat)
*Highly performant model from Alibaba Cloud, dominating pure coding benchmarks for its weight class.*
* **Repo:** `Qwen/Qwen1.5-7B-Chat-GGUF`
* **File:** `qwen1_5-7b-chat-q4_k_m.gguf`
* **Requirements:** 8GB RAM / 4.5GB Disk

### Phind-CodeLlama (34B v2)
*Exceptional programming copilot based on Llama that generates highly accurate standard libraries.*
* **Repo:** `TheBloke/Phind-CodeLlama-34B-v2-GGUF`
* **File:** `phind-codellama-34b-v2.Q4_K_M.gguf`
* **Requirements:** 32GB RAM / 20.2GB Disk

---

## 🔬 Uncensored & Frontier Exploratory

### Grok-1 (314B - Not strictly GGUF friendly for standard RAM)
*(Note: Extremely massive, requires highly specialized MoE infrastructure, typically run clustered, not listed here for single-node standard).*

### Dolphin Llama 3 (8B) 
*An uncensored variant of Llama 3 that bypasses traditional AI safety alignments for unfiltered processing.*
* **Repo:** `cognitivecomputations/dolphin-2.9-llama3-8b-gguf`
* **File:** `dolphin-2.9-llama3-8b.q4_k_m.gguf`
* **Requirements:** 8GB RAM / 4.9GB Disk

---

## ⚡ Edge Testing & Micro-Models (CPU Efficient)

### Microsoft Phi-3 (Mini 4k Instruct)
*Packs extreme intelligence into a very small parameter space. Fantastic for CPU instances.*
* **Repo:** `microsoft/Phi-3-mini-4k-instruct-gguf`
* **File:** `Phi-3-mini-4k-instruct-q4.gguf`
* **Requirements:** 4GB RAM / 2.4GB Disk

### Qwen 1.5 (0.5B Chat)
*Micro-model designed for lightning-fast latency tests. Fits practically anywhere.*
* **Repo:** `Qwen/Qwen1.5-0.5B-Chat-GGUF`
* **File:** `qwen1_5-0_5b-chat-q4_k_m.gguf`
* **Requirements:** 1GB RAM / ~398MB Disk

### Google Gemma (2B Instruct)
*A scaled down iteration of Google Gemini's open weights utilizing native Gemini architectures.*
* **Repo:** `bartowski/gemma-2b-it-GGUF`
* **File:** `gemma-2b-it-Q4_K_M.gguf`
* **Requirements:** 4GB RAM / ~1.6GB Disk

---

## 🚀 Heavy Duty Massive MoE (GPU Array Highly Recommended)

### Mixtral 8x22B (Instruct v0.1)
*Vastly powerful Mixture-of-Experts architecture. Requires enterprise cloud computation.*
* **Repo:** `MaziyarPanahi/Mixtral-8x22B-Instruct-v0.1-GGUF`
* **File:** `Mixtral-8x22B-Instruct-v0.1.Q4_K_M.gguf`
* **Requirements:** 128GB RAM or Multi-GPU Arrays / ~80GB Disk

### Meta Llama 3 (70B Instruct)
*State-of-the-art capability approaching GPT-4, requires immense RAM processing boundaries.*
* **Repo:** `QuantFactory/Meta-Llama-3-70B-Instruct-GGUF`
* **File:** `Meta-Llama-3-70B-Instruct.Q4_K_M.gguf`
* **Requirements:** 64GB RAM / 42.5GB Disk
