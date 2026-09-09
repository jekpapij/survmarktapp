import 'package:flutter_test/flutter_test.dart';
import 'package:survmarkt/features/admin/data/datasources/admin_remote_datasource_mock.dart';
import 'package:survmarkt/features/admin/domain/entities/withdrawal_request_entity.dart';

/// Unit test buat `AdminRemoteDataSourceMock` — logika bisnis utama fitur
/// Admin: approve/reject withdrawal HARUS beneran mindahin status by-`id`
/// (bukan index), dan datasource ini STATEFUL (mutasinya kepakai/kebaca
/// lagi di fetch berikutnya), bukan cuma hardcoded response yang sama tiap
/// dipanggil. Instance baru dibuat di tiap test (`setUp`) biar state nggak
/// bocor antar test satu sama lain.
void main() {
  late AdminRemoteDataSourceMock datasource;

  setUp(() {
    datasource = AdminRemoteDataSourceMock();
  });

  group('getWithdrawals', () {
    test('mengembalikan 7 withdrawal seed, semuanya berstatus pending di awal', () async {
      final withdrawals = await datasource.getWithdrawals();

      expect(withdrawals.length, 7);
      expect(withdrawals.every((w) => w.status == WithdrawalStatus.pending), isTrue);
    });

    test('semua id withdrawal unik', () async {
      final withdrawals = await datasource.getWithdrawals();
      final ids = withdrawals.map((w) => w.id).toSet();
      expect(ids.length, withdrawals.length);
    });
  });

  group('approveWithdrawal', () {
    test('mengubah status withdrawal target jadi disetujui, yang lain tetap pending', () async {
      await datasource.approveWithdrawal('wd-1');
      final withdrawals = await datasource.getWithdrawals();

      final wd1 = withdrawals.firstWhere((w) => w.id == 'wd-1');
      expect(wd1.status, WithdrawalStatus.disetujui);

      final others = withdrawals.where((w) => w.id != 'wd-1');
      expect(others.every((w) => w.status == WithdrawalStatus.pending), isTrue);
    });

    test('melempar StateError kalau id tidak ditemukan', () async {
      expect(() => datasource.approveWithdrawal('id-tidak-ada'), throwsStateError);
    });
  });

  group('rejectWithdrawal', () {
    test('mengubah status withdrawal target jadi ditolak', () async {
      await datasource.rejectWithdrawal('wd-2');
      final withdrawals = await datasource.getWithdrawals();

      final wd2 = withdrawals.firstWhere((w) => w.id == 'wd-2');
      expect(wd2.status, WithdrawalStatus.ditolak);
    });

    test('melempar StateError kalau id tidak ditemukan', () async {
      expect(() => datasource.rejectWithdrawal('id-tidak-ada'), throwsStateError);
    });
  });

  test('approve lalu reject withdrawal BEDA tidak saling mempengaruhi (dicari lewat id, bukan index)', () async {
    await datasource.approveWithdrawal('wd-3');
    await datasource.rejectWithdrawal('wd-4');
    final withdrawals = await datasource.getWithdrawals();

    expect(withdrawals.firstWhere((w) => w.id == 'wd-3').status, WithdrawalStatus.disetujui);
    expect(withdrawals.firstWhere((w) => w.id == 'wd-4').status, WithdrawalStatus.ditolak);
    // wd-1/wd-2/wd-5/wd-6/wd-7 nggak ikut kesundul.
    expect(withdrawals.firstWhere((w) => w.id == 'wd-5').status, WithdrawalStatus.pending);
  });

  group('getDashboardStats', () {
    test('mengembalikan angka statis sesuai frame Figma admin-dashboard', () async {
      final stats = await datasource.getDashboardStats();

      expect(stats.revenue, 8450000);
      expect(stats.totalTransaksi, 312);
      expect(stats.totalPengguna, 2480);
      expect(stats.surveyAktif, 86);
      expect(stats.surveyDitutupBulanIni, 34);
      expect(stats.weeklyChart.length, 7);
    });
  });

  group('getAuditLog', () {
    test('mengembalikan 5 entri audit log seed', () async {
      final entries = await datasource.getAuditLog();
      expect(entries.length, 5);
    });
  });
}
