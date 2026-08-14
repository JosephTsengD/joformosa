-- JoinCrew schema v1
-- 設計原則見計劃書第 6.2 節。

create extension if not exists "pgcrypto";

create type sport_kind   as enum ('run','ride','hyrox','other');
create type session_kind as enum ('regular','special','race','social');
create type crew_status  as enum ('draft','pending','published','archived');

create table cities (
  code    char(3) primary key,
  name_zh text not null,
  name_en text not null,
  sort    int  not null default 0
);

insert into cities (code, name_zh, name_en, sort) values
  ('TPE','台北','Taipei',1), ('TPH','新北','New Taipei',2),
  ('TYN','桃園','Taoyuan',3), ('HSZ','新竹','Hsinchu',4),
  ('TXG','台中','Taichung',5), ('TNN','台南','Tainan',6),
  ('KHH','高雄','Kaohsiung',7), ('ILA','宜蘭','Yilan',8);

create table style_tags (
  code     text primary key,
  label_zh text not null,
  label_en text not null
);

insert into style_tags values
  ('beginner','新手友善','Beginner friendly'),
  ('night','夜間','Night'),
  ('trail','越野/山徑','Trail'),
  ('social','歡樂社交','Social'),
  ('long','長距離','Long distance'),
  ('interval','間歇/速度','Intervals'),
  ('morning','晨跑','Morning'),
  ('riverside','河濱','Riverside'),
  ('race_prep','備賽衝刺','Race prep'),
  ('office','上班族','Office workers');

create table crews (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null check (slug ~ '^[a-z0-9-]{3,60}$'),
  name          text not null check (char_length(name) between 2 and 80),
  handle        text,
  sport         sport_kind not null,
  city_code     char(3) not null references cities(code),
  home_base     text not null,
  regular_schedule text,
  intro         text,
  -- 積分只能由排程 job 寫入；RLS 禁止團長自行修改（見 0002_rls.sql）
  activity_score int not null default 0 check (activity_score >= 0),
  manual_score_adjustment int not null default 0,
  status        crew_status not null default 'pending',
  owner_id      uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 分區排序的關鍵索引：原站「在所屬縣市的曝光越前面」是 partitioned sort
create index crews_city_score_idx on crews (city_code, activity_score desc, id);
create index crews_score_idx      on crews (activity_score desc, id);
create index crews_owner_idx      on crews (owner_id) where owner_id is not null;
create index crews_search_idx     on crews
  using gin (to_tsvector('simple', name || ' ' || coalesce(intro,'')));

create table sessions (
  id            uuid primary key default gen_random_uuid(),
  crew_id       uuid not null references crews(id) on delete cascade,
  title         text not null,
  kind          session_kind not null default 'regular',
  starts_at     timestamptz not null,
  ends_at       timestamptz,
  location_name text not null,
  cover_url     text,
  external_url  text,
  created_at    timestamptz not null default now(),
  -- ⚠ 沒有 status 欄位：狀態由時間推導（ADR-006）
  constraint ends_after_starts check (ends_at is null or ends_at > starts_at)
);

create index sessions_crew_starts_idx on sessions (crew_id, starts_at desc);
-- 部分索引：只索引未來場次，讓「下一場」查詢極快且索引極小
create index sessions_upcoming_idx on sessions (starts_at) where starts_at > now();

create table crew_style_tags (
  crew_id  uuid not null references crews(id) on delete cascade,
  tag_code text not null references style_tags(code),
  primary key (crew_id, tag_code)
);

create table outbound_links (
  id       uuid primary key default gen_random_uuid(),
  crew_id  uuid not null references crews(id) on delete cascade,
  platform text not null check (platform in ('instagram','threads','strava','line')),
  url      text not null,
  unique (crew_id, platform)
);

-- 事件表：只增不改，不存 IP / 裝置 ID（隱私）
create table outbound_clicks (
  id           bigserial primary key,
  link_id      uuid not null references outbound_links(id) on delete cascade,
  clicked_at   timestamptz not null default now(),
  session_hash text
);

create table score_snapshots (
  crew_id    uuid not null references crews(id) on delete cascade,
  week_start date not null,
  score      int  not null,
  breakdown  jsonb not null,
  primary key (crew_id, week_start)
);

create table favorites (
  user_id    uuid not null references auth.users(id) on delete cascade,
  crew_id    uuid not null references crews(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, crew_id)
);

-- 複合主鍵 = 冪等性寫進 schema。連點五次「我要去」只會有一筆。
create table rsvps (
  user_id    uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references sessions(id) on delete cascade,
  state      text not null check (state in ('going','interested','cancelled')),
  updated_at timestamptz not null default now(),
  primary key (user_id, session_id)
);

-- 表單送出的冪等鍵：網路重試不產生兩筆
create table submissions (
  idempotency_key text primary key,
  crew_id         uuid references crews(id) on delete cascade,
  payload         jsonb not null,
  created_at      timestamptz not null default now()
);

create or replace function touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

create trigger crews_touch before update on crews
  for each row execute function touch_updated_at();
