import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/respondent_activity_entity.dart';
import '../providers/respondent_providers.dart';

/// Aktivitas — frame Figma `respondent-activity` (get_design_context, node
/// `77:2902`). Data (daftar aktivitas) diambil dari
/// `respondentActivitiesProvider` (mock, `AsyncValue.when` di bawah nanganin
/// Loading/Error/Success — CPMK 3). Kartu di sini juga jadi tempat mendarat
/// abis tap "Isi Survei" di `SurveyDetailModal` (`respondent-discover`) —
/// lihat `submitSurveyResponse`.
///
/// **Deviasi/keputusan disadari — filter tab Aktif/Riwayat:** frame Figma
/// cuma nampilin SATU state (tab "Aktif" terpilih, isinya 5 kartu campur
/// SEMUA status: 3x Menunggu Verifikasi + 1x Diverifikasi + 1x Ditolak) —
/// nggak ada frame kedua buat isi tab "Riwayat", jadi logic pemisahannya
/// diputusin sendiri sesuai makna kata "Aktif" (masih diproses/belum
/// final) vs "Riwayat" (udah final/beres): **Aktif = status Menunggu
/// Verifikasi**, **Riwayat = Diverifikasi + Ditolak** (2 status akhir).
class RespondentActivityScreen extends ConsumerStatefulWidget {
  const RespondentActivityScreen({super.key});

  @override
  ConsumerState<RespondentActivityScreen> createState() => _RespondentActivityScreenState();
}

enum _ActivityTab { aktif, riwayat }

class _RespondentActivityScreenState extends ConsumerState<RespondentActivityScreen> {
  _ActivityTab _selectedTab = _ActivityTab.aktif;

  List<RespondentActivityEntity> _filter(List<RespondentActivityEntity> activities) {
    return activities.where((a) {
      final isAktif = a.status == ActivityStatus.menungguVerifikasi;
      return _selectedTab == _ActivityTab.aktif ? isAktif : !isAktif;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(respondentActivitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SurvMarktAppBar(
              eyebrow: 'AKTIVITAS',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            _SegmentedTabRow(
              selected: _selectedTab,
              onSelected: (tab) => setState(() => _selectedTab = tab),
            ),
            Expanded(
              child: activitiesAsync.when(
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
                          'Gagal memuat aktivitas.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(respondentActivitiesProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (activities) {
                  final filtered = _filter(activities);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 40, color: AppColors.slate400),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _selectedTab == _ActivityTab.aktif
                                  ? 'Belum ada survei yang lagi menunggu verifikasi.'
                                  : 'Belum ada riwayat survei yang beres diverifikasi.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ActivityCard(activity: filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 1,
        items: const [
          SurvMarktNavItem(icon: Icons.explore_outlined, label: 'Discover'),
          SurvMarktNavItem(icon: Icons.history_rounded, label: 'Aktivitas'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.respondentHome);
            return;
          }
          if (index == 3) {
            context.push(AppRoutes.respondentProfile);
            return;
          }
          // Update 2026-09-09: Wallet (`respondent-wallet`, node 77:3000)
          // belum ditranslate — stub sementara, pola sama kayak di layar
          // respondent lain.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layar ini nyusul — belum ditranslate dari Figma.')),
          );
        },
      ),
    );
  }
}

class _SegmentedTabRow extends StatelessWidget {
  const _SegmentedTabRow({required this.selected, required this.onSelected});

  final _ActivityTab selected;
  final ValueChanged<_ActivityTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.primary100)),
      ),
      child: Row(
        children: [
          Expanded(child: _TabItem(label: 'Aktif', isActive: selected == _ActivityTab.aktif, onTap: () => onSelected(_ActivityTab.aktif))),
          Expanded(child: _TabItem(label: 'Riwayat', isActive: selected == _ActivityTab.riwayat, onTap: () => onSelected(_ActivityTab.riwayat))),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 14, bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? AppColors.amber500 : Colors.transparent, width: 3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.amber500 : AppColors.slate400,
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final RespondentActivityEntity activity;

  /// Warna badge & nominal per status — nggak ada padanan persis di
  /// `AppColors` (Figma pakai green-50/600 & red-50/600 khusus buat status
  /// ini, beda dari `success`/`danger` global yang shade-nya beda), jadi
  /// literal `Color()` di sini, pola sama kayak badge "Segera Berakhir" di
  /// `survey_detail_modal.dart`. `menungguVerifikasi` pakai `AppColors.
  /// amber50` buat background karena KEBETULAN sama persis (#FFFBEB).
  (Color bg, Color fg) get _statusColors => switch (activity.status) {
        ActivityStatus.menungguVerifikasi => (AppColors.amber50, const Color(0xFFD97706)),
        ActivityStatus.diverifikasi => (const Color(0xFFECFDF5), const Color(0xFF059669)),
        ActivityStatus.ditolak => (const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors;
    final isDitolak = activity.status == ActivityStatus.ditolak;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: AppColors.primary900.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  activity.surveyTitle,
                  style: AppTypography.labelSemibold.copyWith(fontSize: 14, color: AppColors.slate900),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: activity.status.label,
                background: bg,
                foreground: fg,
                fontSize: 10,
                fontFamily: 'Inter',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.primary100, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Text(
                    activity.submittedLabel,
                    style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.slate400),
                  ),
                ],
              ),
              Text(
                Formatters.rupiahFull(activity.incentiveAmount),
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDitolak ? AppColors.slate400 : (activity.status == ActivityStatus.diverifikasi ? fg : AppColors.slate600),
                  decoration: isDitolak ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
