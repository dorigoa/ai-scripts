#/opt/llama.cpp/llama-server -m /Users/dorigo_a/Qwen3.8-27B-UD-Q4_K_XL.gguf -md /Users/dorigo_a/mtp-Qwen3.8-27B-Q4_0.gguf --port 8080 --host 0.0.0.0 --parallel 1 --flash-attn on --no-context-shift -c 20000 --alias /Qwen3.8-27B-UD-Q4_K_XL --fit on --metrics --slot-save-path /Users/dorigo_a/llama-cache/ --fit-ctx 20000 --fit-target 512 --jinja --verbosity 4 --cache-type-k q8_0 --cache-type-v q8_0 --reasoning on --chat-template-kwargs '{"preserve_thinking": true}' --ctx-checkpoints 10 --no-mmproj-auto --spec-type draft-mtp --spec-draft-n-max 3

#!/usr/bin/env bash
set -euo pipefail

# ========================= Default (modifica qui se preferisci) =========================
LLAMA_SERVER="/opt/llama.cpp/llama-server"
HOST="0.0.0.0"

GGUF_DIR="/Users/dorigo_a"          # directory dei due .gguf
MODEL_NAME="Qwen3.8-27B-UD-Q4_K_XL.gguf"   # file per -m
MTP_NAME="mtp-Qwen3.8-27B-Q4_0.gguf"       # file per -md

CTX_SIZE=20000            # context size (-c e --fit-ctx)
PORT=8080                 # porta TCP (--port)
REASONING="on"            # on | off
REASONING_EFFORT="medium" # low | medium | high
MTP="on"                  # on | off (aggiunge -md + --spec-type draft-mtp)

SLOT_SAVE_PATH="/Users/dorigo_a/llama-cache/"

# ========================= Help =========================
usage() {
cat <<EOF
Uso: $0 [opzioni]

  -d, --dir <path>     directory contenente i due .gguf (default: $GGUF_DIR)
  -c, --ctx <n>        context size (default: $CTX_SIZE)
  -p, --port <n>       porta TCP (default: $PORT)
  -r, --reasoning <s>  on | off (default: $REASONING)
  -e, --effort <s>     reasoning effort: low | medium | xhigh  (default: $REASONING_EFFORT)
  -M, --mtp <s>        on | off (default: $MTP)
  -h, --help           mostra questo aiuto
EOF
}

# ========================= Parse argomenti =========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)       GGUF_DIR="$2"; shift 2 ;;
    -c|--ctx)       CTX_SIZE="$2"; shift 2 ;;
    -p|--port)      PORT="$2"; shift 2 ;;
    -r|--reasoning) REASONING="$2"; shift 2 ;;
    -e|--effort)    REASONING_EFFORT="$2"; shift 2 ;;
    -M|--mtp)       MTP="$2"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Opzione sconosciuta: $1" >&2; usage; exit 1 ;;
  esac
done

# ========================= Validazioni =========================
[[ -d "$GGUF_DIR" ]] || { echo "Directory non trovata: $GGUF_DIR" >&2; exit 1; }
[[ -f "$GGUF_DIR/$MODEL_NAME" ]] || { echo "File non trovato: $GGUF_DIR/$MODEL_NAME" >&2; exit 1; }
[[ "$CTX_SIZE" =~ ^[0-9]+$ ]] || { echo "Context size deve essere numerico" >&2; exit 1; }
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "Porta deve essere numerica" >&2; exit 1; }
case "$REASONING" in on|off) ;; *) echo "--reasoning deve essere on o off" >&2; exit 1 ;; esac
case "$MTP" in on|off) ;; *) echo "--mtp deve essere on o off" >&2; exit 1 ;; esac
case "$REASONING_EFFORT" in low|medium|xhigh) ;; *) echo "--effort deve essere low|medium|xhigh" >&2; exit 1 ;; esac
[[ "$MTP" == "on" && ! -f "$GGUF_DIR/$MTP_NAME" ]] && { echo "File non trovato: $GGUF_DIR/$MTP_NAME" >&2; exit 1; }

# ========================= Costruzione comando =========================
ALIAS="${MODEL_NAME%.gguf}"

CMD=("$LLAMA_SERVER"
  -m "$GGUF_DIR/$MODEL_NAME"
  --port "$PORT" --host "$HOST"
  --parallel 1 --flash-attn on --no-context-shift
  -c "$CTX_SIZE"
  --alias "$ALIAS"
  --fit on --metrics
  --slot-save-path "$SLOT_SAVE_PATH"
  --fit-ctx "$CTX_SIZE" --fit-target 512
  --jinja --verbosity 4
  --cache-type-k q8_0 --cache-type-v q8_0
  --reasoning "$REASONING"
  --ctx-checkpoints 10 --no-mmproj-auto
)

# reasoning: kwargs solo se on
if [[ "$REASONING" == "on" ]]; then
  CMD+=(--chat-template-kwargs "{\"preserve_thinking\": true, \"reasoning_effort\": \"${REASONING_EFFORT}\"}")
fi

# MTP: on/off
if [[ "$MTP" == "on" ]]; then
  CMD+=(-md "$GGUF_DIR/$MTP_NAME" --spec-type draft-mtp --spec-draft-n-max 3)
fi

echo "Execute: ${CMD[*]}"
exec "${CMD[@]}"

