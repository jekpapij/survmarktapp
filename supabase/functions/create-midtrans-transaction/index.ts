// CPMK 5 (Integration Engine) — Supabase Edge Function, pengganti Cloud
// Function `createMidtransTransaction` yang lama (lihat `functions/index.js`,
// sekarang DEPRECATED — dipindah ke sini 2026-09-10 biar nggak perlu upgrade
// Firebase ke plan Blaze cuma buat manggil API luar dari Cloud Functions).
//
// Dipanggil dari Flutter (`lib/core/network/midtrans_service.dart`) pas
// Researcher tap "Deposit Dana" — header `Authorization: Bearer <ID Token
// Firebase Auth user yang login>`, body `{"amount": number}`. Balikin
// `{orderId, redirectUrl}` buat dibuka di browser eksternal.
//
// SETUP WAJIB sebelum deploy — checklist bernomor lengkap ada di CLAUDE.md
// ("CPMK 5 — Payment Gateway Midtrans via Supabase"), ringkasnya: bikin
// project Supabase (gratis, nggak perlu kartu), install Supabase CLI,
// `supabase secrets set` buat FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/
// FIREBASE_PRIVATE_KEY (dari Service Account key Firebase Console) +
// MIDTRANS_SERVER_KEY/MIDTRANS_CLIENT_KEY (dari Dashboard Sandbox Midtrans),
// `supabase functions deploy create-midtrans-transaction --no-verify-jwt`
// (WAJIB `--no-verify-jwt` — token yang dikirim itu ID Token FIREBASE, bukan
// token Supabase, jadi verifikasi JWT bawaan Supabase justru bakal NOLAK
// request yang valid kalau nggak dimatiin; verifikasi tokennya kita
// lakuin manual sendiri lewat `verifyFirebaseIdToken` di bawah).

import { verifyFirebaseIdToken, firestoreCommit, firestoreGet, firestoreDelete, CORS_HEADERS } from "../_shared/firebase.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS_HEADERS });
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  // Pengganti `request.auth` bawaan `onCall` Firebase — di sini diverifikasi manual.
  const authHeader = req.headers.get("Authorization") ?? "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
  if (!idToken) return json({ error: "unauthenticated", message: "Login dulu sebelum deposit." }, 401);

  let uid: string;
  let userEmail: string | undefined;
  try {
    const decoded = await verifyFirebaseIdToken(idToken);
    uid = decoded.uid;
    userEmail = decoded.email;
  } catch (e) {
    return json({ error: "unauthenticated", message: `Sesi tidak valid: ${(e as Error).message}` }, 401);
  }

  let amount: unknown;
  try {
    const body = await req.json();
    amount = body?.amount;
  } catch {
    return json({ error: "invalid-argument", message: "Body request tidak valid (harus JSON)." }, 400);
  }
  if (typeof amount !== "number" || !Number.isFinite(amount) || amount <= 0) {
    return json({ error: "invalid-argument", message: "Nominal deposit tidak valid." }, 400);
  }

  const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY");
  const clientKey = Deno.env.get("MIDTRANS_CLIENT_KEY");
  if (!serverKey || !clientKey) {
    return json(
      { error: "failed-precondition", message: "MIDTRANS_SERVER_KEY/MIDTRANS_CLIENT_KEY belum di-set — lihat checklist CLAUDE.md." },
      500,
    );
  }

  const orderId = `deposit-${uid}-${Date.now()}`;
  const grossAmount = Math.round(amount);
  const txPath = `wallets/${uid}/transactions/${orderId}`;

  // Dokumen 'pending' dibikin DULUAN (sebelum manggil Midtrans) — sama
  // alasannya kayak versi Cloud Function lama: biar app Flutter bisa
  // langsung mulai listen ke dokumen ini dari detik pertama.
  try {
    await firestoreCommit([
      {
        path: txPath,
        fields: { type: "deposit", title: "Deposit Dana", amount: grossAmount, status: "pending", createdAt: "SERVER_TIMESTAMP" },
      },
    ]);
  } catch (e) {
    // Dibungkus try/catch (2026-09-10, nyusul bugfix `firestoreResourceName`)
    // biar Flutter dapet JSON error yang jelas ("Respons server pembayaran
    // tidak valid" sebelumnya kejadian karena error di sini ke-throw
    // unhandled, Supabase balikin 500 generik yang bukan JSON, bukan format
    // `{error, message}` yang diharapkan `MidtransService`).
    return json({ error: "internal", message: `Gagal bikin dokumen transaksi: ${(e as Error).message}` }, 502);
  }

  // Best-effort ambil email dari profil Firestore (buat `customer_details`
  // Midtrans) — fallback ke email dari ID Token kalau profil belum kebaca.
  let email = userEmail;
  try {
    const userDoc = await firestoreGet(`users/${uid}`);
    if (userDoc.exists && typeof userDoc.data.email === "string") email = userDoc.data.email as string;
  } catch {
    // Non-fatal.
  }

  try {
    const midtransRes = await fetch("https://app.sandbox.midtrans.com/snap/v1/transactions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${btoa(`${serverKey}:`)}`,
      },
      body: JSON.stringify({
        transaction_details: { order_id: orderId, gross_amount: grossAmount },
        customer_details: email ? { email } : undefined,
      }),
    });
    if (!midtransRes.ok) {
      const errText = await midtransRes.text();
      throw new Error(`Midtrans API menolak request: ${midtransRes.status} ${errText}`);
    }
    const data = await midtransRes.json() as { redirect_url: string };
    return json({ orderId, redirectUrl: data.redirect_url }, 200);
  } catch (e) {
    // Bersihin dokumen 'pending' yang keburu kebentuk kalau Midtrans-nya sendiri yang nolak.
    await firestoreDelete(txPath);
    return json({ error: "internal", message: `Gagal bikin transaksi Midtrans: ${(e as Error).message}` }, 502);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}
