import 'package:equatable/equatable.dart';

/// Fitur "Wallet" (get_design_context node 77:2237, `researcher-wallet`)
/// SENGAJA ditaruh sebagai modul terpisah `features/wallet/` (bukan di
/// dalam `features/researcher/`) — sama alasannya kayak `features/
/// notifications/`: konsepnya lintas-role. Bottom nav Respondent juga
/// punya tab "Wallet" (lihat CLAUDE.md "Bottom nav per role"), jadi domain
/// & data layer di sini dipakai ulang nanti, cuma presentation screen-nya
/// yang beda per role (researcher lihat "Deposit Dana", respondent nanti
/// kemungkinan "Tarik Dana").
enum TransactionType { deposit, expense }

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
  });

  final String id;
  final TransactionType type;
  final String title;

  /// Selalu nilai POSITIF — tanda (+/-) & warna ditentukan dari [type] pas
  /// ditampilin, bukan disimpen sebagai angka negatif di domain.
  final int amount;
  final DateTime date;

  @override
  List<Object?> get props => [id, type, title, amount, date];
}
