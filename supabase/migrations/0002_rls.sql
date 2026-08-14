-- Row Level Security：授權邏輯下沉到資料層。
-- 即使前端被完全繞過，攻擊者拿 anon key 直連 PostgREST 也拿不到東西。
-- 對應的滲透測試在 test/security/（每一條都必須被拒絕）。

alter table crews           enable row level security;
alter table sessions        enable row level security;
alter table crew_style_tags enable row level security;
alter table outbound_links  enable row level security;
alter table favorites       enable row level security;
alter table rsvps           enable row level security;
alter table score_snapshots enable row level security;

-- ── 公開讀 ────────────────────────────────────────────────
create policy crews_public_read on crews for select
  using (status = 'published');

create policy sessions_public_read on sessions for select
  using (exists (select 1 from crews c
                 where c.id = sessions.crew_id and c.status = 'published'));

create policy tags_public_read on crew_style_tags for select
  using (exists (select 1 from crews c
                 where c.id = crew_style_tags.crew_id and c.status = 'published'));

create policy links_public_read on outbound_links for select
  using (exists (select 1 from crews c
                 where c.id = outbound_links.crew_id and c.status = 'published'));

create policy snapshots_public_read on score_snapshots for select using (true);

-- ── 團長寫入 ──────────────────────────────────────────────
-- 關鍵：with check 阻止團長自己改積分。
-- 光有 using 是不夠的——using 決定「能改哪些列」，
-- with check 決定「改成什麼樣子可以被接受」。這是最常見的 RLS 漏洞。
create policy crews_owner_update on crews for update
  using (auth.uid() = owner_id)
  with check (
    auth.uid() = owner_id
    and activity_score = (select c.activity_score from crews c where c.id = crews.id)
    and manual_score_adjustment = (select c.manual_score_adjustment from crews c where c.id = crews.id)
    and status = (select c.status from crews c where c.id = crews.id)
  );

create policy sessions_owner_all on sessions for all
  using (exists (select 1 from crews c
                 where c.id = sessions.crew_id and c.owner_id = auth.uid()))
  with check (exists (select 1 from crews c
                      where c.id = sessions.crew_id and c.owner_id = auth.uid()));

-- ── 個人資料 ──────────────────────────────────────────────
create policy favorites_own on favorites for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy rsvps_own on rsvps for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
