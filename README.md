# pickly-skills

Единый скилл и инструменты команды **Pickly** — приложения для разбора галереи телефона
и Яндекс Диска. Один источник правил для Claude Code и Codex.

## Состав
```
skills/pickly/                 единый скилл (Claude Code и Codex читают один и тот же)
  SKILL.md                     оркестратор: инварианты, маршрутизация, режимы build/review/photo/triage
  references/
    product.md                 бриф продукта
    ui-design.md               роль UI-дизайнера: стек, токены, движение, тактильность, производительность
    copy-marketing.md          роль маркетолога-редактора: посыл, словарь, награды, пуши, пейволл, ревью
    photo-analysis.md          роль аналитика фото: дубли, серии, лучший кадр, категории, корзина, метрики
    auth-account.md            вход (Яндекс ID, Apple, Google), кабинет, подписка
    feedback-pipeline.md       отзыв → Telegram → агент → PR
    team-routing.md            Claude + Codex: кто что делает, экономия токенов
templates/                     AGENTS.md, CLAUDE.md, шаблон задачи — для репозитория приложения
pipeline/                      Cloudflare Worker, GitHub Actions, промпт triage, схема Supabase
install.sh                     подключить скилл к проекту приложения
```

## Подключить к проекту
```bash
./install.sh ~/code/pickly
```
Создаст `.claude/skills/pickly` (Claude Code) и `.agents/skills/pickly` (Codex) как
копию скилла (`.agents/skills/pickly`) и ссылку на неё для Claude Code (`.claude/skills/pickly`), положит `AGENTS.md`, `CLAUDE.md`, `tasks/`, `docs/DECISIONS.md`.

## Как пользоваться
- Claude Code: «Сделай экран разбора серии», «Проверь онбординг» — скилл подхватится сам,
  или явно: `/pickly review src/screens/Paywall.tsx`.
- Codex: правила приходят из `AGENTS.md` и `.agents/skills/pickly`.

Конвейер отзывов — `pipeline/README.md`.
