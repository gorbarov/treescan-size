#!/bin/zsh
# Запуск дешёвого исполнителя (coding-lite через your-gateway.example) в песочнице.
#   tools/run_executor.sh <модель> <файл-задания.md> [макс. ходов]
#   tools/run_executor.sh deepseek/deepseek-v4.1-flash docs/tasks/stage2.md
# Отдельный конфиг Claude Code в .agent-home (без входа CEO и без его CLAUDE.md),
# ключ — CODING_LITE_KEY из ~/.image_gen_keys.env, лог и стоимость — в docs/runs/.
set -e
cd "$(dirname "$0")/.."
MODEL=${1:?модель}; TASK=${2:?файл задания}
source ~/.image_gen_keys.env
[ -n "$CODING_LITE_KEY" ] || { echo "нет CODING_LITE_KEY в ~/.image_gen_keys.env" >&2; exit 1; }
export CLAUDE_CONFIG_DIR="$PWD/.agent-home"
export ANTHROPIC_BASE_URL="https://your-gateway.example"
export ANTHROPIC_AUTH_TOKEN="$CODING_LITE_KEY"
unset ANTHROPIC_API_KEY
export ANTHROPIC_MODEL="$MODEL" ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL" ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL" ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL" CLAUDE_CODE_SUBAGENT_MODEL="$MODEL"
export DISABLE_TELEMETRY=1 DISABLE_ERROR_REPORTING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
mkdir -p docs/runs
STAMP=$(date +%Y-%m-%d_%H%M)
LOG="docs/runs/${STAMP}_$(basename "$TASK" .md)_${MODEL//\//_}.jsonl"
claude -p "$(cat docs/tasks/_preamble.md "$TASK")" --bare --model "$MODEL" \
  --settings tools/executor-settings.json --permission-mode dontAsk \
  --output-format stream-json --verbose < /dev/null > "$LOG" 2> "${LOG%.jsonl}.stderr"
python3 tools/run_cost.py "$LOG"
echo "лог: $LOG"
