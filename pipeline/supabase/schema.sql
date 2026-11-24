-- Pikkalo: схема личного кабинета (Supabase, бесплатный тариф).
-- Только агрегаты: никаких фото, превью, эмбеддингов, лиц и токенов облаков.

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  locale text not null default 'ru',
  review_mode text not null default 'best_swipe' check (review_mode in ('best_swipe', 'grid')),
  reminder_time time,                 -- локальное время напоминаний; null = выключены
  reminders_per_week smallint not null default 3 check (reminders_per_week between 0 and 7),
  created_at timestamptz not null default now()
);

create table public.stats (
  user_id uuid primary key references auth.users on delete cascade,
  photos_reviewed integer not null default 0,
  photos_trashed integer not null default 0,
  bytes_freed bigint not null default 0,
  series_reviewed integer not null default 0,
  streak_days integer not null default 0,
  streak_freezes smallint not null default 1,
  last_review_date date,
  updated_at timestamptz not null default now()
);

create table public.achievements (
  user_id uuid references auth.users on delete cascade,
  code text not null,                 -- 'first_series', 'week_streak', 'freed_1gb', …
  unlocked_at timestamptz not null default now(),
  primary key (user_id, code)
);

create table public.storages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  provider text not null check (provider in ('device', 'yandex_disk')),
  account_label text,                 -- например, логин Яндекса; токен хранится только на устройстве
  quota_total bigint,
  quota_used bigint,
  connected_at timestamptz not null default now(),
  unique (user_id, provider, account_label)
);

create type public.feedback_status as enum
  ('new', 'triaged', 'approved', 'in_progress', 'done', 'rejected');

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  kind text not null check (kind in ('bug', 'idea', 'other')),
  text text not null check (char_length(text) between 3 and 4000),
  screen text, app_version text, platform text, os_version text, locale text,
  status public.feedback_status not null default 'new',
  issue_number integer unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.feedback (user_id, created_at desc);

-- Row Level Security: пользователь видит и меняет только своё.
alter table public.profiles     enable row level security;
alter table public.stats        enable row level security;
alter table public.achievements enable row level security;
alter table public.storages     enable row level security;
alter table public.feedback     enable row level security;

create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "own stats" on public.stats
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own achievements read" on public.achievements
  for select using (auth.uid() = user_id);
create policy "own achievements insert" on public.achievements
  for insert with check (auth.uid() = user_id);
create policy "own storages" on public.storages
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- Отзывы создаёт и меняет только воркер (service key); пользователь их только читает.
create policy "own feedback read" on public.feedback
  for select using (auth.uid() = user_id);

-- Профиль и статистика создаются автоматически при регистрации.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
    values (new.id, new.raw_user_meta_data ->> 'display_name');
  insert into public.stats (user_id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Подписку не храним здесь: источник правды — RevenueCat (app_user_id = auth.users.id).
