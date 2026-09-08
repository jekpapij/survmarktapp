import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';

/// Layar "Notifikasi" — self-designed (nggak ada frame Figma referensi
/// buat ini, lihat catatan di `NotificationEntity`), ngikutin design
/// system SurvMarkt yang udah ada (app-bar indigo900 sama persis kayak
/// `researcher_dashboard_screen.dart`, card/warna/tipografi dari
/// `core/constants/`). Data (mock) diambil dari `notificationsProvider` —
/// `AsyncValue.when` di bawah nanganin Loading/Error/Success (CPMK 3).
///
/// Dibuka sebagai PAGE biasa (`context.push`), bukan modal — beda dari
/// "Kelola Survey" yang emang logic aslinya popup. Notifikasi konsepnya
/// list yang bisa discroll panjang + punya aksi "tandai semua dibaca" di
/// app-bar, jadi lebih natural sebagai layar penuh (dan dipakai lintas role
/// nanti, bukan spesifik 1 fitur kayak modal survey).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBar(
              hasUnread: notificationsAsync.maybeWhen(
                data: (list) => list.any((n) => !n.isRead),
                orElse: () => false,
              ),
              onMarkAllRead: () async {
                await ref.read(notificationRepositoryProvider).markAllAsRead();
                ref.invalidate(notificationsProvider);
              },
            ),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.indigoAccent),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.slate400),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gagal memuat notifikasi.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(notificationsProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (notifications) => _NotificationList(notifications: notifications),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.hasUnread, required this.onMarkAllRead});

  final bool hasUnread;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      color: AppColors.primary900,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Notifikasi',
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasUnread)
            TextButton(
              onPressed: onMarkAllRead,
              child: Text(
                'Tandai semua',
                style: AppTypography.monoSmall.copyWith(color: const Color(0xFFA5B4FC), fontSize: 12),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.notifications});

  final List<NotificationEntity> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.slate400),
              SizedBox(height: AppSpacing.sm),
              Text('Belum ada notifikasi.', style: AppTypography.bodyMedium),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationTile(
          notification: notification,
          onTap: notification.isRead
              ? null
              : () async {
                  await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
                  ref.invalidate(notificationsProvider);
                },
        );
      },
    );
  }
}
