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

  static String _trimZero(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}
