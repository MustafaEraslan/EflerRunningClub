-- Efeler Running Club core schema. Safe for the shared Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.efeler_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  full_name text not null check (length(trim(full_name)) between 2 and 120),
  role text not null default 'member' check (role in ('member','coach','admin')),
  consent_accepted_at timestamptz not null,
  consent_version text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.efeler_runs (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  title text not null,
  starts_at timestamptz not null,
  location text not null,
  status text not null default 'scheduled' check (status in ('scheduled','open','closed')),
  points integer not null default 10 check (points > 0 and points <= 10000),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.efeler_qr_tokens (
  token uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  run_id uuid not null references public.efeler_runs(id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists efeler_qr_tokens_run_idx on public.efeler_qr_tokens(run_id, expires_at);

create table if not exists public.efeler_checkins (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  run_id uuid not null references public.efeler_runs(id) on delete cascade,
  member_id uuid not null references public.efeler_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (run_id, member_id)
);

create table if not exists public.efeler_points_ledger (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  member_id uuid not null references public.efeler_profiles(id) on delete cascade,
  delta integer not null check (delta <> 0),
  reason text not null check (reason in ('checkin','redeem','refund','adjustment')),
  ref_id uuid,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists efeler_ledger_member_idx on public.efeler_points_ledger(member_id, created_at desc);

create table if not exists public.efeler_rewards (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  name text not null,
  description text,
  image_url text,
  points_cost integer not null check (points_cost > 0),
  stock integer not null default 0 check (stock >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.efeler_reward_requests (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  member_id uuid not null references public.efeler_profiles(id) on delete cascade,
  reward_id uuid not null references public.efeler_rewards(id),
  points_spent integer not null check (points_spent > 0),
  status text not null default 'requested' check (status in ('requested','delivered','cancelled')),
  created_at timestamptz not null default now(),
  handled_by uuid references auth.users(id) on delete set null,
  handled_at timestamptz
);

create or replace function public.efeler_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.efeler_profiles where id = auth.uid() and app_id = 'efeler' $$;

create or replace function public.efeler_create_profile()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.raw_user_meta_data->>'app_id' <> 'efeler' then return new; end if;
  insert into public.efeler_profiles(id, app_id, full_name, consent_accepted_at, consent_version)
  values (
    new.id, 'efeler', coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'Yeni Üye'),
    coalesce((new.raw_user_meta_data->>'consent_accepted_at')::timestamptz, now()),
    coalesce(new.raw_user_meta_data->>'consent_version', '1.0')
  ) on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists efeler_on_auth_user_created on auth.users;
create trigger efeler_on_auth_user_created after insert on auth.users
for each row execute function public.efeler_create_profile();

create or replace view public.efeler_member_balance
with (security_invoker = true) as
select p.app_id, p.id member_id, coalesce(sum(l.delta), 0)::bigint balance
from public.efeler_profiles p left join public.efeler_points_ledger l
  on l.member_id = p.id and l.app_id = 'efeler'
where p.app_id = 'efeler'
group by p.app_id, p.id;

alter table public.efeler_profiles enable row level security;
alter table public.efeler_runs enable row level security;
alter table public.efeler_qr_tokens enable row level security;
alter table public.efeler_checkins enable row level security;
alter table public.efeler_points_ledger enable row level security;
alter table public.efeler_rewards enable row level security;
alter table public.efeler_reward_requests enable row level security;

drop policy if exists efeler_profiles_select on public.efeler_profiles;
create policy efeler_profiles_select on public.efeler_profiles for select
using (app_id = 'efeler' and (id = auth.uid() or public.efeler_role() = 'admin'));
drop policy if exists efeler_runs_select on public.efeler_runs;
create policy efeler_runs_select on public.efeler_runs for select
using (app_id = 'efeler' and public.efeler_role() is not null);
drop policy if exists efeler_checkins_select on public.efeler_checkins;
create policy efeler_checkins_select on public.efeler_checkins for select
using (app_id = 'efeler' and (member_id = auth.uid() or public.efeler_role() in ('coach','admin')));
drop policy if exists efeler_ledger_select on public.efeler_points_ledger;
create policy efeler_ledger_select on public.efeler_points_ledger for select
using (app_id = 'efeler' and (member_id = auth.uid() or public.efeler_role() = 'admin'));
drop policy if exists efeler_rewards_select on public.efeler_rewards;
create policy efeler_rewards_select on public.efeler_rewards for select
using (app_id = 'efeler' and public.efeler_role() is not null and (active or public.efeler_role() = 'admin'));
drop policy if exists efeler_requests_select on public.efeler_reward_requests;
create policy efeler_requests_select on public.efeler_reward_requests for select
using (app_id = 'efeler' and (member_id = auth.uid() or public.efeler_role() = 'admin'));

-- Only admins write ordinary records directly. Attendance, ledger and requests are RPC-only.
drop policy if exists efeler_runs_admin_write on public.efeler_runs;
create policy efeler_runs_admin_write on public.efeler_runs for all
using (app_id = 'efeler' and public.efeler_role() = 'admin')
with check (app_id = 'efeler' and public.efeler_role() = 'admin');
drop policy if exists efeler_rewards_admin_write on public.efeler_rewards;
create policy efeler_rewards_admin_write on public.efeler_rewards for all
using (app_id = 'efeler' and public.efeler_role() = 'admin')
with check (app_id = 'efeler' and public.efeler_role() = 'admin');

revoke all on public.efeler_qr_tokens from anon, authenticated;
revoke insert, update, delete on public.efeler_checkins from anon, authenticated;
revoke insert, update, delete on public.efeler_points_ledger from anon, authenticated;
revoke insert, update, delete on public.efeler_reward_requests from anon, authenticated;
revoke update (role, app_id) on public.efeler_profiles from authenticated;
grant select on public.efeler_profiles, public.efeler_runs, public.efeler_checkins,
  public.efeler_points_ledger, public.efeler_rewards, public.efeler_reward_requests,
  public.efeler_member_balance to authenticated;

create or replace function public.efeler_get_qr_token(p_run_id uuid)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare v_token uuid;
begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  if not exists (select 1 from public.efeler_runs where id=p_run_id and app_id='efeler' and status='open') then raise exception 'run_closed'; end if;
  delete from public.efeler_qr_tokens where app_id='efeler' and expires_at < now();
  insert into public.efeler_qr_tokens(app_id, run_id, expires_at)
  values ('efeler', p_run_id, now() + interval '60 seconds') returning token into v_token;
  return jsonb_build_object('token', v_token::text, 'expires_at', now() + interval '60 seconds');
end $$;

create or replace function public.efeler_check_in(p_token text)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_run public.efeler_runs%rowtype; v_token public.efeler_qr_tokens%rowtype; v_checkin uuid;
begin
  if not exists (select 1 from public.efeler_profiles where id=v_user and app_id='efeler') then return jsonb_build_object('code','no_profile'); end if;
  select * into v_token from public.efeler_qr_tokens where token=p_token::uuid and app_id='efeler';
  if not found then return jsonb_build_object('code','invalid_token'); end if;
  if v_token.expires_at < now() then return jsonb_build_object('code','expired_token'); end if;
  select * into v_run from public.efeler_runs where id=v_token.run_id and app_id='efeler' for update;
  if v_run.status <> 'open' then return jsonb_build_object('code','run_closed'); end if;
  if exists (select 1 from public.efeler_checkins where run_id=v_run.id and member_id=v_user) then return jsonb_build_object('code','already_checked_in'); end if;
  insert into public.efeler_checkins(app_id, run_id, member_id) values ('efeler', v_run.id, v_user) returning id into v_checkin;
  insert into public.efeler_points_ledger(app_id, member_id, delta, reason, ref_id, created_by)
  values ('efeler', v_user, v_run.points, 'checkin', v_checkin, v_user);
  return jsonb_build_object('code','success','points',v_run.points);
exception when invalid_text_representation then return jsonb_build_object('code','invalid_token');
end $$;

create or replace function public.efeler_redeem(p_reward_id uuid)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_reward public.efeler_rewards%rowtype; v_balance bigint; v_request uuid;
begin
  if not exists (select 1 from public.efeler_profiles where id=v_user and app_id='efeler') then return jsonb_build_object('code','no_profile'); end if;
  select * into v_reward from public.efeler_rewards where id=p_reward_id and app_id='efeler' for update;
  if not found or not v_reward.active then return jsonb_build_object('code','inactive_reward'); end if;
  if v_reward.stock < 1 then return jsonb_build_object('code','no_stock'); end if;
  select coalesce(sum(delta),0) into v_balance from public.efeler_points_ledger where member_id=v_user and app_id='efeler';
  if v_balance < v_reward.points_cost then return jsonb_build_object('code','not_enough_points'); end if;
  update public.efeler_rewards set stock=stock-1 where id=p_reward_id;
  insert into public.efeler_reward_requests(app_id, member_id, reward_id, points_spent)
  values ('efeler',v_user,p_reward_id,v_reward.points_cost) returning id into v_request;
  insert into public.efeler_points_ledger(app_id,member_id,delta,reason,ref_id,created_by)
  values ('efeler',v_user,-v_reward.points_cost,'redeem',v_request,v_user);
  return jsonb_build_object('code','success','request_id',v_request);
end $$;

create or replace function public.efeler_set_run_status(p_run_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public
as $$ begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  if p_status not in ('open','closed') then raise exception 'invalid_status'; end if;
  update public.efeler_runs set status=p_status where id=p_run_id and app_id='efeler';
end $$;

create or replace function public.efeler_mark_delivered(p_request_id uuid)
returns void language plpgsql security definer set search_path = public
as $$ begin
  if public.efeler_role() <> 'admin' then raise exception 'not_allowed'; end if;
  update public.efeler_reward_requests set status='delivered',handled_by=auth.uid(),handled_at=now()
  where id=p_request_id and app_id='efeler' and status='requested';
end $$;

create or replace function public.efeler_cancel_request(p_request_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare v_req public.efeler_reward_requests%rowtype;
begin
  if public.efeler_role() <> 'admin' then raise exception 'not_allowed'; end if;
  select * into v_req from public.efeler_reward_requests where id=p_request_id and app_id='efeler' for update;
  if not found or v_req.status <> 'requested' then raise exception 'invalid_request'; end if;
  update public.efeler_reward_requests set status='cancelled',handled_by=auth.uid(),handled_at=now() where id=p_request_id;
  update public.efeler_rewards set stock=stock+1 where id=v_req.reward_id and app_id='efeler';
  insert into public.efeler_points_ledger(app_id,member_id,delta,reason,ref_id,note,created_by)
  values ('efeler',v_req.member_id,v_req.points_spent,'refund',v_req.id,'İptal edilen ödül talebi',auth.uid());
end $$;

create or replace function public.efeler_adjust_points(p_member_id uuid, p_delta integer, p_note text)
returns void language plpgsql security definer set search_path = public
as $$ begin
  if public.efeler_role() <> 'admin' then raise exception 'not_allowed'; end if;
  if p_delta=0 or nullif(trim(p_note),'') is null then raise exception 'invalid_adjustment'; end if;
  insert into public.efeler_points_ledger(app_id,member_id,delta,reason,note,created_by)
  select 'efeler',id,p_delta,'adjustment',trim(p_note),auth.uid() from public.efeler_profiles where id=p_member_id and app_id='efeler';
end $$;

create or replace function public.efeler_delete_account()
returns void language plpgsql security definer set search_path = public, auth
as $$
declare v_user uuid := auth.uid(); v_meta jsonb;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select raw_user_meta_data into v_meta from auth.users where id=v_user;
  delete from public.efeler_profiles where id=v_user and app_id='efeler';
  -- Delete auth only when metadata identifies Efeler as the sole app. FK protection
  -- from any other app makes this fail safely; in that case the shared auth user remains.
  if v_meta->>'app_id'='efeler' and coalesce(jsonb_array_length(coalesce(v_meta->'app_ids','[]'::jsonb)),0) <= 1 then
    begin delete from auth.users where id=v_user; exception when foreign_key_violation then null; end;
  end if;
end $$;

revoke all on function public.efeler_get_qr_token(uuid) from public;
revoke all on function public.efeler_check_in(text) from public;
revoke all on function public.efeler_redeem(uuid) from public;
revoke all on function public.efeler_set_run_status(uuid,text) from public;
revoke all on function public.efeler_mark_delivered(uuid) from public;
revoke all on function public.efeler_cancel_request(uuid) from public;
revoke all on function public.efeler_adjust_points(uuid,integer,text) from public;
revoke all on function public.efeler_delete_account() from public;
grant execute on function public.efeler_get_qr_token(uuid), public.efeler_check_in(text),
  public.efeler_redeem(uuid), public.efeler_set_run_status(uuid,text), public.efeler_mark_delivered(uuid),
  public.efeler_cancel_request(uuid), public.efeler_adjust_points(uuid,integer,text),
  public.efeler_delete_account() to authenticated;
