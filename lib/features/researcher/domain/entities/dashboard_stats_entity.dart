import 'package:equatable/equatable.dart';

/// 4 stat card di header dashboard researcher (`stat-grid` di Figma).
/// Nominal uang disimpan sebagai angka mentah (bukan string "Rp 6.2jt"
/// yang udah diformat) — biar layer domain tetap murni data, formatting
/// tampilan (`Formatters.rupiahShort`) itu tanggung jawab presentation.
class DashboardStatsEntity extends Equatable {
  const DashboardStatsEntity({
    required this.totalSurvey,
    required this.totalExpense,
    required this.targetResponden,
    required this.saldo,
  });

  final int totalSurvey;
  final int totalExpense;
  final int targetResponden;
  final int saldo;

  @override
  List<Object?> get props => [totalSurvey, totalExpense, targetResponden, saldo];
}
