#!/usr/bin/env bash
# Отдаёт задачу Codex. Использование:
#   codex-delegate.sh check                       — подключён ли Codex (код 0 = да)
#   codex-delegate.sh run <TASK.md> <worktree>    — выполнить задачу в worktree
# Коды выхода: 0 — готово; 2 — Codex не установлен или не залогинен;
#              3 — закончились лимиты/токены; иное — ошибка выполнения (см. лог).
# Последнее сообщение Codex — <worktree>/.codex-last.md, лог — $TMPDIR/codex-<TASK>.log.
set -uo pipefail

connected() {
  command -v codex >/dev/null 2>&1 || { echo "Codex CLI не установлен" >&2; return 2; }
  codex login status 2>&1 | grep -qi "logged in" || { echo "Codex не залогинен: codex login" >&2; return 2; }
}

case "${1:-}" in
  check) connected; exit $? ;;
  run)
    TASK="${2:?Укажите файл задачи}"; WT="${3:?Укажите worktree}"
    connected || exit 2
    [ -f "$WT/$TASK" ] || [ -f "$TASK" ] || { echo "Нет файла задачи $TASK" >&2; exit 1; }
    LOG="${TMPDIR:-/tmp}/codex-$(basename "$TASK" .md).log"
    codex exec --sandbox workspace-write -c sandbox_workspace_write.network_access=true \
      -C "$WT" --output-last-message "$WT/.codex-last.md" \
      "Выполни задачу из файла $TASK. Соблюдай AGENTS.md и скилл .agents/skills/pikkalo. \
Прогони проверки из раздела «Готово, когда». Не коммить: предложи сообщение коммита в «Заметках» задачи." \
      >"$LOG" 2>&1
    CODE=$?
    if [ $CODE -ne 0 ] && tail -n 40 "$LOG" | grep -qiE "usage limit|rate.?limit|quota|insufficient|too many requests|(^|[^0-9])429([^0-9]|$)" "$LOG"; then
      echo "У Codex закончились лимиты — см. $LOG" >&2; exit 3
    fi
    echo "Лог: $LOG"; exit $CODE ;;
  *) sed -n '2,7p' "$0"; exit 1 ;;
esac
