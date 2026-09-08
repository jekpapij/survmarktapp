/// Form validators — aturan sesuai PROMPT_SPEC.md §6 (Validation rules).
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  // Nomor HP Indonesia: 08xx, 628xx, atau +628xx.
  static final RegExp _phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,10}$');

  /// Login: field boleh diisi email ATAU no. HP.
  static String? emailOrPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email atau no. HP wajib diisi';
    if (v.contains('@')) {
      return _emailRegex.hasMatch(v) ? null : 'Format email tidak valid';
    }
    return _phoneRegex.hasMatch(v) ? null : 'Format no. HP tidak valid';
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email wajib diisi';
    return _emailRegex.hasMatch(v) ? null : 'Format email tidak valid';
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'No. HP wajib diisi';
    return _phoneRegex.hasMatch(v) ? null : 'Format no. HP tidak valid';
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nama lengkap wajib diisi';
    if (v.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  /// Min 8 karakter — PROMPT_SPEC.md §6.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password wajib diisi';
    if (v.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Konfirmasi password tidak cocok';
    return null;
  }

  // Update 2026-09-08: buat form `create-survey` — generik, dipakai ulang
  // buat beberapa field beda (judul, link) yang cuma butuh "wajib diisi".
  static String? required(String? value, String fieldLabel) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$fieldLabel wajib diisi';
    return null;
  }

  /// Buat field numerik yang harus > 0 (Jumlah Responden, Estimasi Waktu,
  /// Nominal Insentif).
  static String? positiveNumber(String? value, String fieldLabel) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$fieldLabel wajib diisi';
    final n = int.tryParse(v);
    if (n == null) return '$fieldLabel harus berupa angka';
    if (n <= 0) return '$fieldLabel harus lebih dari 0';
    return null;
  }
}
