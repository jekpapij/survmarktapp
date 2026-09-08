import 'package:equatable/equatable.dart';

/// State machine survey — lihat CLAUDE.md "Keputusan produk penting":
/// `OPEN ⇄ PAUSED → CLOSED` (final), dari status manapun bisa jadi `deleted`
/// (soft delete, dikelola terpisah di audit log admin — nggak pernah muncul
/// di dashboard researcher biasa).
enum SurveyStatus { open, paused, closed, deleted }

/// Info tambahan yang ditampilin di baris bawah tiap survey card — beda-beda
/// tergantung status (deadline buat open/featured, kapan di-pause/lanjut,
/// kapan selesai buat closed). Dipisah dari [SurveyStatus] karena banyak
/// status bisa punya "meta-like" label tapi arti beda.
enum SurveyMetaKind { deadline, paused, resumed, completed }

/// Update 2026-09-08: field ditambah banyak buat nyakup detail modal
/// "Kelola Survey" (`get_design_context` node 77:2588) — durasi/insentif/
/// target/deadline/progress count/analytics. `progressPercent` yang tadinya
/// field mentah sekarang jadi GETTER dari `respondentCount`/`targetCount`
/// (1 sumber kebenaran, bukan 2 angka yang bisa nggak sinkron).
class SurveyEntity extends Equatable {
  const SurveyEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.durationMinutes,
    required this.incentiveAmount,
    required this.targetLabel,
    required this.deadlineDate,
    required this.respondentCount,
    required this.targetCount,
    required this.views,
    required this.conversionPercent,
    required this.metaKind,
    required this.metaText,
    this.featured = false,
    this.expiringSoon = false,
  });

  final String id;
  final String title;
  final String category;
  final SurveyStatus status;

  final int durationMinutes;

  /// Nominal mentah (Rupiah) — diformat pas ditampilin (`Formatters`).
  final int incentiveAmount;
  final String targetLabel;
  final DateTime deadlineDate;

  final int respondentCount;
  final int targetCount;

  final int views;
  final double conversionPercent;

  final SurveyMetaKind metaKind;
  final String metaText;

  /// Cuma relevan buat survey yang lagi `open` — lihat PROMPT_SPEC.md soal
  /// Featured Survey (monetisasi sekunder).
  final bool featured;
  final bool expiringSoon;

  /// 0-100, dipakai buat progress bar "X% Terisi" (dashboard card) & "X/Y
  /// (Z%)" (detail modal). Diturunin dari `respondentCount`/`targetCount`,
  /// bukan disimpen terpisah.
  int get progressPercent =>
      targetCount == 0 ? 0 : ((respondentCount / targetCount) * 100).round().clamp(0, 100);

  SurveyEntity copyWith({
    SurveyStatus? status,
    SurveyMetaKind? metaKind,
    String? metaText,
  }) {
    return SurveyEntity(
      id: id,
      title: title,
      category: category,
      status: status ?? this.status,
      durationMinutes: durationMinutes,
      incentiveAmount: incentiveAmount,
      targetLabel: targetLabel,
      deadlineDate: deadlineDate,
      respondentCount: respondentCount,
      targetCount: targetCount,
      views: views,
      conversionPercent: conversionPercent,
      metaKind: metaKind ?? this.metaKind,
      metaText: metaText ?? this.metaText,
      featured: featured,
      expiringSoon: expiringSoon,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        status,
        durationMinutes,
        incentiveAmount,
        targetLabel,
        deadlineDate,
        respondentCount,
        targetCount,
        views,
        conversionPercent,
        metaKind,
        metaText,
        featured,
        expiringSoon,
      ];
}
