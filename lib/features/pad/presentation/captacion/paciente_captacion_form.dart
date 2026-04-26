import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/features/pad/catalogs/aseguradoras_catalog.dart';
import 'package:hext/features/pad/services/pad_firestore_service.dart';

import 'paciente_captacion_catalogs.dart';
import 'paciente_captacion_helpers.dart';
import 'paciente_captacion_labels.dart';
import 'paciente_captacion_models.dart';

class PacienteCaptacionForm extends StatefulWidget {
  const PacienteCaptacionForm({
    super.key,
    this.candidatoId,
    this.initialData,
  });

  final String? candidatoId;
  final Map<String, dynamic>? initialData;

  @override
  State<PacienteCaptacionForm> createState() => _PacienteCaptacionFormState();
}

class _PacienteCaptacionFormState extends State<PacienteCaptacionForm> {
  static const Color _brandPrimary = Color(0xFF17726D);
  static const Color _surfaceMuted = Color(0xFFF3F4F6);
  static const Color _surfaceBase = Color(0xFFFFFFFF);
  static const Color _borderSoft = Color(0xFFD9E2E7);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _identificacionController =
      TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  final TextEditingController _aseguradoraController =
      TextEditingController();

  final TextEditingController _diagnosticoController =
      TextEditingController();
  final TextEditingController _grupoRiesgoController =
      TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  SexoPaciente? _sexo;

  TipoAseguramiento? _tipoAseguramiento;
  RegimenAseguramiento? _regimenAseguramiento;
  String? _aseguradoraCatalogKey;

  TipoCaptacionPad? _tipoCaptacionPad;
  DecisionPad? _decision;

  String? _grupoRiesgoSeleccionado;

  bool get _isEditing =>
      widget.candidatoId != null && widget.candidatoId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic>? data = widget.initialData;
    if (data != null) {
      _hydrateFromData(data);
    }
  }

  void _hydrateFromData(Map<String, dynamic> data) {
    _nombreCompletoController.text =
        (data['nombreCompleto'] as String?) ??
        (data['nombre'] as String?) ??
        '';

    _identificacionController.text =
        (data['identificacion'] as String?) ??
        (data['documento'] as String?) ??
        '';

    final dynamic edadValue = data['edad'];
    if (edadValue != null) {
      _edadController.text = edadValue.toString();
    }

    _aseguradoraController.text =
        (data['aseguradora'] as String?)?.trim() ?? '';

    _diagnosticoController.text =
        (data['diagnostico'] as String?)?.trim() ?? '';

    _grupoRiesgoController.text =
        (data['grupoRelacionadoRiesgo'] as String?)?.trim() ?? '';

    _observacionesController.text =
        (data['observaciones'] as String?)?.trim() ?? '';

    final String grupoRiesgo = _grupoRiesgoController.text.trim();
    if (grupoRiesgo.isEmpty) {
      _grupoRiesgoSeleccionado = null;
    } else if (grupoRiesgoOptions.contains(grupoRiesgo)) {
      _grupoRiesgoSeleccionado = grupoRiesgo;
    } else {
      _grupoRiesgoSeleccionado = grupoRiesgoOtro;
    }

    _sexo = findEnumByLabel<SexoPaciente>(
      SexoPaciente.values,
      data['sexo'] as String?,
      sexoPacienteLabel,
    );

    _tipoAseguramiento = findEnumByLabel<TipoAseguramiento>(
      TipoAseguramiento.values,
      data['tipoAseguramiento'] as String?,
      tipoAseguramientoLabel,
    );

    _regimenAseguramiento = findEnumByLabel<RegimenAseguramiento>(
      RegimenAseguramiento.values,
      data['regimenAseguramiento'] as String?,
      regimenAseguramientoLabel,
    );

    _syncAseguradoraFromStoredValue();

    _tipoCaptacionPad = findEnumByLabel<TipoCaptacionPad>(
      TipoCaptacionPad.values,
      data['tipoCaptacionPad'] as String?,
      tipoCaptacionPadLabel,
    );

    _decision = findEnumByLabel<DecisionPad>(
      DecisionPad.values,
      data['decision'] as String?,
      decisionPadLabel,
    );
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _identificacionController.dispose();
    _edadController.dispose();
    _aseguradoraController.dispose();
    _diagnosticoController.dispose();
    _grupoRiesgoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: true,
      filled: true,
      fillColor: _surfaceBase,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      hintStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.15,
        color: _textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: _brandPrimary,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.2,
        ),
      ),
    );
  }

  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      'nombreCompleto': _nombreCompletoController.text.trim(),
      'identificacion': _identificacionController.text.trim(),
      'sexo': _sexo == null ? null : sexoPacienteLabel(_sexo!),
      'edad': int.tryParse(_edadController.text.trim()),
      'tipoAseguramiento': _tipoAseguramiento == null
          ? null
          : tipoAseguramientoLabel(_tipoAseguramiento!),
      'aseguradora': _aseguradoraController.text.trim(),
      'regimenAseguramiento': _regimenAseguramiento == null
          ? null
          : regimenAseguramientoLabel(_regimenAseguramiento!),
      'tipoCaptacionPad': _tipoCaptacionPad == null
          ? null
          : tipoCaptacionPadLabel(_tipoCaptacionPad!),
      'diagnostico': _diagnosticoController.text.trim(),
      'grupoRelacionadoRiesgo': _grupoRiesgoController.text.trim(),
      'decision': _decision == null ? null : decisionPadLabel(_decision!),
      'observaciones': _observacionesController.text.trim(),
    };
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final Map<String, dynamic> data = _buildPayload();

    try {
      if (_isEditing) {
        await PadFirestoreService.actualizarCensoPaciente(
          widget.candidatoId!,
          data,
        );
      } else {
        await PadFirestoreService.guardarCandidato(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado exitoso.')),
      );

      context.go('/cases');
    } catch (e) {
      debugPrint('Error al guardar candidato PAD: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el candidato PAD.'),
        ),
      );
    }
  }

  void _cancelar() {
    final NavigatorState navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    context.go('/cases');
  }

  void _onTipoAseguramientoChanged(TipoAseguramiento? value) {
    _tipoAseguramiento = value;

    if (value == TipoAseguramiento.particular) {
      _aseguradoraCatalogKey = null;
      _aseguradoraController.text = 'Particular';
      return;
    }

    if (value == TipoAseguramiento.otro) {
      _aseguradoraCatalogKey = null;

      if (_aseguradoraController.text.trim().toLowerCase() == 'particular') {
        _aseguradoraController.clear();
      }

      return;
    }

    final List<dynamic> options = aseguradorasPorTipo(
      catalogTipoFromAseguramiento(value),
    );

    final bool hasSelected = options.any(
      (dynamic option) => option.value == _aseguradoraCatalogKey,
    );

    if (!hasSelected) {
      _aseguradoraCatalogKey = null;
      _aseguradoraController.clear();
    }
  }

  void _syncAseguradoraFromStoredValue() {
    final String rawValue = _aseguradoraController.text.trim();

    if (rawValue.isEmpty) {
      _aseguradoraCatalogKey = null;
      return;
    }

    final List<dynamic> options = aseguradorasPorTipo(
      catalogTipoFromAseguramiento(_tipoAseguramiento),
    );

    for (final dynamic option in options) {
      final String value = option.value.toString();
      final String label = option.label.toString();

      if (rawValue == value || rawValue.toLowerCase() == label.toLowerCase()) {
        _aseguradoraCatalogKey = value;
        _aseguradoraController.text = label;
        return;
      }
    }

    _aseguradoraCatalogKey = null;
  }

  Widget _buildAseguradoraField() {
    if (_tipoAseguramiento == TipoAseguramiento.particular) {
      return TextFormField(
        controller: _aseguradoraController,
        readOnly: true,
        decoration: _inputDecoration('Aseguradora'),
      );
    }

    if (_tipoAseguramiento == TipoAseguramiento.otro) {
      return TextFormField(
        controller: _aseguradoraController,
        decoration: _inputDecoration('Especificar entidad'),
      );
    }

    final List<dynamic> options = aseguradorasPorTipo(
      catalogTipoFromAseguramiento(_tipoAseguramiento),
    );

    if (options.isEmpty) {
      return TextFormField(
        controller: _aseguradoraController,
        enabled: false,
        decoration: _inputDecoration('Aseguradora'),
      );
    }

    final bool selectedExists = options.any(
      (dynamic option) => option.value == _aseguradoraCatalogKey,
    );

    return DropdownButtonFormField<String>(
      initialValue: selectedExists ? _aseguradoraCatalogKey : null,
      decoration: _inputDecoration('Aseguradora'),
      items: options.map<DropdownMenuItem<String>>((dynamic option) {
        return DropdownMenuItem<String>(
          value: option.value.toString(),
          child: Text(option.label.toString()),
        );
      }).toList(),
      onChanged: (String? selectedKey) {
        setState(() {
          _aseguradoraCatalogKey = selectedKey;

          if (selectedKey == null) {
            _aseguradoraController.clear();
            return;
          }

          final dynamic match = options.firstWhere(
            (dynamic option) => option.value == selectedKey,
          );

          _aseguradoraController.text = match.label.toString();
        });
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _isEditing ? 'Editar candidato PAD' : 'Nuevo candidato PAD',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Captación, valoración inicial y decisión de ingreso al programa.',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosBasicosSection() {
    return _SectionCard(
      title: 'Datos básicos',
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _nombreCompletoController,
            decoration: _inputDecoration('Nombre completo'),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _identificacionController,
            decoration: _inputDecoration('Identificación'),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SexoPaciente>(
            initialValue: _sexo,
            decoration: _inputDecoration('Sexo'),
            items: sortedByLabel<SexoPaciente>(
              SexoPaciente.values,
              sexoPacienteLabel,
            ).map<DropdownMenuItem<SexoPaciente>>((SexoPaciente value) {
              return DropdownMenuItem<SexoPaciente>(
                value: value,
                child: Text(sexoPacienteLabel(value)),
              );
            }).toList(),
            onChanged: (SexoPaciente? value) {
              setState(() => _sexo = value);
            },
            validator: (SexoPaciente? value) {
              if (value == null) return 'Campo obligatorio';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _edadController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Edad'),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }

              final int? edad = int.tryParse(value.trim());
              if (edad == null || edad < 0 || edad > 120) {
                return 'Edad inválida';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAseguramientoSection() {
    return _SectionCard(
      title: 'Aseguramiento',
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<TipoAseguramiento>(
            initialValue: _tipoAseguramiento,
            decoration: _inputDecoration('Tipo de aseguramiento'),
            items: sortedByLabel<TipoAseguramiento>(
              TipoAseguramiento.values,
              tipoAseguramientoLabel,
            ).map<DropdownMenuItem<TipoAseguramiento>>(
              (TipoAseguramiento value) {
                return DropdownMenuItem<TipoAseguramiento>(
                  value: value,
                  child: Text(tipoAseguramientoLabel(value)),
                );
              },
            ).toList(),
            onChanged: (TipoAseguramiento? value) {
              setState(() => _onTipoAseguramientoChanged(value));
            },
          ),
          const SizedBox(height: 12),
          _buildAseguradoraField(),
          const SizedBox(height: 12),
          DropdownButtonFormField<RegimenAseguramiento>(
            initialValue: _regimenAseguramiento,
            decoration: _inputDecoration('Régimen'),
            items: sortedByLabel<RegimenAseguramiento>(
              RegimenAseguramiento.values,
              regimenAseguramientoLabel,
            ).map<DropdownMenuItem<RegimenAseguramiento>>(
              (RegimenAseguramiento value) {
                return DropdownMenuItem<RegimenAseguramiento>(
                  value: value,
                  child: Text(regimenAseguramientoLabel(value)),
                );
              },
            ).toList(),
            onChanged: (RegimenAseguramiento? value) {
              setState(() => _regimenAseguramiento = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaptacionPadSection() {
    return _SectionCard(
      title: 'Captación PAD',
      child: DropdownButtonFormField<TipoCaptacionPad>(
        initialValue: _tipoCaptacionPad,
        decoration: _inputDecoration('Tipo de captación PAD'),
        items: sortedByLabel<TipoCaptacionPad>(
          TipoCaptacionPad.values,
          tipoCaptacionPadLabel,
        ).map<DropdownMenuItem<TipoCaptacionPad>>((TipoCaptacionPad value) {
          return DropdownMenuItem<TipoCaptacionPad>(
            value: value,
            child: Text(tipoCaptacionPadLabel(value)),
          );
        }).toList(),
        onChanged: (TipoCaptacionPad? value) {
          setState(() => _tipoCaptacionPad = value);
        },
        validator: (TipoCaptacionPad? value) {
          if (value == null) return 'Campo obligatorio';
          return null;
        },
      ),
    );
  }

  Widget _buildContextoClinicoSection() {
    return _SectionCard(
      title: 'Contexto clínico',
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _diagnosticoController,
            decoration: _inputDecoration('Diagnóstico'),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _grupoRiesgoSeleccionado,
            isExpanded: true,
            decoration: _inputDecoration('Grupo relacionado de riesgo'),
            items: grupoRiesgoOptions.map<DropdownMenuItem<String>>(
              (String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            onChanged: (String? value) {
              setState(() {
                _grupoRiesgoSeleccionado = value;

                if (value == null) {
                  _grupoRiesgoController.clear();
                  return;
                }

                if (value != grupoRiesgoOtro) {
                  _grupoRiesgoController.text = value;
                } else {
                  _grupoRiesgoController.clear();
                }
              });
            },
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }

              if (value == grupoRiesgoOtro &&
                  _grupoRiesgoController.text.trim().isEmpty) {
                return 'Especifique el grupo';
              }

              return null;
            },
          ),
          if (_grupoRiesgoSeleccionado == grupoRiesgoOtro) ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              controller: _grupoRiesgoController,
              decoration: _inputDecoration('Especifique grupo de riesgo'),
              validator: (String? value) {
                if (_grupoRiesgoSeleccionado == grupoRiesgoOtro &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Campo obligatorio';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecisionIngresoSection() {
    return _SectionCard(
      title: 'Decisión de ingreso',
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<DecisionPad>(
            initialValue: _decision,
            decoration: _inputDecoration('Resultado de la valoración'),
            items: sortedByLabel<DecisionPad>(
              DecisionPad.values,
              decisionPadLabel,
            ).map<DropdownMenuItem<DecisionPad>>((DecisionPad value) {
              return DropdownMenuItem<DecisionPad>(
                value: value,
                child: Text(decisionPadLabel(value)),
              );
            }).toList(),
            onChanged: (DecisionPad? value) {
              setState(() => _decision = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observacionesController,
            decoration: _inputDecoration('Observaciones'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          onPressed: _cancelar,
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _brandPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _surfaceMuted,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDatosBasicosSection(),
            const SizedBox(height: 16),
            _buildAseguramientoSection(),
            const SizedBox(height: 16),
            _buildCaptacionPadSection(),
            const SizedBox(height: 16),
            _buildContextoClinicoSection(),
            const SizedBox(height: 16),
            _buildDecisionIngresoSection(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  static const Color _surfaceBase = Color(0xFFFFFFFF);
  static const Color _borderSoft = Color(0xFFD9E2E7);
  static const Color _textPrimary = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}