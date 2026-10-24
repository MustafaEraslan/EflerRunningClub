-- Coach and runner progression levels with head-coach-only coach management.
alter table public.efeler_profiles
  add column if not exists coach_level integer not null default 0,
  add column if not exists runner_level integer not null default 1;

update public.efeler_profiles
set coach_level = case
  when role in ('coach', 'admin') then 3
  else 0
end
where app_id = 'efeler';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'efeler_profiles_coach_level_check'
  ) then
    alter table public.efeler_profiles
      add constraint efeler_profiles_coach_level_check
      check (coach_level between 0 and 3);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'efeler_profiles_runner_level_check'
  ) then
    alter table public.efeler_profiles
      add constraint efeler_profiles_runner_level_check
      check (runner_level between 1 and 4);
  end if;
end $$;

drop function if exists public.efeler_list_members();
create function public.efeler_list_members()
returns table(
  id uuid,
  full_name text,
  role text,
  bio text,
  avatar_path text,
  coach_level integer,
  runner_level integer
)
language sql stable security definer set search_path = public
as $$
  select
    p.id, p.full_name, p.role, p.bio, p.avatar_path,
    p.coach_level, p.runner_level
  from public.efeler_profiles p
  where p.app_id = 'efeler'
    and exists (
      select 1
      from public.efeler_profiles caller
      where caller.id = auth.uid()
        and caller.app_id = 'efeler'
        and caller.role in ('coach', 'admin')
    )
  order by
    case p.role when 'admin' then 0 when 'coach' then 1 else 2 end,
    p.coach_level desc,
    p.runner_level desc,
    p.full_name;
$$;

create or replace function public.efeler_promote_to_coach(p_member_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare
  caller_role text;
  caller_level integer;
begin
  select role, coach_level into caller_role, caller_level
  from public.efeler_profiles
  where id = auth.uid() and app_id = 'efeler';

  if caller_role <> 'admin' and not (caller_role = 'coach' and caller_level = 3) then
    raise exception 'not_allowed';
  end if;

  update public.efeler_profiles
  set role = 'coach', coach_level = 1
  where id = p_member_id and app_id = 'efeler' and role = 'member';
  if not found then raise exception 'member_not_found'; end if;
end $$;

create or replace function public.efeler_set_coach_level(
  p_coach_id uuid,
  p_level integer
)
returns void language plpgsql security definer set search_path = public
as $$
declare
  caller_role text;
  caller_level integer;
begin
  if p_level not between 1 and 3 then raise exception 'invalid_level'; end if;

  select role, coach_level into caller_role, caller_level
  from public.efeler_profiles
  where id = auth.uid() and app_id = 'efeler';

  if caller_role <> 'admin' and not (caller_role = 'coach' and caller_level = 3) then
    raise exception 'not_allowed';
  end if;
  if caller_role <> 'admin' and p_coach_id = auth.uid() then
    raise exception 'cannot_change_own_level';
  end if;

  update public.efeler_profiles
  set coach_level = p_level
  where id = p_coach_id and app_id = 'efeler' and role = 'coach';
  if not found then raise exception 'coach_not_found'; end if;
end $$;

create or replace function public.efeler_change_runner_level(
  p_member_id uuid,
  p_direction integer
)
returns integer language plpgsql security definer set search_path = public
as $$
declare
  next_level integer;
begin
  if p_direction not in (-1, 1) then raise exception 'invalid_direction'; end if;
  if not exists (
    select 1 from public.efeler_profiles
    where id = auth.uid() and app_id = 'efeler' and role in ('coach', 'admin')
  ) then
    raise exception 'not_allowed';
  end if;

  update public.efeler_profiles
  set runner_level = greatest(1, least(4, runner_level + p_direction))
  where id = p_member_id and app_id = 'efeler' and role = 'member'
  returning runner_level into next_level;
  if not found then raise exception 'member_not_found'; end if;
  return next_level;
end $$;

revoke all on function public.efeler_list_members() from public;
revoke all on function public.efeler_promote_to_coach(uuid) from public;
revoke all on function public.efeler_set_coach_level(uuid, integer) from public;
revoke all on function public.efeler_change_runner_level(uuid, integer) from public;
grant execute on function public.efeler_list_members(),
  public.efeler_promote_to_coach(uuid),
  public.efeler_set_coach_level(uuid, integer),
  public.efeler_change_runner_level(uuid, integer) to authenticated;
