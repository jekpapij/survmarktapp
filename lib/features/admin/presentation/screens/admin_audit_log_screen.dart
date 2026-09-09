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
import '../../domain/entities/audit_log_entry_entity.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar.dart';

/// Layar "Audit Log" Admin — frame Figma `admin-audit-log` (get_design_
/// context, node `86:170`). 4 filter chip (Semua/Survey/Withdrawal/Akun)
/// DIFILTER LOKAL dari 1 fetch `adminAuditLogProvider` — `null` = "Semua".
///
/// Label tab bottom-nav dipilih "Audit" (bukan "Audit Log") biar konsisten
/// sama 3 frame Figma admin LAIN yang nunjukin bottom-nav (dashboard/
/// withdrawal/profil semua nulis "Audit" — cuma frame audit-log ITU SENDIRI
/// yang beda nulis "Audit Log" buat label tab aktifnya sendiri). Dianggap
/// sama kayak kasus label "Buat Survei" vs "Create Survey" — konsisten
/// lintas layar menang, bukan niru literal per-frame.
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  AuditCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final auditLogAsync = ref.watch(adminAuditLogProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AdminAppBar(
              eyebrow: 'AUDIT LOG',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: auditLogAsync.when(
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
                          'Gagal memuat audit log.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(adminAuditLogProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (entries) => _AuditLogBody(
                  entries: entries,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (category) => setState(() => _selectedCategory = category),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 2,
        items: const [
          SurvMarktNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Withdrawal'),
          SurvMarktNavItem(icon: Icons.fact_check_outlined, label: 'Audit'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Akun'),
        ],
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.adminHome);
            return;
          }
          if (index == 1) {
            context.push(AppRoutes.adminWithdrawal);
            return;
          }
          context.push(AppRoutes.adminProfile);
        },
      ),
    );
  }
}

class _AuditLogBody extends StatelessWidget {
  const _AuditLogBody({
    required this.entries,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final List<AuditLogEntryEntity> entries;
  final AuditCategory? selectedCategory;
  final ValueChanged<AuditCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == null
        ? entries
        : entries.where((e) => e.category == selectedCategory).toList();
    final sorted = List.of(filtered)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryChips(selected: selectedCategory, onChanged: onCategoryChanged),
          const SizedBox(height: AppSpacing.md),
          _SoftDeleteBanner(),
          const SizedBox(height: AppSpacing.md),
          if (sorted.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 40, color: AppColors.slate400),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Belum ada aktivitas di kategori ini.', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            )
          else
            for (final entry in sorted) ...[
              _AuditCard(entry: entry),
              if (entry != sorted.last) const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onChanged});

  final AuditCategory? selected;
  final ValueChanged<AuditCategory?> onChanged;

  static const _labels = {
    null: 'Semua',
    AuditCategory.survey: 'Survey',
    AuditCategory.withdrawal: 'Withdrawal',
    AuditCategory.akun: 'Akun',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in _labels.entries) ...[
            GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: entry.key == selected ? AppColors.indigoAccent : Colors.white,
                  border: Border.all(color: entry.key == selected ? AppColors.indigoAccent : AppColors.primary100),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  entry.value,
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: entry.key == selected ? Colors.white : AppColors.slate600,
                  ),
                ),
              ),
            ),
            if (entry.key != _labels.keys.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SoftDeleteBanner extends StatelessWidget {
  const _SoftDeleteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.indigoAccent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Aksi hapus (mis. survey) tercatat di sini sebagai soft-delete — datanya tetap tersimpan buat audit, bukan langsung hilang permanen dari sistem.',
              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.slate600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry});

  final AuditLogEntryEntity entry;

  (IconData, Color) get _iconAndColor => switch (entry.actionType) {
        AuditActionType.deleteSurvey => (Icons.delete_outline_rounded, AppColors.danger),
        AuditActionType.withdrawalApproved => (Icons.check_circle_outline_rounded, const Color(0xFF16A34A)),
        AuditActionType.roleChanged => (Icons.manage_accounts_outlined, AppColors.info),
        AuditActionType.surveyPaused => (Icons.pause_circle_outline_rounded, AppColors.amber500),
        AuditActionType.surveyClosed => (Icons.archive_outlined, AppColors.slate600),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.description,
                  style: AppTypography.labelSemibold.copyWith(fontSize: 13, color: AppColors.slate900),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.actorLabel,
                  style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.slate600),
                ),
                const SizedBox(height: 2),
                Text(
                  // Update: `Formatters.dateTimeShort` (bullet "•", pola
                  // konsisten dipakai lintas fitur) dipakai di sini — BUKAN
                  // niru literal format koma Figma ("31 Agu 2026, 14:20")
                  // — biar konsisten sama semua timestamp lain di app
                  // (notifikasi, transaksi wallet), pola sama kayak label
                  // "Buat Survei" yang menang atas versi literal per-frame.
                  Formatters.dateTimeShort(entry.timestamp),
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
