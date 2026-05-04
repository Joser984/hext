import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
import 'package:hext/shared/widgets/hext_modal.dart';

/// Modelo mínimo para el caso PAD en la tabla compacta.
class PadSummaryCase {
  final String id;
  final String nombreCompleto;
  final String? diagnosticoPrincipal;
  final String? estadoPad;

  const PadSummaryCase({
    required this.id,
    required this.nombreCompleto,
    this.diagnosticoPrincipal,
    this.estadoPad,
  });
}

/// Helper para saber si el caso puede egresarse según el estado.
bool canDischarge(String? value) {
  final raw = (value ?? '').trim().toLowerCase();

  final normalized = raw
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  const allowed = <String>{
    'activo en pad',
    'activoenpad',
    'seguimiento',
    'en seguimiento',
  };

  return allowed.contains(raw) || allowed.contains(normalized);
}

/// Payload limpio que devuelve el modal de egreso.
class PadDischargePayload {
  final String tipoEgreso;
  final DateTime fechaEgreso;
  final String? observacion;

  const PadDischargePayload({
    required this.tipoEgreso,
    required this.fechaEgreso,
    this.observacion,
  });
}

/// Widget de celda de acciones para la tabla compacta PAD.
class PadSummaryActionsCell extends StatelessWidget {
  final PadSummaryCase item;
  final VoidCallback onEdit;
  final ValueChanged<PadDischargePayload> onDischargeConfirmed;
  final bool canDischarge;

  const PadSummaryActionsCell({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDischargeConfirmed,
    required this.canDischarge,
  });

  @override
  Widget build(BuildContext context) {
    const double kActionButtonWidth = 96;
    const double kActionButtonHeight = 34;
    const double kActionButtonRadius = 10;

    // Determinar si el botón Egresar debe mostrarse
    final bool showDischarge = canDischarge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: kActionButtonWidth,
          height: kActionButtonHeight,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF334155),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kActionButtonRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Editar'),
          ),
        ),
        if (showDischarge) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: kActionButtonWidth,
            height: kActionButtonHeight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final payload = await showPadDischargeDialog(context, item);
                if (payload != null) {
                  onDischargeConfirmed(payload);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFB86A00),
                backgroundColor: Color(0xFFFFF7ED),
                side: const BorderSide(color: Color(0xFFE8B469)),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kActionButtonRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.logout_rounded, size: 15),
              label: const Text('Egresar'),
            ),
          ),
        ],
      ],
    );
  }

  }

/// Modal de egreso PAD. Devuelve un [PadDischargePayload] o null si se cancela.
Future<PadDischargePayload?> showPadDischargeDialog(BuildContext context, PadSummaryCase item) async {
  final formKey = GlobalKey<FormState>();
  final observacionCtrl = TextEditingController();
  DateTime fechaEgreso = DateTime.now();
  String? tipoEgreso;
  bool confirmo = false;

  return showHextDialog<PadDischargePayload>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final canSubmit = tipoEgreso != null && confirmo;
          return HextModal(
            title: 'Egresar paciente',
            subtitle: 'Registrar cierre operativo del caso desde el resumen PAD.',
            maxWidth: 540,
            onClose: () => Navigator.of(dialogContext).pop(),
            actions: <Widget>[
              SizedBox(
                width: 132,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: hextSecondaryButtonStyle(),
                  child: const Text('Cancelar'),
                ),
              ),
              SizedBox(
                width: 168,
                child: ElevatedButton(
                  onPressed: canSubmit
                      ? () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.of(dialogContext).pop(
                            PadDischargePayload(
                              tipoEgreso: tipoEgreso!,
                              fechaEgreso: fechaEgreso,
                              observacion: observacionCtrl.text.trim().isEmpty
                                  ? null
                                  : observacionCtrl.text.trim(),
                            ),
                          );
                        }
                      : null,
                  style: hextPrimaryButtonStyle(),
                  child: const Text('Confirmar egreso'),
                ),
              ),
            ],
            child: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombreCompleto,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.diagnosticoPrincipal ?? 'Sin diagnóstico resumido',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: tipoEgreso,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de egreso',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'alta_clinica', child: Text('Alta clínica')),
                        DropdownMenuItem(value: 'egreso_administrativo', child: Text('Egreso administrativo')),
                        DropdownMenuItem(value: 'cierre_operativo', child: Text('Cierre operativo')),
                        DropdownMenuItem(value: 'traslado', child: Text('Traslado')),
                        DropdownMenuItem(value: 'fallecimiento', child: Text('Fallecimiento')),
                      ],
                      onChanged: (value) => setState(() => tipoEgreso = value),
                      validator: (value) => value == null ? 'Selecciona el tipo de egreso' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de egreso'),
                      subtitle: Text(
                        '${fechaEgreso.day}/${fechaEgreso.month}/${fechaEgreso.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaEgreso,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => fechaEgreso = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: observacionCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Observación de cierre',
                        hintText: 'Opcional',
                      ),
                    ),
                    CheckboxListTile(
                      value: confirmo,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Confirmo que deseo cerrar este caso'),
                      onChanged: (value) {
                        setState(() => confirmo = value ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
