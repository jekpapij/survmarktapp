// CPMK 5 (Integration Engine) — helper bersama buat kedua Supabase Edge
// Function (`create-midtrans-transaction` & `midtrans-notification-handler`).
//
// Kenapa file ini ada: begitu Payment Gateway pindah dari Firebase Cloud
// Functions ke Supabase Edge Functions (keputusan user 2026-09-10, biar
// nggak perlu upgrade Firebase ke plan Blaze cuma buat 1 fitur kecil), kode
// yang jalan di sini BUKAN lagi "di dalam" project Firebase — jadi 2 hal
// yang dulu otomatis dikasih gratis sama Firebase (`request.auth` di Cloud
// Function, `admin.firestore()` Admin SDK) sekarang harus diimplementasi
// manual pakai REST API murni + Web Crypto API (Deno/Supabase Edge Runtime
// nggak jalanin Node.js beneran, `firebase-admin` nggak reliable dipasang
// di sini) — TAPI konsepnya sama persis kayak versi Cloud Functions yang
// lama (`functions/index.js`, sekarang DEPRECATED, lihat catatan di file
// itu), cuma "cara nyampe ke situ"-nya beda.
//
// 2 hal yang direplikasi manual di file ini:
// 1. `verifyFirebaseIdToken` — pengganti `request.auth` bawaan Firebase
//    `onCall`. Verifikasi ID Token Firebase Auth (dikirim Flutter lewat
//    header `Authorization: Bearer <token>`) pakai public key Google
//    (format JWK, endpoint resmi Google — BUKAN endpoint tebakan) + Web
//    Crypto API bawaan Deno (RS256), tanpa perlu library JWT pihak ketiga.
// 2. `getFirebaseAccessToken` + `firestoreCommit`/`firestoreGet` — pengganti
//    `admin.firestore()` Admin SDK. Pakai Service Account key Firebase
//    (didapet dari Firebase Console -> Project Settings -> Service
//    Accounts -> Generate new private key, JSON) buat dapetin OAuth2 access
//    token (JWT Bearer flow standar Google), terus manggil Firestore REST
//    API langsung. Kredensial ini SECRET, disimpen sebagai Supabase secrets
//    (`FIREBASE_PROJECT_ID`/`FIREBASE_CLIENT_EMAIL`/`FIREBASE_PRIVATE_KEY`)
//    — lihat checklist setup lengkap di CLAUDE.md "CPMK 5 — Payment Gateway
//    Midtrans via Supabase".

// ---------- base64url helpers ----------

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/[/]/g, "_").replace(/=+$/, "");
}

function base64UrlDecode(str: string): Uint8Array<ArrayBuffer> {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((str.length + 3) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function jsonToBase64Url(obj: unknown): string {
  return base64UrlEncode(new TextEncoder().encode(JSON.stringify(obj)));
}

function base64UrlToJson<T>(segment: string): T {
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(segment))) as T;
}

// ---------- Service Account env ----------

interface ServiceAccountEnv {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

function getServiceAccountEnv(): ServiceAccountEnv {
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  // Private key disimpen sebagai 1 baris di Supabase secrets (literal `\n`
  // buat ganti baris, bukan newline beneran — cara paling gampang nge-paste
  // value dari JSON service account ke `supabase secrets set`) — di-unescape
  // di sini jadi newline beneran biar valid PEM.
  const privateKeyRaw = Deno.env.get("FIREBASE_PRIVATE_KEY");
  if (!projectId || !clientEmail || !privateKeyRaw) {
    throw new Error(
      "FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY belum di-set di Supabase secrets — lihat checklist CLAUDE.md.",
    );
  }
  return { projectId, clientEmail, privateKey: privateKeyRaw.replace(/\\n/g, "\n") };
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  // Body PEM itu base64 STANDAR (pakai '+'/'/', bukan base64url) — decode
  // langsung pakai `atob`, JANGAN lewat `base64UrlDecode` (fungsi itu buat
  // string base64url, alfabetnya beda).
  const stripped = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(stripped);
  const der = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) der[i] = binary.charCodeAt(i);
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

// ---------- OAuth2 access token (JWT Bearer flow, buat panggil Firestore REST API) ----------

let cachedToken: { value: string; expiresAtMs: number } | null = null;

/**
 * Tuker Service Account key jadi OAuth2 access token buat Firestore REST
 * API (scope `datastore`). Di-cache in-memory selama masih valid (isolate
 * Edge Function bisa "warm"/dipakai ulang antar-request — kalaupun nggak,
 * ini cuma optimisasi, tetep aman kalau ternyata selalu generate baru).
 */
export async function getFirebaseAccessToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAtMs - 60_000 > now) return cachedToken.value;

  const { clientEmail, privateKey } = getServiceAccountEnv();
  const nowSec = Math.floor(now / 1000);
  const header = jsonToBase64Url({ alg: "RS256", typ: "JWT" });
  const claims = jsonToBase64Url({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    iat: nowSec,
    exp: nowSec + 3600,
  });
  const signingInput = `${header}.${claims}`;
  const key = await importPrivateKey(privateKey);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`Gagal tuker Service Account key jadi access token: ${res.status} ${await res.text()}`);
  }
  const data = await res.json() as { access_token: string; expires_in: number };
  cachedToken = { value: data.access_token, expiresAtMs: now + data.expires_in * 1000 };
  return data.access_token;
}

// ---------- Verifikasi ID Token Firebase Auth (pengganti `request.auth` bawaan onCall) ----------

interface DecodedFirebaseToken {
  uid: string;
  email?: string;
}

/**
 * Verifikasi ID Token Firebase Auth (dikirim Flutter via
 * `FirebaseAuth.instance.currentUser.getIdToken()`, header `Authorization:
 * Bearer <token>`) — pakai public key JWK resmi Google (BUKAN endpoint
 * X.509 cert yang butuh parsing ASN.1 manual, JWK jauh lebih simpel buat
 * di-import langsung ke Web Crypto API). Throw kalau invalid/expired/salah
 * project — caller (index.ts) yang nangkep & balikin 401.
 */
export async function verifyFirebaseIdToken(idToken: string): Promise<DecodedFirebaseToken> {
  const { projectId } = getServiceAccountEnv();
  const parts = idToken.split(".");
  if (parts.length !== 3) throw new Error("Format ID Token nggak valid.");
  const [headerB64, payloadB64, signatureB64] = parts;

  const header = base64UrlToJson<{ kid?: string; alg?: string }>(headerB64);
  const payload = base64UrlToJson<{
    aud?: string;
    iss?: string;
    exp?: number;
    iat?: number;
    sub?: string;
    email?: string;
  }>(payloadB64);

  if (header.alg !== "RS256" || !header.kid) throw new Error("Algoritma/kid ID Token nggak dikenali.");
  if (payload.aud !== projectId) throw new Error("ID Token buat project Firebase lain.");
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) throw new Error("Issuer ID Token nggak valid.");
  const nowSec = Math.floor(Date.now() / 1000);
  if (!payload.exp || payload.exp < nowSec) throw new Error("ID Token sudah expired.");
  if (!payload.sub) throw new Error("ID Token nggak punya `sub` (uid).");

  const jwksRes = await fetch("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com");
  if (!jwksRes.ok) throw new Error("Gagal ambil public key Google buat verifikasi ID Token.");
  const jwks = await jwksRes.json() as { keys: (JsonWebKey & { kid?: string })[] };
  const jwk = jwks.keys.find((k) => k.kid === header.kid);
  if (!jwk) throw new Error("Public key (kid) buat ID Token ini nggak ketemu — coba lagi (key rotation Google).");

  const publicKey = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    base64UrlDecode(signatureB64),
    new TextEncoder().encode(`${headerB64}.${payloadB64}`),
  );
  if (!valid) throw new Error("Signature ID Token nggak valid.");

  return { uid: payload.sub, email: payload.email };
}

// ---------- Firestore REST API (pengganti Admin SDK `admin.firestore()`) ----------

function firestoreDocUrl(projectId: string, path: string): string {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`;
}

/**
 * Bug ketemu 2026-09-10 (dari log error Supabase — "Document name ... lacks
 * \"projects\" at index 0"): `Write.update.name` di body JSON `:commit`
 * HARUS resource name TANPA prefix `https://firestore.googleapis.com/v1/`
 * (beda dari URL buat `fetch()` biasa di `firestoreGet`/`firestoreDelete`,
 * yang justru WAJIB pakai full URL). `firestoreCommit` di bawah kepakean
 * `firestoreDocUrl` (full URL) buat ini secara salah — sekarang dipisah ke
 * helper sendiri.
 */
function firestoreResourceName(projectId: string, path: string): string {
  return `projects/${projectId}/databases/(default)/documents/${path}`;
}

/** Convert object JS biasa -> format `fields` Firestore REST API (subset tipe yang dipakai app ini aja: string/int/bool/null/timestamp). */
export function toFirestoreFields(obj: Record<string, unknown>): Record<string, unknown> {
  const fields: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) {
      fields[key] = { nullValue: null };
    } else if (typeof value === "string") {
      fields[key] = value === "SERVER_TIMESTAMP" ? { timestampValue: new Date().toISOString() } : { stringValue: value };
    } else if (typeof value === "number") {
      fields[key] = Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
    } else if (typeof value === "boolean") {
      fields[key] = { booleanValue: value };
    }
  }
  return fields;
}

/** Convert format `fields` Firestore REST API -> object JS biasa (subset tipe yang sama kayak di atas). */
export function fromFirestoreFields(fields: Record<string, Record<string, unknown>> | undefined): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (!fields) return out;
  for (const [key, wrapped] of Object.entries(fields)) {
    if ("stringValue" in wrapped) out[key] = wrapped.stringValue;
    else if ("integerValue" in wrapped) out[key] = Number(wrapped.integerValue);
    else if ("doubleValue" in wrapped) out[key] = wrapped.doubleValue;
    else if ("booleanValue" in wrapped) out[key] = wrapped.booleanValue;
    else if ("timestampValue" in wrapped) out[key] = wrapped.timestampValue;
    else if ("nullValue" in wrapped) out[key] = null;
  }
  return out;
}

export interface FirestoreDoc {
  exists: boolean;
  data: Record<string, unknown>;
  updateTime?: string;
}

/** GET 1 dokumen. `exists:false` kalau dokumennya belum ada (404 dari Firestore, bukan error jaringan). */
export async function firestoreGet(path: string): Promise<FirestoreDoc> {
  const { projectId } = getServiceAccountEnv();
  const token = await getFirebaseAccessToken();
  const res = await fetch(firestoreDocUrl(projectId, path), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 404) return { exists: false, data: {} };
  if (!res.ok) throw new Error(`Firestore GET ${path} gagal: ${res.status} ${await res.text()}`);
  const doc = await res.json() as { fields?: Record<string, Record<string, unknown>>; updateTime?: string };
  return { exists: true, data: fromFirestoreFields(doc.fields), updateTime: doc.updateTime };
}

export interface FirestoreWrite {
  path: string;
  fields: Record<string, unknown>;
  /** Kalau di-set, update ini CUMA jalan kalau `updateTime` dokumen di server masih SAMA (optimistic concurrency — pengganti `db.runTransaction` Admin SDK). */
  requireUpdateTime?: string;
}

/**
 * Commit 1 atau lebih write SEKALIGUS — Firestore REST API menjamin semua
 * write dalam 1 panggilan `:commit` atomik (semua sukses atau semua gagal),
 * SEKALIPUN nggak pakai `beginTransaction` eksplisit. Ini yang dipakai
 * `midtrans-notification-handler` buat update saldo wallet + status
 * transaksi jadi 1 operasi atomik, pengganti `db.runTransaction()` versi
 * Admin SDK yang lama.
 */
export async function firestoreCommit(writes: FirestoreWrite[]): Promise<void> {
  const { projectId } = getServiceAccountEnv();
  const token = await getFirebaseAccessToken();
  const body = {
    writes: writes.map((w) => ({
      update: { name: firestoreResourceName(projectId, w.path), fields: toFirestoreFields(w.fields) },
      ...(w.requireUpdateTime ? { currentDocument: { updateTime: w.requireUpdateTime } } : {}),
    })),
  };
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );
  if (!res.ok) {
    const text = await res.text();
    const err = new Error(`Firestore commit gagal: ${res.status} ${text}`);
    (err as Error & { status?: number }).status = res.status;
    throw err;
  }
}

/** Hapus 1 dokumen (dipakai buat rollback dokumen `pending` kalau ternyata Midtrans API-nya sendiri gagal). */
export async function firestoreDelete(path: string): Promise<void> {
  const { projectId } = getServiceAccountEnv();
  const token = await getFirebaseAccessToken();
  await fetch(firestoreDocUrl(projectId, path), {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}` },
  }).catch(() => {});
}

/** Header CORS standar — dipasang di semua response biar aman kalau suatu saat dipanggil dari web/browser juga, nggak ngefek ke panggilan dari app mobile. */
export const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
