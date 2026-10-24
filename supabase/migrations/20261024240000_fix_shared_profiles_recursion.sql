-- The shared project's legacy admin policy queried profiles from the profiles
-- policy itself. Keep the same rule without recursive RLS evaluation.
create or replace function public.shared_profile_is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id=auth.uid() and role='admin'
  );
$$;

revoke all on function public.shared_profile_is_admin() from public;
grant execute on function public.shared_profile_is_admin() to authenticated;

drop policy if exists "profiles: admin hepsini okur" on public.profiles;
create policy "profiles: admin hepsini okur" on public.profiles for select
to authenticated using (public.shared_profile_is_admin());
