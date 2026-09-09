import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/withdrawal_request_entity.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar.dart';

/// Layar "Withdrawal" Admin — frame Figma `admin-withdrawal` (get_design_
/// context, node `86:52`). 3 tab (Pending/Disetujui/Ditolak) DIFILTER LOKAL
/// dari 1 list yang sama (`adminWithdrawalsProvider`) — bukan 3 fetch
/// terpisah, biar approve/reject 1 item otomatis mindahin dia ke tab lain
/// abis `ref.invalidate`, tanpa perlu sinkronin 3 list independen.
///
/// Approve/reject pola LOKAL `_busyIds` (Set<String>, bukan 1 bool global)
/// — beda dikit dari `_KelolaSurveyModalState._busy` (yang cuma nanganin
/// 1 survey per modal) karena di sini banyak card ditampilin SEKALIGUS
/// dalam 1 layar, jadi butuh tau card MANA yang lagi diproses (biar cuma
/// tombol di card itu yang disabled, bukan semua card).
class AdminWithdrawalScreen extends ConsumerStatefulWidget {
  const AdminWithdrawalScreen({super.key});

  @override
  ConsumerState<AdminWithdrawalScreen> createState() => _AdminWithdrawalScreenState();
}

class _AdminWithdrawalScreenState extends ConsumerState<AdminWithdrawalScreen> {
  WithdrawalStatus _selectedTab = WithdrawalStatus.pending;
  final Set<String> _busyIds = {};

  Future<void> _approve(WithdrawalRequestEntity withdrawal) async {
    setState(() => _busyIds.add(withdrawal.id));
    try {
      await ref.read(adminRepositoryProvider).approveWithdrawal(withdrawal.id);
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyetujui withdrawal: $e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(withdrawal.id));
    }
  }

  Future<void> _reject(WithdrawalRequestEntity withdrawal) async {
    setState(() => _busyIds.add(withdrawal.id));
    try {
      await ref.read(adminRepositoryProvider).rejectWithdrawal(withdrawal.id);
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menolak withdrawal: $e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(withdrawal.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalsAsync = ref.watch(adminWithdrawalsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AdminAppBar(
              eyebrow: 'WITHDRAWAL',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: withdrawalsAsync.when(
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
                          'Gagal memuat data withdrawal.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(adminWithdrawalsProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (withdrawals) => _WithdrawalBody(
                  withdrawals: withdrawals,
                  selectedTab: _selectedTab,
                  busyIds: _busyIds,
                  onTabChanged: (tab) => setState(() => _selectedTab = tab),
                  onApprove: _approve,
                  onReject: _reject,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 1,
        items: const [
          SurvMarktNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Withdrawal'),
          SurvMarktNavItem(icon: Icons.fact_check_outlined, label: 'Audit'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Akun'),
        ],
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.adminHome);
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

class _WithdrawalBody extends StatelessWidget {
  const _WithdrawalBody({
    required this.withdrawals,
    required this.selectedTab,
    required this.busyIds,
    required this.onTabChanged,
    required this.onApprove,
    required this.onReject,
  });

  final List<WithdrawalRequestEntity> withdrawals;
  final WithdrawalStatus selectedTab;
  final Set<String> busyIds;
  final ValueChanged<WithdrawalStatus> onTabChanged;
  final ValueChanged<WithdrawalRequestEntity> onApprove;
  final ValueChanged<WithdrawalRequestEntity> onReject;

  int _countFor(WithdrawalStatus status) => withdrawals.where((w) => w.status == status).length;

  @override
  Widget build(BuildContext context) {
    final filtered = withdrawals.where((w) => w.status == selectedTab).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _TabSegmented(
            selectedTab: selectedTab,
            countFor: _countFor,
            onChanged: onTabChanged,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 40, color: AppColors.slate400),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Belum ada withdrawal di tab ini.', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final withdrawal = filtered[index];
                    return _WithdrawalCard(
                      withdrawal: withdrawal,
                      colorIndex: withdrawals.indexOf(withdrawal),
                      busy: busyIds.contains(withdrawal.id),
                      onApprove: () => onApprove(withdrawal),
                      onReject: () => onReject(withdrawal),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TabSegmented extends StatelessWidget {
  const _TabSegmented({required this.selectedTab, required this.countFor, required this.onChanged});

  final WithdrawalStatus selectedTab;
  final int Function(WithdrawalStatus) countFor;
  final ValueChanged<WithdrawalStatus> onChanged;

  String _labelFor(WithdrawalStatus status) => switch (status) {
        WithdrawalStatus.pending => 'Pending',
        WithdrawalStatus.disetujui => 'Disetujui',
        WithdrawalStatus.ditolak => 'Ditolak',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: AppColors.primary100)),
      child: Row(
        children: [
          for (final status in WithdrawalStatus.values) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(status),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: status == selectedTab ? AppColors.indigoAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _labelFor(status),
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status == selectedTab ? Colors.white : AppColors.slate600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: status == selectedTab ? Colors.white.withValues(alpha: 0.2) : AppColors.primary50,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${countFor(status)}',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status == selectedTab ? Colors.white : AppColors.slate600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({
    required this.withdrawal,
    required this.colorIndex,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final WithdrawalRequestEntity withdrawal;
  final int colorIndex;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  // Figma nunjukin avatar bulat inisial dengan warna beda-beda per baris —
  // nggak nentuin skema warna spesifik per user, jadi dirotasi dari palet
  // tetap berdasarkan posisi withdrawal di list PENUH (bukan posisi di tab
  // yang lagi difilter, biar warna 1 withdrawal konsisten nggak
  // berubah-ubah pas dia pindah tab abis di-approve/reject).
  static const _palette = [
    AppColors.indigoAccent,
    AppColors.amber500,
    Color(0xFF16A34A),
    AppColors.info,
  ];

  String get _initials {
    final parts = withdrawal.respondentName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _palette[colorIndex % _palette.length];
    final isPending = withdrawal.status == WithdrawalStatus.pending;

    return Container(
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withValues(alpha: 0.15),
                child: Text(
                  _initials,
                  style: AppTypography.labelSemibold.copyWith(color: avatarColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      withdrawal.respondentName,
                      style: AppTypography.labelSemibold.copyWith(fontSize: 14, color: AppColors.slate900),
                    ),
                    Text(
                      withdrawal.destinationLabel,
                      style: AppTypography.monoSmall.copyWith(fontSize: 12, color: AppColors.slate600),
                    ),
                    Text(
                      Formatters.shortDate(withdrawal.requestDate),
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.rupiahFull(withdrawal.amount),
                style: AppTypography.monoNumber.copyWith(fontSize: 15, color: AppColors.primary900),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    ),
                    child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      disabledBackgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Setujui', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
