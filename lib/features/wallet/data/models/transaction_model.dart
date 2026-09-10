import '../../domain/entities/transaction_entity.dart';

/// TransactionModel — mapping JSON <-> TransactionEntity, dipakai buat
/// caching ke Hive (`WalletLocalDataSourceImpl`). Pola sama persis kayak
/// `UserModel` (auth) — dipisah dari entity murni per aturan Clean
/// Architecture PROMPT_SPEC.md §2.2, domain layer nggak boleh tau soal
/// serialisasi. Ini modul `wallet/data/models/` yang PERTAMA — sebelum CPMK
/// 4, fitur ini masih passthrough tipis tanpa Model sama sekali (langsung
/// pakai `TransactionEntity` mentah), karena belum ada kebutuhan
/// serialisasi (Mock datasource cuma balikin List in-memory). Sekarang
/// dibutuhin karena data mau ditulis/dibaca dari Hive (`Box<String>`,
/// disimpen sebagai JSON string).
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.title,
    required super.amount,
    required super.date,
    super.isPendingSync,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      isPendingSync: entity.isPendingSync,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (t) => t.name == json['type'] as String,
        orElse: () => TransactionType.expense,
      ),
      title: json['title'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'isPendingSync': isPendingSync,
      };
}
