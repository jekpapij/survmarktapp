import 'package:equatable/equatable.dart';

/// Update 2026-09-08: fitur "Notifikasi" nggak punya frame Figma khusus
/// (cuma icon bell yang tersebar di app-bar tiap role + beberapa baris menu
/// "Notifikasi" yang sebenernya bagian dari Profil, bukan notification
/// center beneran) — jadi di-self-design ngikutin design system SurvMarkt
/// yang udah ada (warna/tipografi `core/constants/`), bukan translate 1:1
/// dari Figma kayak fitur lain. Lihat CLAUDE.md.
///
/// Ditaruh di `features/notifications/` TERPISAH dari `features/researcher/`
/// (walau baru dipakai dari dashboard researcher dulu) karena notifikasi itu
/// konsepnya lintas-role — bell icon juga bakal ada di app-bar respondent &
/// admin nanti, jadi 1 modul ini dipakai ulang bukan diduplikasi per role.
enum NotificationType { payment, survey, respondent, system }

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, createdAt, isRead];
}
