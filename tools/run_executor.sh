#!/bin/zsh
# Запуск дешёвого исполнителя (coding-lite через your-gateway.example) в песочнице.
#   tools/run_executor.sh <модель> <файл-задания.md> [макс. ходов]
#   tools/run_executor.sh deepseek/deepseek-v4.1-flash docs/tasks/stage2.md
#   tools/run_executor.sh <модель> --resume <лог.jsonl> "уточнение"   # продолжить ту же сессию исполнителя
# Отдельный конфиг Claude Code в .agent-home (без входа CEO и без его CLAUDE.md),
# ключ — CODING_LITE_KEY из ~/.image_gen_keys.env, лог и стоимость — в docs/runs/.
set -e
# zsh читает скрипт по ходу выполнения: правка файла во время прогона запускала второй прогон (24.09.2026).
# Поэтому работаем с копией из /tmp.
if [ -z "$TS_RUNNER_COPY" ]; then
  export TS_PROJECT="$(cd "$(dirname "$0")/.." && pwd)" TS_RUNNER_COPY=1
  C=$(mktemp /tmp/ts-runner.XXXXXX); cp "$0" "$C"; exec zsh "$C" "$@"
fi
cd "$TS_PROJECT"
MODEL=${1:?модель}; TASK=${2:?файл задания}
RESUME=()
if [ "$TASK" = "--resume" ]; then
  PREV=${3:?лог прошлого прогона}; MSG=${4:?текст уточнения}
  SID=$(python3 -c "import json,sys
for l in open(sys.argv[1]):
    try: e=json.loads(l)
    except ValueError: continue
    if e.get('session_id'): print(e['session_id']); break" "$PREV")
  [ -n "$SID" ] || { echo "не нашёл session_id в $PREV" >&2; exit 1; }
  RESUME=(--resume "$SID"); TASK="${PREV%.jsonl}"
fi
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
if (( ${#RESUME} )); then
  PROMPT="$MSG"; LOG="${PREV%.jsonl}_r$(date +%H%M).jsonl"
else
  PROMPT="$(cat docs/tasks/_preamble.md "$TASK")"; LOG="docs/runs/${STAMP}_$(basename "$TASK" .md)_${MODEL//\//_}.jsonl"
fi
claude -p "$PROMPT" "${RESUME[@]}" --bare --model "$MODEL" \
  --settings tools/executor-settings.json --permission-mode dontAsk \
  --output-format stream-json --verbose < /dev/null > "$LOG" 2> "${LOG%.jsonl}.stderr" &
PID=$!
# Сторож: нет новых записей в логе IDLE_MAX секунд или прогон дольше TOTAL_MAX — прибить и сказать об этом.
IDLE_MAX=${IDLE_MAX:-600}; TOTAL_MAX=${TOTAL_MAX:-3600}; START=$(date +%s)
while kill -0 $PID 2>/dev/null; do
  sleep 15
  NOW=$(date +%s); IDLE=$(( NOW - $(stat -f %m "$LOG") ))
  if (( IDLE > IDLE_MAX || NOW - START > TOTAL_MAX )); then
    echo "СТОРОЖ: остановлен (тишина ${IDLE} с, всего $(( NOW - START )) с)" | tee -a "${LOG%.jsonl}.stderr"
    kill $PID; sleep 3; kill -9 $PID 2>/dev/null
  fi
done
wait $PID 2>/dev/null || true
python3 tools/run_cost.py "$LOG"
echo "лог: $LOG"
