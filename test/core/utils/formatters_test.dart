import 'package:flutter_test/flutter_test.dart';
import 'package:survmarkt/core/utils/formatters.dart';

/// Unit test sederhana buat `Formatters` — kumpulan pure function (nggak
/// ada dependency ke Widget/Provider/network), dipakai di HAMPIR SEMUA
/// fitur (nominal Rupiah, tanggal, umur dari `birthDate`). CPMK 3 poin 4:
/// "Lakukan pembuatan Unit Test sederhana untuk memvalidasi fungsi logika
/// bisnis utama".
void main() {
  group('Formatters.rupiahShort', () {
    test('disingkat ke "jt" untuk nominal jutaan', () {
      expect(Formatters.rupiahShort(6200000), 'Rp 6.2jt');
    });

    test('disingkat ke "rb" untuk nominal ribuan', () {
      expect(Formatters.rupiahShort(350000), 'Rp 350rb');
      expect(Formatters.rupiahShort(12000), 'Rp 12rb');
    });

    test('nominal di bawah seribu ditampilkan apa adanya', () {
      expect(Formatters.rupiahShort(999), 'Rp 999');
    });
  });

  group('Formatters.rupiahFull', () {
    test('pemisah ribuan pakai titik', () {
      expect(Formatters.rupiahFull(1200000), 'Rp 1.200.000');
      expect(Formatters.rupiahFull(250000), 'Rp 250.000');
    });

    test('nominal negatif tetap diberi tanda minus di depan "Rp"', () {
      expect(Formatters.rupiahFull(-5000), 'Rp -5.000');
    });
  });

  group('Formatters.thousands', () {
    test('pemisah ribuan pakai koma', () {
      expect(Formatters.thousands(1840), '1,840');
      expect(Formatters.thousands(2480), '2,480');
    });
  });

  group('Formatters.dateTimeShort', () {
    test('tampilkan jam kalau bukan 00:00', () {
      expect(Formatters.dateTimeShort(DateTime(2026, 8, 24, 14, 20)), '24 Agu 2026 • 14:20');
    });

    test('sembunyikan jam kalau tepat 00:00 (data lama cuma nyimpen tanggal)', () {
      expect(Formatters.dateTimeShort(DateTime(2026, 8, 24)), '24 Agu 2026');
    });
  });

  group('Formatters.ageLabelFromBirthDate', () {
    test('string kosong menghasilkan label kosong ("Belum diisi")', () {
      expect(Formatters.ageLabelFromBirthDate(''), '');
    });

    test('string invalid menghasilkan label kosong', () {
      expect(Formatters.ageLabelFromBirthDate('bukan-tanggal'), '');
    });

    test('tanggal lahir valid menghasilkan label "N Tahun"', () {
      // Umur pastinya bergantung tanggal test dijalankan, jadi cuma dicek
      // FORMAT-nya ("<angka> Tahun"), bukan angka eksaknya — biar test
      // tetap valid dipanggil kapan aja.
      final label = Formatters.ageLabelFromBirthDate('2000-05-12');
      expect(label, matches(RegExp(r'^\d+ Tahun$')));
    });
  });
}
