-- 審核後台。
--
-- 角色判定放在 auth.users.raw_app_meta_data，不是在 crews 表加欄位——
-- 角色屬於「使用者」，不屬於「資料」。放錯地方的後果是：
-- 每新增一種需要權限的資源，就要再加一個欄位。

create or replace function is_admin() returns boolean
language sql stable security definer as $$
  select coalesce(
    (select raw_app_meta_data->>'role' = 'admin'
     from auth.users where id = auth.uid()),
    false);
$$;

-- ⚠ 設定管理員（在 Supabase SQL Editor 執行，不要放進 App）：
--   update auth.users
--   set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb
--   where email = 'you@example.com';
--
-- 用 raw_app_meta_data 而非 raw_user_meta_data：
-- **後者可以被使用者自己透過 updateUser() 修改**。
-- 把角色放在 user_metadata 等於讓任何人自封管理員，這是很常見的漏洞。

create table moderation_log (
  id         uuid primary key default gen_random_uuid(),
  crew_id    uuid not null references crews(id) on delete cascade,
  crew_name  text not null,          -- 快照：社團被刪除後紀錄仍可讀
  action     text not null check (action in ('approve', 'reject')),
  reason     text,
  actor_id   uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  -- 拒絕必須有理由。寫成 constraint 而非應用層檢查，
  -- 因為稽核紀錄的完整性不該依賴呼叫端的自律。
  constraint reject_needs_reason
    check (action <> 'reject' or (reason is not null and length(trim(reason)) > 0))
);

create index moderation_log_crew_idx on moderation_log (crew_id, created_at desc);

alter table moderation_log enable row level security;

create policy moderation_log_admin_read on moderation_log for select
  using (is_admin());

-- 沒有 insert / update / delete 政策：
-- 只能透過下面的 security definer 函式寫入，應用層無法直接改動。
-- 這就是「只增不改」的實作方式——不是靠約定，是靠沒有那個入口。

create policy crews_admin_read on crews for select using (is_admin());
create policy crews_admin_update on crews for update
  using (is_admin()) with check (is_admin());

create or replace function moderate_crew(
  p_crew_id uuid,
  p_action  text,
  p_reason  text default null
) returns moderation_log
language plpgsql security definer as $$
declare
  v_crew  crews;
  v_entry moderation_log;
begin
  if not is_admin() then
    raise exception 'admin_required';
  end if;

  select * into v_crew from crews where id = p_crew_id;
  if not found then
    raise exception 'crew_not_found';
  end if;

  if p_action = 'approve' then
    update crews set status = 'published' where id = p_crew_id;
  elsif p_action = 'reject' then
    if p_reason is null or length(trim(p_reason)) = 0 then
      raise exception 'reason_required';
    end if;
    update crews set status = 'archived' where id = p_crew_id;
  else
    raise exception 'invalid_action';
  end if;

  insert into moderation_log (crew_id, crew_name, action, reason, actor_id)
  values (p_crew_id, v_crew.name, p_action, nullif(trim(coalesce(p_reason,'')), ''), auth.uid())
  returning * into v_entry;

  return v_entry;
end $$;

create or replace function pending_crews()
returns setof crews language sql stable security invoker as $$
  select * from crews
  where status = 'pending' and is_admin()
  order by created_at asc;   -- 先送先審
$$;
