import 'package:equatable/equatable.dart';

/// State machine survey — lihat CLAUDE.md "Keputusan produk penting":
/// `OPEN ⇄ PAUSED → CLOSED` (final), dari status manapun bisa jadi `deleted`
/// (soft delete, dikelola terpisah di audit log admin — nggak pernah muncul
/// di dashboard researcher biasa).
enum SurveyStatus { open, paused, closed, deleted }

/// Info tambahan yang ditampilin di baris bawah tiap survey card — beda-beda
/// tergantung status (deadline buat open/featured, kapan di-pause buat
/// paused, kapan selesai buat closed). Dipisah dari [SurveyStatus] karena
/// closed & open sama-sama bisa punya "deadline-like" label tapi arti beda.
enum SurveyMetaKind { deadline, paused, completed }

class SurveyEntity extends Equatable {
  const SurveyEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.progressPercent,
    required this.views,
    required this.conversionPercent,
    required this.metaKind,
    required this.metaText,
    this.featured = false,
    this.expiringSoon = false,
  });

  final String id;
  final String title;
  final SurveyStatus status;

  /// 0-100, dipakai buat progress bar "X% Terisi".
  final int progressPercent;
  final int views;
  final double conversionPercent;

  final SurveyMetaKind metaKind;
  final String metaText;

  /// Cuma relevan buat survey yang lagi `open` — lihat PROMPT_SPEC.md soal
  /// Featured Survey (monetisasi sekunder).
  final bool featured;
  final bool expiringSoon;

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        progressPercent,
        views,
        conversionPercent,
        metaKind,
        metaText,
        featured,
        expiringSoon,
      ];
}
