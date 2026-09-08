import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../wallet/domain/entities/transaction_entity.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../wallet/presentation/widgets/transaction_tile.dart';

/// Wallet Researcher — frame Figma `researcher-wallet` (get_design_context,
/// node 77:2237). Domain/data layer (`TransactionEntity`, `WalletRepository`,
/// dst.) ditaruh di `features/wallet/` (bukan `features/researcher/`) biar
/// bisa dipakai ulang buat wallet Respondent nanti — lihat catatan di
/// `TransactionEntity`. Data (mock) dari `walletProvider` —
/// `AsyncValue.when` nanganin Loading/Error/Success (CPMK 3).
class ResearcherWalletScreen extends ConsumerWidget {
  const ResearcherWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SurvMarktAppBar(
              eyebrow: 'WALLET',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: walletAsync.when(
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
                          'Gagal memuat data wallet.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(walletProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (wallet) => _WalletBody(balance: wallet.balance, transactions: wallet.transactions),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 2,
        items: const [
          SurvMarktNavItem(icon: Icons.home_rounded, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.add_circle_outline, label: 'Buat Survei'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.researcherHome);
            return;
          }
          if (index == 1) {
            context.push(AppRoutes.createSurvey);
            return;
          }
          ref.read(authNotifierProvider.notifier).logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil belum tersedia — logout dulu ya.')),
          );
          context.go(AppRoutes.login);
        },
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.balance, required this.transactions});

  final int balance;
  final List<TransactionEntity> transactions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceHeroCard(balance: balance),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'RIWAYAT TRANSAKSI',
            style: AppTypography.eyebrowMuted.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
          ),
          const SizedBox(height: 2),
          Text(
            'Aktivitas Terakhir',
            style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final transaction in transactions) ...[
            TransactionTile(transaction: transaction),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SALDO',
            style: AppTypography.monoSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA5B4FC)),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.rupiahFull(balance),
            style: AppTypography.monoNumber.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              // Update 2026-09-08: Deposit Dana beneran butuh payment
              // gateway (Midtrans/Xendit/Stripe sandbox) — itu scope CPMK 5
              // (Integration Engine), sama kayak Google Sign-In. Distub
              // dulu, bukan ditinggal diam tanpa feedback.
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deposit Dana (payment gateway) nyusul di CPMK 5.')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                'Deposit Dana',
                style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.amber500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
