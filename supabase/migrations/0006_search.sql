-- 中文搜尋。
--
-- Postgres 的內建 to_tsvector 不會斷中文詞——'simple' 設定把整串當一個 token，
-- 所以搜「夜跑」找不到「信義夜跑團」。這是 0001 留下的實際缺陷。
--
-- 解法：用 pg_trgm 的三元組相似度做模糊比對。它不需要斷詞，
-- 對中文與錯字都有效，而且能走 GIN 索引。

create extension if not exists pg_trgm;

-- 取代原本的 tsvector 索引
drop index if exists crews_search_idx;

create index crews_name_trgm_idx on crews using gin (name gin_trgm_ops);
create index crews_intro_trgm_idx on crews using gin (intro gin_trgm_ops);
create index crews_home_base_trgm_idx on crews using gin (home_base gin_trgm_ops);

-- 相似度門檻。0.3 是預設值，對中文太嚴格（三元組少），調到 0.1。
-- 太低會撈出無關結果，太高則短關鍵字完全搜不到。
set pg_trgm.similarity_threshold = 0.1;

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
    where sx.crew_id = c.id and sx.starts_at >= now()
    order by sx.starts_at asc
    limit 1
  ) s on true
  where c.status = 'published'
    and (p_city  is null or c.city_code = p_city)
    and (p_sport is null or c.sport = p_sport)
    -- 三段比對：完全包含（最可靠）→ 名稱模糊 → 介紹/地點模糊
    and (p_query is null or p_query = '' or
         c.name ilike '%' || p_query || '%' or
         c.home_base ilike '%' || p_query || '%' or
         coalesce(c.intro, '') ilike '%' || p_query || '%' or
         c.name % p_query)
    and (p_tags  is null or not exists (
          select 1 from unnest(p_tags) tag
          where not exists (select 1 from crew_style_tags t
                            where t.crew_id = c.id and t.tag_code = tag)))
    and (p_after_score is null or
         (c.activity_score, c.id) < (p_after_score, p_after_id))
  order by
    -- 有搜尋字時，名稱命中的排前面；否則維持積分排序
    case when p_query is null or p_query = '' then 0
         when c.name ilike '%' || p_query || '%' then 0
         else 1 end,
    c.activity_score desc, c.id
  limit p_limit;
$$;
