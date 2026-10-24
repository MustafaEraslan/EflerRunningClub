# Mimari

## İstemci

Flutter uygulaması feature-first yapıdadır. Riverpod veri yükleme ve yenilemeyi, GoRouter kimlik doğrulama yönlendirmesini, Supabase Flutter ise oturum ve veri erişimini yönetir. Mobil uygulama atlet ve antrenör deneyimini sunar; Phase 2'de aynı proje web yönetim panelini barındıracaktır.

İstemci hiçbir zaman katılım, puan hareketi veya ödül talebi tablosuna doğrudan yazmaz. Kritik işlemler tek transaction içinde çalışan `security definer` RPC'lerden geçer.

## Veri modeli

- `efeler_profiles`: ortak `auth.users` kaydına bağlı, uygulamaya özel profil ve rol.
- `efeler_runs`: koşu planı, durum ve kazanılacak puan.
- `efeler_qr_tokens`: 60 saniye geçerli, tahmin edilemez QR token'ları.
- `efeler_checkins`: koşu başına üye için tek katılım.
- `efeler_points_ledger`: append-only puan hareketleri; bakiye `efeler_member_balance` görünümünde toplanır.
- `efeler_rewards`: tekstil ürünleri, puan bedeli ve stok.
- `efeler_reward_requests`: fiziksel teslimat talepleri.

Her tabloda sabit `app_id = 'efeler'` kontrolü vardır. Profil tetikleyicisi yalnızca kullanıcı metadata'sındaki `app_id` değeri `efeler` olduğunda çalışır.

## RPC'ler

- `efeler_get_qr_token`: antrenör/yönetici, açık koşu için 60 saniyelik token üretir.
- `efeler_check_in`: token, süre, koşu durumu ve mükerrer katılımı doğrular; katılım ile puanı atomik yazar.
- `efeler_redeem`: ödül satırını kilitler; bakiye/stok kontrolü sonrası stok, puan ve talebi atomik günceller.
- `efeler_set_run_status`: antrenör/yönetici koşuyu açar veya kapatır.
- `efeler_mark_delivered`, `efeler_cancel_request`, `efeler_adjust_points`: yönetici operasyonları.
- `efeler_delete_account`: Efeler verilerini siler. Metadata Efeler'i tek uygulama olarak gösteriyorsa auth kaydını silmeyi dener; başka uygulama FK'sı varsa auth kaydını güvenle korur.

## Rol matrisi

| İşlem | Atlet | Antrenör | Yönetici |
|---|:---:|:---:|:---:|
| Koşu/aktif ödül okuma | ✓ | ✓ | ✓ |
| QR ile katılım | ✓ | ✓ | ✓ |
| Kendi puan/talep geçmişi | ✓ | ✓ | ✓ |
| Koşu aç/kapat ve QR göster |  | ✓ | ✓ |
| Koşu/ödül yönetimi |  |  | ✓ |
| Teslim/iptal/puan düzeltme |  |  | ✓ |

RLS her okumada `app_id = 'efeler'` koşulunu ve Efeler profilinin varlığını zorunlu tutar. Rol değişikliği istemci sütun yetkisiyle engellenmiştir.
