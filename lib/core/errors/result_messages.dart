String checkInMessage(String code) => switch (code) {
  'success' => 'Katılımın onaylandı. Puanın hesabına eklendi!',
  'expired_token' => 'QR kodun süresi doldu. Antrenörden yeni kod iste.',
  'already_checked_in' => 'Bu koşuya daha önce katılım yaptın.',
  'run_closed' => 'Bu koşu katılıma kapalı.',
  'invalid_token' => 'QR kod geçersiz.',
  'no_profile' => 'Efeler Running Club profilin bulunamadı.',
  _ => 'İşlem tamamlanamadı. Lütfen tekrar dene.',
};

String redeemMessage(String code) => switch (code) {
  'success' => 'Talebin alındı. Ürününü kulüpten teslim alabilirsin.',
  'not_enough_points' => 'Bu ürün için yeterli puanın yok.',
  'no_stock' => 'Bu ürün şu anda stokta yok.',
  'inactive_reward' => 'Bu ödül artık kullanılamıyor.',
  _ => 'Talep oluşturulamadı. Lütfen tekrar dene.',
};
