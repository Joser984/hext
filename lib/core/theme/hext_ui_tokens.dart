import 'package:flutter/material.dart';

class HextColors {
  static const Color primary = Color(0xFF17726D);
  static const Color primaryHover = Color(0xFF135E59);
  static const Color primaryPressed = Color(0xFF0F4A46);
  static const Color primarySoft = Color(0x1417726D);
  static const Color secondary = Color(0xFFCCBA86);
  static const Color overlay = Color(0x661F2937);

  static const Color sidebarDark = primary;
  static const Color sidebar = primary;
  static const Color sidebarSelected = Color(0x1AFFFFFF);

  static const Color background = Color(0xFFF7F9F8);
  static const Color card = Colors.white;
  static const Color subcard = Color(0xFFF7F9F8);
  static const Color border = Color(0xFFDDE4E8);
  static const Color borderSoft = Color(0xFFDDE4E8);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF7A869A);

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFF3E0);
  static const Color warningText = Color(0xFF9A3412);
  static const Color success = primary;
}

class HextDimens {
  static const double pageMaxWidth = 1720.0;
  static const double pageMaxWidthForm = 1720.0;
  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double topBarHeight = 72.0;

  static const double fieldHeight = 40.0;
  static const double buttonHeight = 40.0;
  static const double chipHeight = 40.0;

  static const double radiusField = 8.0;
  static const double radiusPill = 999.0;
  static const double radiusChip = 8.0;
  static const double radiusCard = 12.0;
  static const double radiusSubcard = 10.0;
  static const double radiusModal = 16.0;

  static const double paddingCard = 16.0;
  static const double paddingModal = 24.0;
  static const double gap = 12.0;
  static const double sectionGap = 16.0;

  static const double iconSize = 18.0;
  static const double sidebarIconSize = 20.0;

  static const double labelGap = 6.0;
  static const double autocompleteWidth = 360.0;
  static const double autocompleteMaxHeight = 260.0;
  static const double autocompleteItemHorizontalPadding = 12.0;
  static const double autocompleteItemVerticalPadding = 10.0;

  static double pageHorizontalPadding(double width) {
    return width >= 900 ? 32.0 : 16.0;
  }

  static EdgeInsets pagePadding(
    double width, {
    double top = 24.0,
    double bottom = 24.0,
  }) {
    final double horizontal = pageHorizontalPadding(width);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }
}

class HextShadows {
  static const List<BoxShadow> card = <BoxShadow>[];

  static const List<BoxShadow> footer = <BoxShadow>[];
}

class HextTextStyles {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: HextColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: HextColors.primary,
    height: 1.2,
    letterSpacing: 2,
  );

  static const TextStyle subsectionTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: HextColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: HextColors.textMuted,
    height: 1.2,
  );

  static const TextStyle field = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: HextColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: HextColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle tablePrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: HextColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle tableSecondary = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: HextColors.textSecondary,
    height: 1.25,
  );

  static const TextStyle sidebarItem = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle sidebarFooter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xB3FFFFFF),
    height: 1.3,
  );
}

class HextSidebarTokens {
  static const double width = HextDimens.sidebarWidth;
  static const double collapsedWidth = HextDimens.sidebarCollapsedWidth;
  static const double itemHeight = 46.0;
  static const double itemRadius = 10.0;
  static const double horizontalPadding = 16.0;
  static const double iconSize = 20.0;
  static const double badgeSize = 22.0;
}

InputDecoration hextInputDecoration({
  required String hint,
  bool error = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(HextDimens.radiusField),
    borderSide: BorderSide(
      color: error ? HextColors.error : HextColors.border,
      width: 1,
    ),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: HextTextStyles.label,
    isDense: true,
    filled: true,
    fillColor: HextColors.card,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    constraints: const BoxConstraints.tightFor(height: HextDimens.fieldHeight),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(HextDimens.radiusField),
      borderSide: const BorderSide(color: HextColors.primary, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(HextDimens.radiusField),
      borderSide: const BorderSide(color: HextColors.error, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(HextDimens.radiusField),
      borderSide: const BorderSide(color: HextColors.error, width: 1.2),
    ),
  );
}

BoxDecoration hextCardDecoration() {
  return BoxDecoration(
    color: HextColors.card,
    borderRadius: BorderRadius.circular(HextDimens.radiusCard),
    border: Border.all(color: HextColors.border, width: 1),
    boxShadow: HextShadows.card,
  );
}

ButtonStyle hextPrimaryButtonStyle() {
  return ElevatedButton.styleFrom(
    fixedSize: const Size.fromHeight(HextDimens.buttonHeight),
    minimumSize: const Size(120, HextDimens.buttonHeight),
    maximumSize: const Size(double.infinity, HextDimens.buttonHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    backgroundColor: HextColors.primary,
    foregroundColor: Colors.white,
    disabledBackgroundColor: HextColors.borderSoft,
    disabledForegroundColor: HextColors.textMuted,
    overlayColor: HextColors.primarySoft,
    elevation: 0,
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HextDimens.radiusField),
    ),
  );
}

ButtonStyle hextSecondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    fixedSize: const Size.fromHeight(HextDimens.buttonHeight),
    minimumSize: const Size(120, HextDimens.buttonHeight),
    maximumSize: const Size(double.infinity, HextDimens.buttonHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    foregroundColor: HextColors.primary,
    disabledForegroundColor: HextColors.textMuted,
    overlayColor: HextColors.primarySoft,
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    backgroundColor: HextColors.card,
    side: const BorderSide(color: HextColors.border, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HextDimens.radiusField),
    ),
  );
}

ButtonStyle hextNeutralButtonStyle() {
  return OutlinedButton.styleFrom(
    fixedSize: const Size.fromHeight(HextDimens.buttonHeight),
    minimumSize: const Size(120, HextDimens.buttonHeight),
    maximumSize: const Size(double.infinity, HextDimens.buttonHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    foregroundColor: HextColors.textSecondary,
    backgroundColor: HextColors.card,
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    side: const BorderSide(color: HextColors.border, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HextDimens.radiusField),
    ),
  );
}
