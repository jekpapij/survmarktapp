import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
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
            // Update 2026-09-08: pakai `SurvMarktAppBar` reusable (dulunya
            // `_AppBar` privat di sini, diekstrak ke `core/widgets/` biar
            // dipakai ulang persis sama di `create_survey_screen.dart`).
            // Bell icon beneran buka layar "Notifikasi" (`context.push`
            // biar tombol back natural balik ke sini), bukan stub SnackBar
            // lagi — lihat CLAUDE.md soal fitur notifikasi self-designed.
            SurvMarktAppBar(
              eyebrow: 'DASHBOARD',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
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
          // Update 2026-09-08: tab "Buat Survei" (index 1) sekarang beneran
          // buka layar `create-survey` (`context.push` biar tombol back di
          // layar itu balik natural ke sini).
          if (index == 1) {
            context.push(AppRoutes.createSurvey);
            return;
          }
          // Update 2026-09-08: tab "Wallet" (index 2) sekarang beneran
          // buka layar `researcher-wallet`.
          if (index == 2) {
            context.push(AppRoutes.researcherWallet);
            return;
          }
          // Update 2026-09-08: tab Profil (index 3) sekarang beneran buka
          // layar `researcher-profile` (bukan logout-langsung-hack lagi —
          // tombol Logout beneran sekarang ada DI layar itu, sesuai Figma).
          context.push(AppRoutes.researcherProfile);
        },
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
