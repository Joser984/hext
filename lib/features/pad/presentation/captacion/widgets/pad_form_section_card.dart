import 'package:flutter/material.dart';

import 'pad_form_styles.dart';

class PadFormSectionCard extends StatelessWidget {
  const PadFormSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        PadFormMetrics.paddingTarjetaCompacta,
        12,
        PadFormMetrics.paddingTarjetaCompacta,
        PadFormMetrics.paddingTarjetaCompacta,
      ),
      decoration: padFormSectionCardDecoration(),
      margin: const EdgeInsets.only(bottom: PadFormMetrics.margenTarjeta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: PadFormMetrics.gap),
                decoration: BoxDecoration(
                  color: PadFormColors.acentoDorado,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (icon != null) ...[
                Icon(
                  icon,
                  size: PadFormMetrics.icono,
                  color: PadFormColors.verdePrincipal,
                ),
                const SizedBox(width: PadFormMetrics.gap),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: PadFormTextStyles.tituloSeccion.copyWith(
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: PadFormMetrics.gap),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: PadFormMetrics.gapCabeceraSeccion),
          child,
        ],
      ),
    );
  }
}
