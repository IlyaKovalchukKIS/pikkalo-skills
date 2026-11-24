#!/usr/bin/env bash
# Подключает скилл Pickly к проекту приложения.
# Использование: ./install.sh /путь/к/проекту-pickly [--copy]
#   по умолчанию — симлинки (обновления репо скиллов сразу видны в проекте);
#   --copy — копия (если проект собирается в CI без этого репозитория).
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:?Укажите путь к проекту приложения}"
MODE="${2:-}"

[ -d "$DEST" ] || { echo "Нет папки $DEST" >&2; exit 1; }
DEST="$(cd "$DEST" && pwd)"

link() { # $1 — источник, $2 — цель
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] || [ -L "$2" ]; then
    echo "  пропуск: $2 уже существует"
    return
  fi
  if [ "$MODE" = "--copy" ]; then cp -R "$1" "$2"; else ln -s "$1" "$2"; fi
  echo "  ок: $2"
}

echo "Скилл:"
link "$SRC/skills/pickly" "$DEST/.claude/skills/pickly"   # Claude Code
link "$SRC/skills/pickly" "$DEST/.agents/skills/pickly"   # Codex (на него ссылается AGENTS.md)

echo "Инструкции агентов (копия, правьте под проект):"
for f in AGENTS.md CLAUDE.md; do
  if [ -e "$DEST/$f" ]; then echo "  пропуск: $f уже есть"; else cp "$SRC/templates/$f" "$DEST/$f"; echo "  ок: $f"; fi
done

mkdir -p "$DEST/tasks" "$DEST/docs"
[ -e "$DEST/tasks/TEMPLATE.md" ] || cp "$SRC/templates/TASK-TEMPLATE.md" "$DEST/tasks/TEMPLATE.md"
[ -e "$DEST/docs/DECISIONS.md" ] || printf '# Решения\n\nФормат: `ГГГГ-ММ-ДД — что решили — почему`\n\n' > "$DEST/docs/DECISIONS.md"

echo "Готово. Конвейер отзывов ставится отдельно: см. pipeline/README.md"
