#!/bin/zsh
# Тот же исполнитель, но на Pi (pi.dev) вместо Claude Code — для сравнения оболочек.
#   tools/run_pi.sh <модель> <файл-задания.md>
#   tools/run_pi.sh <модель> --resume <лог.jsonl> "уточнение"
# Конфиг Pi — в .pi-home (провайдер coding-lite, песочница pi-sandbox), сторож — tools/pi-guard.ts.
set -e
# zsh читает скрипт по ходу выполнения: правка файла во время прогона запускала второй прогон (24.09.2026).
# Поэтому работаем с копией из /tmp.
if [ -z "$TS_RUNNER_COPY" ]; then
  export TS_PROJECT="$(cd "$(dirname "$0")/.." && pwd)" TS_RUNNER_COPY=1
  C=$(mktemp /tmp/ts-runner.XXXXXX); cp "$0" "$C"; exec zsh "$C" "$@"
fi
cd "$TS_PROJECT"
MODEL=${1:?модель}; TASK=${2:?файл задания}
source ~/.image_gen_keys.env
[ -n "$CODING_LITE_KEY" ] || { echo "нет CODING_LITE_KEY" >&2; exit 1; }
export CODING_LITE_KEY PI_CODING_AGENT_DIR="$PWD/.pi-home"
mkdir -p /tmp/claude   # временная папка, которую pi-sandbox подставляет командам
mkdir -p docs/runs
SESSION=()
if [ "$TASK" = "--resume" ]; then
  PREV=${3:?лог}; PROMPT=${4:?уточнение}
  SID=$(head -1 "$PREV" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['id'])")
  SESSION=(--session "$SID"); LOG="${PREV%.jsonl}_r$(date +%H%M).jsonl"
else
  PROMPT="$(cat docs/tasks/_preamble.md "$TASK")"
  LOG="docs/runs/$(date +%Y-%m-%d_%H%M)_$(basename "$TASK" .md)_pi_${MODEL//\//_}.jsonl"
fi
pi --mode json -p "$PROMPT" "${SESSION[@]}" --provider coding-lite --model "$MODEL" \
  --no-context-files --no-skills --no-prompt-templates -e tools/pi-guard.ts \
  --session-dir "$PWD/.pi-home/sessions" < /dev/null > "$LOG" 2> "${LOG%.jsonl}.stderr" &
PID=$!
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
