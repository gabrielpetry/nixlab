#!/usr/bin/env bash

# # if the command below has an error then the script below will not execute
set -e

# -hf Jackrong/Qwopus3.5-4B-v3-GGUF:Q4_K_M \
# --reasoning off \
llama-server \
  -hf unsloth/Qwen3.5-2B-GGUF:UD-Q6_K_XL \
  --port 8012 \
  -ngl all \
  --flash-attn on \
  --ctx-size 16000 \
  --cache-reuse 256 \
  --parallel 1 \
  --batch-size 512 \
  --ubatch-size 512 \
  --temp 0.1 \
  --top-k 20 \
  --top-p 0.95 \
  --min-p 0.0 \
  --repeat-penalty 1.0 \
  --repeat-last-n 128 \
  --frequency-penalty 0.2 \
  --presence-penalty 0.0 \
  --ctx-checkpoints 0 \
  --reasoning-budget 0 \
  --dry-multiplier 0.8 \
  --dry-base 1.75 \
  --dry-allowed-length 2 \
  --dry-penalty-last-n 512

# --threads 3
# - --cache-type-k
# - q4_0
# - --cache-type-v
# - q4_0
# - --tools
# - all
