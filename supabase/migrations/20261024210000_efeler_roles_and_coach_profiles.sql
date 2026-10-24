-- Coach profiles, member promotion and coach details on planned runs.
alter table public.efeler_profiles
  add column if not exists bio text not null default '';

create or replace function public.efeler_update_profile(
  p_full_name text,
  p_bio text default ''
)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if nullif(trim(p_full_name), '') is null then raise exception 'invalid_name'; end if;
  update public.efeler_profiles
  set full_name=left(trim(p_full_name), 100), bio=left(trim(coalesce(p_bio, '')), 280)
  where id=auth.uid() and app_id='efeler';
  if not found then raise exception 'profile_not_found'; end if;
end $$;

create or replace function public.efeler_list_members()
returns table(id uuid, full_name text, role text, bio text)
language sql stable security definer set search_path = public
as $$
  select p.id, p.full_name, p.role, p.bio
  from public.efeler_profiles p
  where p.app_id='efeler'
    and public.efeler_role() in ('coach','admin')
  order by case p.role when 'admin' then 0 when 'coach' then 1 else 2 end, p.full_name;
$$;

create or replace function public.efeler_promote_to_coach(p_member_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  update public.efeler_profiles
  set role='coach'
  where id=p_member_id and app_id='efeler' and role='member';
  if not found then raise exception 'member_not_found'; end if;
end $$;

drop function if exists public.efeler_list_runs();
create function public.efeler_list_runs()
returns table(
  id uuid, title text, starts_at timestamptz, location text, status text,
  points integer, capacity integer, reserved_count bigint,
  is_reserved boolean, created_by uuid, coach_name text, coach_bio text
)
language sql stable security definer set search_path = public
as $$
  select
    r.id, r.title, r.starts_at, r.location, r.status, r.points, r.capacity,
    count(rv.id) filter (where rv.status in ('booked','attended')) as reserved_count,
    coalesce(bool_or(rv.member_id=auth.uid() and rv.status in ('booked','attended')), false) as is_reserved,
    r.created_by, coach.full_name, coach.bio
  from public.efeler_runs r
  join public.efeler_profiles coach
    on coach.id=r.created_by and coach.app_id='efeler'
  left join public.efeler_reservations rv
    on rv.run_id=r.id and rv.app_id='efeler'
  where r.app_id='efeler'
    and exists (select 1 from public.efeler_profiles p where p.id=auth.uid() and p.app_id='efeler')
  group by r.id, coach.full_name, coach.bio
  order by r.starts_at;
$$;

revoke all on function public.efeler_update_profile(text,text) from public;
revoke all on function public.efeler_list_members() from public;
revoke all on function public.efeler_promote_to_coach(uuid) from public;
revoke all on function public.efeler_list_runs() from public;
grant execute on function public.efeler_update_profile(text,text),
  public.efeler_list_members(), public.efeler_promote_to_coach(uuid),
  public.efeler_list_runs() to authenticated;
