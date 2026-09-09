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
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../wallet/domain/entities/transaction_entity.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../wallet/presentation/widgets/transaction_tile.dart';

/// Wallet Respondent — frame Figma `respondent-wallet` (get_design_context,
/// node `77:3000`). Pakai ULANG TOTAL modul `features/wallet/` yang udah
/// ada (`TransactionEntity`, `walletProvider`, `TransactionTile`) — sesuai
/// rencana yang emang udah dicatet dari awal pas modul ini dibikin buat
/// `researcher-wallet` ("dipakai ulang lagi buat wallet respondent nanti").
/// Cuma layar (presentation) ini yang baru — domain/data layer TIDAK ada
/// file baru, cuma `WalletRemoteDataSourceMock` yang dibikin ROLE-AWARE
/// (lihat catatan lengkap di `WalletRepository`) biar saldo & riwayat
/// transaksinya beda dari researcher (insentif+penarikan, bukan
/// deposit+biaya survey).
///
/// **Deviasi disadari — 2 metric card (TOTAL DIPEROLEH/SURVEI SELESAI)
/// DIHITUNG LIVE dari transaksi**, BUKAN angka statis Figma (`Rp 430.000`/
/// `24`): Figma cuma nunjukin 5 baris riwayat (3 insentif totalnya cuma
/// Rp 60.000, bukan Rp 430.000) — sama kasusnya kayak banner "Profil 40%"
/// di `respondent-profil` yang juga nggak nyambung sama data di frame yang
/// sama. Prinsip yang udah dipegang dari awal proyek: jangan duplikat angka
/// mock kedua yang bisa nggak sinkron — dihitung dari `transactions` yang
/// SAMA yang dipakai nampilin daftar riwayat di bawahnya (`TOTAL DIPEROLEH`
/// = jumlah semua transaksi `deposit`/insentif, `SURVEI SELESAI` = banyaknya
/// transaksi `deposit` itu, karena 1 insentif = 1 survei yang beres diisi &
/// diverifikasi).
class RespondentWalletScreen extends ConsumerWidget {
  const RespondentWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    // CPMK 4 — "nyalain" listener auto-sync selama layar Wallet Respondent
    // ini mounted (lihat catatan lengkap di `walletAutoSyncProvider`).
    // Cukup di sini doang (bukan juga di `ResearcherWalletScreen`) karena
    // cuma "Tarik Dana" respondent yang punya alur tulis-offline beneran
    // di scope CPMK 4 ini — "Deposit Dana" researcher tetap stub CPMK 5.
    ref.watch(walletAutoSyncProvider);

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
          SurvMarktNavItem(icon: Icons.explore_outlined, label: 'Discover'),
          SurvMarktNavItem(icon: Icons.history_rounded, label: 'Aktivitas'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.respondentHome);
            return;
          }
          if (index == 1) {
            context.push(AppRoutes.respondentActivity);
            return;
          }
          context.push(AppRoutes.respondentProfile);
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
    final depositTransactions = transactions.where((t) => t.type == TransactionType.deposit);
    final totalDiperoleh = depositTransactions.fold<int>(0, (sum, t) => sum + t.amount);
    final surveiSelesai = depositTransactions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceHeroCard(balance: balance),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: MetricCard(label: 'TOTAL DIPEROLEH', value: Formatters.rupiahFull(totalDiperoleh)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: MetricCard(label: 'SURVEI SELESAI', value: '$surveiSelesai')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'RIWAYAT TRANSAKSI',
            style: AppTypography.eyebrowMuted.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
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

  // Update CPMK 4 (Persistent Data & Offline-First): "Tarik Dana" BUKAN
  // stub snackbar lagi (payout BENERAN ke bank/e-wallet via payment
  // gateway tetap nyusul CPMK 5 — nominal di sini dummy/fixed, bukan
  // transfer sungguhan). Yang beneran baru: tombol ini sekarang jalur
  // TULIS pertama di app yang keduanya (a) tetap "berhasil" walau device
  // OFFLINE (masuk antrean lokal, Panduan Pengerjaan CPMK 4 poin 2), dan
  // (b) langsung nyerminin perubahan saldo secara optimis tanpa nunggu
  // sync — buktiin `WalletRepositoryImpl` offline-first beneran jalan,
  // bukan cuma di layer baca.
  Future<void> _handleTarikDana() async {
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => const _TarikDanaDialog(),
    );
    if (amount == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(walletRepositoryProvider)
          .requestWithdrawal(forRole: UserRole.responden, amount: amount);
      ref.invalidate(walletProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isPendingSync
                ? 'Device lagi offline — Tarik Dana ${Formatters.rupiahFull(amount)} disimpan lokal, otomatis disinkronkan pas online lagi.'
                : 'Tarik Dana ${Formatters.rupiahFull(amount)} berhasil diproses.',
          ),
          backgroundColor: result.isPendingSync ? AppColors.amber500 : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses Tarik Dana: $e'), backgroundColor: AppColors.danger),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SALDO',
            style: AppTypography.monoSmall.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA5B4FC)),
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.rupiahFull(widget.balance),
            style: AppTypography.monoNumber.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: _isSubmitting ? null : _handleTarikDana,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSubmitting) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber500),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Tarik Dana',
                    style: AppTypography.monoSmall.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber500),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.amber500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog kecil buat masukin nominal Tarik Dana — self-designed (nggak ada
/// frame Figma buat ini, sama pola kayak "Ubah Password"/"Lupa Password"),
/// nominal default `50000` biar tinggal tap "Tarik" tanpa ngetik apa-apa
/// kalau cuma mau coba alur offline-first-nya cepat.
class _TarikDanaDialog extends StatefulWidget {
  const _TarikDanaDialog();

  @override
  State<_TarikDanaDialog> createState() => _TarikDanaDialogState();
}

class _TarikDanaDialogState extends State<_TarikDanaDialog> {
  final _controller = TextEditingController(text: '50000');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tarik Dana'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          prefixText: 'Rp ',
          labelText: 'Nominal',
          helperText: 'Coba matikan WiFi/data dulu buat tes alur offline-nya.',
          helperMaxLines: 2,
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
          child: const Text('Tarik'),
        ),
      ],
    );
  }
}
