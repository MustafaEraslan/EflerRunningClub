-- Social profile claim and coach run planning.
create or replace function public.efeler_ensure_profile()
returns void language plpgsql security definer set search_path = public, auth
as $$
declare
  v_user auth.users%rowtype;
  v_name text;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if exists (select 1 from public.efeler_profiles where id=auth.uid() and app_id='efeler') then return; end if;

  select * into v_user from auth.users where id=auth.uid();
  v_name := coalesce(
    nullif(trim(v_user.raw_user_meta_data->>'full_name'), ''),
    nullif(trim(v_user.raw_user_meta_data->>'name'), ''),
    nullif(split_part(v_user.email, '@', 1), ''),
    'Yeni Üye'
  );

  insert into public.efeler_profiles(
    id, app_id, full_name, role, consent_accepted_at, consent_version
  ) values (
    auth.uid(), 'efeler', v_name, 'member', now(), '1.0'
  ) on conflict (id) do nothing;
end $$;

create or replace function public.efeler_create_run(
  p_title text,
  p_starts_at timestamptz,
  p_location text,
  p_points integer default 10
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_run_id uuid;
begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  if nullif(trim(p_title),'') is null or nullif(trim(p_location),'') is null then raise exception 'invalid_run'; end if;
  if p_starts_at <= now() or p_points < 1 or p_points > 10000 then raise exception 'invalid_run'; end if;

  insert into public.efeler_runs(
    app_id, title, starts_at, location, status, points, created_by
  ) values (
    'efeler', trim(p_title), p_starts_at, trim(p_location), 'scheduled', p_points, auth.uid()
  ) returning id into v_run_id;
  return v_run_id;
end $$;

revoke all on function public.efeler_ensure_profile() from public;
revoke all on function public.efeler_create_run(text,timestamptz,text,integer) from public;
grant execute on function public.efeler_ensure_profile(),
  public.efeler_create_run(text,timestamptz,text,integer) to authenticated;
