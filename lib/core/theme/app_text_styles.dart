import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system: elegant serif for brand/hero moments,
/// clean geometric sans for UI and body text.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _serifBase => GoogleFonts.playfairDisplay();
  static TextStyle get _sansBase => GoogleFonts.plusJakartaSans();

  // Brand / hero
  static TextStyle logo = _serifBase.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    letterSpacing: -0.5,
  );

  static TextStyle heroTitle = _serifBase.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.ivory,
    height: 1.2,
  );

  static TextStyle displaySerif = _serifBase.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    height: 1.25,
  );

  // Headings
  static TextStyle h1 = _sansBase.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
    letterSpacing: -0.3,
  );

  static TextStyle h2 = _sansBase.copyWith(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
    letterSpacing: -0.2,
  );

  static TextStyle h3 = _sansBase.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.charcoal,
  );

  // Body
  static TextStyle bodyLarge = _sansBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoalSoft,
    height: 1.4,
  );

  static TextStyle bodyMedium = _sansBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.graphite,
    height: 1.4,
  );

  static TextStyle bodySmall = _sansBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedGray,
    height: 1.3,
  );

  // Labels / UI
  static TextStyle label = _sansBase.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    letterSpacing: 0.1,
  );

  static TextStyle labelMuted = _sansBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedGray,
  );

  static TextStyle button = _sansBase.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ivory,
    letterSpacing: 0.1,
  );

  static TextStyle caption = _sansBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedGray,
  );

  static TextStyle navLabel = _sansBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
