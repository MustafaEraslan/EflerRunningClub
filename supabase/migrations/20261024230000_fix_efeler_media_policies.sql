-- Avoid profile-policy recursion while still limiting each upload to its owner.
drop policy if exists efeler_reward_media_insert on storage.objects;
create policy efeler_reward_media_insert on storage.objects for insert to authenticated
with check (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='rewards'
  and owner_id=auth.uid()::text
);

drop policy if exists efeler_reward_media_update on storage.objects;
create policy efeler_reward_media_update on storage.objects for update to authenticated
using (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='rewards'
  and owner_id=auth.uid()::text
)
with check (
  bucket_id='efeler-media'
  and (storage.foldername(name))[1]='rewards'
  and owner_id=auth.uid()::text
);
