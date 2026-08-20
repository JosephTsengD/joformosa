-- 時間區間篩選。
--
-- 注意參數是 timestamptz 而非 'weekend' 這種語意字串。
-- 「今天是誰的今天」「週末從週六還是週五算」這類判斷全部留在客戶端，
-- 資料庫只回答「有沒有場次落在這個區間」——
-- 語意散佈到兩個系統是時區 bug 的主要來源。

create or replace function crews_with_next_session(
  p_city        char(3)     default null,
  p_sport       sport_kind  default null,
  p_tags        text[]      default null,
  p_query       text        default null,
  p_from        timestamptz default null,
  p_to          timestamptz default null,
  p_limit       int         default 20,
  p_after_score int         default null,
  p_after_id    uuid        default null
)
returns table (
  id uuid, slug text, name text, handle text, sport sport_kind,
  city_code char(3), home_base text, regular_schedule text, intro text,
  activity_score int, owner_id uuid, created_at timestamptz,
  crew_style_tags jsonb, outbound_links jsonb, next_session jsonb
)
language sql stable security invoker as $$
  select
    c.id, c.slug, c.name, c.handle, c.sport, c.city_code, c.home_base,
    c.regular_schedule, c.intro, c.activity_score, c.owner_id, c.created_at,
    coalesce(
      (select jsonb_agg(jsonb_build_object('tag_code', t.tag_code))
       from crew_style_tags t where t.crew_id = c.id), '[]'::jsonb),
    coalesce(
      (select jsonb_agg(jsonb_build_object('platform', l.platform, 'url', l.url))
       from outbound_links l where l.crew_id = c.id), '[]'::jsonb),
    to_jsonb(s)
  from crews c
  left join lateral (
    select sx.id, sx.crew_id, sx.title, sx.kind, sx.starts_at, sx.ends_at,
           sx.location_name
    from sessions sx
    where sx.crew_id = c.id
      and sx.starts_at >= coalesce(p_from, now())
      and (p_to is null or sx.starts_at < p_to)
    order by sx.starts_at asc
    limit 1
  ) s on true
  where c.status = 'published'
    and (p_city  is null or c.city_code = p_city)
    and (p_sport is null or c.sport = p_sport)
    and (p_query is null or p_query = '' or
         c.name ilike '%' || p_query || '%' or
         c.home_base ilike '%' || p_query || '%' or
         coalesce(c.intro, '') ilike '%' || p_query || '%' or
         c.name % p_query)
    and (p_tags is null or not exists (
          select 1 from unnest(p_tags) tag
          where not exists (select 1 from crew_style_tags t
                            where t.crew_id = c.id and t.tag_code = tag)))
    -- 有指定區間時，必須真的有場次落在裡面才算符合
    and (p_from is null or exists (
          select 1 from sessions sx
          where sx.crew_id = c.id
            and sx.starts_at >= p_from
            and sx.starts_at < p_to))
    and (p_after_score is null or
         (c.activity_score, c.id) < (p_after_score, p_after_id))
  order by
    case when p_query is null or p_query = '' then 0
         when c.name ilike '%' || p_query || '%' then 0
         else 1 end,
    c.activity_score desc, c.id
  limit p_limit;
$$;
