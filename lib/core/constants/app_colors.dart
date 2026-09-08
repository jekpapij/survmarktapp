import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Indigo
  static const Color primary900 = Color(0xFF312E81);
  // Update 2026-09-07: disamain persis sama warna tombol/link nyata di file
  // Figma (dicek via Figma Dev Mode MCP get_design_context pada frame
  // login-page) — sebelumnya #4F46E5, aslinya di Figma #4338CA. Ini global,
  // jadi kepake otomatis di semua tombol/link primary di seluruh app.
  static const Color primary600 = Color(0xFF4338CA);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary50  = Color(0xFFEEF2FF);
  // Update 2026-09-08: shade indigo KEDUA, beda dari primary600. Ketemu pas
  // get_design_context frame `researcher-dashboard` — progress bar fill &
  // aksen bottom-nav aktif konsisten pakai #4F46E5 (indigo-600 Tailwind
  // standar, warna primary600 YANG LAMA sebelum diganti user ke #4338CA
  // khusus tombol/link). Kemungkinan besar ini karena frame dashboard
  // di-generate lewat Figma AI prompting (2026-09-02) SEBELUM keputusan
  // recolor tombol/link (2026-09-07) — bukan typo, tapi juga belum tentu
  // "disengaja" kayak yang di login/register. Diputuskan: dipisah jadi
  // token sendiri (bukan dipaksa jadi primary600) karena konsisten dipakai
  // di 3 tempat berbeda dalam 1 frame — aman buat dikoreksi ke primary600
  // nanti kalau user bilang itu emang harusnya sama.
  static const Color indigoAccent = Color(0xFF4F46E5);

  // Accent — Amber
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber100 = Color(0xFFFDE68A);
  static const Color amber50  = Color(0xFFFFFBEB);

  // Neutral
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Dark mode
  static const Color darkBg      = Color(0xFF0F0D2E);
  static const Color darkSurface = Color(0xFF1A1740);
  static const Color darkCard    = Color(0xFF1E293B);
}
