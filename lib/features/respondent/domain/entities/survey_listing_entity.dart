import 'package:equatable/equatable.dart';

/// Kategori survei — dipakai buat filter chip di `respondent-discover`
/// ("Semua"/"Pendidikan"/"Kesehatan"/"Bisnis" persis nama chip di Figma).
/// `lainnya` sengaja disediakan buat survei yang nggak masuk 3 kategori
/// eksplisit itu (masih muncul di "Semua", cuma nggak ke-filter chip
/// manapun) — Figma cuma nunjukin 4 chip contoh, bukan daftar kategori
/// yang lengkap/final.
enum SurveyCategory { pendidikan, kesehatan, bisnis, lainnya }

extension SurveyCategoryX on SurveyCategory {
  String get label => switch (this) {
        SurveyCategory.pendidikan => 'Pendidikan',
        SurveyCategory.kesehatan => 'Kesehatan',
        SurveyCategory.bisnis => 'Bisnis',
        SurveyCategory.lainnya => 'Lainnya',
      };
}

/// Badge kecil di pojok kanan atas card (opsional) — beda dari
/// [SurveyCategory]. `matched` = "Cocok untukmu" (survei match sama profil
/// responden), `expiringSoon` = "Segera Berakhir" (deadline mepet). Nggak
/// semua survei punya badge (lihat `normal-survey-card` ke-2 di Figma,
/// "Evaluasi Layanan Kesehatan Digital", nggak ada badge sama sekali).
enum SurveyListingBadge { matched, expiringSoon }

/// Satu item survei yang bisa di-discover/diikuti responden — frame Figma
/// `respondent-discover` (get_design_context node 77:2719). SENGAJA entity
/// terpisah dari `SurveyEntity` (domain researcher), walau sama-sama
/// "survei": ini representasi dari sudut pandang RESPONDEN (listing buat
/// diikuti — insentif/durasi/kuota/deadline dari kacamata orang yang mau
/// isi), bukan dari sudut pandang peneliti yang mengelola (progress/views/
/// conversion/status open-paused-closed). Nyilangin import antar-feature
/// (`respondent/` depend ke `researcher/domain`) juga ngelanggar batas
/// modul Clean Architecture — jadi walau field-nya mirip, tetap dipisah.
class SurveyListingEntity extends Equatable {
  const SurveyListingEntity({
    required this.id,
    required this.title,
    required this.authorLabel,
    required this.category,
    required this.incentiveAmount,
    required this.durationMinutes,
    required this.respondentCount,
    required this.targetCount,
    required this.daysLeft,
    this.featured = false,
    this.badge,
  });

  final String id;
  final String title;

  /// Teks penulis/institusi apa adanya kayak di Figma — kadang "Nama •
  /// Institusi" (mis. "Dr. Rina Hartono • Universitas Indonesia"), kadang
  /// cuma nama organisasi ("Kemenkes RI"). Sengaja 1 string bebas (bukan
  /// dipaksa split name+institution) karena polanya nggak konsisten di
  /// data Figma-nya sendiri.
  final String authorLabel;

  final SurveyCategory category;

  /// Nominal mentah (Rupiah) — diformat pas ditampilin lewat
  /// `Formatters.rupiahFull`.
  final int incentiveAmount;
  final int durationMinutes;

  final int respondentCount;
  final int targetCount;

  /// Sisa hari sampai deadline. Disimpen sebagai int statis (BUKAN
  /// `DateTime` yang di-diff live dari `DateTime.now()` kayak
  /// `SurveyEntity.metaText` di sisi researcher) — sengaja lebih simpel di
  /// sini karena layar ini murni browse/listing (nggak ada aksi mutasi kayak
  /// pause/lanjutkan yang butuh countdown akurat detik-ke-detik), dan biar
  /// teksnya persis cocok sama contoh angka di Figma tanpa drift seiring
  /// waktu.
  final int daysLeft;

  final bool featured;
  final SurveyListingBadge? badge;

  String get durationLabel => '~$durationMinutes min';
  String get progressLabel => '$respondentCount/$targetCount resp';
  String get daysLeftLabel => '$daysLeft hari';

  @override
  List<Object?> get props => [
        id,
        title,
        authorLabel,
        category,
        incentiveAmount,
        durationMinutes,
        respondentCount,
        targetCount,
        daysLeft,
        featured,
        badge,
      ];
}
