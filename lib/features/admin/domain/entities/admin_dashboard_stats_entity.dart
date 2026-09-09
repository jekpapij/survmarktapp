import 'package:equatable/equatable.dart';

/// Angka-angka statis di `admin-dashboard` (node `88:52`) yang MEMANG nggak
/// punya list sumber buat dihitung ulang (revenue, chart, total transaksi,
/// dst. — beda dari `withdrawalPending`, lihat catatan penting di bawah).
///
/// **Keputusan penting soal `withdrawalPending` (BUKAN field di sini):**
/// Figma dashboard nunjukin stat card "WITHDRAWAL 7", sedangkan frame
/// `admin-withdrawal` di halaman TERPISAH cuma nampilin 4 contoh card
/// withdrawal pending. Dua angka ini kalau disimpen sebagai 2 field mock
/// independen bisa gampang nggak sinkron (persis kasus banner "Profil 40%"
/// vs 4 field "Belum diisi" di `respondent-profil`, sama kasus lain yang
/// udah diputusin dihitung LIVE). Di sini diselesaiin dengan SEED withdrawal
/// pending JADI PERSIS 7 (4 contoh asli Figma + 3 tambahan dikarang biar
/// genap 7, lihat `AdminRemoteDataSourceMock`), terus jumlah "WITHDRAWAL"
/// di dashboard DIHITUNG LIVE dari list withdrawal yang sama (`AdminDashboardData.
/// withdrawalPendingCount` di `admin_providers.dart`) — bukan angka statis
/// kedua. Konsekuensinya: begitu Admin approve/reject 1 withdrawal, angka di
/// dashboard ini otomatis ikut turun kalau di-refresh (perilaku yang benar).
class AdminDashboardStatsEntity extends Equatable {
  const AdminDashboardStatsEntity({
    required this.revenue,
    required this.weeklyChart,
    required this.totalTransaksi,
    required this.rataRataPerHari,
    required this.totalPengguna,
    required this.surveyAktif,
    required this.surveyDitutupBulanIni,
  });

  /// "PENDAPATAN PLATFORM" bulan ini (Rp 8.450.000 di Figma).
  final int revenue;

  /// 7 nilai Senin..Minggu buat bar chart amber di hero card — 0-100
  /// (TINGGI BAR RELATIF, bukan nominal Rupiah — Figma nggak nunjukin angka
  /// literal per hari, cuma bar proporsional).
  final List<int> weeklyChart;

  final int totalTransaksi;

  /// "RATA-RATA/HARI" (Rp 272rb di Figma) — disimpen sebagai nominal Rupiah
  /// utuh (272000), diformat singkat pas ditampilin (`Formatters.rupiahShort`),
  /// BUKAN dihitung dari `revenue`/30 (Figma-nya nggak exact match kalkulasi
  /// itu — dianggap 2 angka independen dari mock, sama kayak
  /// `totalTransaksi` yang juga independen).
  final int rataRataPerHari;

  final int totalPengguna;
  final int surveyAktif;
  final int surveyDitutupBulanIni;

  @override
  List<Object?> get props => [
        revenue,
        weeklyChart,
        totalTransaksi,
        rataRataPerHari,
        totalPengguna,
        surveyAktif,
        surveyDitutupBulanIni,
      ];
}
