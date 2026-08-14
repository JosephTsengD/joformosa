-- 每週一 12:00（台北）重算活躍度積分。
-- 權重放在 config 表而非硬編碼，方便日後 A/B 調整。
create table scoring_config (
  key   text primary key,
  value numeric not null
);
insert into scoring_config values
  ('w_sessions', 3), ('w_photos', 2), ('w_freshness', 5), ('w_clicks', 1);

create or replace function recompute_scores() returns void
language plpgsql security definer as $$
declare
  w_s numeric; w_p numeric; w_f numeric; w_c numeric;
  v_week date := date_trunc('week', now() at time zone 'Asia/Taipei')::date;
begin
  select value into w_s from scoring_config where key = 'w_sessions';
  select value into w_p from scoring_config where key = 'w_photos';
  select value into w_f from scoring_config where key = 'w_freshness';
  select value into w_c from scoring_config where key = 'w_clicks';

  with calc as (
    select c.id,
      -- 本月公告場次
      (select count(*) from sessions s
        where s.crew_id = c.id
          and s.starts_at >= date_trunc('month', now() at time zone 'Asia/Taipei'))
        * w_s as pts_sessions,
      (select count(*) from sessions s
        where s.crew_id = c.id and s.cover_url is not null) * w_p as pts_photos,
      -- 新鮮度：7 天內更新滿分，之後線性衰減到 0
      greatest(0, 1 - extract(epoch from now() - c.updated_at) / (7*86400)) * w_f
        as pts_fresh,
      -- 點擊熱度取 log 壓縮，避免刷量
      ln(1 + (select count(*) from outbound_clicks oc
              join outbound_links ol on ol.id = oc.link_id
              where ol.crew_id = c.id
                and oc.clicked_at > now() - interval '30 days')) * w_c
        as pts_clicks
    from crews c where c.status = 'published'
  )
  update crews c
  set activity_score = greatest(0, round(
        calc.pts_sessions + calc.pts_photos + calc.pts_fresh + calc.pts_clicks
      )::int + c.manual_score_adjustment)
  from calc where calc.id = c.id;

  -- 保留可稽核的歷史快照
  insert into score_snapshots (crew_id, week_start, score, breakdown)
  select c.id, v_week, c.activity_score,
         jsonb_build_object('manual', c.manual_score_adjustment)
  from crews c where c.status = 'published'
  on conflict (crew_id, week_start) do update set score = excluded.score;
end $$;

-- ⚠ 時區陷阱：cron 用 UTC。台北 UTC+8 且無日光節約，
--   所以 04:00 UTC = 12:00 台北恆成立。若套到有 DST 的地區會每年錯兩次。
-- select cron.schedule('weekly-score', '0 4 * * 1', $$ select recompute_scores() $$);
