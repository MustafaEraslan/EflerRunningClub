-- FCM device tokens for push notifications.
create table if not exists public.efeler_device_tokens (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'efeler' check (app_id = 'efeler'),
  user_id uuid not null references public.efeler_profiles(id) on delete cascade,
  fcm_token text not null,
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);
create index if not exists efeler_device_tokens_user_idx
  on public.efeler_device_tokens(user_id);

alter table public.efeler_device_tokens enable row level security;

-- Users can only see their own tokens.
drop policy if exists efeler_device_tokens_select on public.efeler_device_tokens;
create policy efeler_device_tokens_select on public.efeler_device_tokens for select
using (app_id = 'efeler' and user_id = auth.uid());

-- Revoke direct writes — everything goes through the RPC.
revoke insert, update, delete on public.efeler_device_tokens from anon, authenticated;
grant select on public.efeler_device_tokens to authenticated;

-- ─── SAVE DEVICE TOKEN ──────────────────────────────────────────────────────
create or replace function public.efeler_save_device_token(p_token text)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if nullif(trim(p_token), '') is null then raise exception 'invalid_token'; end if;
  insert into public.efeler_device_tokens(app_id, user_id, fcm_token, updated_at)
  values ('efeler', auth.uid(), trim(p_token), now())
  on conflict (user_id, fcm_token)
  do update set updated_at = now();
end $$;

revoke all on function public.efeler_save_device_token(text) from public;
grant execute on function public.efeler_save_device_token(text) to authenticated;
