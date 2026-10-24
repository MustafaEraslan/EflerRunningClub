# Efeler Running Club

Efeler Running Club'ın atlet, antrenör ve yönetici deneyimlerini tek Flutter projesinde birleştiren uygulaması. Phase 1; üyelik, QR ile koşu katılımı, puan ve fiziksel ödül akışlarını içerir.

## Gereksinimler

- Flutter stable (3.44 veya üzeri)
- Xcode / Android Studio
- Supabase projesi `xgkoglszscleaktotldk`
- Uygulama kimliği: `com.efelerrunningclub.app`

## Supabase kurulumu

Migration'ları Supabase SQL Editor'da dosya adı sırasıyla çalıştırın:

1. `supabase/migrations/20261024180000_efeler_core.sql`
2. `supabase/migrations/20261024190000_efeler_social_and_coach.sql`
3. `supabase/migrations/20261024200000_efeler_run_reservations.sql`
4. İsteğe bağlı, yalnızca geliştirme ortamında: `supabase/seed.sql`

Migration tekrar çalıştırılabilir ve ortak projedeki mevcut nesneleri değiştirmez; oluşturduğu tüm tablo, görünüm, fonksiyon, politika ve tetikleyiciler `efeler_` öneklidir. İlk yönetici hesabını uygulamada kaydettikten sonra SQL Editor'da bir kez şu sorguyla yetkilendirin:

```sql
update public.efeler_profiles
set role = 'admin'
where id = (select id from auth.users where email = 'yonetici@ornek.com')
  and app_id = 'efeler';
```

Antrenörler için aynı sorguda rolü `coach` yapın. `service_role` anahtarı uygulamada kullanılmaz ve depoya eklenmemelidir.

## Çalıştırma

Supabase Dashboard > Project Settings > API ekranındaki publishable/anon anahtarıyla:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://xgkoglszscleaktotldk.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Alternatif olarak değerleri git tarafından yok sayılan yerel `.env` dosyasında saklayabilirsiniz; Flutter CLI komutuna yine `--dart-define-from-file=.env` ekleyin. Örnek için `.env.example` dosyasına bakın.

## Test ve derleme

```bash
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=.env
flutter build ios --release --dart-define-from-file=.env
flutter build web --release --dart-define-from-file=.env
```

iOS derlemesi için Apple Developer imzalama ekibi ve provisioning profile Xcode'dan seçilmelidir.

## Manuel dashboard adımları

- Authentication > Providers bölümünde e-posta/şifre girişini etkinleştirin.
- Authentication > Providers altında Google ve Apple sağlayıcılarını etkinleştirin. Google Cloud'da Web OAuth istemcisine Supabase callback URL'sini; Apple Developer'da App ID/Services ID ve Sign in with Apple ayarlarını tanımlayın.
- Authentication > URL Configuration > Redirect URLs listesine `com.efelerrunningclub.app://login-callback` ekleyin.
- Üretimde özel SMTP sağlayıcısı tanımlayın; ücretsiz geliştirmede Supabase'in limitli e-posta servisi kullanılabilir.
- Authentication > URL Configuration altında mobil deep link ve ilerideki web paneli alan adını redirect URL olarak ekleyin.
- KVKK ekranındaki yayın bağlantısını gerçek aydınlatma metni URL'siyle değiştirin.
- İlk admin ve antrenör rollerini yukarıdaki SQL ile atayın.
- `supabase/seed.sql` dosyasını üretimde çalıştırmayın.
- Resmî kulüp logosu `assets/icon/icon.png` dosyasındadır; değişirse `dart run flutter_launcher_icons` çalıştırın.

## Fazlar

- Phase 1: mobil çekirdek, QR, puan, ödüller ve güvenli Supabase altyapısı — tamamlandı.
- Phase 2: Flutter Web yönetim paneli — Phase 1 kullanıcı testi sonrasında.
- Phase 3: FCM bildirimleri ve duyurular — Phase 2 sonrasında.

Teknik kararlar ve rol matrisi için [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) dosyasına bakın.
