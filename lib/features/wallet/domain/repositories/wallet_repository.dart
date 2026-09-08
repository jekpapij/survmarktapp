import '../entities/transaction_entity.dart';

/// Kontrak layer domain buat fitur wallet — pola sama persis kayak
/// `ResearcherRepository`/`NotificationRepository`.
abstract class WalletRepository {
  Future<int> getBalance();

  Future<List<TransactionEntity>> getTransactions();
}
