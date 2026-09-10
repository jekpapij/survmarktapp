// CPMK 5 (Integration Engine) — Supabase Edge Function, pengganti Cloud
// Function `midtransNotificationHandler` yang lama (lihat `functions/index.js`,
// sekarang DEPRECATED — dipindah ke sini 2026-09-10, alasan sama kayak
// `create-midtrans-transaction/index.ts`: hindari Firebase plan Blaze).
//
// Ini WEBHOOK PUBLIK (bukan dipanggil Flutter) — di-set sebagai "Payment
// Notification URL" di Dashboard Midtrans Sandbox, dipanggil Midtrans
// SERVER-KE-SERVER begitu status pembayaran berubah. TIDAK ada header
// Authorization Firebase di sini (Midtrans yang manggil, bukan app) —
// keamanannya dari verifikasi `signature_key` (baris di bawah), BUKAN dari
// token Firebase. Makanya function ini JUGA WAJIB di-deploy dengan
// `--no-verify-jwt` (Midtrans nggak pernah kirim token Supabase apapun).
//
// SETUP: lihat checklist lengkap di CLAUDE.md ("CPMK 5 — Payment Gateway
// Midtrans via Supabase") — deploy pakai
// `supabase functions deploy midtrans-notification-handler --no-verify-jwt`,
// terus copy URL hasil deploy-nya ke Dashboard Sandbox Midtrans -> Settings
// -> Configuration -> "Payment Notification URL".

import { firestoreCommit, firestoreGet, CORS_HEADERS } from "../_shared/firebase.ts";

interface MidtransNotification {
  order_id?: string;
  status_code?: string;
  gross_amount?: string; // STRING dari Midtrans (mis. "10000.00") — JANGAN diubah sebelum verifikasi signature.
  signature_key?: string;
  transaction_status?: string;
  fraud_status?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS_HEADERS });
  if (req.method !== "POST") return text("Method not allowed.", 405);

  let body: MidtransNotification;
  try {
    body = await req.json();
  } catch {
    return text("Payload bukan JSON valid.", 400);
  }

  const { order_id: orderId, status_code: statusCode, gross_amount: grossAmount, signature_key: signatureKey, transaction_status: transactionStatus, fraud_status: fraudStatus } = body;
  if (!orderId || !statusCode || !grossAmount || !signatureKey) {
    return text("Payload tidak lengkap.", 400);
  }

  const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY");
  if (!serverKey) return text("MIDTRANS_SERVER_KEY belum di-set.", 500);

  const expectedSignature = await sha512Hex(`${orderId}${statusCode}${grossAmount}${serverKey}`);
  if (expectedSignature !== signatureKey) return text("Signature tidak valid.", 403);

  // Format order_id: `deposit-{uid}-{timestamp}` — uid Firebase Auth nggak
  // pernah mengandung karakter "-", jadi split aman (sama persis logic-nya
  // kayak versi Cloud Function lama).
  const parts = orderId.split("-");
  if (parts.length < 3 || parts[0] !== "deposit") {
    return text("OK (order_id di luar format yang dikenali, diabaikan).", 200);
  }
  const uid = parts[1];
  const walletPath = `wallets/${uid}`;
  const txPath = `wallets/${uid}/transactions/${orderId}`;

  const isSuccess = transactionStatus === "settlement" || (transactionStatus === "capture" && fraudStatus === "accept");
  const isFailed = ["deny", "cancel", "expire"].includes(transactionStatus ?? "");

  if (isSuccess) {
    // Pengganti `db.runTransaction()` Admin SDK: baca dulu (buat cek
    // idempotency + dapetin `updateTime` wallet buat optimistic-concurrency
    // precondition), baru commit 2 write (saldo + status transaksi)
    // SEKALIGUS dalam 1 panggilan atomik. Retry 1x kalau ada race
    // (precondition gagal karena ada write lain di antara read & commit —
    // sangat jarang buat skala trafik proyek kelas, tapi tetap ditangani).
    for (let attempt = 0; attempt < 2; attempt++) {
      const txDoc = await firestoreGet(txPath);
      if (txDoc.exists && txDoc.data.status === "success") {
        return text("OK (sudah diproses sebelumnya).", 200);
      }
      const walletDoc = await firestoreGet(walletPath);
      const currentBalance = typeof walletDoc.data.balance === "number" ? walletDoc.data.balance : 0;
      try {
        await firestoreCommit([
          {
            path: walletPath,
            fields: { balance: currentBalance + Number(grossAmount) },
            requireUpdateTime: walletDoc.exists ? walletDoc.updateTime : undefined,
          },
          { path: txPath, fields: { status: "success" } },
        ]);
        break;
      } catch (e) {
        const status = (e as Error & { status?: number }).status;
        if ((status === 409 || status === 412) && attempt === 0) continue; // retry sekali
        throw e;
      }
    }
  } else if (isFailed) {
    await firestoreCommit([{ path: txPath, fields: { status: "failed" } }]);
  }
  // `transactionStatus === 'pending'` -> biarin apa adanya, nunggu notifikasi berikutnya.

  return text("OK", 200);
});

async function sha512Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-512", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function text(body: string, status: number): Response {
  return new Response(body, { status, headers: { "Content-Type": "text/plain", ...CORS_HEADERS } });
}
