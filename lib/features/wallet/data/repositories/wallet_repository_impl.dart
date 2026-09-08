import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

/// Passthrough tipis ke datasource — pola sama kayak `ResearcherRepositoryImpl`.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remoteDataSource);

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<int> getBalance() => _remoteDataSource.getBalance();

  @override
  Future<List<TransactionEntity>> getTransactions() => _remoteDataSource.getTransactions();
}
