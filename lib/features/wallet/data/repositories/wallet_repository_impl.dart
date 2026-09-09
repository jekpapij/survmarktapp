import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

/// Passthrough tipis ke datasource — pola sama kayak `ResearcherRepositoryImpl`.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remoteDataSource);

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<int> getBalance({UserRole? forRole}) => _remoteDataSource.getBalance(forRole: forRole);

  @override
  Future<List<TransactionEntity>> getTransactions({UserRole? forRole}) =>
      _remoteDataSource.getTransactions(forRole: forRole);
}
