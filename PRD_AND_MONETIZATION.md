# Product Requirements Document (PRD) — SurvMarkt v1.0
**Last Updated:** 2026-08-14
**Version:** 1.0
**Product:** SurvMarkt — Marketplace Responden Penelitian
**Platform:** Mobile App (Flutter / Android & iOS)
**SDG Alignment:** SDG 4 — Quality Education

---

# 1. Product Overview

**Nama Produk:** SurvMarkt  
**Tagline:** Marketplace Responden Penelitian  
**Product Type:** Two-Sided Digital Marketplace  
**Target Utama:** Mahasiswa/peneliti dan responden penelitian  
**Konteks:** Platform digital pendukung penelitian dan pembelajaran berbasis data

SurvMarkt adalah platform marketplace yang mempertemukan **peneliti yang membutuhkan responden** dengan **responden yang bersedia berpartisipasi dalam penelitian dengan memperoleh insentif**.

Platform membantu peneliti menentukan kebutuhan responden berdasarkan kriteria seperti gender, usia, dan status, kemudian menyediakan proses pencarian dan matching responden yang lebih terarah. Bagi responden, SurvMarkt menyediakan daftar penelitian yang sesuai dengan profil mereka serta memberikan insentif atas partisipasi yang telah dilakukan.

Konsep ini dikembangkan untuk mengatasi proses penyebaran survei secara manual yang cenderung tidak terarah, memakan waktu, dan sering kali menghasilkan responden yang tidak sesuai target.

---

# 2. Problem Statement

### 2.1 Masalah Peneliti

Mahasiswa dan peneliti sering membutuhkan responden dalam jumlah dan karakteristik tertentu untuk memenuhi kebutuhan penelitian, tugas akademik, skripsi, maupun kegiatan evaluasi.

Metode konvensional seperti menyebarkan link melalui WhatsApp, Instagram, Telegram, atau jaringan pribadi memiliki beberapa masalah:

- Jangkauan penyebaran terbatas.
- Link survei dapat diabaikan oleh calon responden.
- Responden yang diperoleh belum tentu sesuai dengan kriteria penelitian.
- Peneliti membutuhkan waktu lebih lama untuk mencapai jumlah responden yang ditargetkan.
- Proses pencarian responden dilakukan secara manual dan tidak terstruktur.

### 2.2 Masalah Responden

Dari sisi responden, terdapat kebutuhan untuk memperoleh:

- Kesempatan berpartisipasi dalam penelitian secara fleksibel.
- Penelitian yang sesuai dengan profil mereka.
- Kompensasi atas waktu yang digunakan untuk mengisi survei.
- Proses yang mudah dan terstruktur.

### 2.3 Core Problem

**Peneliti kesulitan memperoleh responden yang sesuai secara cepat dan terarah, sementara calon responden tidak memiliki tempat terpusat untuk menemukan penelitian yang relevan dan memperoleh kompensasi atas partisipasinya.**

---

# 3. Solution

SurvMarkt menyelesaikan masalah tersebut dengan membangun **marketplace responden penelitian** yang mempertemukan kedua sisi tersebut dalam satu platform.

### Untuk Peneliti

Peneliti dapat:

1. Membuat dan mempublikasikan survey.
2. Menentukan jumlah responden yang dibutuhkan.
3. Menentukan kriteria responden (gender, usia, status).
4. Menentukan besaran insentif per responden.
5. Menggunakan sistem matching/filtering untuk memperoleh responden yang sesuai.
6. Memantau progress penelitian secara real-time.
7. Menggunakan Featured Survey untuk meningkatkan visibilitas survey.
8. Pause/Resume survey kapan saja.
9. Melihat analytics: views, conversion rate, completion rate.
10. Mengelola wallet: deposit, riwayat transaksi.

### Untuk Responden

Responden dapat:

1. Membuat profil berdasarkan karakteristik yang dibutuhkan penelitian.
2. Menemukan survey yang sesuai dengan profil mereka.
3. Melihat insentif sebelum mengikuti survey.
4. Mengikuti penelitian secara fleksibel.
5. Mendapatkan insentif setelah menyelesaikan survey yang valid.
6. Melihat riwayat penelitian melalui history.
7. Mengelola wallet: saldo, withdrawal request.

---

# 4. Solution Novelty

### 4.1 Targeted Respondent Marketplace

SurvMarkt mempertemukan supply dan demand responden secara lebih terarah:

```
Peneliti → membutuhkan responden dengan karakteristik tertentu
Responden → mencari penelitian yang sesuai dengan profilnya
```

Sistem filtering dan matching menjadi penghubung kedua pihak.

### 4.2 Incentive-Based Participation

Responden memperoleh insentif sebagai kompensasi atas waktu dan partisipasi mereka. Insentif diposisikan sebagai **kompensasi waktu, bukan pembelian jawaban**, sehingga konsep marketplace tetap memperhatikan etika penelitian.

### 4.3 Academic-Focused Marketplace

Berbeda dari platform microtask umum, SurvMarkt difokuskan pada kebutuhan penelitian, khususnya pasar mahasiswa dan penelitian akademik di Indonesia.

### 4.4 Structured Research Ecosystem

SurvMarkt membangun alur terstruktur:

```
Upload Survey → Tentukan Kriteria → Matching → Responden Mengisi
→ Validasi → Insentif → Progress Tracking → Withdrawal
```

---

# 5. SDG Alignment — SDG 4: Quality Education

SurvMarkt berkontribusi terhadap **SDG 4 (Quality Education)** melalui dukungan terhadap aktivitas penelitian dan pembelajaran berbasis data.

```
Quality Education
↓
Pembelajaran dan penelitian akademik yang berkualitas
↓
Membutuhkan data dan evaluasi yang memadai
↓
Peneliti/mahasiswa membutuhkan responden
↓
SurvMarkt mempermudah akses terhadap responden yang sesuai
↓
Proses penelitian menjadi lebih cepat, terarah, dan efisien
```

---

# 6. User Persona

## Persona 1 — Peneliti / Mahasiswa

**Nama:** Raka  
**Usia:** 20–24 tahun  
**Status:** Mahasiswa tingkat akhir  
**Goal:** Mendapatkan responden penelitian dengan cepat dan sesuai kriteria.

**Pain Points:**
- Sulit mencapai target responden.
- Harus menyebarkan link ke banyak grup.
- Banyak orang tidak merespons.
- Responden yang diperoleh tidak selalu sesuai kriteria.
- Deadline penelitian terbatas.

**Value SurvMarkt:** *"Saya tidak perlu lagi mencari responden secara manual dari satu grup ke grup lain."*

---

## Persona 2 — Responden

**Nama:** Dinda  
**Usia:** 18–25 tahun  
**Status:** Mahasiswa / Pekerja / Masyarakat Umum  
**Goal:** Mengikuti penelitian yang sesuai profil dan memperoleh kompensasi.

**Pain Points:**
- Tidak tahu survey apa yang sedang membutuhkan responden.
- Banyak link survei tersebar tanpa informasi yang jelas.
- Tidak selalu mengetahui apakah survei cocok dengan profilnya.
- Mengisi survei tanpa kompensasi.

**Value SurvMarkt:** *"Saya bisa menemukan penelitian yang cocok dan mendapatkan kompensasi atas waktu saya."*

---

# 7. Business Model

## 7.1 Business Model Type: Two-Sided Marketplace

```
PENELITI
   │
   │ Membutuhkan responden, membayar insentif + fee
   ▼
SURVMARKT (Platform)
   │
   │ Matching + Filtering + Validasi
   ▼
RESPONDEN
   │
   │ Partisipasi penelitian
   ▼
INSENTIF
```

## 7.2 Revenue Model

### Primary Revenue — Platform Fee (20%)

SurvMarkt mengenakan **platform fee sebesar 20% dari total biaya insentif survey**.

```
Contoh:
- 100 responden × Rp2.000 insentif = Rp200.000 total insentif
- Platform fee 20% = Rp40.000
- Total tagihan peneliti = Rp240.000
```

### Secondary Revenue — Featured Survey

Peneliti dapat membayar biaya tambahan untuk menjadikan survey sebagai **Featured Survey**, memberikan visibilitas lebih tinggi di discovery feed responden.

---

# 8. Value Proposition

| Untuk Peneliti | Untuk Responden |
|---|---|
| **Cepat** — Kurangi waktu pencarian responden | **Relevan** — Survey disesuaikan dengan profil |
| **Tepat Sasaran** — Filter berbasis kriteria | **Fleksibel** — Kerjakan sesuai waktu tersedia |
| **Fleksibel** — Tentukan insentif & deadline sendiri | **Menguntungkan** — Dapat kompensasi atas partisipasi |
| **Terukur** — Analytics & progress real-time | **Transparan** — Informasi insentif jelas sebelum isi |

---

# 9. Core Product Flow

## Peneliti
```
Login → Dashboard → Buat Survey → Tentukan Responden
→ Tentukan Kriteria → Tentukan Insentif & Deadline
→ Publish → Matching Responden → Monitor Progress → Survey Selesai
```

## Responden
```
Login → Profil → Explore Survey → Filter/Matching
→ Survey Detail → Isi Survey → Validasi → Insentif Masuk Wallet → Withdraw
```

---

# 10. Product Scope v1.0

### Researcher Features
- Create Survey
- Respondent Criteria (Gender, Usia, Status: Mahasiswa/Pekerja/Masyarakat Umum)
- Incentive Management
- Platform Fee Calculation (otomatis 20%)
- Featured Survey (paid premium)
- Deadline Survey (preset: 7/14/30/60/90 hari, atau custom)
- Survey Progress (real-time)
- Pause / Resume Survey
- Delete Survey (soft delete + audit)
- Survey Analytics (views, conversion rate)
- Wallet & Deposit

### Respondent Features
- Survey Discovery & Search
- Incentive Filter
- Matching berbasis profil
- Survey Detail Modal
- Survey Participation
- Progress Tracking
- Survey History
- Notification
- Wallet & Withdrawal Request

### Admin Features
- Business Metrics Dashboard
- Revenue & Revenue Trend
- Total Users (Peneliti, Responden, Masyarakat Umum)
- Survey Statistics (OPEN, PAUSED, CLOSED, DELETED)
- Top Survey by Views
- Withdrawal Approval / Rejection
- Deleted Survey Audit (Soft Delete Log)
- Platform Monitoring

---

# 11. MoSCoW Prioritization

| Priority | Feature | Role |
|---|---|---|
| **MUST** | Auth (login, register, logout) | All |
| **MUST** | Role selection (Peneliti/Responden) | All |
| **MUST** | Create Survey + Criteria | Researcher |
| **MUST** | Fee Calculation | Researcher |
| **MUST** | Survey Discovery + Matching | Respondent |
| **MUST** | Survey Participation (redirect to form) | Respondent |
| **MUST** | Wallet display | All |
| **MUST** | Survey Progress | Researcher |
| **MUST** | Notifications | All |
| **SHOULD** | Featured Survey | Researcher |
| **SHOULD** | Deadline Survey | Researcher |
| **SHOULD** | Pause/Resume Survey | Researcher |
| **SHOULD** | Survey Analytics (views, conversion) | Researcher |
| **SHOULD** | Withdrawal Request | Respondent |
| **SHOULD** | Survey History | Respondent |
| **SHOULD** | Admin Dashboard | Admin |
| **COULD** | Revenue Trend Chart | Admin |
| **COULD** | Top Survey Widget | Admin |
| **COULD** | Soft Delete Audit Log | Admin |
| **WON'T (v1)** | In-app survey builder (forms) | Researcher |
| **WON'T (v1)** | Real-time chat researcher-responden | All |
| **WON'T (v1)** | Referral system | All |

---

# 12. Payment & Wallet Flow

```
[Peneliti Deposit] → Midtrans/Xendit → Wallet Peneliti (saldo bertambah)

[Peneliti Publish Survey] → Dana insentif ditahan di wallet peneliti

[Responden Submit Survey + Valid]
    → Platform fee (20%) masuk ke wallet SurvMarkt
    → Insentif netto masuk ke wallet Responden

[Responden Withdrawal Request]
    → Admin approve → Dana dipindah ke rekening (via payment gateway)
```

**Fee Calculation:**
```
Total Insentif = target_respondents × incentive_per_respondent
Platform Fee   = Total Insentif × 20%
Total Tagihan  = Total Insentif + Platform Fee
Featured Fee   = Terpisah (opsional, admin set harga)
```

---

# 13. Risk & Assumptions

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Fake Respondent | Survey tidak valid | Attention check, limit submission per user |
| Survey Abuse | Konten tidak etis | Terms of service, admin review |
| Payment Fraud | Withdrawal fraudulent | Admin approval wajib, limit withdrawal/hari |
| Low Quality Responses | Data penelitian tidak usable | Screening kriteria ketat |

**Assumptions:**
- Target pengguna pertama: mahasiswa Indonesia (usia 18-25).
- Insentif survey: Rp1.000 – Rp10.000 per responden.
- Platform fee tetap 20% untuk v1.0.
- Payment gateway: Midtrans atau Xendit (Indonesia).
- Backend menyediakan REST API; frontend mengonsumsi API.

---

# 14. Success Metrics

| Metric | Target v1.0 (3 bulan) |
|---|---|
| Peneliti yang membuat survei | 100+ |
| Survei yang mendapat responden | 50+ |
| Responden aktif (bulanan) | 500+ |
| Persentase survei mencapai target | > 70% |
| Total platform fee | Rp5.000.000+ |
| Completion rate survei | > 80% |
| Conversion rate views → responden | > 10% |

---

# 15. Vision

**Menjadi platform marketplace responden yang mempermudah proses penelitian dan membangun ekosistem riset yang lebih cepat, terarah, dan efisien.**

---

# 16. Appendix — Glossary

| Istilah | Definisi |
|---|---|
| Respondent | Orang yang mengisi survei penelitian |
| Researcher | Peneliti/mahasiswa yang membuat survei |
| Incentive | Imbalan bagi responden atas partisipasi |
| Platform Fee | Komisi SurvMarkt (20%) dari total insentif |
| Featured Survey | Survei dengan visibilitas lebih tinggi (paid) |
| Wallet | Saldo digital pengguna di dalam aplikasi |
| Withdrawal | Proses tarik saldo responden ke rekening bank |
| Matching | Proses menautkan survei dengan responden yang sesuai kriteria |
| Soft Delete | Survey dihapus tapi data tetap ada untuk audit admin |
| Deadline | Batas waktu survei aktif, ditentukan peneliti, gratis |

---

*PRD ini adalah acuan utama untuk development team dalam membangun SurvMarkt v1.0 Mobile App.*
