<div align="center">

# SurvMarkt

**Marketplace Responden Penelitian**

*Platform yang mempertemukan peneliti dengan responden secara cepat, terarah, dan berbasis kriteria.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-4F46E5?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-312E81?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![SDG](https://img.shields.io/badge/SDG-4%20Quality%20Education-F59E0B?style=flat-square)](https://sdgs.un.org/goals/goal4)
[![License](https://img.shields.io/badge/License-MIT-10B981?style=flat-square)](LICENSE)

</div>

---

## Tentang Proyek

SurvMarkt adalah **two-sided marketplace** yang mempertemukan:

- **Peneliti** yang membutuhkan responden dengan kriteria spesifik
- **Responden** yang ingin berpartisipasi dalam penelitian dan mendapatkan insentif

Dibangun sebagai proyek tugas besar mata kuliah **Rekayasa Perangkat Lunak Mobile** menggunakan Flutter, dengan pendekatan *Project-Based Learning* berbasis SDG 4 — Quality Education.

---

## Fitur Utama

### Peneliti
- Buat survey dengan kriteria responden (gender, usia, status)
- Kalkulator insentif otomatis + platform fee 20%
- Deadline survey (preset 7/14/30/60/90 hari atau custom)
- Featured Survey untuk visibilitas lebih tinggi
- Pause / Resume / Hapus survey (soft delete)
- Analytics per survey: views, respondent count, conversion rate
- Wallet & deposit

### Responden
- Discovery feed — hanya tampil survey yang cocok dengan profil
- Search & filter berdasarkan minimal insentif
- Detail survey sebelum memutuskan mengisi
- Riwayat survey & wallet
- Withdrawal request

### Admin
- Business metrics dashboard
- Revenue trend (4 minggu)
- Top survey by views
- Withdrawal approval / rejection
- Deleted survey audit log

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter 3.x (stable) |
| Language | Dart 3.x (null-safety) |
| State Management | Riverpod |
| Navigation | go_router |
| HTTP Client | Dio + interceptors |
| Local Storage | Hive + Flutter Secure Storage |
| Backend | REST API |
| Auth | JWT + Firebase Auth |
| Push Notification | Firebase Cloud Messaging |
| Payment | Midtrans / Xendit |

---

## Design System

SurvMarkt menggunakan tiga-font system yang konsisten di seluruh platform:

| Font | Penggunaan |
|---|---|
| **Lora** (serif) | Display heading, judul section, logo |
| **Inter** (sans-serif) | Body text, UI label, form |
| **JetBrains Mono** | Eyebrow label, angka metric, kode |

**Palet warna:**

```
Indigo 900  #312E81  — Sidebar, dark header
Indigo 600  #4F46E5  — Primary CTA, accent
Indigo 50   #EEF2FF  — Background, light surface
Amber 500   #F59E0B  — Insentif, featured, wallet
```

---

## Struktur Proyek

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/        # AppColors, AppTypography, AppSpacing
│   ├── errors/           # Failures, Exceptions
│   ├── network/          # Dio client + interceptors
│   ├── usecases/         # Abstract UseCase<T, P>
│   ├── utils/            # Currency formatter, validators
│   └── widgets/          # Shared widgets (Button, EmptyState, dll)
├── features/
│   ├── auth/
│   ├── researcher/
│   ├── respondent/
│   ├── wallet/
│   ├── admin/
│   └── notification/
├── injection.dart        # Riverpod providers
└── router.dart           # go_router config
```

Setiap feature mengikuti **Clean Architecture**:

```
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/     # Abstract
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

## Setup & Menjalankan

### Prasyarat

- Flutter SDK 3.x (stable channel)
- Dart 3.x
- Android Studio / VS Code
- Android Emulator atau device fisik (Android min API 21 / iOS min 12)

### Instalasi

```bash
# 1. Clone repo
git clone https://github.com/USERNAME/survmarkt.git
cd survmarkt

# 2. Install dependencies
flutter pub get

# 3. Generate code (Riverpod, Freezed, Hive)
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan aplikasi
flutter run
```

### Build APK

```bash
# Debug
flutter build apk --debug

# Release (butuh keystore)
flutter build apk --release
flutter build appbundle --release
```

---

## Milestone Progress

| Milestone | CPMK | Fokus | Status |
|---|---|---|---|
| 1 | CPMK 1 | SDG Ideation, PRD, Setup Environment | ✅ Done |
| 2 | CPMK 2 | Design System, Dynamic UI/UX | 🔄 In Progress |
| 3 | CPMK 3 | State Management, Clean Architecture | ⏳ Upcoming |
| 4 | CPMK 4 | Persistent Storage, Offline-First | ⏳ Upcoming |
| 5 | CPMK 5 | API Integration, Payment Gateway | ⏳ Upcoming |
| 6 | CPMK 6 | Security, CI/CD, Store Distribution | ⏳ Upcoming |

---

## Dokumentasi

| Dokumen | Deskripsi |
|---|---|
| [`PRD_AND_MONETIZATION.md`](PRD_AND_MONETIZATION.md) | Product Requirements Document v1.0 |

---

## Business Model

SurvMarkt menggunakan model **Two-Sided Marketplace**:

```
Peneliti  →  Bayar insentif + platform fee (20%)
              ↓
         SurvMarkt Platform
         Matching + Filtering
              ↓
Responden →  Terima insentif atas partisipasi
```

**Revenue:**
- **Primary:** Platform fee 20% dari total insentif per survey
- **Secondary:** Featured Survey (paid visibility boost)

---

## SDG Alignment

**SDG 4 — Quality Education**

SurvMarkt berkontribusi pada ekosistem riset akademik dengan mempercepat dan mempermudah proses pengumpulan data penelitian, khususnya bagi mahasiswa dan peneliti di Indonesia.

---

<div align="center">

*SurvMarkt — Tugas Besar Pemrograman Mobile*

</div>
