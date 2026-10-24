-- Run editing (owner or admin) and reward editing/deletion (coach or admin).

-- ─── UPDATE RUN ─────────────────────────────────────────────────────────────
-- The creator (coach) can update their own scheduled/open runs.
-- Admins can update any run.
create or replace function public.efeler_update_run(
  p_run_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_location text,
  p_points integer default 10,
  p_capacity integer default 30
)
returns void language plpgsql security definer set search_path = public
as $$
declare
  v_role text := public.efeler_role();
  v_run public.efeler_runs%rowtype;
begin
  if v_role not in ('coach', 'admin') then raise exception 'not_allowed'; end if;
  select * into v_run from public.efeler_runs
    where id = p_run_id and app_id = 'efeler' for update;
  if not found then raise exception 'run_not_found'; end if;
  -- Only the creator or an admin can edit.
  if v_role <> 'admin' and v_run.created_by <> auth.uid() then
    raise exception 'not_allowed';
  end if;
  -- Validate inputs.
  if nullif(trim(p_title), '') is null or nullif(trim(p_location), '') is null then
    raise exception 'invalid_run';
  end if;
  if p_starts_at <= now() or p_points < 1 or p_points > 10000
     or p_capacity < 1 or p_capacity > 10000 then
    raise exception 'invalid_run';
  end if;
  update public.efeler_runs
  set title    = trim(p_title),
      starts_at = p_starts_at,
      location  = trim(p_location),
      points    = p_points,
      capacity  = p_capacity
  where id = p_run_id and app_id = 'efeler';
end $$;

revoke all on function public.efeler_update_run(uuid, text, timestamptz, text, integer, integer) from public;
grant execute on function public.efeler_update_run(uuid, text, timestamptz, text, integer, integer) to authenticated;

-- ─── UPDATE REWARD ──────────────────────────────────────────────────────────
create or replace function public.efeler_update_reward(
  p_reward_id uuid,
  p_name text,
  p_description text,
  p_points_cost integer,
  p_stock integer
)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if public.efeler_role() not in ('coach', 'admin') then raise exception 'not_allowed'; end if;
  if nullif(trim(p_name), '') is null or p_points_cost < 1 or p_stock < 0 then
    raise exception 'invalid_reward';
  end if;
  update public.efeler_rewards
  set name        = left(trim(p_name), 120),
      description = left(trim(coalesce(p_description, '')), 500),
      points_cost = p_points_cost,
      stock       = p_stock
  where id = p_reward_id and app_id = 'efeler' and active;
  if not found then raise exception 'reward_not_found'; end if;
end $$;

revoke all on function public.efeler_update_reward(uuid, text, text, integer, integer) from public;
grant execute on function public.efeler_update_reward(uuid, text, text, integer, integer) to authenticated;

-- ─── DELETE (DEACTIVATE) REWARD ─────────────────────────────────────────────
create or replace function public.efeler_delete_reward(p_reward_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if public.efeler_role() not in ('coach', 'admin') then raise exception 'not_allowed'; end if;
  update public.efeler_rewards set active = false
  where id = p_reward_id and app_id = 'efeler' and active;
  if not found then raise exception 'reward_not_found'; end if;
end $$;

revoke all on function public.efeler_delete_reward(uuid) from public;
grant execute on function public.efeler_delete_reward(uuid) to authenticated;
