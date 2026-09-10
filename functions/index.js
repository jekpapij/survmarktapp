/**
 * DEPRECATED 2026-09-10 — file ini SENGAJA DIBIARKAN KOSONG/nggak dipakai.
 *
 * Payment Gateway Midtrans (CPMK 5 — Integration Engine) awalnya dibangun
 * di sini sebagai Firebase Cloud Functions v2, TAPI Cloud Functions v2
 * WAJIB upgrade project Firebase ke plan Blaze (pay-as-you-go) buat bisa
 * akses jaringan keluar (manggil API Midtrans) — dan Google Cloud minta
 * PREPAYMENT DI MUKA (bukan sekadar kartu buat verifikasi, beneran charge
 * di depan, walau technically jadi credit/bisa di-refund) buat akun
 * billing baru di Indonesia. Ini friksi yang nggak sepadan buat 1 fitur
 * kecil di proyek tugas kuliah.
 *
 * **Logic-nya DIPINDAH ke Supabase Edge Functions** (gratis, nggak perlu
 * kartu sama sekali) — lihat folder `supabase/functions/` di root project
 * ini:
 * - `supabase/functions/create-midtrans-transaction/index.ts` (pengganti
 *   `createMidtransTransaction` di bawah)
 * - `supabase/functions/midtrans-notification-handler/index.ts` (pengganti
 *   `midtransNotificationHandler` di bawah)
 * - `supabase/functions/_shared/firebase.ts` (helper verifikasi ID Token
 *   Firebase Auth + panggil Firestore REST API — pengganti `request.auth`
 *   & `admin.firestore()` yang otomatis didapet gratis di Cloud Functions)
 *
 * Checklist setup lengkap (Supabase CLI, secrets, deploy, webhook URL) ada
 * di CLAUDE.md ("CPMK 5 — Payment Gateway Midtrans via Supabase").
 *
 * Folder `functions/` ini boleh dihapus manual kapan aja kalau mau beres-
 * beres (nggak pernah sempet di-`firebase init functions`/deploy, jadi
 * nggak ada infrastruktur live yang perlu dibersihin di sisi Firebase) —
 * tapi dibiarin ada dulu sebagai jejak/referensi histori keputusan.
 */
