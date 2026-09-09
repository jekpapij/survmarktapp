import 'package:equatable/equatable.dart';

/// 5 jenis aksi yang tercatat di `admin-audit-log` (node `86:170`) — nentuin
/// icon+warna badge tiap card (mapping lengkap ada di layer presentation,
/// domain sengaja nggak import `flutter/material` biar tetep murni Dart —
/// pola sama kayak `SurveyStatus`/`TransactionType` yang juga nggak nyimpen
/// warna/icon literal di entity).
enum AuditActionType { deleteSurvey, withdrawalApproved, roleChanged, surveyPaused, surveyClosed }

/// 4 filter chip di frame yang sama: Semua / Survey / Withdrawal / Akun.
/// Dipisah dari [AuditActionType] karena beberapa actionType beda bisa
/// masuk kategori filter yang sama (mis. `deleteSurvey`/`surveyPaused`/
/// `surveyClosed` semua masuk kategori "Survey").
enum AuditCategory { survey, withdrawal, akun }

extension AuditActionTypeX on AuditActionType {
  AuditCategory get category => switch (this) {
        AuditActionType.deleteSurvey => AuditCategory.survey,
        AuditActionType.withdrawalApproved => AuditCategory.withdrawal,
        AuditActionType.roleChanged => AuditCategory.akun,
        AuditActionType.surveyPaused => AuditCategory.survey,
        AuditActionType.surveyClosed => AuditCategory.survey,
      };
}

/// 1 baris riwayat aksi platform — Figma nampilin badge icon berwarna +
/// deskripsi bold + `"oleh {actor}"` + timestamp (`"31 Agu 2026, 14:20"`).
/// `actorLabel` disimpen APA ADANYA (String bebas, udah termasuk kata
/// "oleh" + role dalam kurung kalau ada, mis. `"oleh Andi Wijaya
/// (Peneliti)"`) — bukan dipecah jadi actorName+actorRole terpisah, karena
/// beberapa aksi (mis. `surveyClosed` otomatis kuota tercapai) aktornya
/// "Sistem", bukan user manapun.
class AuditLogEntryEntity extends Equatable {
  const AuditLogEntryEntity({
    required this.id,
    required this.actionType,
    required this.description,
    required this.actorLabel,
    required this.timestamp,
  });

  final String id;
  final AuditActionType actionType;
  final String description;
  final String actorLabel;
  final DateTime timestamp;

  AuditCategory get category => actionType.category;

  @override
  List<Object?> get props => [id, actionType, description, actorLabel, timestamp];
}
