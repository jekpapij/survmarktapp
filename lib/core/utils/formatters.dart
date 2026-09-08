/// Formatter angka/uang buat tampilan singkat ala Figma (`Rp 6.2jt`, `Rp
/// 350rb`) — dipakai pertama kali di `researcher-dashboard`, tapi ditaruh di
/// `core/utils/` (bukan di dalam fitur researcher) karena bakal dipakai
/// ulang juga di wallet/withdrawal (researcher, respondent, admin — semua
/// nampilin nominal uang).
class Formatters {
  Formatters._();

  /// `6200000` -> `Rp 6.2jt`, `350000` -> `Rp 350rb`, `12000` -> `Rp 12rb`,
  /// di bawah 1000 -> `Rp 999` apa adanya.
  static String rupiahShort(num amount) {
    if (amount >= 1000000000) {
      return 'Rp ${_trimZero(amount / 1000000000)}M';
    }
    if (amount >= 1000000) {
      return 'Rp ${_trimZero(amount / 1000000)}jt';
    }
    if (amount >= 1000) {
      return 'Rp ${_trimZero(amount / 1000)}rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  /// `1840` -> `1,840` (pemisah ribuan pakai koma, sesuai contoh di Figma
  /// `TARGET RESPONDEN` -> `1,840`).
  static String thousands(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// `DateTime` -> teks relatif ("12 hari lagi", "Hari ini", "Lewat 3 hari")
  /// — dipakai buat countdown deadline yang LIVE di modal "Kelola Survey"
  /// (dihitung ulang dari `DateTime.now()` tiap kali di-build), beda dari
  /// `SurveyEntity.metaText` yang statis/snapshot dari mock data.
  static String relativeDays(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff > 0) return '$diff hari lagi';
    return 'Lewat ${-diff} hari';
  }

  /// `DateTime` (WAKTU LAMPAU) -> teks relatif ("Baru saja", "12 menit
  /// lalu", "2 jam lalu", "Kemarin", "3 hari lalu") — kebalikan dari
  /// [relativeDays] yang buat tanggal MASA DEPAN (deadline). Dipakai buat
  /// timestamp notifikasi. Lebih dari seminggu jatuh balik ke [shortDate].
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return shortDate(date);
  }

  /// `DateTime(2026, 9, 20)` -> `20 Sep 2026`.
  static String shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _trimZero(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}
