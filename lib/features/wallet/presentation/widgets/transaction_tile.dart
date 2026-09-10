import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/transaction_entity.dart';

/// 1 baris riwayat transaksi — icon-badge bulat panah naik/turun + judul +
/// tanggal + nominal berwarna (hijau deposit, merah expense). Nyamain
/// persis "transaction-card" di Figma `researcher-wallet` (get_design_
/// context node 77:2257 dst). Reusable — dipakai ulang lagi buat wallet
/// respondent nanti (lihat catatan di `TransactionEntity`).
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionEntity transaction;

  bool get _isDeposit => transaction.type == TransactionType.deposit;

  @override
  Widget build(BuildContext context) {
    final amountColor = _isDeposit ? const Color(0xFF16A34A) : AppColors.danger;
    final sign = _isDeposit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.indigoAccent.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(20)),
            child: Icon(
              _isDeposit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 18,
              color: AppColors.indigoAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        // Update 2026-09-09: `dateTimeShort` (bukan
                        // `shortDate` polos) — nampilin jam kalau
                        // transaksinya nyimpen jam beneran (respondent-
                        // wallet), tetep polos-tanggal buat data lama yang
                        // cuma nyimpen tanggal (researcher-wallet).
                        Formatters.dateTimeShort(transaction.date),
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.slate400),
                      ),
                    ),
                    // CPMK 4 (Offline-First) — badge ini SATU-SATUNYA tempat
                    // di UI yang beda antara transaksi "settled" vs yang
                    // masih ke-antre offline; sisanya (baris, warna, ikon)
                    // dirender IDENTIK, sengaja, biar transaksi pending
                    // nggak keliatan kayak error/gagal — cuma "belum sinkron".
                    if (transaction.isPendingSync) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'MENUNGGU SINKRONISASI',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sign${Formatters.rupiahFull(transaction.amount)}',
            style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor),
          ),
        ],
      ),
    );
  }
}
