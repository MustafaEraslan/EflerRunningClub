String checkInMessage(String code) => switch (code) {
  'success' => 'Katılımın onaylandı. Puanın hesabına eklendi!',
  'expired_token' => 'QR kodun süresi doldu. Antrenörden yeni kod iste.',
  'already_checked_in' => 'Bu koşuya daha önce katılım yaptın.',
  'run_closed' => 'Bu koşu katılıma kapalı.',
  'invalid_token' => 'QR kod geçersiz.',
  'no_profile' => 'Efeler Running Club profilin bulunamadı.',
  'not_reserved' => 'Bu koşuya rezervasyonun bulunmuyor.',
  _ => 'İşlem tamamlanamadı. Lütfen tekrar dene.',
};

// success message is handled separately (pink accent) — not used for the
// 'success' code here; kept as a fallback only.
String reservationMessage(String code) => switch (code) {
  'success' => 'Tebrikler, rezervasyonun tamamlandı.',
  'already_reserved' => 'Bu koşuya zaten rezervasyon yaptın.',
  'run_full' => 'Bu koşunun kontenjanı doldu.',
  'run_closed' => 'Bu koşu rezervasyona kapalı.',
  'cancelled' => 'Rezervasyonun iptal edildi.',
  'no_profile' => 'Efeler Running Club profilin bulunamadı.',
  'unknown' => 'Rezervasyon bulunamadı veya iptal edilemedi.',
  'offline' => 'İnternet bağlantısı yok. Lütfen bağlantını kontrol et.',
  _ => 'Rezervasyon işlemi tamamlanamadı. Tekrar dene.',
};

String redeemMessage(String code) => switch (code) {
  'success' => 'Talebin alındı. Ürününü kulüpten teslim alabilirsin.',
  'not_enough_points' => 'Bu ürün için yeterli puanın yok.',
  'no_stock' => 'Bu ürün şu anda stokta yok.',
  'inactive_reward' => 'Bu ödül artık kullanılamıyor.',
  _ => 'Talep oluşturulamadı. Lütfen tekrar dene.',
};
