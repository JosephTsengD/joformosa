-- 示範用種子資料（全部為虛構內容，非任何真實社團）
--
-- 活動時間刻意使用相對於 now() 的區間而非固定日期：
-- 這樣不論何時重新載入，首頁都有「今天／本週」的場次，
-- 不會因為時間經過而變成一片「已結束」。
--
--   supabase db reset          # 套用 migrations 後自動執行本檔
--   psql "$DB_URL" -f supabase/seed.sql
begin;

-- 只清除種子資料（seed- 開頭的 slug），使用者送出的內容不受影響
delete from sessions where crew_id in (select id from crews where slug like 'seed-%');
delete from crew_style_tags where crew_id in (select id from crews where slug like 'seed-%');
delete from outbound_links where crew_id in (select id from crews where slug like 'seed-%');
delete from crews where slug like 'seed-%';


insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-dawn-0', '晨光跑者 Dawn Runners', 'DAWN', 'run', 'TPE',
        '大安森林公園南側門', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        24, 'published', now() - interval '5 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-dawn-0';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/dawn/' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'special',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '市民廣場' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '15 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '15 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '18 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '18 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '運動中心大廳' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '14 days' + interval '19 hours',
       date_trunc('day', now()) - interval '14 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-dawn-0';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '午夜長征 Midnight Ultra', 'special',
       date_trunc('day', now()) + interval '2 days' + interval '22 hours',
       date_trunc('day', now()) + interval '3 days' + interval '1 hour',
       '河濱公園自行車道起點' from crews where slug = 'seed-dawn-0';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-xinyi-night-1', '信義夜跑團', 'XINYI NIGHT', 'run', 'TPE',
        '河濱公園自行車道起點', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        27, 'published', now() - interval '8 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-xinyi-night-1';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/xinyinight/' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '0 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '0 minutes' + interval '120 minutes',
       '市民廣場' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '運動中心大廳' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-xinyi-night-1';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-xinyi-night-1';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-slowly-2', '河濱慢慢跑', 'SLOWLY', 'run', 'TPE',
        '市民廣場', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        25, 'published', now() - interval '11 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-slowly-2';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/slowly/' from crews where slug = 'seed-slowly-2';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'special',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '市民廣場' from crews where slug = 'seed-slowly-2';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '田徑場暖身區' from crews where slug = 'seed-slowly-2';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-slowly-2';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-slowly-2';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-slowly-2';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-slowly-2';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-ttec-3', '台北山徑越野俱樂部 Taipei Trail Explorers Club', 'TTEC', 'run', 'TPE',
        '田徑場暖身區', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        24, 'published', now() - interval '14 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'office' from crews where slug = 'seed-ttec-3';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/ttec/' from crews where slug = 'seed-ttec-3';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-ttec-3';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-ttec-3';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '運動中心大廳' from crews where slug = 'seed-ttec-3';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-pacelab-4', 'Pace Lab 配速實驗室', 'PACELAB', 'run', 'TPE',
        '捷運站 2 號出口', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        21, 'published', now() - interval '17 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-pacelab-4';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/pacelab/' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'special',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '運動中心大廳' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '河堤入口' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '車站前廣場' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '運動中心大廳' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-pacelab-4';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '14 days' + interval '19 hours',
       date_trunc('day', now()) - interval '14 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-pacelab-4';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-ddc-cycling-5', '大稻埕自行車隊', 'DDC CYCLING', 'ride', 'TPE',
        '運動中心大廳', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        22, 'published', now() - interval '20 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'social' from crews where slug = 'seed-ddc-cycling-5';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/ddccycling/' from crews where slug = 'seed-ddc-cycling-5';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '3 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '3 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '運動中心大廳' from crews where slug = 'seed-ddc-cycling-5';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '河堤入口' from crews where slug = 'seed-ddc-cycling-5';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '車站前廣場' from crews where slug = 'seed-ddc-cycling-5';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-ddc-cycling-5';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '運動中心大廳' from crews where slug = 'seed-ddc-cycling-5';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-ddc-cycling-5';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-hrx-tpe-6', 'HYROX Taipei Box', 'HRX TPE', 'hyrox', 'TPE',
        '河堤入口', 'TPE的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        19, 'published', now() - interval '126 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-hrx-tpe-6';
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-hrx-tpe-6';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/hrxtpe/' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'special',
       date_trunc('day', now()) + interval '1 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '河堤入口' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '車站前廣場' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '10 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '10 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '市民廣場' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '17 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '17 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '田徑場暖身區' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-hrx-tpe-6';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-hrx-tpe-6';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-bq-run-7', '板橋跑步俱樂部', 'BQ RUN', 'run', 'TPH',
        '車站前廣場', 'TPH的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        17, 'published', now() - interval '137 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '車站前廣場' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '市民廣場' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-bq-run-7';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-bq-run-7';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-easy-ntp-8', '新北輕鬆跑', 'EASY NTP', 'run', 'TPH',
        '大安森林公園南側門', 'TPH的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        17, 'published', now() - interval '148 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'social' from crews where slug = 'seed-easy-ntp-8';
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-easy-ntp-8';
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-easy-ntp-8';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/easyntp/' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'special',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '市民廣場' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-easy-ntp-8';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '14 days' + interval '19 hours',
       date_trunc('day', now()) - interval '14 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-easy-ntp-8';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-tamsui-ride-9', '淡水海線車隊', 'TAMSUI RIDE', 'ride', 'TPH',
        '河濱公園自行車道起點', 'TPH的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        20, 'published', now() - interval '159 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-tamsui-ride-9';
insert into crew_style_tags (crew_id, tag_code) select id, 'night' from crews where slug = 'seed-tamsui-ride-9';
insert into crew_style_tags (crew_id, tag_code) select id, 'beginner' from crews where slug = 'seed-tamsui-ride-9';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/tamsuiride/' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '1 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '市民廣場' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '15 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '15 days' + interval '7 hours' + interval '0 minutes' + interval '120 minutes',
       '運動中心大廳' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-tamsui-ride-9';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-tamsui-ride-9';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-tyn-runners-10', '桃園機捷跑團', 'TYN RUNNERS', 'run', 'TYN',
        '市民廣場', 'TYN的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        14, 'published', now() - interval '170 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'social' from crews where slug = 'seed-tyn-runners-10';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/tynrunners/' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'special',
       date_trunc('day', now()) + interval '3 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '3 days' + interval '7 hours' + interval '0 minutes' + interval '120 minutes',
       '市民廣場' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '運動中心大廳' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '15 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '15 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '河堤入口' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-tyn-runners-10';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-tyn-runners-10';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-qingpu-am-11', '青埔晨練社', 'QINGPU AM', 'run', 'TYN',
        '田徑場暖身區', 'TYN的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        18, 'published', now() - interval '181 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-qingpu-am-11';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/qingpuam/' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '運動中心大廳' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '河堤入口' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '14 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '14 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '車站前廣場' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-qingpu-am-11';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-qingpu-am-11';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-hsp-runners-12', '新竹科園跑者', 'HSP RUNNERS', 'run', 'HSZ',
        '捷運站 2 號出口', NULL, '每週三 19:30、每週六 07:00',
        12, 'published', now() - interval '192 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-hsp-runners-12';
insert into crew_style_tags (crew_id, tag_code) select id, 'trail' from crews where slug = 'seed-hsp-runners-12';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/hsprunners/' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'special',
       date_trunc('day', now()) + interval '3 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '3 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '運動中心大廳' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '河堤入口' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '車站前廣場' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '運動中心大廳' from crews where slug = 'seed-hsp-runners-12';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-hsp-runners-12';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-windcity-13', '風城自行車', 'WINDCITY', 'ride', 'HSZ',
        '運動中心大廳', 'HSZ的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        14, 'published', now() - interval '203 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-windcity-13';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/windcity/' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '運動中心大廳' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '河堤入口' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes' + interval '90 minutes',
       '車站前廣場' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '17 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '17 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '市民廣場' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '運動中心大廳' from crews where slug = 'seed-windcity-13';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-windcity-13';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-txg-greenway-14', '台中綠園道跑團', 'TXG GREENWAY', 'run', 'TXG',
        '河堤入口', 'TXG的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        14, 'published', now() - interval '214 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-txg-greenway-14';
insert into crew_style_tags (crew_id, tag_code) select id, 'office' from crews where slug = 'seed-txg-greenway-14';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/txggreenway/' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'special',
       date_trunc('day', now()) + interval '1 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '河堤入口' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '車站前廣場' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-txg-greenway-14';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '14 days' + interval '19 hours',
       date_trunc('day', now()) - interval '14 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-txg-greenway-14';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-fcu-night-15', '逢甲夜跑', 'FCU NIGHT', 'run', 'TXG',
        '車站前廣場', 'TXG的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        9, 'published', now() - interval '225 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-fcu-night-15';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/fcunight/' from crews where slug = 'seed-fcu-night-15';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '車站前廣場' from crews where slug = 'seed-fcu-night-15';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '5 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-fcu-night-15';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-fcu-night-15';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-fcu-night-15';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-fcu-night-15';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-fcu-night-15';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-ctw-trail-16', '中台灣越野社', 'CTW TRAIL', 'run', 'TXG',
        '大安森林公園南側門', 'TXG的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        9, 'published', now() - interval '236 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'morning' from crews where slug = 'seed-ctw-trail-16';
insert into crew_style_tags (crew_id, tag_code) select id, 'beginner' from crews where slug = 'seed-ctw-trail-16';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/ctwtrail/' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'special',
       date_trunc('day', now()) + interval '3 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '3 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '市民廣場' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-ctw-trail-16';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-ctw-trail-16';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-hrx-txg-17', 'HYROX Taichung', 'HRX TXG', 'hyrox', 'TXG',
        '河濱公園自行車道起點', 'TXG的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        10, 'published', now() - interval '247 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-hrx-txg-17';
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-hrx-txg-17';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/hrxtxg/' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '市民廣場' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '田徑場暖身區' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '15 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '15 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '運動中心大廳' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-hrx-txg-17';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-hrx-txg-17';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-tainan-old-18', '台南古都跑者', 'TAINAN OLD', 'run', 'TNN',
        '市民廣場', 'TNN的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        9, 'published', now() - interval '258 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-tainan-old-18';
insert into crew_style_tags (crew_id, tag_code) select id, 'social' from crews where slug = 'seed-tainan-old-18';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/tainanold/' from crews where slug = 'seed-tainan-old-18';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'special',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '1 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '市民廣場' from crews where slug = 'seed-tainan-old-18';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '田徑場暖身區' from crews where slug = 'seed-tainan-old-18';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '8 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-tainan-old-18';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-tainan-old-18';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-tainan-old-18';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-tainan-old-18';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-anping-19', '安平海風跑團', 'ANPING', 'run', 'TNN',
        '田徑場暖身區', 'TNN的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        10, 'published', now() - interval '269 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-anping-19';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/anping/' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '3 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '3 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '田徑場暖身區' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '運動中心大廳' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '河堤入口' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '車站前廣場' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-anping-19';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-anping-19';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-love-river-20', '高雄愛河跑團', 'LOVE RIVER', 'run', 'KHH',
        '捷運站 2 號出口', 'KHH的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        5, 'published', now() - interval '280 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'social' from crews where slug = 'seed-love-river-20';
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-love-river-20';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/loveriver/' from crews where slug = 'seed-love-river-20';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-harbor-ride-21', '港都自行車隊', 'HARBOR RIDE', 'ride', 'KHH',
        '運動中心大廳', 'KHH的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        8, 'published', now() - interval '291 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'race_prep' from crews where slug = 'seed-harbor-ride-21';
insert into crew_style_tags (crew_id, tag_code) select id, 'morning' from crews where slug = 'seed-harbor-ride-21';
insert into crew_style_tags (crew_id, tag_code) select id, 'trail' from crews where slug = 'seed-harbor-ride-21';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/harborride/' from crews where slug = 'seed-harbor-ride-21';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '19 hours' + interval '30 minutes' + interval '90 minutes',
       '運動中心大廳' from crews where slug = 'seed-harbor-ride-21';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '河堤入口' from crews where slug = 'seed-harbor-ride-21';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '車站前廣場' from crews where slug = 'seed-harbor-ride-21';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '運動中心大廳' from crews where slug = 'seed-harbor-ride-21';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-harbor-ride-21';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-siziwan-am-22', '西子灣晨跑會', 'SIZIWAN AM', 'run', 'KHH',
        '河堤入口', 'KHH的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        2, 'published', now() - interval '302 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'long' from crews where slug = 'seed-siziwan-am-22';
insert into crew_style_tags (crew_id, tag_code) select id, 'beginner' from crews where slug = 'seed-siziwan-am-22';
insert into crew_style_tags (crew_id, tag_code) select id, 'riverside' from crews where slug = 'seed-siziwan-am-22';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/siziwanam/' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'special',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '30 minutes' + interval '120 minutes',
       '河堤入口' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '車站前廣場' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '19 hours' + interval '30 minutes' + interval '120 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '11 days' + interval '7 hours' + interval '0 minutes' + interval '120 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '14 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '14 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '市民廣場' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '田徑場暖身區' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '河堤入口' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-siziwan-am-22';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '14 days' + interval '19 hours',
       date_trunc('day', now()) - interval '14 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-siziwan-am-22';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-yilan-field-23', '宜蘭田野跑團', 'YILAN FIELD', 'run', 'ILA',
        '車站前廣場', 'ILA的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', NULL,
        6, 'published', now() - interval '313 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'trail' from crews where slug = 'seed-yilan-field-23';
insert into crew_style_tags (crew_id, tag_code) select id, 'social' from crews where slug = 'seed-yilan-field-23';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/yilanfield/' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Hill Repeats', 'regular',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '2 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '車站前廣場' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'regular',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '4 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '7 days' + interval '7 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '7 days' + interval '7 hours' + interval '30 minutes' + interval '60 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '12 days' + interval '7 hours' + interval '0 minutes' + interval '60 minutes',
       '市民廣場' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes',
       date_trunc('day', now()) + interval '13 days' + interval '19 hours' + interval '30 minutes' + interval '60 minutes',
       '田徑場暖身區' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '16 days' + interval '19 hours' + interval '0 minutes' + interval '120 minutes',
       '捷運站 2 號出口' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '車站前廣場' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-yilan-field-23';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-yilan-field-23';

insert into crews (slug, name, handle, sport, city_code, home_base, intro,
                   regular_schedule, activity_score, status, created_at)
values ('seed-luodong-tri-24', '羅東鐵人訓練', 'LUODONG TRI', 'other', 'ILA',
        '大安森林公園南側門', 'ILA的運動社團，歡迎各種程度的夥伴一起參加。我們每週固定團練，重視安全與陪伴，不留任何人在後面。', '每週三 19:30、每週六 07:00',
        0, 'published', now() - interval '324 days');
insert into crew_style_tags (crew_id, tag_code) select id, 'interval' from crews where slug = 'seed-luodong-tri-24';
insert into crew_style_tags (crew_id, tag_code) select id, 'night' from crews where slug = 'seed-luodong-tri-24';
insert into outbound_links (crew_id, platform, url) select id, 'instagram', 'https://www.instagram.com/luodongtri/' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Social Run', 'special',
       date_trunc('day', now()) + interval '3 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '3 days' + interval '19 hours' + interval '0 minutes' + interval '60 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Dash & Run', 'regular',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '6 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'LSD 長距離', 'regular',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '9 days' + interval '7 hours' + interval '0 minutes' + interval '90 minutes',
       '市民廣場' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '0 minutes',
       date_trunc('day', now()) + interval '10 days' + interval '19 hours' + interval '0 minutes' + interval '90 minutes',
       '田徑場暖身區' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Track Night', 'regular',
       date_trunc('day', now()) - interval '2 days' + interval '19 hours',
       date_trunc('day', now()) - interval '2 days' + interval '20 hours 30 minutes',
       '大安森林公園南側門' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '間歇課表', 'regular',
       date_trunc('day', now()) - interval '6 days' + interval '19 hours',
       date_trunc('day', now()) - interval '6 days' + interval '20 hours 30 minutes',
       '河濱公園自行車道起點' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, 'Coffee Run', 'regular',
       date_trunc('day', now()) - interval '10 days' + interval '19 hours',
       date_trunc('day', now()) - interval '10 days' + interval '20 hours 30 minutes',
       '市民廣場' from crews where slug = 'seed-luodong-tri-24';
insert into sessions (crew_id, title, kind, starts_at, ends_at, location_name)
select id, '河濱輕鬆跑', 'regular',
       date_trunc('day', now()) - interval '14 days' + interval '19 hours',
       date_trunc('day', now()) - interval '14 days' + interval '20 hours 30 minutes',
       '田徑場暖身區' from crews where slug = 'seed-luodong-tri-24';

commit;
