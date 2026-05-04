import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

class PadFormColors {
  static const Color verdePrincipal = HextColors.primary;
  static const Color doradoAcento = HextColors.secondary;
  static const Color blanco = HextColors.card;
  static const Color fondoSuave = HextColors.background;
  static const Color bordeSuave = HextColors.border;
  static const Color bordeInterno = HextColors.borderSoft;
  static const Color textoPrincipal = HextColors.textPrimary;
  static const Color textoSecundario = HextColors.textSecondary;
  static const Color textoMuted = HextColors.textMuted;
  static const Color error = HextColors.error;

  static const acentoDorado = doradoAcento;
  static const bordeCampo = bordeSuave;
  static const fondoTarjeta = blanco;
  static const fondoSubtarjeta = HextColors.subcard;
  static const chipSeleccionado = HextColors.primarySoft;
  static const chipBorde = bordeSuave;
  static const fondoAdvertencia = HextColors.warningSoft;
  static const textoAdvertencia = HextColors.warningText;
}

class PadFormMetrics {
  static const double radioBase = HextDimens.radiusField;
  static const double radioPill = HextDimens.radiusPill;
  static const double radioChip = HextDimens.radiusChip;
  static const double radioTarjeta = HextDimens.radiusCard;
  static const double radioSubtarjeta = HextDimens.radiusSubcard;

  static const double alturaCampo = HextDimens.fieldHeight;
  static const double alturaBoton = HextDimens.buttonHeight;
  static const double alturaChip = HextDimens.chipHeight;

  static const double paddingCampoHorizontal = 12.0;
  static const double paddingCampoVertical = 8.0;
  static const double paddingTarjeta = HextDimens.paddingCard;
  static const double paddingSubtarjeta = HextDimens.paddingCard;
  static const double paddingTarjetaCompacta = 14.0;
  static const double margenTarjeta = 12.0;
  static const double gapCabeceraSeccion = 12.0;

  static const double gap = HextDimens.gap;
  static const double gapSeccion = HextDimens.sectionGap;
  static const double icono = HextDimens.iconSize;
  static const double labelGap = HextDimens.labelGap;
  static const double maxFieldWidthFactor = 0.92;
  static const double autocompleteWidth = HextDimens.autocompleteWidth;
  static const double autocompleteMaxHeight = HextDimens.autocompleteMaxHeight;
  static const double autocompleteItemHorizontalPadding =
      HextDimens.autocompleteItemHorizontalPadding;
  static const double autocompleteItemVerticalPadding =
      HextDimens.autocompleteItemVerticalPadding;
}

class PadFormTextStyles {
  static const TextStyle tituloPrincipal = HextTextStyles.pageTitle;
  static const TextStyle tituloSeccion = HextTextStyles.sectionTitle;
  static const TextStyle tituloSubseccion = HextTextStyles.subsectionTitle;
  static const TextStyle labelCampo = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: HextColors.textMuted,
    height: 1.2,
    letterSpacing: 0.2,
  );
  static const TextStyle textoCampo = HextTextStyles.field;
  static const TextStyle textoAuxiliar = HextTextStyles.secondary;

  static const chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: PadFormColors.verdePrincipal,
    height: 1.2,
  );

  static const chipNoSeleccionado = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: PadFormColors.textoSecundario,
    height: 1.2,
  );

  static const error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: PadFormColors.error,
    height: 1.2,
  );
}

InputDecoration padFormInputDecoration({
  required String label,
  String? hint,
  bool error = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return hextInputDecoration(
    hint: hint ?? label,
    error: error,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
  ).copyWith(
    labelText: null,
    hintStyle: PadFormTextStyles.labelCampo,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    fillColor: PadFormColors.blanco,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PadFormMetrics.paddingCampoHorizontal,
      vertical: PadFormMetrics.paddingCampoVertical,
    ),
  );
}

InputDecoration padFormDropdownDecoration({
  required String label,
  String? hint,
  bool error = false,
}) => padFormInputDecoration(label: label, hint: hint, error: error);

BoxDecoration padFormSectionCardDecoration() => BoxDecoration(
  color: PadFormColors.fondoTarjeta,
  borderRadius: BorderRadius.circular(PadFormMetrics.radioTarjeta),
  border: Border.all(color: PadFormColors.bordeSuave),
  boxShadow: HextShadows.card,
);

BoxDecoration padFormSubcardDecoration() => BoxDecoration(
  color: PadFormColors.fondoSubtarjeta,
  borderRadius: BorderRadius.circular(PadFormMetrics.radioSubtarjeta),
  border: Border.all(color: PadFormColors.bordeInterno),
);

RoundedRectangleBorder padFormChipShape({Color? borderColor}) =>
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PadFormMetrics.radioChip),
      side: BorderSide(color: borderColor ?? PadFormColors.chipBorde),
    );

BoxDecoration padFormFooterDecoration() => const BoxDecoration(
  color: PadFormColors.fondoTarjeta,
  boxShadow: HextShadows.footer,
);

class PadFormChipTheme {
  static ChipThemeData get(BuildContext context) {
    return ChipTheme.of(context).copyWith(
      backgroundColor: PadFormColors.fondoTarjeta,
      selectedColor: PadFormColors.chipSeleccionado,
      labelStyle: PadFormTextStyles.chipNoSeleccionado,
      secondaryLabelStyle: PadFormTextStyles.chip,
      shape: padFormChipShape(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      side: const BorderSide(color: PadFormColors.chipBorde),
      checkmarkColor: PadFormColors.verdePrincipal,
    );
  }
}

Widget padOneLineField(Widget child) =>
    SizedBox(height: PadFormMetrics.alturaCampo, child: child);

ButtonStyle padPrimaryButtonStyle(BuildContext context) =>
    hextPrimaryButtonStyle();

ButtonStyle padSecondaryButtonStyle(BuildContext context) =>
    hextSecondaryButtonStyle();

ButtonStyle padNeutralButtonStyle(BuildContext context) =>
    hextNeutralButtonStyle();

Widget padFormVerticalGap([double? height]) =>
    SizedBox(height: height ?? PadFormMetrics.gapSeccion);

Widget padFormHorizontalGap([double? width]) =>
    SizedBox(width: width ?? PadFormMetrics.gap);
