-- Private avatar bucket for Efeler members.
-- Path pattern: {user_id}/avatar.jpg
-- Reads are allowed for any authenticated Efeler user (profile pic is not a secret).
-- Writes are limited to the owning user's folder.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
  'efeler-avatars',
  'efeler-avatars',
  false,
  614400,  -- 600 KB ceiling; client uploads ≤512×512 JPEG at 80% quality
  array['image/jpeg']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Owner can write their own file (insert + update).
drop policy if exists efeler_avatars_owner_insert on storage.objects;
create policy efeler_avatars_owner_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'efeler-avatars'
  and name = auth.uid()::text || '/avatar.jpg'
);

drop policy if exists efeler_avatars_owner_update on storage.objects;
create policy efeler_avatars_owner_update on storage.objects for update to authenticated
using (
  bucket_id = 'efeler-avatars'
  and name = auth.uid()::text || '/avatar.jpg'
)
with check (
  bucket_id = 'efeler-avatars'
  and name = auth.uid()::text || '/avatar.jpg'
);

-- Authenticated Efeler members can read any avatar in this bucket.
drop policy if exists efeler_avatars_authenticated_read on storage.objects;
create policy efeler_avatars_authenticated_read on storage.objects for select to authenticated
using (
  bucket_id = 'efeler-avatars'
  and exists (
    select 1
    from public.efeler_profiles
    where id = auth.uid()
      and app_id = 'efeler'
  )
);

-- Update efeler_update_profile to accept the new bucket path format.
-- Accepts either legacy 'avatars/{id}.jpg' (efeler-media) or new '{id}/avatar.jpg' (efeler-avatars).
drop function if exists public.efeler_update_profile(text, text, text);
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
  if p_avatar_path is not null
    and p_avatar_path <> ('avatars/' || auth.uid()::text || '.jpg')
    and p_avatar_path <> (auth.uid()::text || '/avatar.jpg')
  then
    raise exception 'invalid_avatar';
  end if;
  update public.efeler_profiles
  set full_name    = left(trim(p_full_name), 100),
      bio          = left(trim(coalesce(p_bio, '')), 280),
      avatar_path  = coalesce(p_avatar_path, avatar_path)
  where id = auth.uid() and app_id = 'efeler';
  if not found then raise exception 'profile_not_found'; end if;
end $$;

revoke all on function public.efeler_update_profile(text, text, text) from public;
grant execute on function public.efeler_update_profile(text, text, text) to authenticated;
