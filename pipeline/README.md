# Установка конвейера отзывов и кабинета

> **Внимание:** бэкенд Pickly переезжает в Yandex Cloud (данные в РФ). Разделы про
> Supabase и Cloudflare Worker ниже — черновик прошлой архитектуры; их логика переносится
> в функции `backend/` репозитория приложения. Workflows и промпт triage — актуальны.

Порядок: Supabase → Telegram-бот → Cloudflare Worker → GitHub (секреты и workflows).
Схема и правила — `skills/pickly/references/feedback-pipeline.md`.

## 1. Supabase
1. Создайте проект на supabase.com (Free).
2. SQL Editor → выполните `supabase/schema.sql`.
3. Authentication → Providers: включите **Apple** и **Google** (для `signInWithIdToken`),
   Email оставьте включённым (через него работает вход Яндекс ID).
4. Сохраните `Project URL`, `anon key`, `service_role key`.

## 2. Telegram-бот
1. В @BotFather: `/newbot` → получите токен.
2. Узнайте свой числовой id (например, через @userinfobot).
3. Напишите боту `/start`, чтобы он мог присылать вам сообщения.

## 3. Cloudflare Worker
```bash
cd pipeline/worker && npm install
npx wrangler login
```
Впишите в `wrangler.toml` `GITHUB_REPO`, `SUPABASE_URL`, `TELEGRAM_OWNER_ID`, затем секреты:
```bash
npx wrangler secret put GITHUB_TOKEN
npx wrangler secret put TELEGRAM_BOT_TOKEN
npx wrangler secret put TELEGRAM_WEBHOOK_SECRET
npx wrangler secret put SUPABASE_ANON_KEY
npx wrangler secret put SUPABASE_SERVICE_KEY
npx wrangler deploy
```
`GITHUB_TOKEN` — fine-grained PAT только на репозиторий приложения, права Issues: read/write.
`TELEGRAM_WEBHOOK_SECRET` — любая случайная строка (`openssl rand -hex 24`).

Подключите вебхук Telegram (подставьте значения):
```bash
curl "https://api.telegram.org/bot<TOKEN>/setWebhook" -d "url=https://pickly-edge.<you>.workers.dev/telegram" -d "secret_token=<WEBHOOK_SECRET>" -d 'allowed_updates=["callback_query"]'
```

## 4. Яндекс OAuth
oauth.yandex.ru → создать приложение: платформа iOS/Android, redirect `pickly://oauth`,
доступы `login:info`, `login:email`, `cloud_api:disk.read`, `cloud_api:disk.write`.

## 5. GitHub (репозиторий приложения)
Скопируйте файлы:
```bash
mkdir -p .github/workflows .github/prompts
cp <pickly-skills>/pipeline/github/workflows/*.yml .github/workflows/
cp <pickly-skills>/pipeline/github/prompts/triage.md .github/prompts/
```
Создайте метки: `feedback`, `kind:bug`, `kind:idea`, `kind:other`, `approved`, `rejected`,
`route:claude`, `route:codex`, `priority:P1..P3`, `effort:S/M/L`.

Секреты репозитория (Settings → Secrets and variables → Actions):
| Секрет | Откуда |
|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | `claude setup-token` на вашем Mac (подписка Pro) |
| `TELEGRAM_BOT_TOKEN`, `TELEGRAM_OWNER_ID` | шаг 2 |
| `SUPABASE_URL`, `SUPABASE_SERVICE_KEY` | шаг 1 |
| `OWNER_GH_PAT` | ваш PAT (Issues: write) — чтобы `@codex` был от вашего имени |

Установите GitHub App Claude (`claude` → `/install-github-app`) и подключите репозиторий
в настройках Codex (chatgpt.com/codex → GitHub).

## 6. Проверка
1. Создайте вручную issue с меткой `feedback` → через ~1 мин в Telegram придёт карточка.
2. Нажмите «Согласовать» → issue получит `approved` → запустится реализация.
3. Влейте PR → придёт «🎉 реализован», статус в Supabase станет `done`.
