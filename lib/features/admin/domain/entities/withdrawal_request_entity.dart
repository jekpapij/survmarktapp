import 'package:equatable/equatable.dart';

/// State withdrawal — frame Figma `admin-withdrawal` (node `86:52`) nunjukin
/// 3 tab: Pending / Disetujui / Ditolak. Beda dari `SurveyStatus` sisi
/// researcher (nggak ada state final "closed" tambahan) — dari `pending`
/// admin cuma bisa nyetujui atau nolak, keduanya final (nggak ada alur balik
/// ke pending lagi, konsisten sama gimana proses withdrawal beneran kerja).
enum WithdrawalStatus { pending, disetujui, ditolak }

/// Permintaan penarikan dana dari Responden — dikelola Admin lewat
/// `admin-withdrawal`. `destinationLabel` gabungan nama bank/e-wallet +
/// nomor rekening/akun tersamar (persis format Figma, mis. `"Bank BCA
/// •••1234"`), disimpen sebagai 1 String (bukan dipecah bank/nomor
/// terpisah) karena cuma ditampilin apa adanya, nggak pernah diolah lagi.
class WithdrawalRequestEntity extends Equatable {
  const WithdrawalRequestEntity({
    required this.id,
    required this.respondentName,
    required this.destinationLabel,
    required this.amount,
    required this.requestDate,
    required this.status,
  });

  final String id;
  final String respondentName;
  final String destinationLabel;

  /// Nominal mentah (Rupiah) — diformat pas ditampilin, pola sama kayak
  /// `TransactionEntity.amount`/`SurveyEntity.incentiveAmount`.
  final int amount;
  final DateTime requestDate;
  final WithdrawalStatus status;

  WithdrawalRequestEntity copyWith({WithdrawalStatus? status}) {
    return WithdrawalRequestEntity(
      id: id,
      respondentName: respondentName,
      destinationLabel: destinationLabel,
      amount: amount,
      requestDate: requestDate,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, respondentName, destinationLabel, amount, requestDate, status];
}
