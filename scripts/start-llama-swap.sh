#!/usr/bin/env bash
# Start llama-swap — on-demand multi-model proxy for llama-server.
# Web UI:  http://localhost:11444/ui
# API:     http://localhost:11444/v1/chat/completions
# Config:  ~/projects/llm/config.yaml

exec llama-swap \
  --config "$(dirname "$0")/llama-swap-config.yaml" \
  --listen 0.0.0.0:11444
