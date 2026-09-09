import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

/// Layar "Akun" sisi Responden — frame Figma `respondent-profil`
/// (get_design_context, node `89:4765`, fileKey `sh3QGUb2P6BHPTIbtxXjOT`).
/// Dibangun 2026-09-09 dengan MELOMPAT duluan dari urutan standar
/// (`respondent-activity`/`wallet`/`edit-profile`) atas permintaan user
/// eksplisit — biar bisa dites logout + gonta-ganti akun peneliti/responden,
/// yang sebelumnya nggak bisa dites sama sekali karena logout cuma ada di
/// Profil, dan Profil sisi respondent belum ada.
///
/// Strukturnya SENGAJA nyontek `ResearcherProfileScreen` abis-abisan (bukan
/// nulis dari nol) — pola app-bar/header-card/menu-card/logout-button udah
/// established & konsisten dipakai lintas role, cuma isi card yang beda per
/// role (lihat perbedaan didokumentasikan di tiap widget di bawah).
class RespondentProfileScreen extends ConsumerWidget {
  const RespondentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

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
                  ? const _NoSessionFallback()
                  : _ProfileBody(
                      user: user,
                      // Update 2026-09-09: `respondent-edit-profile` (node
                      // 77:3214) BELUM digarap — jadi baik pensil di header
                      // card maupun "Edit Profil" di menu list masih stub
                      // dulu, sama pola kayak menu-row lain yang nunggu
                      // frame-nya digarap.
                      onEditProfilStub: () => _showStub(
                        context,
                        'Edit Profil (isi Data Responden) nyusul pas frame respondent-edit-profile digarap.',
                      ),
                      onMenuStub: (label) => _showStub(
                        context,
                        '$label belum ada frame Figma-nya — di luar cakupan 16 frame MVP.',
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
          SurvMarktNavItem(icon: Icons.explore_outlined, label: 'Discover'),
          SurvMarktNavItem(icon: Icons.history_rounded, label: 'Aktivitas'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.respondentHome);
            return;
          }
          if (index == 1) {
            // Update 2026-09-09: bukan stub lagi — `respondent-activity`
            // (node 77:2902) udah ditranslate. Lihat CLAUDE.md.
            context.push(AppRoutes.respondentActivity);
            return;
          }
          // Update 2026-09-09: `respondent-wallet` (node 77:3000) belum
          // ditranslate — stub, pola sama kayak di
          // `respondent_discover_screen.dart`.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layar ini nyusul — belum ditranslate dari Figma.')),
          );
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
    required this.onEditProfilStub,
    required this.onMenuStub,
    required this.onNotifikasiTap,
    required this.onUbahPasswordTap,
    required this.onLogout,
  });

  final UserEntity user;
  final VoidCallback onEditProfilStub;
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
          _ProfileHeaderCard(user: user, onEditTap: onEditProfilStub),
          const SizedBox(height: AppSpacing.md),
          _CompletionBanner(user: user),
          const SizedBox(height: AppSpacing.md),
          _InfoAkunCard(user: user),
          const SizedBox(height: AppSpacing.md),
          _DataRespondenCard(user: user),
          const SizedBox(height: AppSpacing.md),
          _MenuListCard(
            onEditProfil: onEditProfilStub,
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

  /// Sama persis pola avatar inisial kayak `ResearcherProfileScreen` — Figma
  /// frame ini pakai foto stok "Budiono Siregar" yang bakal selalu sama
  /// nggak peduli akun mana yang login, jadi diganti inisial live per-user
  /// (deviasi disadari, konsisten sama sisi researcher).
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
      // Fix 2026-09-08 (lihat catatan sama di `researcher_profile_screen.
      // dart`): `Stack.alignment: Alignment.topCenter` WAJIB biar Column
      // non-`Positioned` di dalamnya nggak nempel kiri.
      child: Stack(
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

/// Banner "Lengkapi profil kamu" — Figma nampilin teks statis "Profil 40%"
/// dengan progress bar ~40% terisi, tapi 4 field "Data Responden" di frame
/// yang SAMA semuanya nampilin "Belum diisi" (alias 0/4 keisi). Update
/// 2026-09-09: dua hal itu nggak konsisten satu sama lain di mockup-nya
/// sendiri — disimpulkan angka "40%" cuma placeholder statis Figma, BUKAN
/// nilai yang sengaja di-hardcode buat ditiru. Jadi di implementasi ini
/// persentase DIHITUNG LIVE dari berapa banyak dari 4 field
/// (gender/age/respondentStatus/domicile) yang udah keisi — konsisten sama
/// prinsip proyek "angka yang bisa dihitung dari state, jangan didobel jadi
/// mock kedua yang bisa nggak sinkron" (sama kayak stat card di
/// researcher-profile).
class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.user});

  final UserEntity user;

  int get _filledCount => [
        user.gender,
        user.age,
        user.respondentStatus,
        user.domicile,
      ].where((v) => v.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final percent = _filledCount / 4;
    if (percent >= 1.0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        border: Border.all(color: AppColors.amber100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.amber500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lengkapi profil kamu',
                  style: AppTypography.labelSemibold.copyWith(fontSize: 13, color: AppColors.slate900),
                ),
              ),
              Text(
                'Profil ${(percent * 100).round()}%',
                style: AppTypography.monoSmall.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lengkapi agar bisa mengerjakan survei',
            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.amber100,
              valueColor: const AlwaysStoppedAnimation(AppColors.amber500),
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
    // Beda dari `ResearcherProfileScreen._InfoAkunCard`: cuma 2 baris (Email
    // + Nomor HP), TANPA Institusi — sesuai frame Figma `respondent-profil`
    // yang emang nggak punya baris itu (institusi konsepnya khusus peneliti).
    final rows = [
      ('EMAIL', user.email),
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

/// Card baru "Data Responden" — nggak ada padanannya di sisi researcher.
/// Nampung 4 field matching (gender/age/respondentStatus/domicile) yang cuma
/// bisa BENERAN diisi lewat `respondent-edit-profile` (belum digarap) —
/// jadi di sini murni tampilan READ-ONLY. Tiap baris kosong ('') nampilin
/// teks italic "Belum diisi" + titik indikator abu-abu (bukan hijau),
/// konsisten sama gambaran di screenshot Figma (semua field kosong di
/// mockup-nya).
class _DataRespondenCard extends StatelessWidget {
  const _DataRespondenCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('JENIS KELAMIN', user.gender),
      ('USIA', user.age),
      ('STATUS', user.respondentStatus),
      ('DOMISILI', user.domicile),
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
            'MATCHING',
            style: AppTypography.eyebrowMuted.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
          ),
          const SizedBox(height: 2),
          Text(
            'Data Responden',
            style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: AppTypography.monoSmall.copyWith(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.slate400),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: rows[i].$2.isEmpty ? AppColors.slate400 : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        rows[i].$2.isEmpty ? 'Belum diisi' : rows[i].$2,
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 13,
                          color: rows[i].$2.isEmpty ? AppColors.slate400 : AppColors.slate900,
                          fontStyle: rows[i].$2.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
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
