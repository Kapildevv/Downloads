import 'package:flutter/material.dart';

/// Howealthy Design System — Spacing & Layout Tokens
/// Ensures consistent padding, margins, and radii across all screens.
/// Optimized for Indian Android devices (5"–6.7" screens).
class AppSpacing {
  AppSpacing._();

  // ─── SPACING SCALE ────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ─── BORDER RADIUS ────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusFull = 999.0;

  // ─── PRE-BUILT BORDER RADII ───────────────────────────────
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // ─── PADDING PRESETS ──────────────────────────────────────
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: md);

  // ─── GLASSMORPHISM CONSTANTS ──────────────────────────────
  /// Blur sigma for glass cards — kept moderate for low-end devices
  static const double glassBlurSigma = 12.0;

  /// Lighter blur for overlays on 2GB RAM devices
  static const double glassBlurLight = 6.0;

  // ─── ELEVATION ────────────────────────────────────────────
  static const double elevationNone = 0.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // ─── ICON SIZES ───────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconHero = 80.0;

  // ─── ANIMATION DURATIONS (milliseconds) ───────────────────
  /// Fast micro-interactions (button presses, toggles)
  static const Duration animFast = Duration(milliseconds: 200);

  /// Standard transitions (page slides, card reveals)
  static const Duration animNormal = Duration(milliseconds: 350);

  /// Cinematic transitions (hero cards, onboarding slides)
  static const Duration animSlow = Duration(milliseconds: 600);

  /// Stagger delay between list items
  static const Duration staggerDelay = Duration(milliseconds: 80);
}
