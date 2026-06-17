#!/usr/bin/env bash
# Start llama.cpp HTTP server on demand.
# Mirrors the services.llama-cpp config without the systemd sandbox restrictions.

LLM_DIR="${HOME}/projects/llm"
LLAMA_CACHE="${LLM_DIR}/.cache"
mkdir -p "$LLAMA_CACHE" "${LLM_DIR}/models"

export LLAMA_CACHE

exec llama-server \
  --host 0.0.0.0 \
  --port 11444 \
  --n-gpu-layers -1 \
  --model "${LLM_DIR}/models/Qwen3.5-9B-Q4_1.gguf"
