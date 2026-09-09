import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../widgets/admin_app_bar.dart';

/// Layar "Akun" Admin — frame Figma `admin-profil` (get_design_context, node
/// `89:4492`). Strukturnya nyontek `RespondentProfileScreen`/
/// `ResearcherProfileScreen` abis-abisan (pola app-bar/header-card/
/// menu-card/logout-button udah established lintas role).
///
/// **Deviasi disadari (avatar + nama + email):** Figma pakai foto stok +
/// teks statis "Admin Utama"/"admin@survmarkt.id" — diganti avatar inisial
/// LIVE + `user.name`/`user.email` dari `authNotifierProvider` (pola PERSIS
/// sama kayak deviasi avatar di profil researcher/respondent), biar
/// konsisten kalau suatu saat ada >1 akun admin dummy. "ID Admin: ADM-001"
/// TETEP statis — di scope MVP ini cuma ada 1 akun admin (nggak ada alur
/// manajemen banyak admin/ID admin beneran), jadi placeholder ID ini aman
/// di-hardcode (beda dari nama/email yang emang representasi user beneran).
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AdminAppBar(
              eyebrow: 'AKUN',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: user == null
                  ? const _NoSessionFallback()
                  : _ProfileBody(
                      user: user,
                      onMenuStub: (label) => _showStub(
                        context,
                        '$label belum ada frame Figma-nya — di luar cakupan MVP.',
                      ),
                      onNotifikasiTap: () => context.push(AppRoutes.notifications),
                      onUbahPasswordTap: () => context.push(AppRoutes.changePassword),
                      onLogout: () {
                        ref.read(authNotifierProvider.notifier).logout();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Berhasil logout.')));
                        context.go(AppRoutes.login);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 3,
        items: const [
          SurvMarktNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Withdrawal'),
          SurvMarktNavItem(icon: Icons.fact_check_outlined, label: 'Audit'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Akun'),
        ],
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.adminHome);
            return;
          }
          if (index == 1) {
            context.push(AppRoutes.adminWithdrawal);
            return;
          }
          context.push(AppRoutes.adminAuditLog);
        },
      ),
    );
  }

  static void _showStub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NoSessionFallback extends StatelessWidget {
  const _NoSessionFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 40, color: AppColors.slate400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sesi tidak ditemukan. Silakan login ulang.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Ke Halaman Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.onMenuStub,
    required this.onNotifikasiTap,
    required this.onUbahPasswordTap,
    required this.onLogout,
  });

  final UserEntity user;
  final ValueChanged<String> onMenuStub;
  final VoidCallback onNotifikasiTap;
  final VoidCallback onUbahPasswordTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeaderCard(user: user),
          const SizedBox(height: AppSpacing.md),
          _AccountInfoCard(user: user),
          const SizedBox(height: AppSpacing.md),
          _MenuListCard(
            onEditProfil: () => onMenuStub('Edit Profil'),
            onUbahPassword: onUbahPasswordTap,
            onNotifikasi: onNotifikasiTap,
            onBantuan: () => onMenuStub('Bantuan'),
            onSyaratKetentuan: () => onMenuStub('Syarat & Ketentuan'),
          ),
          const SizedBox(height: AppSpacing.md),
          _LogoutButton(onTap: onLogout),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.user});

  final UserEntity user;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: AppColors.primary900.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary100,
            child: Text(
              _initials,
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.primary900,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: AppTypography.monoSmall.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(
              'Administrator',
              style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amber500),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('EMAIL', user.email),
      ('ID ADMIN', 'ADM-001'),
    ];

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
          for (final row in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.$1, style: AppTypography.eyebrowMuted.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(row.$2, style: AppTypography.monoSmall.copyWith(fontSize: 13, color: AppColors.slate900)),
              ],
            ),
            if (row != rows.last) const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.primary100),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuListCard extends StatelessWidget {
  const _MenuListCard({
    required this.onEditProfil,
    required this.onUbahPassword,
    required this.onNotifikasi,
    required this.onBantuan,
    required this.onSyaratKetentuan,
  });

  final VoidCallback onEditProfil;
  final VoidCallback onUbahPassword;
  final VoidCallback onNotifikasi;
  final VoidCallback onBantuan;
  final VoidCallback onSyaratKetentuan;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.edit_outlined, 'Edit Profil', onEditProfil),
      (Icons.lock_outline_rounded, 'Ubah Password', onUbahPassword),
      (Icons.notifications_none_rounded, 'Notifikasi', onNotifikasi),
      (Icons.help_outline_rounded, 'Bantuan', onBantuan),
      (Icons.description_outlined, 'Syarat & Ketentuan', onSyaratKetentuan),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: AppColors.primary900.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items) ...[
            InkWell(
              onTap: item.$3,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                child: Row(
                  children: [
                    Icon(item.$1, size: 18, color: AppColors.slate600),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(item.$2, style: AppTypography.bodyMedium.copyWith(color: AppColors.slate900, fontSize: 14)),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.slate400),
                  ],
                ),
              ),
            ),
            if (item != items.last) const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md, color: AppColors.primary100),
          ],
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          textStyle: AppTypography.buttonText.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}
