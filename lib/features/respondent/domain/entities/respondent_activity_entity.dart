import 'package:equatable/equatable.dart';

import '../../../../core/utils/formatters.dart';

/// Tiga status hasil isi survei — frame Figma `respondent-activity`
/// (get_design_context, node `77:2902`), sama daftar status yang udah
/// dicatet duluan di CLAUDE.md "Progress desain via Figma AI prompting"
/// (tabel ringkasan 16 frame, baris respondent: "tab Aktif/Riwayat, status
/// Menunggu Verifikasi/Diverifikasi/Ditolak").
enum ActivityStatus { menungguVerifikasi, diverifikasi, ditolak }

extension ActivityStatusX on ActivityStatus {
  String get label => switch (this) {
        ActivityStatus.menungguVerifikasi => 'Menunggu Verifikasi',
        ActivityStatus.diverifikasi => 'Diverifikasi',
        ActivityStatus.ditolak => 'Ditolak',
      };
}

/// Satu entri "aktivitas" — survei yang UDAH/LAGI disubmit responden. BEDA
/// dari `SurveyListingEntity` (Discover, katalog survei yang MASIH BISA
/// diisi) — entity ini representasi hasil submit yang statusnya nunggu
/// ditinjau peneliti/admin (lihat `RespondentRepository.
/// submitSurveyResponse`, dipanggil dari tombol "Isi Survei" di
/// `SurveyDetailModal`).
class RespondentActivityEntity extends Equatable {
  const RespondentActivityEntity({
    required this.id,
    required this.surveyTitle,
    required this.status,
    required this.submittedAt,
    required this.incentiveAmount,
  });

  final String id;
  final String surveyTitle;
  final ActivityStatus status;
  final DateTime submittedAt;
  final int incentiveAmount;

  /// `DateTime(2026, 8, 28)` -> `Dikirim 28 Agustus 2026` — teks PERSIS
  /// kayak di Figma, nama bulan PENUH (`Formatters.longDate`, beda dari
  /// `shortDate` yang disingkat "Agu").
  String get submittedLabel => 'Dikirim ${Formatters.longDate(submittedAt)}';

  @override
  List<Object?> get props => [id, surveyTitle, status, submittedAt, incentiveAmount];
}
