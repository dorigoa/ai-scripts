#!/usr/bin/env bash
set -euo pipefail


REASONING_EFFORT="medium"
MAX_CONTEXT="262144"
PORT="8000"
HOST="0.0.0.0"
NOWEBUI=""
LANGONLY=""

# ========================= Help =========================
usage() {
cat <<EOF
Uso: $0 [options]
  -c, --max-ctx <n>    context size (default: $MAX_CONTEXT)
  -p, --port <n>       TCP port of the listening server (default: $PORT)
  -H, --host <host>    Host/IP on which the server binds to (default: $HOST)
  -e, --effort <s>     reasoning effort: low | medium | xhigh  (default: $REASONING_EFFORT)
  -u, --no-webui       disable the WEB ui server (default: enable)
  -l, --language-only  disable the image processor (default: enable)
  -h, --help           show this help
EOF
}

# ========================= Parse arguments =========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--max-ctx)       MAX_CONTEXT="$2"; shift 2 ;;
    -p|--port)          PORT="$2"; shift 2 ;;
    -H|--host)          HOST="$2"; shift 2 ;;     
    -e|--effort)        REASONING_EFFORT="$2"; shift 2 ;;
    -u|--no-webui)      NOWEBUI="--no-webui"; shift ;;
    -l|--language-only) LANGONLY="--language-only"; shift 2 ;;
    -h|--help)          usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

[[ "$MAX_CONTEXT" =~ ^[0-9]+$ ]] || { echo "Max Context must be numeric" >&2; exit 1; }
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "Port must be numeric" >&2; exit 1; }
case "$REASONING_EFFORT" in low|medium|xhigh) ;; *) echo "--effort must be low|medium|xhigh" >&2; exit 1 ;; esac

# ========================= DoIt =========================
hf download mlx-community/Qwen3.8-27B-4bit
#brew install -q incoai/tap/splash

CMD=("splash"
  serve
  --port "$PORT"
  --host $HOST
  --model mlx-community/Qwen3.8-27B-4bit
  --default-reasoning-effort $REASONING_EFFORT
  --max-context $MAX_CONTEXT
  $LANGONLY 
  --served-model-name Qwen3.8-27B-4bit
  --kv-format int8
  --max-memory $(/usr/sbin/sysctl iogpu.wired_limit_mb|awk '{print sprintf("%.0f", $NF/1024)}')G
  --max-cache-disk 16G # should be enough for most of the KVs
  $NOWEBUI
)

echo "Execute: ${CMD[*]}"
exec "${CMD[@]}"

#splash serve --port 8000 --host 0.0.0.0 \
# --model mlx-community/Qwen3.8-27B-4bit \
# --default-reasoning-effort medium \
# --max-context 262144 \
# --language-only \
# --served-model-name Qwen8-27B-4bit \
# --kv-format int8 \
# --max-cache-disk 16G \
# --max-memory 30G
