#!/usr/bin/env bash
# Подключает скилл Pickly к проекту приложения.
# Использование: ./install.sh /путь/к/проекту-pickly
# Скилл копируется в .agents/skills (его видят Codex, облако и CI);
# обновление — scripts/sync-skill.sh в проекте.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:?Укажите путь к проекту приложения}"

[ -d "$DEST" ] || { echo "Нет папки $DEST" >&2; exit 1; }
DEST="$(cd "$DEST" && pwd)"

echo "Скилл:"
# Копия для Codex (работает и в облаке/CI), относительная ссылка для Claude Code.
mkdir -p "$DEST/.agents/skills" "$DEST/.claude/skills"
rsync -a --delete "$SRC/skills/pickly/" "$DEST/.agents/skills/pickly/" && echo "  ок: .agents/skills/pickly (копия)"
[ -e "$DEST/.claude/skills/pickly" ] || ln -s ../../.agents/skills/pickly "$DEST/.claude/skills/pickly"
echo "  ок: .claude/skills/pickly → .agents/skills/pickly"
mkdir -p "$DEST/scripts"
[ -e "$DEST/scripts/sync-skill.sh" ] || printf '#!/usr/bin/env bash\nset -euo pipefail\nROOT="$(cd "$(dirname "$0")/.." && pwd)"\nrsync -a --delete "${1:-$ROOT/../pickly-skills}/skills/pickly/" "$ROOT/.agents/skills/pickly/"\n' > "$DEST/scripts/sync-skill.sh" && chmod +x "$DEST/scripts/sync-skill.sh"

echo "Инструкции агентов (копия, правьте под проект):"
for f in AGENTS.md CLAUDE.md; do
  if [ -e "$DEST/$f" ]; then echo "  пропуск: $f уже есть"; else cp "$SRC/templates/$f" "$DEST/$f"; echo "  ок: $f"; fi
done

mkdir -p "$DEST/tasks" "$DEST/docs"
[ -e "$DEST/tasks/TEMPLATE.md" ] || cp "$SRC/templates/TASK-TEMPLATE.md" "$DEST/tasks/TEMPLATE.md"
[ -e "$DEST/docs/DECISIONS.md" ] || printf '# Решения\n\nФормат: `ГГГГ-ММ-ДД — что решили — почему`\n\n' > "$DEST/docs/DECISIONS.md"

echo "Готово. Конвейер отзывов ставится отдельно: см. pipeline/README.md"
