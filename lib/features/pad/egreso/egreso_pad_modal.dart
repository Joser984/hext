import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
import 'package:hext/shared/widgets/hext_modal.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';

Future<bool?> showEgresoPadDialog({
  required BuildContext context,
  required String pacienteId,
  required String pacienteNombre,
  String? diagnostico,
  String? estadoActual,
  String? initialTipoEgreso,
  String? initialCausaReingreso,
  String? initialCausaReingresoOtro,
  DateTime? initialFechaEgreso,
}) {
  return showHextDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EgresoPadDialog(
      pacienteId: pacienteId,
      pacienteNombre: pacienteNombre,
      diagnostico: diagnostico,
      estadoActual: estadoActual,
      initialTipoEgreso: initialTipoEgreso,
      initialCausaReingreso: initialCausaReingreso,
      initialCausaReingresoOtro: initialCausaReingresoOtro,
      initialFechaEgreso: initialFechaEgreso,
    ),
  );
}

class _EgresoPadDialog extends StatefulWidget {
  const _EgresoPadDialog({
    required this.pacienteId,
    required this.pacienteNombre,
    this.diagnostico,
    this.estadoActual,
    this.initialTipoEgreso,
    this.initialCausaReingreso,
    this.initialCausaReingresoOtro,
    this.initialFechaEgreso,
  });

  final String pacienteId;
  final String pacienteNombre;
  final String? diagnostico;
  final String? estadoActual;
  final String? initialTipoEgreso;
  final String? initialCausaReingreso;
  final String? initialCausaReingresoOtro;
  final DateTime? initialFechaEgreso;

  @override
  State<_EgresoPadDialog> createState() => _EgresoPadDialogState();
}

class _EgresoPadDialogState extends State<_EgresoPadDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();

  Map<String, dynamic> _egresoData = <String, dynamic>{};
  bool _saving = false;
  bool _confirmado = false;

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  bool get _puedeGuardar => !_saving && _confirmado;

  Future<void> _guardar() async {
    if (_saving) return;

    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final String? tipoEgreso = (_egresoData['tipoEgreso'] as String?)?.trim();
    final String? causaReingreso =
        (_egresoData['causaReingreso'] as String?)?.trim();
    final String? causaReingresoOtro =
        (_egresoData['causaReingresoOtro'] as String?)?.trim();
    final dynamic fechaEgreso = _egresoData['fechaEgreso'];

    if (tipoEgreso == null || tipoEgreso.isEmpty) {
      _showError('Selecciona el tipo de egreso.');
      return;
    }

    if (fechaEgreso == null) {
      _showError('Selecciona la fecha de egreso.');
      return;
    }

    if (tipoEgreso == 'Retorno intrahospitalario') {
      if (causaReingreso == null || causaReingreso.isEmpty) {
        _showError('Selecciona el motivo del reingreso.');
        return;
      }

      if (causaReingreso == 'Otro' &&
          (causaReingresoOtro == null || causaReingresoOtro.isEmpty)) {
        _showError('Describe el motivo del reingreso.');
        return;
      }
    }

    if (!_confirmado) {
      _showError('Debes confirmar el egreso antes de guardar.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Map<String, dynamic> payload = _buildFirestorePayload(
        egresoData: _egresoData,
        observacion: _observacionController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('censoPacientes')
          .doc(widget.pacienteId)
          .update(payload);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Egreso registrado correctamente.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showError('No fue posible guardar el egreso. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildFirestorePayload({
    required Map<String, dynamic> egresoData,
    required String observacion,
  }) {
    final String? tipoEgreso = (egresoData['tipoEgreso'] as String?)?.trim();
    final String? causaReingreso =
        (egresoData['causaReingreso'] as String?)?.trim();
    final String? causaReingresoOtro =
        (egresoData['causaReingresoOtro'] as String?)?.trim();
    final dynamic fechaEgreso = egresoData['fechaEgreso'];

    final Map<String, dynamic> payload = <String, dynamic>{
      'tipoEgreso': tipoEgreso,
      'fechaEgreso': fechaEgreso is DateTime
          ? Timestamp.fromDate(fechaEgreso)
          : fechaEgreso,
      'updatedAt': FieldValue.serverTimestamp(),
      'egresadoAt': FieldValue.serverTimestamp(),
      'estadoPad': 'Egresado',
      'estadoCaso': 'Egresado',
      'casoActivo': false,
    };

    if (observacion.isNotEmpty) {
      payload['observacionEgreso'] = observacion;
      payload['observacionCierre'] = observacion;
    }

    if (tipoEgreso == 'Retorno intrahospitalario') {
      payload['causaReingreso'] = causaReingreso;

      if (causaReingreso == 'Otro' &&
          causaReingresoOtro != null &&
          causaReingresoOtro.isNotEmpty) {
        payload['causaReingresoOtro'] = causaReingresoOtro;
      }

      payload['situacionAsistencial'] =
          'Reingreso desde extensión hospitalaria';
      payload['situacionAsistencialLabel'] =
          'Reingreso desde extensión hospitalaria';
      payload['resolucionPad'] = 'Retorno intrahospitalario';
    } else {
      payload['situacionAsistencial'] = 'Alta';
      payload['situacionAsistencialLabel'] = 'Alta';
    }

    return payload;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return HextModal(
      title: 'Egresar paciente',
      subtitle: 'Registrar cierre asistencial del caso en PAD.',
      maxWidth: 560,
      onClose: _saving ? null : () => Navigator.of(context).pop(false),
      actions: <Widget>[
        SizedBox(
          width: 144,
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: hextSecondaryButtonStyle(),
            child: const Text('Cancelar'),
          ),
        ),
        SizedBox(
          width: 160,
          child: ElevatedButton(
            onPressed: _puedeGuardar ? _guardar : null,
            style: hextPrimaryButtonStyle(),
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Guardar egreso'),
          ),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PatientSummaryCard(
            pacienteNombre: widget.pacienteNombre,
            diagnostico: widget.diagnostico,
            estadoActual: widget.estadoActual,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                EgresoPadSection(
                  initialTipoEgreso: widget.initialTipoEgreso,
                  initialCausaReingreso: widget.initialCausaReingreso,
                  initialCausaReingresoOtro: widget.initialCausaReingresoOtro,
                  initialFechaEgreso: widget.initialFechaEgreso,
                  enabled: !_saving,
                  onChanged: (Map<String, dynamic> value) {
                    _egresoData = value;
                  },
                ),
                const SizedBox(height: 16),
                LightInput(
                  controller: _observacionController,
                  label: 'Observación de cierre',
                  enabled: !_saving,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmado,
                  onChanged: _saving
                      ? null
                      : (bool? value) {
                          setState(() {
                            _confirmado = value ?? false;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Confirmo que deseo registrar el egreso de este paciente.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EgresoPadSection extends StatefulWidget {
  const EgresoPadSection({
    super.key,
    required this.onChanged,
    this.initialTipoEgreso,
    this.initialCausaReingreso,
    this.initialCausaReingresoOtro,
    this.initialFechaEgreso,
    this.enabled = true,
  });

  final void Function(Map<String, dynamic> value) onChanged;
  final String? initialTipoEgreso;
  final String? initialCausaReingreso;
  final String? initialCausaReingresoOtro;
  final DateTime? initialFechaEgreso;
  final bool enabled;

  @override
  State<EgresoPadSection> createState() => _EgresoPadSectionState();
}

class _EgresoPadSectionState extends State<EgresoPadSection> {
  final TextEditingController _otroMotivoController = TextEditingController();

  String? _tipoEgreso;
  String? _causaReingreso;
  DateTime? _fechaEgreso;

  static const List<String> _tiposEgreso = <String>[
    'Alta clínica',
    'Traslado',
    'Fallecimiento',
    'Cierre administrativo',
    'Retorno intrahospitalario',
  ];

  static const List<String> _causasReingreso = <String>[
    'Deterioro clínico',
    'Reagudización de enfermedad de base',
    'Complicación del tratamiento',
    'Infección / sospecha de infección',
    'Dolor no controlado',
    'Descompensación respiratoria',
    'Descompensación hemodinámica',
    'Evento neurológico agudo',
    'Requerimiento de estudios o manejo intrahospitalario',
    'Decisión médica',
    'Solicitud familiar con criterio clínico',
    'Otro',
  ];

  bool get _esRetorno => _tipoEgreso == 'Retorno intrahospitalario';
  bool get _esOtroMotivo => _causaReingreso == 'Otro';

  @override
  void initState() {
    super.initState();
    _tipoEgreso = widget.initialTipoEgreso;
    _causaReingreso = widget.initialCausaReingreso;
    _fechaEgreso = widget.initialFechaEgreso ?? DateTime.now();
    _otroMotivoController.text = widget.initialCausaReingresoOtro ?? '';
    _emitValue();
  }

  @override
  void dispose() {
    _otroMotivoController.dispose();
    super.dispose();
  }

  void _emitValue() {
    widget.onChanged(toFirestoreMap());
  }

  void _onTipoEgresoChanged(String? value) {
    setState(() {
      _tipoEgreso = value;

      if (_tipoEgreso != 'Retorno intrahospitalario') {
        _causaReingreso = null;
        _otroMotivoController.clear();
      }

      _emitValue();
    });
  }

  void _onCausaReingresoChanged(String? value) {
    setState(() {
      _causaReingreso = value;

      if (_causaReingreso != 'Otro') {
        _otroMotivoController.clear();
      }

      _emitValue();
    });
  }

  Future<void> _pickFechaEgreso(BuildContext context) async {
    if (!widget.enabled) return;

    final DateTime now = DateTime.now();
    final DateTime initialDate = _fechaEgreso ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Seleccionar fecha de egreso',
    );

    if (picked == null) return;

    setState(() {
      _fechaEgreso = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
      );
      _emitValue();
    });
  }

  String? validateTipoEgreso() {
    if (_tipoEgreso == null || _tipoEgreso!.trim().isEmpty) {
      return 'Selecciona el tipo de egreso.';
    }
    return null;
  }

  String? validateFechaEgreso() {
    if (_fechaEgreso == null) {
      return 'Selecciona la fecha de egreso.';
    }
    return null;
  }

  String? validateCausaReingreso() {
    if (_esRetorno &&
        (_causaReingreso == null || _causaReingreso!.trim().isEmpty)) {
      return 'Selecciona el motivo del reingreso.';
    }
    return null;
  }

  String? validateCausaReingresoOtro() {
    if (_esRetorno && _esOtroMotivo) {
      final String text = _otroMotivoController.text.trim();
      if (text.isEmpty) {
        return 'Describe el motivo del reingreso.';
      }
    }
    return null;
  }

  Map<String, dynamic> toFirestoreMap() {
    final Map<String, dynamic> data = <String, dynamic>{
      'tipoEgreso': _tipoEgreso,
      'fechaEgreso': _fechaEgreso,
    };

    if (_esRetorno) {
      data['causaReingreso'] = _causaReingreso;

      if (_esOtroMotivo && _otroMotivoController.text.trim().isNotEmpty) {
        data['causaReingresoOtro'] = _otroMotivoController.text.trim();
      }
    }

    return data;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Selecciona una fecha';
    final String dd = value.day.toString().padLeft(2, '0');
    final String mm = value.month.toString().padLeft(2, '0');
    final String yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    const SizedBox gap = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Egreso',
          subtitle: 'Complete los datos de cierre asistencial del paciente.',
        ),
        gap,
        LightDropdown<String>(
          label: 'Tipo de egreso',
          value: _tipoEgreso,
          enabled: widget.enabled,
          items: _tiposEgreso
              .map(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: _onTipoEgresoChanged,
        ),
        gap,
        _DateFieldShell(
          label: 'Fecha de egreso',
          value: _formatDate(_fechaEgreso),
          errorText: validateFechaEgreso(),
          enabled: widget.enabled,
          onTap: () => _pickFechaEgreso(context),
        ),
        if (_esRetorno) ...[
          gap,
          LightDropdown<String>(
            label: 'Motivo del reingreso',
            value: _causaReingreso,
            enabled: widget.enabled,
            items: _causasReingreso
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: _onCausaReingresoChanged,
          ),
        ],
        if (_esRetorno && _esOtroMotivo) ...[
          gap,
          LightInput(
            controller: _otroMotivoController,
            label: 'Describe el motivo',
            enabled: widget.enabled,
            onChanged: (_) => _emitValue(),
          ),
        ],
      ],
    );
  }
}

class _PatientSummaryCard extends StatelessWidget {
  const _PatientSummaryCard({
    required this.pacienteNombre,
    this.diagnostico,
    this.estadoActual,
  });

  final String pacienteNombre;
  final String? diagnostico;
  final String? estadoActual;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pacienteNombre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (diagnostico != null && diagnostico!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              diagnostico!.trim(),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (estadoActual != null && estadoActual!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Estado actual: ${estadoActual!.trim()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _DateFieldShell extends StatelessWidget {
  const _DateFieldShell({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF4F4F4),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFB42318)
                    : const Color(0xFFD7DCE3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF243247),
                      ),
                      children: [
                        TextSpan(
                          text: '$label\n',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                        ),
                        TextSpan(text: value),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB42318),
            ),
          ),
        ],
      ],
    );
  }
}