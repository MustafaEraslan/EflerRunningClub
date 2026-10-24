# Efeler Running Club — working notes for Claude

Flutter mobile app (iOS first, tested on a real iPhone) for a running club, backed by Supabase.

## Project rules

- Stack: Flutter + `supabase_flutter`, Riverpod (`flutter_riverpod` 3), `go_router`.
- UI strings are **Turkish only**. Code, comments and commit messages are **English**.
- The Supabase project (ref `xgkoglszscleaktotldk`) is **shared with other apps**.
  - Never alter or drop objects that are not ours (`villages`, `profiles`, `work_posts`, … from
    `0001`–`0003` belong to other apps).
  - All our objects are prefixed `efeler_` (storage buckets `efeler-…`). Every table has
    `app_id text not null default 'efeler' check (app_id = 'efeler')` and RLS restricts to it.
- Anything that changes points, check-ins, reservations or rewards goes through
  `security definer` RPCs. Clients have no direct insert/update/delete on those tables.
- Schema changes ONLY as NEW timestamped files in `supabase/migrations/`
  (`YYYYMMDDHHMMSS_efeler_<topic>.sql`). Never edit an already-applied migration.
  The owner runs them manually in the SQL editor, so always report which files to run, in order.
  Migrations must be re-runnable (`if not exists`, `create or replace`, `drop policy if exists`).
- No `service_role` key in the repo or the app. Free tiers only, no paid services.
- Minimal, focused diffs; no refactors beyond the task. `flutter analyze` must stay clean.
- Git: work on a feature branch (never push to `main`), one commit per task, push and open a PR.

## Run / check

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=.env   # .env holds SUPABASE_URL / SUPABASE_ANON_KEY (gitignored)
```

## Architecture map

```
lib/
  main.dart                     Supabase.initialize + ProviderScope
  app.dart                      MaterialApp.router (dark theme), password-recovery listener
  core/
    config/app_config.dart      dart-define config, appId = 'efeler'
    data/club_repository.dart   ALL Supabase calls (auth, RPCs, storage)
    errors/result_messages.dart RPC result code -> Turkish message
    models/models.dart          Profile, ClubMember, ClubRun, Reward
    providers/providers.dart    FutureProviders (profile, runs, members, rewards, balance, ledger, requests)
    router/app_router.dart      go_router routes + auth redirect
    theme/app_theme.dart        brand colours (pink #FF5ABB, lime #CCFF00, charcoal) and component themes
    widgets/                    small shared widgets (confirm dialog, avatar, …)
  features/
    auth/                       login / register / forgot, reset password
    home/home_screen.dart       bottom-nav tabs: Koşular (runs + reservation), Ödüller, Puanlarım, Taleplerim
    profile/                    profile, edit profile, team (coach/admin member management)
    rewards/reward_form_screen  coach/admin create reward (+ image)
    runs/                       run form (coach), QR display (coach), QR scanner (member)
supabase/migrations/            efeler_* migrations in timestamp order (0001–0003 are other apps')
docs/ARCHITECTURE.md            data model, RPC list, role matrix (Turkish)
```

Key data flow: screens -> `repositoryProvider` (`ClubRepository`) -> Supabase RPC / table select.
After a mutation, invalidate the affected FutureProviders so the UI refetches from the server.

Roles: `member`, `coach` (coach_level 1–3, 3 = head coach), `admin`. `efeler_role()` returns the
caller's role. Runs: `scheduled` -> `open` (coach opens for QR check-in) -> `closed`.
Reservations: `booked` / `cancelled` / `attended`, unique (run_id, member_id).

Storage: `efeler-media` (public: reward images under `rewards/`, legacy avatars under `avatars/`),
`efeler-avatars` (private: `{user_id}/avatar.jpg`, authenticated Efeler members can read).
