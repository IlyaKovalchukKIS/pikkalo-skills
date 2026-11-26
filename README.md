# pikkalo-skills

Единый скилл и инструменты команды **Pikkalo** — приложения для разбора галереи телефона
и Яндекс Диска. Один источник правил для Claude Code и Codex.

## Состав
```
skills/pikkalo/                 единый скилл (Claude Code и Codex читают один и тот же)
  SKILL.md                     оркестратор: инварианты, маршрутизация, режимы build/review/photo/perf/triage
  scripts/codex-delegate.sh    проверка, что Codex подключён, и запуск задачи в worktree
  references/
    product.md                 бриф продукта
    ui-design.md               роль UI-дизайнера: стек, токены, движение, тактильность, производительность
    copy-marketing.md          роль маркетолога-редактора: посыл, словарь, награды, пуши, пейволл, ревью
    photo-analysis.md          роль аналитика фото: дубли, серии, лучший кадр, категории, корзина, метрики
    algorithms.md              роль алгоритмиста: скорость фото/видео, память, конкурентность, мост, ускорение UI
    auth-account.md            вход (Яндекс ID, Apple, Google), кабинет, подписка
    feedback-pipeline.md       отзыв → Telegram → агент → PR
    team-routing.md            Claude + Codex: кто что делает, экономия токенов
    communication.md           краткие ответы, отчёты, описания PR, экономия контекста
    release.md                 выпуск обновления APK: чек-лист, публикация, откат
templates/                     AGENTS.md, CLAUDE.md, шаблон задачи — для репозитория приложения
pipeline/                      Cloudflare Worker, GitHub Actions, промпт triage, схема Supabase
install.sh                     подключить скилл к проекту приложения
```

## Подключить к проекту
```bash
./install.sh ~/code/pikkalo
```
Создаст `.claude/skills/pikkalo` (Claude Code) и `.agents/skills/pikkalo` (Codex) как
копию скилла (`.agents/skills/pikkalo`) и ссылку на неё для Claude Code (`.claude/skills/pikkalo`), положит `AGENTS.md`, `CLAUDE.md`, `tasks/`, `docs/DECISIONS.md`.

## Как пользоваться
- Claude Code: «Сделай экран разбора серии», «Проверь онбординг» — скилл подхватится сам,
  или явно: `/pikkalo review src/screens/Paywall.tsx`.
- Codex: правила приходят из `AGENTS.md` и `.agents/skills/pikkalo`.

Конвейер отзывов — `pipeline/README.md`.
