import 'package:flutter/material.dart';

/// Color palette mirroring the existing Expo app's useColors.ts
class AppColors {
  AppColors._();

  // ── Light Theme ──────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightForeground = Color(0xFF0F172A);
  static const Color lightPrimary = Color(0xFF1D4ED8);
  static const Color lightPrimaryForeground = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFFF1F5F9);
  static const Color lightMutedForeground = Color(0xFF64748B);
  static const Color lightAccent = Color(0xFFEFF6FF);
  static const Color lightAccentForeground = Color(0xFF1D4ED8);

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkForeground = Color(0xFFF8FAFC);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkPrimaryForeground = Color(0xFFFFFFFF);
  static const Color darkMuted = Color(0xFF1E293B);
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkAccent = Color(0xFF172554);
  static const Color darkAccentForeground = Color(0xFF93C5FD);

  // ── Semantic aliases ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
}
