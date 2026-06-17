import 'package:flutter/material.dart';

const Color workLedgerColorPrimary = Color(0xFF181D26);
const Color workLedgerColorPrimaryActive = Color(0xFF0D1218);
const Color workLedgerColorInk = Color(0xFF181D26);
const Color workLedgerColorBody = Color(0xFF333840);
const Color workLedgerColorMuted = Color(0xFF41454D);
const Color workLedgerColorHairline = Color(0xFFDDDDDD);
const Color workLedgerColorBorderStrong = Color(0xFF9297A0);
const Color workLedgerColorCanvas = Color(0xFFFFFFFF);
const Color workLedgerColorSurfaceSoft = Color(0xFFF8FAFC);
const Color workLedgerColorSurfaceDark = Color(0xFF181D26);
const Color workLedgerColorSignatureCoral = Color(0xFFAA2D00);
const Color workLedgerColorSignatureForest = Color(0xFF0A2E0E);
const Color workLedgerColorOnPrimary = Color(0xFFFFFFFF);
const Color workLedgerColorOnDarkMuted = Color(0xCCFFFFFF);
const Color workLedgerColorInfoBorder = Color(0xFF458FFF);
const Color workLedgerColorPricingInk = Color(0xFF1D1F25);

const double workLedgerRadiusSmall = 6;
const double workLedgerRadiusMedium = 10;
const double workLedgerRadiusLarge = 12;
const double workLedgerRadiusPill = 9999;

const double workLedgerSpacingHairline = 2;
const double workLedgerSpacingCalendarMarker = 3;
const double workLedgerSpacingExtraExtraSmall = 4;
const double workLedgerSpacingDense = 6;
const double workLedgerSpacingExtraSmall = 8;
const double workLedgerSpacingCompact = 10;
const double workLedgerSpacingSmall = 12;
const double workLedgerSpacingFieldVertical = 13;
const double workLedgerSpacingMedium = 16;
const double workLedgerSpacingLarge = 24;
const double workLedgerSpacingExtraLarge = 32;

const TextStyle workLedgerButtonTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.4,
  letterSpacing: 0,
);

const TextStyle workLedgerBodyTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.25,
  letterSpacing: 0,
);

const TextStyle workLedgerLabelTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.4,
  letterSpacing: 0,
);

const TextStyle workLedgerTitleMediumTextStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: 0,
);

const TextStyle workLedgerTitleSmallTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  height: 1.4,
  letterSpacing: 0,
);

// Inter Display asset은 MVP에 번들하지 않고 플랫폼 기본 글꼴 폴백을 사용한다.
const TextStyle workLedgerPricingCardTitleTextStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 0,
);

ThemeData createWorkLedgerTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: workLedgerColorPrimary,
    primary: workLedgerColorPrimary,
    surface: workLedgerColorCanvas,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: workLedgerColorCanvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: workLedgerColorCanvas,
      foregroundColor: workLedgerColorInk,
      surfaceTintColor: workLedgerColorCanvas,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      bodyMedium: workLedgerBodyTextStyle,
      bodySmall: workLedgerBodyTextStyle,
      labelLarge: workLedgerButtonTextStyle,
      labelMedium: workLedgerLabelTextStyle,
      titleMedium: workLedgerTitleMediumTextStyle,
      titleSmall: workLedgerTitleSmallTextStyle,
    ),
    dividerTheme: const DividerThemeData(
      color: workLedgerColorHairline,
      space: 1,
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: workLedgerColorPrimary,
        foregroundColor: workLedgerColorOnPrimary,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
        ),
        textStyle: workLedgerButtonTextStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: workLedgerColorInk,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: workLedgerColorHairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
        ),
        textStyle: workLedgerButtonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: workLedgerColorMuted,
        textStyle: workLedgerButtonTextStyle,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: workLedgerColorInk,
        backgroundColor: workLedgerColorCanvas,
        shape: const CircleBorder(),
        minimumSize: const Size.square(40),
      ),
    ),
    cardTheme: CardThemeData(
      color: workLedgerColorCanvas,
      surfaceTintColor: workLedgerColorCanvas,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
        side: const BorderSide(color: workLedgerColorHairline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: workLedgerColorSurfaceSoft,
      selectedColor: workLedgerColorInk,
      disabledColor: workLedgerColorSurfaceSoft,
      checkmarkColor: workLedgerColorOnPrimary,
      labelStyle: workLedgerBodyTextStyle.copyWith(color: workLedgerColorInk),
      secondaryLabelStyle: workLedgerBodyTextStyle.copyWith(
        color: workLedgerColorOnPrimary,
      ),
      side: const BorderSide(color: workLedgerColorHairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: workLedgerColorInk,
      textColor: workLedgerColorInk,
      titleTextStyle: workLedgerLabelTextStyle,
      subtitleTextStyle: workLedgerBodyTextStyle,
      contentPadding: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: workLedgerColorCanvas,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: workLedgerSpacingMedium,
        vertical: workLedgerSpacingSmall,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
        borderSide: const BorderSide(color: workLedgerColorHairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
        borderSide: const BorderSide(color: workLedgerColorHairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(workLedgerRadiusSmall),
        borderSide: const BorderSide(color: workLedgerColorInfoBorder),
      ),
    ),
  );
}
