-- Public club media, coach-managed rewards and member profile photos.
alter table public.efeler_profiles
  add column if not exists avatar_path text;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
  'efeler-media', 'efeler-media', true, 5242880,
  array['image/jpeg','image/png','image/webp','image/heic','image/heif']
)
on conflict (id) do update set
  public=excluded.public,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists efeler_media_public_read on storage.objects;
create policy efeler_media_public_read on storage.objects for select to public
using (bucket_id='efeler-media');

drop policy if exists efeler_avatar_insert on storage.objects;
create policy efeler_avatar_insert on storage.objects for insert to authenticated
with check (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='avatars'
  and storage.filename(name)=auth.uid()::text || '.jpg'
);
drop policy if exists efeler_avatar_update on storage.objects;
create policy efeler_avatar_update on storage.objects for update to authenticated
using (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='avatars'
  and storage.filename(name)=auth.uid()::text || '.jpg'
)
with check (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='avatars'
  and storage.filename(name)=auth.uid()::text || '.jpg'
);

drop policy if exists efeler_reward_media_insert on storage.objects;
create policy efeler_reward_media_insert on storage.objects for insert to authenticated
with check (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='rewards'
  and public.efeler_role() in ('coach','admin')
);
drop policy if exists efeler_reward_media_update on storage.objects;
create policy efeler_reward_media_update on storage.objects for update to authenticated
using (bucket_id='efeler-media' and public.efeler_role() in ('coach','admin'))
with check (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='rewards'
  and public.efeler_role() in ('coach','admin')
);

drop function if exists public.efeler_update_profile(text,text);
create function public.efeler_update_profile(
  p_full_name text,
  p_bio text default '',
  p_avatar_path text default null
)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if nullif(trim(p_full_name), '') is null then raise exception 'invalid_name'; end if;
  if p_avatar_path is not null and p_avatar_path <> ('avatars/' || auth.uid()::text || '.jpg') then
    raise exception 'invalid_avatar';
  end if;
  update public.efeler_profiles
  set full_name=left(trim(p_full_name), 100),
      bio=left(trim(coalesce(p_bio, '')), 280),
      avatar_path=coalesce(p_avatar_path, avatar_path)
  where id=auth.uid() and app_id='efeler';
  if not found then raise exception 'profile_not_found'; end if;
end $$;

create or replace function public.efeler_create_reward(
  p_name text,
  p_description text,
  p_points_cost integer,
  p_stock integer
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_reward_id uuid;
begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  if nullif(trim(p_name),'') is null or p_points_cost < 1 or p_stock < 0 then
    raise exception 'invalid_reward';
  end if;
  insert into public.efeler_rewards(app_id,name,description,points_cost,stock,active)
  values ('efeler',left(trim(p_name),120),left(trim(coalesce(p_description,'')),500),p_points_cost,p_stock,true)
  returning id into v_reward_id;
  return v_reward_id;
end $$;

create or replace function public.efeler_set_reward_image(
  p_reward_id uuid,
  p_image_path text
)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if public.efeler_role() not in ('coach','admin') then raise exception 'not_allowed'; end if;
  if p_image_path <> 'rewards/' || p_reward_id::text || '.jpg' then raise exception 'invalid_image'; end if;
  update public.efeler_rewards set image_url=p_image_path
  where id=p_reward_id and app_id='efeler';
  if not found then raise exception 'reward_not_found'; end if;
end $$;

drop function if exists public.efeler_list_members();
create function public.efeler_list_members()
returns table(id uuid, full_name text, role text, bio text, avatar_path text)
language sql stable security definer set search_path = public
as $$
  select p.id, p.full_name, p.role, p.bio, p.avatar_path
  from public.efeler_profiles p
  where p.app_id='efeler' and public.efeler_role() in ('coach','admin')
  order by case p.role when 'admin' then 0 when 'coach' then 1 else 2 end, p.full_name;
$$;

drop function if exists public.efeler_list_runs();
create function public.efeler_list_runs()
returns table(
  id uuid, title text, starts_at timestamptz, location text, status text,
  points integer, capacity integer, reserved_count bigint,
  is_reserved boolean, created_by uuid, coach_name text, coach_bio text,
  coach_avatar_path text
)
language sql stable security definer set search_path = public
as $$
  select
    r.id, r.title, r.starts_at, r.location, r.status, r.points, r.capacity,
    count(rv.id) filter (where rv.status in ('booked','attended')),
    coalesce(bool_or(rv.member_id=auth.uid() and rv.status in ('booked','attended')), false),
    r.created_by, coach.full_name, coach.bio, coach.avatar_path
  from public.efeler_runs r
  join public.efeler_profiles coach on coach.id=r.created_by and coach.app_id='efeler'
  left join public.efeler_reservations rv on rv.run_id=r.id and rv.app_id='efeler'
  where r.app_id='efeler'
    and exists (select 1 from public.efeler_profiles p where p.id=auth.uid() and p.app_id='efeler')
  group by r.id, coach.full_name, coach.bio, coach.avatar_path
  order by r.starts_at;
$$;

revoke all on function public.efeler_update_profile(text,text,text) from public;
revoke all on function public.efeler_create_reward(text,text,integer,integer) from public;
revoke all on function public.efeler_set_reward_image(uuid,text) from public;
revoke all on function public.efeler_list_members() from public;
revoke all on function public.efeler_list_runs() from public;
grant execute on function public.efeler_update_profile(text,text,text),
  public.efeler_create_reward(text,text,integer,integer),
  public.efeler_set_reward_image(uuid,text), public.efeler_list_members(),
  public.efeler_list_runs() to authenticated;
