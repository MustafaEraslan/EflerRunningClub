-- Capacity-limited run reservations and reservation-aware check-in.
alter table public.efeler_runs
  add column if not exists capacity integer not null default 50;

do $$ begin
  if not exists (
    select 1 from pg_constraint where conname = 'efeler_runs_capacity_check'
  ) then
    alter table public.efeler_runs
      add constraint efeler_runs_capacity_check check (capacity > 0 and capacity <= 10000);
  end if;
end $$;

create table if not exists public.efeler_reservations (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  run_id uuid not null references public.efeler_runs(id) on delete cascade,
  member_id uuid not null references public.efeler_profiles(id) on delete cascade,
  status text not null default 'booked' check (status in ('booked','cancelled','attended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (run_id, member_id)
);
create index if not exists efeler_reservations_run_idx
  on public.efeler_reservations(run_id, status);

alter table public.efeler_reservations enable row level security;
drop policy if exists efeler_reservations_select on public.efeler_reservations;
create policy efeler_reservations_select on public.efeler_reservations for select
using (
  app_id='efeler' and
  (member_id=auth.uid() or public.efeler_role() in ('coach','admin'))
);
revoke insert, update, delete on public.efeler_reservations from anon, authenticated;
grant select on public.efeler_reservations to authenticated;

create or replace function public.efeler_list_runs()
returns table(
  id uuid, title text, starts_at timestamptz, location text, status text,
  points integer, capacity integer, reserved_count bigint,
  is_reserved boolean, created_by uuid
)
language sql stable security definer set search_path = public
as $$
  select
    r.id, r.title, r.starts_at, r.location, r.status, r.points, r.capacity,
    count(rv.id) filter (where rv.status in ('booked','attended')) as reserved_count,
    coalesce(bool_or(rv.member_id=auth.uid() and rv.status in ('booked','attended')), false) as is_reserved,
    r.created_by
  from public.efeler_runs r
  left join public.efeler_reservations rv
    on rv.run_id=r.id and rv.app_id='efeler'
  where r.app_id='efeler'
    and exists (select 1 from public.efeler_profiles p where p.id=auth.uid() and p.app_id='efeler')
  group by r.id
  order by r.starts_at;
$$;

create or replace function public.efeler_reserve_run(p_run_id uuid)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_run public.efeler_runs%rowtype;
  v_count integer;
  v_status text;
begin
  if not exists (select 1 from public.efeler_profiles where id=v_user and app_id='efeler') then
    return jsonb_build_object('code','no_profile');
  end if;
  select * into v_run from public.efeler_runs where id=p_run_id and app_id='efeler' for update;
  if not found or v_run.status='closed' or v_run.starts_at <= now() then
    return jsonb_build_object('code','run_closed');
  end if;
  select status into v_status from public.efeler_reservations
    where run_id=p_run_id and member_id=v_user;
  if v_status in ('booked','attended') then
    return jsonb_build_object('code','already_reserved');
  end if;
  select count(*) into v_count from public.efeler_reservations
    where run_id=p_run_id and app_id='efeler' and status in ('booked','attended');
  if v_count >= v_run.capacity then return jsonb_build_object('code','run_full'); end if;
  insert into public.efeler_reservations(app_id,run_id,member_id,status)
  values ('efeler',p_run_id,v_user,'booked')
  on conflict (run_id,member_id) do update
    set status='booked',updated_at=now();
  return jsonb_build_object('code','success');
end $$;

create or replace function public.efeler_cancel_reservation(p_run_id uuid)
returns jsonb language plpgsql security definer set search_path = public
as $$
begin
  update public.efeler_reservations rv set status='cancelled',updated_at=now()
  from public.efeler_runs r
  where rv.run_id=p_run_id and rv.member_id=auth.uid() and rv.app_id='efeler'
    and rv.status='booked' and r.id=rv.run_id and r.starts_at > now();
  if found then return jsonb_build_object('code','cancelled'); end if;
  return jsonb_build_object('code','unknown');
end $$;

drop function if exists public.efeler_create_run(text,timestamptz,text,integer);
create or replace function public.efeler_create_run(
  p_title text,
  p_starts_at timestamptz,
  p_location text,
  p_points integer default 10,
  p_capacity integer default 30
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_run_id uuid;
begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  if nullif(trim(p_title),'') is null or nullif(trim(p_location),'') is null then raise exception 'invalid_run'; end if;
  if p_starts_at <= now() or p_points < 1 or p_points > 10000 or p_capacity < 1 or p_capacity > 10000 then
    raise exception 'invalid_run';
  end if;
  insert into public.efeler_runs(
    app_id,title,starts_at,location,status,points,capacity,created_by
  ) values (
    'efeler',trim(p_title),p_starts_at,trim(p_location),'scheduled',p_points,p_capacity,auth.uid()
  ) returning id into v_run_id;
  return v_run_id;
end $$;

create or replace function public.efeler_check_in(p_token text)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_run public.efeler_runs%rowtype;
  v_token public.efeler_qr_tokens%rowtype;
  v_checkin uuid;
begin
  if not exists (select 1 from public.efeler_profiles where id=v_user and app_id='efeler') then return jsonb_build_object('code','no_profile'); end if;
  select * into v_token from public.efeler_qr_tokens where token=p_token::uuid and app_id='efeler';
  if not found then return jsonb_build_object('code','invalid_token'); end if;
  if v_token.expires_at < now() then return jsonb_build_object('code','expired_token'); end if;
  select * into v_run from public.efeler_runs where id=v_token.run_id and app_id='efeler' for update;
  if v_run.status <> 'open' then return jsonb_build_object('code','run_closed'); end if;
  if not exists (
    select 1 from public.efeler_reservations
    where run_id=v_run.id and member_id=v_user and app_id='efeler' and status='booked'
  ) then return jsonb_build_object('code','not_reserved'); end if;
  if exists (select 1 from public.efeler_checkins where run_id=v_run.id and member_id=v_user) then return jsonb_build_object('code','already_checked_in'); end if;
  insert into public.efeler_checkins(app_id,run_id,member_id)
  values ('efeler',v_run.id,v_user) returning id into v_checkin;
  update public.efeler_reservations set status='attended',updated_at=now()
    where run_id=v_run.id and member_id=v_user;
  insert into public.efeler_points_ledger(app_id,member_id,delta,reason,ref_id,created_by)
  values ('efeler',v_user,v_run.points,'checkin',v_checkin,v_user);
  return jsonb_build_object('code','success','points',v_run.points);
exception when invalid_text_representation then return jsonb_build_object('code','invalid_token');
end $$;

revoke all on function public.efeler_list_runs() from public;
revoke all on function public.efeler_reserve_run(uuid) from public;
revoke all on function public.efeler_cancel_reservation(uuid) from public;
revoke all on function public.efeler_create_run(text,timestamptz,text,integer,integer) from public;
grant execute on function public.efeler_list_runs(), public.efeler_reserve_run(uuid),
  public.efeler_cancel_reservation(uuid),
  public.efeler_create_run(text,timestamptz,text,integer,integer) to authenticated;
