-- 補上一個 0002 漏掉的 RLS 缺口。
--
-- 問題：crews_public_read 只允許讀 status='published'，
-- 所以團長送出社團後，自己的「團長後台」什麼都看不到——
-- 使用者的體感是「我的資料不見了」。
--
-- 這類缺口只有在把讀寫都跑過一遍才會浮現，光看 policy 是看不出來的。

create policy crews_owner_read on crews for select
  using (auth.uid() is not null and auth.uid() = owner_id);

create policy sessions_owner_read on sessions for select
  using (exists (select 1 from crews c
                 where c.id = sessions.crew_id and c.owner_id = auth.uid()));

create policy tags_owner_read on crew_style_tags for select
  using (exists (select 1 from crews c
                 where c.id = crew_style_tags.crew_id and c.owner_id = auth.uid()));

create policy links_owner_read on outbound_links for select
  using (exists (select 1 from crews c
                 where c.id = outbound_links.crew_id and c.owner_id = auth.uid()));

-- 團長可以自行新增社團的連結（登錄後補上 IG）
create policy links_owner_write on outbound_links for all
  using (exists (select 1 from crews c
                 where c.id = outbound_links.crew_id and c.owner_id = auth.uid()))
  with check (exists (select 1 from crews c
                      where c.id = outbound_links.crew_id and c.owner_id = auth.uid()));

-- ── 速率限制 ────────────────────────────────────────────
-- 沒有這個，一個腳本可以在一分鐘內灌爆審核佇列。
-- 放在 RPC 內而非前端：前端的限制只是禮貌，不是防線。
create or replace function submit_crew(p_payload jsonb, p_idempotency_key text)
returns crews language plpgsql security definer as $$
declare
  v_crew crews;
  v_recent int;
begin
  select c.* into v_crew from submissions s
    join crews c on c.id = s.crew_id
    where s.idempotency_key = p_idempotency_key;
  if found then return v_crew; end if;   -- 已處理過，回傳原結果

  if auth.uid() is null then
    raise exception 'auth_required';
  end if;

  select count(*) into v_recent from crews c
    where c.owner_id = auth.uid()
      and c.created_at > now() - interval '1 hour';
  if v_recent >= 3 then
    raise exception 'rate_limited: 每小時最多送出 3 個社團';
  end if;

  insert into crews (slug, name, sport, city_code, home_base, intro,
                     regular_schedule, status, owner_id)
  values (
    lower(regexp_replace(p_payload->>'name', '[^a-zA-Z0-9]+', '-', 'g'))
      || '-' || substr(gen_random_uuid()::text, 1, 5),
    p_payload->>'name',
    (p_payload->>'sport')::sport_kind,
    p_payload->>'city_code',
    p_payload->>'home_base',
    p_payload->>'intro',
    p_payload->>'regular_schedule',
    'pending',              -- 一律進審核佇列，送出不等於發布
    auth.uid()
  ) returning * into v_crew;

  insert into crew_style_tags (crew_id, tag_code)
  select v_crew.id, tag from jsonb_array_elements_text(p_payload->'styles') tag
  on conflict do nothing;

  insert into outbound_links (crew_id, platform, url)
  values (v_crew.id, 'instagram',
          'https://www.instagram.com/' || replace(p_payload->>'instagram','@','') || '/');

  insert into submissions (idempotency_key, crew_id, payload)
  values (p_idempotency_key, v_crew.id, p_payload);

  return v_crew;
end $$;

-- 每個社團的活動數量上限，同樣防灌爆
create or replace function check_session_quota() returns trigger
language plpgsql as $$
begin
  if (select count(*) from sessions where crew_id = new.crew_id) >= 60 then
    raise exception 'quota_exceeded: 單一社團最多 60 場活動';
  end if;
  return new;
end $$;

create trigger sessions_quota before insert on sessions
  for each row execute function check_session_quota();
