import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';
import '../providers/researcher_providers.dart';
import '../widgets/kelola_survey_modal.dart';
import '../widgets/survey_progress_card.dart';

/// Dashboard Researcher — frame Figma `researcher-dashboard` (get_design_
/// context, node 77:2446). Data (stats + list survey) diambil dari
/// `researcherDashboardProvider` (mock, lihat CLAUDE.md soal keputusan
/// mock/dummy scope-semua-fitur) — `AsyncValue.when` di bawah otomatis
/// nanganin ketiga state Loading/Error/Success yang diminta rubrik CPMK 3.
class ResearcherDashboardScreen extends ConsumerWidget {
  const ResearcherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(researcherDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Update 2026-09-08: bell icon sekarang beneran buka layar
            // "Notifikasi" (`context.push` biar tombol back natural balik
            // ke sini), bukan stub SnackBar lagi — lihat CLAUDE.md soal
            // fitur notifikasi yang di-self-design (nggak ada frame Figma).
            _AppBar(onBellTap: () => context.push(AppRoutes.notifications)),
            Expanded(
              child: dashboardAsync.when(
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
                          'Gagal memuat data dashboard.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(researcherDashboardProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (dashboard) => _DashboardBody(
                  stats: dashboard.stats,
                  surveys: dashboard.surveys,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 0,
        items: const [
          SurvMarktNavItem(icon: Icons.home_rounded, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.add_circle_outline, label: 'Buat Survei'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) return;
          // Update 2026-09-08: tab Profil (index 3) sengaja udah bisa
          // logout beneran walau layarnya sendiri belum dibangun — Profil
          // emang rencananya jadi tempat tombol logout (lihat CLAUDE.md
          // "Bottom nav per role"), dan user butuh cara buat balik ke
          // login pas testing (session ke-cache via "Ingat Saya"/secure
          // storage, jadi splash bakal auto-login terus tanpa ini).
          if (index == 3) {
            ref.read(authNotifierProvider.notifier).logout();
            _showStub(context, 'Profil belum tersedia — logout dulu ya.');
            context.go(AppRoutes.login);
            return;
          }
          const labels = ['Dashboard', 'Buat Survei', 'Wallet', 'Profil'];
          _showStub(context, '${labels[index]} belum tersedia.');
        },
      ),
    );
  }

  void _showStub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AppBar extends ConsumerWidget {
  const _AppBar({required this.onBellTap});

  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Update 2026-09-08: badge titik merah dihitung dari
    // `unreadNotificationCountProvider` (turunan dari `notificationsProvider`
    // yang sama, bukan fetch terpisah) — lihat CLAUDE.md.
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.primary900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DASHBOARD',
                style: AppTypography.eyebrow.copyWith(
                  color: const Color(0xFFA5B4FC),
                  fontSize: 10,
                ),
              ),
              Text(
                'SurvMarkt',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 18, color: Colors.white),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary900, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats, required this.surveys});

  final DashboardStatsEntity stats;
  final List<SurveyEntity> surveys;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: MetricCard(label: 'TOTAL SURVEY', value: '${stats.totalSurvey}')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetricCard(label: 'PENGELUARAN', value: Formatters.rupiahShort(stats.totalExpense)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'TARGET RESPONDEN',
                  value: Formatters.thousands(stats.targetResponden),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: MetricCard(label: 'SALDO', value: Formatters.rupiahShort(stats.saldo))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'KELOLA',
            style: AppTypography.eyebrowMuted.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Progress Survey',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.slate900,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Klik detail survei untuk mengelola',
            style: AppTypography.monoSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final survey in surveys) ...[
            SurveyProgressCard(
              // Update 2026-09-08: dibuka sebagai modal overlay beneran
              // (`showModalBottomSheet`), BUKAN route/page baru — sesuai
              // konfirmasi eksplisit user (lihat CLAUDE.md soal
              // detail-modal-kelola-survei).
              survey: survey,
              onTap: () => showKelolaSurveyModal(context, survey),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
