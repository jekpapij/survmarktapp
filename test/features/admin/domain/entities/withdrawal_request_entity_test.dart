import 'package:flutter_test/flutter_test.dart';
import 'package:survmarkt/features/admin/domain/entities/withdrawal_request_entity.dart';

/// Unit test buat `WithdrawalRequestEntity` — entity inti fitur Admin
/// (approve/reject withdrawal responden). `copyWith` di sini dipakai
/// LANGSUNG oleh `AdminRemoteDataSourceMock.approveWithdrawal`/
/// `rejectWithdrawal` buat mutasi status, jadi harus kepastian cuma
/// `status` yang berubah, field lain (nominal, nama, dsb.) nggak boleh
/// ikut kesundul/berubah.
void main() {
  final withdrawal = WithdrawalRequestEntity(
    id: 'wd-test',
    respondentName: 'Uji Coba',
    destinationLabel: 'Bank Test •••0000',
    amount: 100000,
    requestDate: DateTime(2026, 8, 20),
    status: WithdrawalStatus.pending,
  );

  group('WithdrawalRequestEntity.copyWith', () {
    test('mengubah status jadi disetujui, field lain tetap sama', () {
      final approved = withdrawal.copyWith(status: WithdrawalStatus.disetujui);

      expect(approved.status, WithdrawalStatus.disetujui);
      expect(approved.id, withdrawal.id);
      expect(approved.respondentName, withdrawal.respondentName);
      expect(approved.destinationLabel, withdrawal.destinationLabel);
      expect(approved.amount, withdrawal.amount);
      expect(approved.requestDate, withdrawal.requestDate);
    });

    test('mengubah status jadi ditolak, field lain tetap sama', () {
      final rejected = withdrawal.copyWith(status: WithdrawalStatus.ditolak);

      expect(rejected.status, WithdrawalStatus.ditolak);
      expect(rejected.amount, withdrawal.amount);
    });

    test('tanpa parameter, status tetap sama seperti sebelumnya', () {
      final unchanged = withdrawal.copyWith();
      expect(unchanged.status, withdrawal.status);
    });
  });

  group('WithdrawalRequestEntity Equatable', () {
    test('2 instance dengan field identik dianggap sama (==)', () {
      final other = WithdrawalRequestEntity(
        id: 'wd-test',
        respondentName: 'Uji Coba',
        destinationLabel: 'Bank Test •••0000',
        amount: 100000,
        requestDate: DateTime(2026, 8, 20),
        status: WithdrawalStatus.pending,
      );
      expect(withdrawal, other);
    });

    test('status beda membuat 2 instance dianggap berbeda', () {
      final approved = withdrawal.copyWith(status: WithdrawalStatus.disetujui);
      expect(withdrawal == approved, isFalse);
    });
  });
}
