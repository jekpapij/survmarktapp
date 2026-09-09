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
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/researcher_providers.dart';

/// Layar "Akun" — frame Figma `researcher-profile` (get_design_context, node
/// 77:2331). Data akun (nama/email/HP/role/institusi) diambil LIVE dari
/// `authNotifierProvider` (user yang lagi login), BUKAN dummy statis kayak
/// contoh "Budi Setiawan" di Figma — karena layar ini emang representasi
/// akun yang beneran login (dummy-nya dari `AuthRemoteDataSourceMock`, lihat
/// CLAUDE.md).
///
/// Deviasi disadari: 2 stat card ("Survey Dibuat"/"Total Responden") di
/// Figma nilainya statis 12/1.240 — di implementasi ini DITURUNIN dari
/// `researcherDashboardProvider` (bukan angka mock kedua yang bisa nggak
/// sinkron sama dashboard, prinsip yang sama kayak saldo wallet vs
/// dashboard). "Survey Dibuat" pakai `stats.totalSurvey` yang udah ada,
/// "Total Responden" dihitung live dari `sum(respondentCount)` semua survey
/// yang lagi tampil.
class ResearcherProfileScreen extends ConsumerWidget {
  const ResearcherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final dashboardAsync = ref.watch(researcherDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SurvMarktAppBar(
              eyebrow: 'AKUN',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: user == null
                  // Jaga-jaga kalau layar ini kebuka tanpa sesi aktif (nggak
                  // ada route-guard beneran di project ini — di luar scope
                  // CPMK 3) — daripada nampilin card kosong/null-error.
                  ? const _NoSessionFallback()
                  : _ProfileBody(
                      user: user,
                      dashboardAsync: dashboardAsync,
                      // Update 2026-09-08: bukan stub lagi — beneran buka
                      // layar "Edit Profil" (frame Figma
                      // `researcher-profile-edit`, lihat CLAUDE.md).
                      onEditProfil: () => context.push(AppRoutes.researcherProfileEdit),
                      onMenuStub: (label) => _showStub(
                        context,
                        '$label belum ada frame Figma-nya — di luar cakupan 16 frame MVP.',
                      ),
                      onNotifikasiTap: () => context.push(AppRoutes.notifications),
                      // Update 2026-09-08: bukan stub lagi — beneran buka
                      // layar "Ubah Password" (self-designed, mock, lihat
                      // CLAUDE.md).
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
          SurvMarktNavItem(icon: Icons.home_rounded, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.add_circle_outline, label: 'Buat Survei'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.researcherHome);
            return;
          }
          if (index == 1) {
            context.push(AppRoutes.createSurvey);
            return;
          }
          context.push(AppRoutes.researcherWallet);
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
            const Text(
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
    required this.dashboardAsync,
    required this.onEditProfil,
    required this.onMenuStub,
    required this.onNotifikasiTap,
    required this.onUbahPasswordTap,
    required this.onLogout,
  });

  final UserEntity user;
  final AsyncValue<ResearcherDashboardData> dashboardAsync;
  final VoidCallback onEditProfil;
  final ValueChanged<String> onMenuStub;
  final VoidCallback onNotifikasiTap;
  final VoidCallback onUbahPasswordTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    // Update 2026-09-08: cuma butuh 2 angka ringkas (bukan seluruh state
    // Loading/Error kayak layar utama) — dashboard-nya sendiri udah nunjukin
    // ketiga state CPMK 3 lengkap di layar Dashboard. `maybeWhen` di sini
    // sengaja dipakai buat fallback ringan ('...') pas masih loading/error,
    // biar sisa layar (profil, yang datanya udah sinkron dari auth state)
    // tetep kebuka normal tanpa nunggu network call kedua ini.
    final surveyDibuat = dashboardAsync.maybeWhen(
      data: (d) => '${d.stats.totalSurvey}',
      orElse: () => '...',
    );
    final totalResponden = dashboardAsync.maybeWhen(
      data: (d) => Formatters.thousands(
        d.surveys.fold<int>(0, (sum, s) => sum + s.respondentCount),
      ),
      orElse: () => '...',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeaderCard(user: user, onEditTap: onEditProfil),
          const SizedBox(height: AppSpacing.md),
          _InfoAkunCard(user: user),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: MetricCard(label: 'SURVEY DIBUAT', value: surveyDibuat)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: MetricCard(label: 'TOTAL RESPONDEN', value: totalResponden)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MenuListCard(
            onEditProfil: onEditProfil,
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
  const _ProfileHeaderCard({required this.user, required this.onEditTap});

  final UserEntity user;
  final VoidCallback onEditTap;

  /// Inisial dari nama (mis. "Budi Setiawan" -> "BS", "Admin" -> "A") —
  /// dipakai sebagai avatar. Deviasi disadari dari Figma: frame aslinya
  /// pakai foto profil (asset stok "Budi Setiawan") yang bakal SELALU sama
  /// nggak peduli akun siapa yang login — nggak cocok sama akun ini yang
  /// datanya live per-user (dummy peneliti/responden/admin beda-beda nama).
  /// Avatar inisial otomatis ngikutin nama akun mana pun yang login,
  /// termasuk nanti kalau ada upload foto beneran (bisa jadi fallback-nya).
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
      child: Stack(
        // Fix 2026-09-08 (laporan user): "card foto profil mencong ke
        // kiri". Penyebab: `Column` non-`Positioned` di dalam `Stack`
        // shrink-wrap ke lebar children terlebarnya (BUKAN otomatis full
        // lebar Stack kayak Column biasa) — jadi meski `crossAxisAlignment`
        // Column-nya `center` (default), si Column ITU SENDIRI ditempatkan
        // di `Stack.alignment` default (`topStart` = kiri atas), bukan
        // tengah. `alignment: Alignment.topCenter` nge-center Column secara
        // horizontal (tetap nempel atas biar konsisten sama posisi pensil
        // di `Positioned(top: -8, right: -8)`).
        alignment: Alignment.topCenter,
        children: [
          Column(
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
                decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text(
                  user.role.label,
                  style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.indigoAccent),
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.slate600),
              tooltip: 'Edit Profil',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoAkunCard extends StatelessWidget {
  const _InfoAkunCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('EMAIL', user.email),
      ('INSTITUSI', user.institution.isEmpty ? '-' : user.institution),
      ('NOMOR HP', user.phone.isEmpty ? '-' : user.phone),
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
          Text(
            'AKUN',
            style: AppTypography.eyebrowMuted.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
          ),
          const SizedBox(height: 2),
          Text(
            'Informasi Akun',
            style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rows[i].$1,
                    style: AppTypography.monoSmall.copyWith(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.slate400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rows[i].$2,
                    style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate900),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1) const Divider(color: AppColors.primary100, height: 1),
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
    final rows = [
      (Icons.edit_outlined, 'Edit Profil', onEditProfil),
      (Icons.lock_outline, 'Ubah Password', onUbahPassword),
      (Icons.notifications_outlined, 'Notifikasi', onNotifikasi),
      (Icons.help_outline, 'Bantuan', onBantuan),
      (Icons.description_outlined, 'Syarat & Ketentuan', onSyaratKetentuan),
    ];

    return Container(
      width: double.infinity,
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
          for (var i = 0; i < rows.length; i++) ...[
            _MenuRow(icon: rows[i].$1, label: rows[i].$2, onTap: rows[i].$3),
            if (i != rows.length - 1) const Divider(color: AppColors.primary100, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.slate900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate900),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate400),
            ],
          ),
        ),
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
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: Text(
          'Logout',
          style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger),
        ),
      ),
    );
  }
}
