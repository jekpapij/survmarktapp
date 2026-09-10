import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
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
          // Update 2026-09-08: tab Profil (index 3) sekarang beneran buka
          // layar `researcher-profile` (bukan logout-langsung-hack lagi —
          // tombol Logout beneran sekarang ada DI layar itu, sesuai Figma).
          context.push(AppRoutes.researcherProfile);
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

class _BalanceHeroCard extends ConsumerStatefulWidget {
  const _BalanceHeroCard({required this.balance});

  final int balance;

  @override
  ConsumerState<_BalanceHeroCard> createState() => _BalanceHeroCardState();
}

class _BalanceHeroCardState extends ConsumerState<_BalanceHeroCard> {
  bool _isSubmitting = false;

  /// CPMK 5 (Integration Engine) — Deposit Dana BENERAN lewat Midtrans
  /// Sandbox (keputusan user: integrasi asli, bukan simulasi UI). Alurnya:
  /// (1) dialog nominal -> (2) `MidtransService.createDeposit` (Supabase
  /// Edge Function — update 2026-09-10, sebelumnya Firebase Cloud Function
  /// — bikin transaksi Snap + dokumen Firestore `status: 'pending'`) -> (3)
  /// buka `redirectUrl` (halaman Snap) di browser eksternal -> (4) dialog
  /// "Menunggu Pembayaran" yang LIVE listen ke dokumen transaksi itu di
  /// Firestore — begitu webhook `midtrans-notification-handler` (server-
  /// to-server dari Midtrans) update status jadi 'success', dialog ini
  /// otomatis ke-notice & nutup sendiri, saldo di-refresh. User BEBAS nutup
  /// dialog ini manual kapan aja (mis. baru sempet bayar beberapa menit
  /// lagi) — statusnya tetap kesimpen di Firestore, nggak hilang.
  Future<void> _handleDepositDana() async {
    if (!ApiConstants.useFirebaseBackend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deposit Dana (payment gateway) nyusul di CPMK 5.')),
      );
      return;
    }

    final amount = await showDialog<int>(context: context, builder: (context) => const _DepositDanaDialog());
    if (amount == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(midtransServiceProvider).createDeposit(amount);
      if (!mounted) return;

      final launched = await launchUrl(Uri.parse(result.redirectUrl), mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Nggak ada browser buat buka halaman pembayaran.');
      if (!mounted) return;

      final success = await showDialog<bool>(
        context: context,
        builder: (context) => _WaitingPaymentDialog(orderId: result.orderId),
      );
      if (success == true) {
        ref.invalidate(walletProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deposit berhasil — saldo diperbarui.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai Deposit Dana: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
            Formatters.rupiahFull(widget.balance),
            style: AppTypography.monoNumber.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleDepositDana,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber500),
                    )
                  : Text(
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

/// Dialog nominal Deposit Dana — pola sama kayak `_TarikDanaDialog` di
/// `respondent_wallet_screen.dart`, nominal default `50000`.
class _DepositDanaDialog extends StatefulWidget {
  const _DepositDanaDialog();

  @override
  State<_DepositDanaDialog> createState() => _DepositDanaDialogState();
}

class _DepositDanaDialogState extends State<_DepositDanaDialog> {
  final _controller = TextEditingController(text: '50000');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deposit Dana'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          prefixText: 'Rp ',
          labelText: 'Nominal',
          helperText: 'Nanti dibuka halaman pembayaran Midtrans Sandbox — pakai metode pembayaran simulasi (mis. kartu test), bukan uang beneran.',
          helperMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final amount = int.tryParse(_controller.text.trim());
            if (amount == null || amount <= 0) return;
            Navigator.of(context).pop(amount);
          },
          child: const Text('Lanjut Bayar'),
        ),
      ],
    );
  }
}

/// "Menunggu Pembayaran" — listen LIVE ke 1 dokumen transaksi Firestore
/// spesifik (`wallets/{uid}/transactions/{orderId}`) selama user
/// menyelesaikan pembayaran di halaman Snap (browser eksternal yang barusan
/// kebuka). Begitu webhook `midtransNotificationHandler` ubah status jadi
/// 'success'/'failed', dialog ini otomatis bereaksi — TIDAK perlu polling
/// manual/refresh manual, ini bukti konkret kegunaan real-time listener
/// Firestore (di luar scope Hive-cache offline-first CPMK 4 yang udah ada).
class _WaitingPaymentDialog extends StatelessWidget {
  const _WaitingPaymentDialog({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    final stream = uid == null
        ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance
            .collection('wallets')
            .doc(uid)
            .collection('transactions')
            .doc(orderId)
            .snapshots();

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Menunggu Pembayaran'),
        content: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            final status = snapshot.data?.data()?['status'] as String?;
            if (status == 'success') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
              });
            }
            final label = switch (status) {
              'success' => 'Pembayaran berhasil! Menutup...',
              'failed' => 'Pembayaran gagal/dibatalkan di Midtrans.',
              _ => 'Selesaikan pembayaran di halaman/tab yang barusan kebuka — layar ini update otomatis begitu Midtrans konfirmasi.',
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != 'success' && status != 'failed') ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(label, textAlign: TextAlign.center),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tutup (cek lagi nanti)'),
          ),
        ],
      ),
    );
  }
}
