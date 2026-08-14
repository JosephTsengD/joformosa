-- 解決 N+1 的核心：LATERAL JOIN 一次撈出每團的「下一場」。
-- 千萬不要在 client 端迴圈查每個社團——20 張卡片就是 21 次往返。
create or replace function crews_with_next_session(
  p_city        char(3)    default null,
  p_sport       sport_kind default null,
  p_tags        text[]     default null,
  p_query       text       default null,
  p_limit       int        default 20,
  p_after_score int        default null,
  p_after_id    uuid       default null
)
returns table (
  id uuid, slug text, name text, handle text, sport sport_kind,
  city_code char(3), home_base text, regular_schedule text, intro text,
  activity_score int, created_at timestamptz,
  crew_style_tags jsonb, next_session jsonb
)
language sql stable security invoker as $$
  select
    c.id, c.slug, c.name, c.handle, c.sport, c.city_code, c.home_base,
    c.regular_schedule, c.intro, c.activity_score, c.created_at,
    coalesce(
      (select jsonb_agg(jsonb_build_object('tag_code', t.tag_code))
       from crew_style_tags t where t.crew_id = c.id), '[]'::jsonb),
    to_jsonb(s)
  from crews c
  left join lateral (
    select sx.id, sx.crew_id, sx.title, sx.kind, sx.starts_at, sx.ends_at,
           sx.location_name
    from sessions sx
    where sx.crew_id = c.id and sx.starts_at >= now()
    order by sx.starts_at asc
    limit 1
  ) s on true
  where c.status = 'published'
    and (p_city  is null or c.city_code = p_city)
    and (p_sport is null or c.sport = p_sport)
    and (p_query is null or
         to_tsvector('simple', c.name || ' ' || coalesce(c.intro,''))
           @@ plainto_tsquery('simple', p_query))
    and (p_tags  is null or not exists (
          select 1 from unnest(p_tags) tag
          where not exists (select 1 from crew_style_tags t
                            where t.crew_id = c.id and t.tag_code = tag)))
    -- keyset 分頁：(score, id) 複合游標，資料變動時不會漏也不會重
    and (p_after_score is null or
         (c.activity_score, c.id) < (p_after_score, p_after_id))
  order by c.activity_score desc, c.id
  limit p_limit;
$$;

-- 表單送出：冪等鍵由 client 在**進入表單時**產生，
-- 這樣同一次填寫的網路重試會用同一把鑰匙。
create or replace function submit_crew(p_payload jsonb, p_idempotency_key text)
returns crews language plpgsql security definer as $$
declare v_crew crews;
begin
  select c.* into v_crew from submissions s
    join crews c on c.id = s.crew_id
    where s.idempotency_key = p_idempotency_key;
  if found then return v_crew; end if;   -- 已處理過，直接回傳原結果

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
    'pending',              -- 一律進審核佇列，不直接發佈
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

-- 出站點擊追蹤：**追蹤失敗絕不可阻擋跳轉**，
-- 所以這裡即使 insert 出錯也回傳 url。
create or replace function track_outbound(p_link_id uuid, p_session_hash text)
returns text language plpgsql security definer as $$
declare v_url text;
begin
  select url into v_url from outbound_links where id = p_link_id;
  begin
    insert into outbound_clicks (link_id, session_hash)
    values (p_link_id, p_session_hash);
  exception when others then null;
  end;
  return v_url;
end $$;
