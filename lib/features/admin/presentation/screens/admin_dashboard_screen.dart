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
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/entities/withdrawal_request_entity.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar.dart';

/// Dashboard Admin — frame Figma `admin-dashboard` (get_design_context, node
/// `88:52`). Data (stats + withdrawal pending) diambil dari
/// `adminDashboardProvider` — `AsyncValue.when` nanganin Loading/Error/
/// Success (CPMK 3), pola sama persis kayak `ResearcherDashboardScreen`.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AdminAppBar(
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
                          onPressed: () => ref.invalidate(adminDashboardProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (dashboard) => _DashboardBody(dashboard: dashboard),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 0,
        items: const [
          SurvMarktNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Withdrawal'),
          SurvMarktNavItem(icon: Icons.fact_check_outlined, label: 'Audit'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Akun'),
        ],
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            context.push(AppRoutes.adminWithdrawal);
            return;
          }
          if (index == 2) {
            context.push(AppRoutes.adminAuditLog);
            return;
          }
          context.push(AppRoutes.adminProfile);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});

  final AdminDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final stats = dashboard.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RevenueHeroCard(stats: stats),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: MetricCard(label: 'TOTAL TRANSAKSI', value: Formatters.thousands(stats.totalTransaksi)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetricCard(label: 'RATA-RATA/HARI', value: Formatters.rupiahShort(stats.rataRataPerHari)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatIconCard(
                  icon: Icons.groups_outlined,
                  label: 'PENGGUNA',
                  value: Formatters.thousands(stats.totalPengguna),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatIconCard(
                  icon: Icons.assignment_outlined,
                  label: 'SURVEY',
                  value: '${stats.surveyAktif}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatIconCard(
                  icon: Icons.schedule_rounded,
                  label: 'WITHDRAWAL',
                  value: '${dashboard.withdrawalPendingCount}',
                  valueColor: AppColors.amber500,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatIconCard(
                  icon: Icons.archive_outlined,
                  label: 'DITUTUP',
                  value: '${stats.surveyDitutupBulanIni}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ActionNeededCard(dashboard: dashboard),
        ],
      ),
    );
  }
}

class _RevenueHeroCard extends StatelessWidget {
  const _RevenueHeroCard({required this.stats});

  final AdminDashboardStatsEntity stats;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    const maxHeight = 56.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary900,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary900.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PENDAPATAN PLATFORM',
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA5B4FC),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.rupiahFull(stats.revenue),
            style: AppTypography.monoNumber.copyWith(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            'Bulan ini',
            style: AppTypography.monoSmall.copyWith(fontSize: 12, color: const Color(0xFFA5B4FC)),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: maxHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              // Update: loop INDEX-based (bukan bandingin `value != .last`)
              // — `weeklyChart` isinya `int` biasa, kalau kebetulan ada 2
              // hari dengan tinggi bar SAMA, perbandingan by-value bakal
              // salah nentuin elemen terakhir (skip/nambah spacer di tempat
              // yang salah). Pola sama kayak alasan "bug klasik" cari
              // entity lewat id, bukan value/posisi.
              children: [
                for (var i = 0; i < stats.weeklyChart.length; i++) ...[
                  Expanded(
                    child: Container(
                      height: maxHeight * (stats.weeklyChart[i].clamp(0, 100) / 100),
                      decoration: BoxDecoration(
                        color: AppColors.amber500,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (i != stats.weeklyChart.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < _dayLabels.length; i++) ...[
                Expanded(
                  child: Text(
                    _dayLabels[i],
                    textAlign: TextAlign.center,
                    style: AppTypography.monoSmall.copyWith(fontSize: 9, color: const Color(0xFFA5B4FC)),
                  ),
                ),
                if (i != _dayLabels.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat card ber-icon buat grid 2x2 — beda dikit dari `MetricCard` (yang
/// nggak punya icon di header), jadi ditulis widget khusus di sini (bukan
/// nambah parameter `icon` opsional ke `MetricCard` core yang dipakai
/// polos di researcher/respondent wallet — biar nggak nambah kompleksitas
/// widget shared buat 1 variasi yang cuma dipakai admin).
class _StatIconCard extends StatelessWidget {
  const _StatIconCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(color: Color(0x0A4F46E5), blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.indigoAccent),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.monoSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.monoNumber.copyWith(fontSize: 22, color: valueColor ?? AppColors.primary900),
          ),
        ],
      ),
    );
  }
}

class _ActionNeededCard extends StatelessWidget {
  const _ActionNeededCard({required this.dashboard});

  final AdminDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final preview = dashboard.pendingPreview;

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
          Text(
            'PERLU TINDAKAN',
            style: AppTypography.eyebrowMuted.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate600),
          ),
          const SizedBox(height: 2),
          Text(
            'Withdrawal Menunggu',
            style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Tidak ada withdrawal yang menunggu persetujuan saat ini.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
              ),
            )
          else
            for (final withdrawal in preview) ...[
              _PendingRow(withdrawal: withdrawal),
              if (withdrawal != preview.last) const Divider(height: AppSpacing.lg, color: AppColors.primary100),
            ],
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.withdrawal});

  final WithdrawalRequestEntity withdrawal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                withdrawal.respondentName,
                style: AppTypography.labelSemibold.copyWith(fontSize: 13, color: AppColors.slate900),
              ),
              Text(
                Formatters.rupiahFull(withdrawal.amount),
                style: AppTypography.monoSmall.copyWith(fontSize: 12, color: AppColors.slate600),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.adminWithdrawal),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tinjau',
                style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.indigoAccent),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.indigoAccent),
            ],
          ),
        ),
      ],
    );
  }
}
