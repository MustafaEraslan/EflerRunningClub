-- Keep role and coach level consistent even if a future client writes directly.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'efeler_profiles_role_level_check'
  ) then
    alter table public.efeler_profiles
      add constraint efeler_profiles_role_level_check
      check (
        (role = 'member' and coach_level = 0)
        or (role = 'coach' and coach_level between 1 and 3)
        or (role = 'admin' and coach_level = 3)
      );
  end if;
end $$;
