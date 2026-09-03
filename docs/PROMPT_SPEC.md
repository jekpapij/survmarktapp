# PROMPT_SPEC.md — SurvMarkt Mobile App

**Project:** SurvMarkt — Marketplace Responden Penelitian  
**Platform:** Flutter (Android + iOS)  
**Spec Version:** 1.1 (aligned with web version design system)  
**Standard:** SCI — Structured, Clear, Impactful  
**Based on:** PRD_AND_MONETIZATION.md v1.0  

> **Cara pakai:**
> 1. Baca `PRD_AND_MONETIZATION.md` sebagai konteks bisnis & fitur.
> 2. Gunakan dokumen ini sebagai acuan teknis saat generate/build/implement kode.
> 3. Ikuti Architecture & Convention di bawah secara ketat.
> 4. Setiap fitur yang diimplementasi harus merujuk ke Feature Implementation Checklist (Section 3).
> 5. Design System (Section 4) adalah sumber kebenaran tunggal untuk semua keputusan visual.

---

## 1. Project Context

SurvMarkt adalah aplikasi mobile two-sided marketplace yang mempertemukan peneliti dengan responden penelitian.

- **Peneliti:** membuat survei, menentukan kriteria responden, memberikan insentif, memantau progress.
- **Responden:** menemukan survei yang sesuai profil, mengisi, mendapatkan insentif ke wallet.
- **Admin:** monitor platform, approve/reject withdrawal, lihat business metrics.

**SDG:** SDG 4 — Quality Education (infrastruktur pendukung penelitian akademik)  
**Target pengguna:** Mahasiswa Indonesia usia 18–25  
**Platform:** Android (min SDK 21), iOS (min iOS 12+)

---

## 2. Architecture & Convention

### 2.1 Tech Stack (Fixed — jangan deviate tanpa diskusi)

| Komponen | Pilihan | Alasan |
|---|---|---|
| Framework | Flutter 3.x (stable channel) | Cross-platform, satu codebase |
| Language | Dart 3.x (null-safety strict) | Type-safe, modern |
| State Management | **Riverpod** (flutter_riverpod) | Compile-safe, scalable, testable |
| Local Storage | **Hive** (cache data), **Flutter Secure Storage** (token & sensitive) | Ringan + aman |
| HTTP Client | **Dio** (dengan interceptor auth, logging, retry) | Mature, interceptor ecosystem |
| Routing | **go_router** (deklaratif) | Deep linking ready, type-safe routes |
| DI | Riverpod providers (lazy loading) | Integrated dengan state management |
| Date/Time | **intl** package, timezone-aware | IDR locale support |
| Testing | flutter_test, mockito + build_runner, integration_test | Sesuai rubrik CPMK |

### 2.2 Project Structure (Clean Architecture)

```
lib/
├── main.dart                          # Entry point, ProviderScope, app init
├── app.dart                           # MaterialApp config, theme, router
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Design system colors (lihat Section 4)
│   │   ├── app_typography.dart        # Font styles: Lora, Inter, JetBrains Mono
│   │   ├── app_strings.dart           # Localized string keys
│   │   └── api_constants.dart         # Base URL, timeout, endpoint paths
│   ├── errors/
│   │   ├── failures.dart              # ServerFailure, CacheFailure, NetworkFailure, ValidationFailure
│   │   └── exceptions.dart            # Custom exceptions
│   ├── network/
│   │   ├── dio_client.dart            # Dio setup + interceptors (auth, logging, retry)
│   │   └── api_provider.dart          # Base API class
│   ├── usecases/
│   │   └── use_case.dart              # Abstract UseCase<Type, Params>
│   ├── utils/
│   │   ├── currency_formatter.dart    # Rp formatter (id-ID locale)
│   │   ├── date_formatter.dart        # Date format id-ID
│   │   └── validators.dart            # Form validators
│   └── widgets/
│       ├── loading_widget.dart        # Shimmer / circular indicator
│       ├── error_widget.dart          # Error state + retry button
│       ├── empty_state_widget.dart    # Empty state (icon + title + subtitle)
│       └── survmarkt_button.dart      # Primary button (indigo), secondary, amber
├── features/
│   ├── auth/                          # Login, Register, Logout
│   ├── researcher/                    # Buat survei, dashboard, progress, analytics
│   ├── respondent/                    # Discover, survey detail, history
│   ├── wallet/                        # Wallet, deposit, withdrawal
│   ├── admin/                         # Business metrics, withdrawal approval
│   └── notification/                  # Notification list, FCM handler
├── injection.dart                     # Global Riverpod providers
└── router.dart                        # go_router config + route guards
```

**Aturan wajib:**
- Setiap feature: 3 layer — **data** (datasources, models, repos impl), **domain** (entities, repos abstract, usecases), **presentation** (providers, screens, widgets).
- Domain layer = murni Dart, zero Flutter dependency.
- Widget file > 50 baris → extract ke file terpisah.
- Tidak ada `dynamic`. Tidak ada blocking call di main isolate.

### 2.3 Naming Conventions

| Item | Convention |
|---|---|
| Variabel / method | camelCase |
| Class / Widget | PascalCase |
| File | snake_case |
| API JSON field | snake_case (mapping via fromJson/toJson) |
| Route constants | SCREAMING_SNAKE_CASE di `AppRoutes` class |

### 2.4 Error Handling Pattern

```dart
// Repository: selalu Either<Failure, T>
Future<Either<Failure, Survey>> createSurvey(CreateSurveyParams params);

// Mapping HTTP → Failure
// 400 → ValidationFailure
// 401 → AuthFailure
// 500 → ServerFailure
// No connection → NetworkFailure

// UI: handle via Riverpod AsyncValue
ref.watch(surveyProvider).when(
  data: (survey) => SurveyCard(survey: survey),
  loading: () => const LoadingWidget(),
  error: (e, _) => ErrorWidget(onRetry: () => ref.invalidate(surveyProvider)),
);
```

---

## 3. Feature Implementation Reference (MoSCoW)

### 3.1 Authentication (MUST)

**Acceptance criteria:**
- [ ] Login email + password → JWT token disimpan di Flutter Secure Storage
- [ ] Register dengan email, password, nama, role (Peneliti / Responden)
- [ ] Token refresh otomatis saat expire
- [ ] Logout → clear token, redirect ke LoginScreen
- [ ] Role-based routing setelah login (Researcher → ResearcherDashboard, Respondent → DiscoverScreen)

**Endpoints:**
```
POST /api/v1/auth/login    → { accessToken, refreshToken, user }
POST /api/v1/auth/register → { user }
POST /api/v1/auth/refresh  → { accessToken }
POST /api/v1/auth/logout
```

---

### 3.2 Survey Management — Researcher (MUST)

**Acceptance criteria:**
- [ ] Form create survey: judul, deskripsi, jumlah responden, link form eksternal, estimasi durasi
- [ ] Criteria filter: gender (All/Male/Female), usia (All/18-22/23-30), status (All/Mahasiswa/Pekerja/Umum)
- [ ] Insentif input + auto-calculate platform fee (20%)
- [ ] Deadline: preset (7/14/30/60/90 hari) + custom date picker
- [ ] Featured Survey toggle (paid add-on)
- [ ] Publish → status OPEN
- [ ] Pause / Resume (OPEN ↔ PAUSED)
- [ ] Delete (soft delete → status DELETED, hanya admin bisa lihat)
- [ ] Progress real-time: current/target, progress bar, views, conversion rate

**Status state machine:**
```
OPEN ↔ PAUSED → CLOSED (target tercapai atau deadline habis)
OPEN/PAUSED/CLOSED → DELETED (soft delete, tetap di DB untuk audit)
```

---

### 3.3 Survey Discovery — Respondent (MUST)

**Acceptance criteria:**
- [ ] Feed hanya tampilkan survei OPEN yang cocok dengan profil responden
- [ ] Featured surveys tampil di posisi teratas
- [ ] Search by judul
- [ ] Filter by minimum insentif
- [ ] Survey detail modal: judul, deskripsi, durasi, insentif, target, deadline, progress bar
- [ ] Tombol "Isi Survey" → buka URL form eksternal di browser/WebView
- [ ] Views counter increment saat detail dibuka

---

### 3.4 Wallet (MUST)

**Acceptance criteria:**
- [ ] Tampilkan saldo wallet
- [ ] Peneliti: tombol Deposit (redirect ke payment gateway)
- [ ] Responden: tombol Withdrawal Request (input nominal, status Pending)
- [ ] Riwayat transaksi (list dengan tanggal, nominal, keterangan)

---

### 3.5 Notifications (MUST)

**Acceptance criteria:**
- [ ] List notifikasi in-app
- [ ] Badge count di navigation
- [ ] FCM push notification (survey matched, insentif diterima, withdrawal status)
- [ ] Kategori: `survey_matched`, `incentive_received`, `withdrawal_status`, `deposit_status`, `survey_deadline`

---

### 3.6 Featured Survey (SHOULD)

**Acceptance criteria:**
- [ ] Toggle "Jadikan Featured" saat create/edit survey
- [ ] Fee featured terpisah dari platform fee (admin set harga)
- [ ] Featured surveys: tampil di atas discover feed, badge visual khusus, border amber

---

### 3.7 Survey Analytics (SHOULD)

**Acceptance criteria:**
- [ ] Per-survey analytics: Views, Respondent count, Conversion Rate (current/views×100)
- [ ] Tampil di survey progress card dan detail modal

---

### 3.8 Admin Dashboard (SHOULD)

**Acceptance criteria:**
- [ ] Business metrics: Total Survey, Survey Aktif, Survey Selesai, Revenue
- [ ] Revenue trend chart (4 minggu, dummy proporsional untuk v1)
- [ ] Top Survey by views (top 3 dengan ranking)
- [ ] Withdrawal requests list (Approve / Reject)
- [ ] Deleted survey audit log

---

## 4. Design System (Aligned with Web Version)

> Ini adalah sumber kebenaran tunggal untuk semua keputusan visual di mobile.
> Konsisten dengan web version (landing.html + dashboard.html) yang sudah ada.

### 4.1 Color Palette

```dart
// app_colors.dart
class AppColors {
  // Primary — Indigo
  static const Color primary900 = Color(0xFF312E81); // Sidebar, dark header
  static const Color primary600 = Color(0xFF4F46E5); // CTA button, accent
  static const Color primary50  = Color(0xFFEEF2FF); // Background, light surface
  static const Color primary100 = Color(0xFFE0E7FF); // Card background, border

  // Accent — Amber (insentif, featured, wallet)
  static const Color amber500   = Color(0xFFF59E0B);
  static const Color amber100   = Color(0xFFFDE68A);
  static const Color amber50    = Color(0xFFFFFBEB);

  // Neutral
  static const Color slate900   = Color(0xFF0F172A); // Body text
  static const Color slate600   = Color(0xFF475569); // Muted text
  static const Color slate400   = Color(0xFF94A3B8); // Placeholder
  static const Color slate200   = Color(0xFFE2E8F0); // Border
  static const Color slate100   = Color(0xFFF1F5F9); // Subtle background

  // Semantic
  static const Color success    = Color(0xFF10B981); // Green (survey OPEN, insentif)
  static const Color warning    = Color(0xFFF59E0B); // Orange (PAUSED, expiring)
  static const Color danger     = Color(0xFFEF4444); // Red (CLOSED, error, delete)
  static const Color info       = Color(0xFF3B82F6); // Blue (info notification)

  // Dark mode surfaces
  static const Color darkBg     = Color(0xFF0F0D2E);
  static const Color darkSurface = Color(0xFF1A1740);
  static const Color darkCard   = Color(0xFF1E293B);
}
```

### 4.2 Typography (Three-Font System)

```dart
// app_typography.dart
// Lora    → Display/Heading (serif, akademik-tapi-modern)
// Inter   → Body/UI (sans-serif, clean, readable)
// JetBrains Mono → Label/Eyebrow/Code/Angka (mono, technical)

class AppTypography {
  // Display — Lora (section titles, card headings)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Lora',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Lora',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Lora',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primary900,
  );
  static const TextStyle displayItalic = TextStyle(
    fontFamily: 'Lora',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: AppColors.primary900,
  );

  // Body — Inter (semua teks UI, deskripsi, label form)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.slate900,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.slate600,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.slate400,
  );
  static const TextStyle labelSemibold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.slate900,
  );
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  // Eyebrow — JetBrains Mono (section labels, status badges, angka metric)
  // "EYEBROW" = teks uppercase kecil yang ada di atas heading
  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.primary600,
  );
  static const TextStyle eyebrowMuted = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.slate400,
  );
  static const TextStyle monoNumber = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.primary900,
  );
  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.slate600,
  );
}
```

**Aturan penggunaan:**
- `displayLarge/Medium/Small` → card title, screen heading (sebelumnya `h3`, `h2` di web)
- `eyebrow` → selalu taruh SEBELUM heading (pattern: eyebrow di atas, display di bawah)
- `monoNumber` → angka wallet, stats metric
- `bodyMedium` → deskripsi, body text umum
- Jangan pakai `Text(style: TextStyle(...))` inline — selalu refer ke `AppTypography`

### 4.3 Spacing & Radius

```dart
class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;   // Card radius
  static const double full = 999.0; // Pill/badge
}
```

### 4.4 Card & Component Pattern

**Standard card:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(color: AppColors.primary100),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary900.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POLA WAJIB: eyebrow dulu, baru display heading
        Text('LABEL', style: AppTypography.eyebrow),
        const SizedBox(height: 4),
        Text('Judul Card', style: AppTypography.displaySmall),
        // ... content
      ],
    ),
  ),
)
```

**Featured survey card:** tambahkan border amber + gradient `from amber50 to white`

**Status badge:**
```dart
// OPEN → green, PAUSED → amber, CLOSED → red, DELETED → slate
// Expiring Soon (≤3 hari) → orange, tambah di samping status badge
```

### 4.5 Button Styles

```dart
// Primary: indigo-600 background, white text, rounded-xl
// Amber CTA: amber-500 background, indigo-900 text (untuk wallet/insentif action)
// Outline: white bg, indigo-600 border + text
// Destructive: red-600 background, white text (delete, reject)
```

### 4.6 Navigation Pattern

> Update 2026-09-02 (revisi kedua) — Admin nambah tab Profil (lihat poin 5). Update 2026-08-31 (revisi dari versi awal) — lihat rasional lengkap di bawah tabel.

- **Bottom Navigation Bar:** jumlah & isi tab BOLEH beda per role — disesuaikan sama destinasi yang genuinely dikunjungi berulang buat role itu, jangan dipaksa seragam 4 tab semua role.
  - **Researcher:** Dashboard, Buat Survei, Wallet, **Profil**
  - **Respondent:** Discover, **Aktivitas** (mencakup riwayat survey yang udah dikerjain), Wallet, **Profil**
  - **Admin:** Dashboard, Withdrawal, Audit, **Profil** (4 tab — tetap nggak ada Wallet karena admin nggak punya wallet pribadi di platform, tapi Profil tetap perlu buat ganti password & logout)
- **Notifikasi BUKAN bottom nav tab** di role manapun — selalu icon bel di pojok kanan atas app bar, konsisten di semua role/screen.
- **App Bar:** minimal, judul pakai `displaySmall` (Lora), icon bel notifikasi di kanan atas
- **Back button:** selalu ada di screen detail

**Kenapa direvisi dari rencana awal (Dashboard/Buat Survei/Progress/Wallet + Discover/Riwayat/Notifikasi/Wallet):**

1. **Notifikasi dipindah ke bel app bar, bukan tab** — notifikasi bukan "area" yang dikunjungi berulang kaya Discover/Wallet, jadi taruh sebagai icon bel (konsisten di semua role) lebih natural daripada maksain jadi salah satu dari cuma-4-slot tab.
2. **"Progress" dihapus dari nav Researcher** — nggak perlu tab sendiri, karena manajemen survey (pause/resume/delete + analytics detail) udah include di card "Progress Survey" pada Dashboard: tap card → buka layar "Kelola Survey" (persis pattern yang udah tervalidasi di web version, `dashboard.html`, diadaptasi jadi layar detail terpisah bukan modal overlay di mobile). Duplikasi jadi tab terpisah = redundant sama apa yang udah ada di Dashboard.
3. **Profil jadi tab pengganti (bukan cuma menu tersembunyi)** — alasan konkret, bukan estetika: form register di scope saat ini cuma nama/email/password/role (data buat matching survey — umur, gender, status — sengaja belum diisi di register). Jadi harus ada tempat user melengkapi/update data itu setelah daftar → Profil = progressive profiling step yang genuinely dibutuhin, bukan preferensi kosmetik. Ini berlaku juga di Responden (data matching-nya sama pentingnya di sana). **Catatan:** isi Edit Profil beda per role — Researcher & Admin soal identitas/kredibilitas (institusi, peran), Respondent soal data matching survey (gender/usia/status/domisili) dengan warning banner wajib-lengkapi karena beneran nge-gate fitur "isi survei".
4. **Respondent "Riwayat" → "Aktivitas"** — nama lebih luas biar bisa nampung riwayat survey yang dikerjain sekaligus log aktivitas terkait (mirip section "Aktivitas / Notifikasi" yang udah ada di web version).
5. **Admin nambah tab Profil (revisi 2026-09-02)** — awalnya Admin cuma 3 tab (Dashboard/Withdrawal/Audit) dengan asumsi admin nggak butuh area personal. Ternyata itu gap: nggak ada tempat buat logout atau ganti password setelah admin login. Profil versi Admin sengaja dibikin **minimal** — cuma info akun dasar (Email, ID Admin) + menu Ubah Password/Notifikasi/Bantuan + tombol Keluar, TANPA completion banner atau stat card kayak Researcher/Respondent, karena admin nggak butuh progressive profiling ataupun analytics pribadi di sini.

### 4.7 Dark Mode

Aplikasi mendukung dark mode mengikuti sistem (tidak ada toggle manual — sama seperti landing page web yang pakai `prefers-color-scheme`). Override colors di dark mode:

```dart
// Dark mode token mapping
// primary900 background → darkBg (0xFF0F0D2E)
// white surface → darkSurface (0xFF1A1740)
// card bg → darkCard (0xFF1E293B)
// primary100 border → primary900 with opacity 0.25
// text slate900 → primary100 (0xFFE0E7FF)
```

---

## 5. Font Setup (pubspec.yaml)

```yaml
flutter:
  fonts:
    - family: Lora
      fonts:
        - asset: assets/fonts/Lora-Regular.ttf
        - asset: assets/fonts/Lora-Medium.ttf
          weight: 500
        - asset: assets/fonts/Lora-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Lora-Bold.ttf
          weight: 700
        - asset: assets/fonts/Lora-Italic.ttf
          style: italic
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
        - asset: assets/fonts/Inter-ExtraBold.ttf
          weight: 800
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
```

> Download fonts: Lora dan Inter dari Google Fonts, JetBrains Mono dari JetBrains.
> Taruh di `assets/fonts/`. Jangan gunakan CDN di mobile — bundle di app.

---

## 6. Error Handling Specification

| Skenario | Tindakan |
|---|---|
| Tidak ada koneksi | SnackBar "Tidak ada koneksi internet" + tampilkan cached data jika ada |
| Timeout (>30 detik) | Dialog/SnackBar "Server tidak merespons" + tombol Retry |
| Server error (5xx) | "Terjadi masalah pada server. Coba lagi nanti." |
| Client error (400) | Pesan spesifik dari API (misal: "Email sudah terdaftar") |
| 401 Unauthorized | Auto redirect ke LoginScreen, clear token |

**Validation rules:**

| Field | Aturan |
|---|---|
| Email | Format valid, unik |
| Password | Min 8 karakter |
| Judul survei | Min 5, max 100 karakter |
| Deskripsi | Min 10 karakter |
| Jumlah responden | Min 10, max 5.000 |
| Insentif per responden | Min Rp1.000, max Rp50.000 |
| Nominal withdrawal | Min Rp50.000, ≤ saldo |

---

## 7. Testing Strategy

### Unit Test (wajib, target 80% coverage use cases)
- Use cases: login, register, create survey, calculate fee, discover surveys
- Repositories: mock datasource, test failure mapping
- Models: serialization/deserialization JSON

### Widget Test
- LoginScreen: input validation, button state
- CreateSurveyForm: fee calculation display, validation errors
- DiscoverFeed: list render, filter apply
- WalletScreen: saldo display, withdrawal flow

### Integration Test (2 flow kritis)
- Flow 1: Login → Create Survey → Publish → View Progress
- Flow 2: Login Responden → Discover → View Detail → Isi Survey → View History

---

## 8. API Endpoint Reference

### Auth
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
```

### Researcher
```
GET  /api/v1/researcher/dashboard
GET  /api/v1/surveys
POST /api/v1/surveys
GET  /api/v1/surveys/{id}
PUT  /api/v1/surveys/{id}/publish
PUT  /api/v1/surveys/{id}/pause
PUT  /api/v1/surveys/{id}/resume
DELETE /api/v1/surveys/{id}
GET  /api/v1/surveys/{id}/progress
POST /api/v1/surveys/{id}/featured
```

### Respondent
```
GET  /api/v1/respondent/profile
POST /api/v1/respondent/profile
GET  /api/v1/surveys/discover
GET  /api/v1/surveys/{id}
POST /api/v1/surveys/{id}/view          # increment views
POST /api/v1/surveys/{id}/participate   # mulai survey
GET  /api/v1/respondent/wallet
GET  /api/v1/respondent/wallet/transactions
POST /api/v1/respondent/withdrawal/request
GET  /api/v1/respondent/withdrawal/history
GET  /api/v1/respondent/history
```

### Wallet (Common)
```
GET  /api/v1/wallet/balance
GET  /api/v1/wallet/transactions
POST /api/v1/wallet/deposit
```

### Admin
```
GET  /api/v1/admin/dashboard
GET  /api/v1/admin/surveys/statistics
GET  /api/v1/admin/withdrawals
POST /api/v1/admin/withdrawals/{id}/approve
POST /api/v1/admin/withdrawals/{id}/reject
GET  /api/v1/admin/surveys/deleted
GET  /api/v1/admin/top-surveys
```

---

## 9. Constraints & Assumptions

- Tidak ada offline mode penuh. Koneksi internet diperlukan untuk fitur utama.
- Form survey bisa di-save as draft lokal sementara jika network tidak tersedia.
- Semua monetary value dalam Rupiah (IDR), format `Rp X.XXX`.
- Backend menyediakan REST API — frontend tidak implement backend logic.
- Payment gateway: Midtrans atau Xendit. Frontend hanya menerima callback/notifikasi.
- Admin panel: native mobile app (bukan web-based) — bedanya dari versi web SurvMarkt.

---

## 10. Definition of Done (Milestone Checklist)

Implementasi siap untuk testing/QA ketika:

- [ ] Semua fitur MUST (Section 3.1 – 3.5) berfungsi sesuai acceptance criteria
- [ ] Semua fitur SHOULD (Section 3.6 – 3.8) diimplementasi
- [ ] Design System (Section 4) diterapkan konsisten di seluruh screen
- [ ] Font tiga-family (Lora / Inter / JetBrains Mono) terbundle dan teraplikasi
- [ ] Unit test use cases & repositories ≥ 80% coverage
- [ ] Widget test untuk screen utama tersedia
- [ ] Integration test 2 flow kritis tersedia
- [ ] Build berhasil untuk Android (APK/AAB) dan bisa jalan di emulator

---

*End of PROMPT_SPEC.md — SurvMarkt v1.1*
