import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SexoPaciente {
  femenino,
  masculino,
  otro,
}

enum TipoAseguramiento {
  eps,
  medicinaPrepagada,
  poliza,
  particular,
  otro,
}

enum RegimenAseguramiento {
  contributivo,
  subsidiado,
  especial,
  particular,
  noAplica,
}

enum TipoCaptacionPad {
  busquedaActivaPad,
  presentadoPorServicio,
}

enum ServicioQuePresenta {
  urgencias,
  hospitalizacion,
  uci,
  cirugia,
  consultaExterna,
  otro,
}

enum OrigenPaciente {
  urgencias,
  hospitalizacion,
  uci,
  cirugia,
  consultaExterna,
  otro,
}

enum EspecialidadPrincipalTratante {
  medicinaInterna,
  cirugiaGeneral,
  ortopedia,
  ginecologia,
  pediatria,
}

enum DecisionPad {
  ingresoAprobado,
  ingresoNoAprobado,
  pendienteValoracion,
  requiereNuevaValoracion,
}

class PacienteCaptacion {
  final String nombreCompleto;
  final String identificacion;
  final SexoPaciente sexo;
  final int edad;

  final TipoAseguramiento? tipoAseguramiento;
  final String aseguradora;
  final RegimenAseguramiento? regimenAseguramiento;

  final TipoCaptacionPad tipoCaptacionPad;
  final ServicioQuePresenta? servicioQuePresenta;

  final OrigenPaciente? origenPaciente;
  final EspecialidadPrincipalTratante? especialidadPrincipalTratante;
  final String diagnostico;
  final String grupoRelacionadoRiesgo;
  final Set<String> motivos;

  final String unidadFuncionalOrigen;
  final DecisionPad? decision;
  final String observaciones;

  const PacienteCaptacion({
    required this.nombreCompleto,
    required this.identificacion,
    required this.sexo,
    required this.edad,
    required this.tipoAseguramiento,
    required this.aseguradora,
    required this.regimenAseguramiento,
    required this.tipoCaptacionPad,
    required this.servicioQuePresenta,
    required this.origenPaciente,
    required this.especialidadPrincipalTratante,
    required this.diagnostico,
    required this.grupoRelacionadoRiesgo,
    required this.motivos,
    required this.unidadFuncionalOrigen,
    required this.decision,
    required this.observaciones,
  });
}

class PacienteCaptacionForm extends StatefulWidget {
  const PacienteCaptacionForm({super.key});

  @override
  State<PacienteCaptacionForm> createState() => _PacienteCaptacionFormState();
}

class _PacienteCaptacionFormState extends State<PacienteCaptacionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _identificacionController =
      TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  final TextEditingController _aseguradoraController = TextEditingController();

  final TextEditingController _diagnosticoController =
      TextEditingController();
  final TextEditingController _grupoRiesgoController =
      TextEditingController();

  final TextEditingController _unidadFuncionalOrigenController =
      TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  SexoPaciente? _sexo;
  TipoAseguramiento? _tipoAseguramiento;
  RegimenAseguramiento? _regimenAseguramiento;

  TipoCaptacionPad? _tipoCaptacionPad;
  ServicioQuePresenta? _servicioQuePresenta;

  OrigenPaciente? _origenPaciente;
  EspecialidadPrincipalTratante? _especialidadPrincipalTratante;
  DecisionPad? _decision;

  final Set<String> _motivosSeleccionados = <String>{};

  static const List<String> _motivosOptions = <String>[
    'Motivo 1',
    'Motivo 2',
    'Motivo 3',
  ];

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _identificacionController.dispose();
    _edadController.dispose();
    _aseguradoraController.dispose();
    _diagnosticoController.dispose();
    _grupoRiesgoController.dispose();
    _unidadFuncionalOrigenController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final PacienteCaptacion paciente = PacienteCaptacion(
      nombreCompleto: _nombreCompletoController.text.trim(),
      identificacion: _identificacionController.text.trim(),
      sexo: _sexo!,
      edad: int.parse(_edadController.text.trim()),
      tipoAseguramiento: _tipoAseguramiento,
      aseguradora: _aseguradoraController.text.trim(),
      regimenAseguramiento: _regimenAseguramiento,
      tipoCaptacionPad: _tipoCaptacionPad!,
      servicioQuePresenta: _servicioQuePresenta,
      origenPaciente: _origenPaciente,
      especialidadPrincipalTratante: _especialidadPrincipalTratante,
      diagnostico: _diagnosticoController.text.trim(),
      grupoRelacionadoRiesgo: _grupoRiesgoController.text.trim(),
      motivos: Set<String>.from(_motivosSeleccionados),
      unidadFuncionalOrigen: _unidadFuncionalOrigenController.text.trim(),
      decision: _decision,
      observaciones: _observacionesController.text.trim(),
    );

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Candidato guardado'),
        content: SingleChildScrollView(
          child: Text(
            'Nombre: ${paciente.nombreCompleto}\n'
            'Identificación: ${paciente.identificacion}\n'
            'Sexo: ${_sexoPacienteLabel(paciente.sexo)}\n'
            'Edad: ${paciente.edad}\n'
            'Tipo captación PAD: ${_tipoCaptacionPadLabel(paciente.tipoCaptacionPad)}\n'
            'Servicio que presenta: ${paciente.servicioQuePresenta != null ? _servicioQuePresentaLabel(paciente.servicioQuePresenta!) : '-'}\n'
            'Origen: ${paciente.origenPaciente != null ? _origenPacienteLabel(paciente.origenPaciente!) : '-'}\n'
            'Especialidad: ${paciente.especialidadPrincipalTratante != null ? _especialidadPrincipalTratanteLabel(paciente.especialidadPrincipalTratante!) : '-'}\n'
            'Diagnóstico: ${paciente.diagnostico}\n'
            'Grupo de riesgo: ${paciente.grupoRelacionadoRiesgo}\n'
            'Motivos: ${paciente.motivos.isEmpty ? '-' : paciente.motivos.join(', ')}\n'
            'Decisión: ${paciente.decision != null ? _decisionPadLabel(paciente.decision!) : '-'}',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _aprobarIngreso() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Candidato aprobado para ingreso'),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A66), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: <Widget>[
                _SectionCard(
                  title: 'Datos básicos',
                  child: _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 32,
                        child: TextFormField(
                          controller: _nombreCompletoController,
                          decoration: _inputDecoration('Nombre completo'),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                      _FieldItem(
                        flex: 22,
                        child: TextFormField(
                          controller: _identificacionController,
                          decoration: _inputDecoration('Identificación'),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                      _FieldItem(
                        flex: 10,
                        child: DropdownButtonFormField<SexoPaciente>(
                          initialValue: _sexo,
                          decoration: _inputDecoration('Sexo'),
                          items: SexoPaciente.values
                              .map(
                                (SexoPaciente value) =>
                                    DropdownMenuItem<SexoPaciente>(
                                  value: value,
                                  child: Text(_sexoPacienteLabel(value)),
                                ),
                              )
                              .toList(),
                          onChanged: (SexoPaciente? value) {
                            setState(() => _sexo = value);
                          },
                          validator: (SexoPaciente? value) {
                            if (value == null) return 'Campo obligatorio';
                            return null;
                          },
                        ),
                      ),
                      _FieldItem(
                        flex: 8,
                        child: TextFormField(
                          controller: _edadController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _inputDecoration('Edad'),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo obligatorio';
                            }
                            final int? edad = int.tryParse(value.trim());
                            if (edad == null) return 'Edad inválida';
                            if (edad < 0 || edad > 120) return 'Edad inválida';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Aseguramiento',
                  child: _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 16,
                        child: DropdownButtonFormField<TipoAseguramiento>(
                          initialValue: _tipoAseguramiento,
                          decoration: _inputDecoration('Tipo'),
                          items: TipoAseguramiento.values
                              .map(
                                (TipoAseguramiento value) =>
                                    DropdownMenuItem<TipoAseguramiento>(
                                  value: value,
                                  child: Text(_tipoAseguramientoLabel(value)),
                                ),
                              )
                              .toList(),
                          onChanged: (TipoAseguramiento? value) {
                            setState(() => _tipoAseguramiento = value);
                          },
                        ),
                      ),
                      _FieldItem(
                        flex: 36,
                        child: TextFormField(
                          controller: _aseguradoraController,
                          decoration: _inputDecoration('Aseguradora'),
                        ),
                      ),
                      _FieldItem(
                        flex: 16,
                        child: DropdownButtonFormField<RegimenAseguramiento>(
                          initialValue: _regimenAseguramiento,
                          decoration: _inputDecoration('Régimen'),
                          items: RegimenAseguramiento.values
                              .map(
                                (RegimenAseguramiento value) =>
                                    DropdownMenuItem<RegimenAseguramiento>(
                                  value: value,
                                  child: Text(
                                    _regimenAseguramientoLabel(value),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (RegimenAseguramiento? value) {
                            setState(() => _regimenAseguramiento = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Captación PAD',
                  child: Column(
                    children: <Widget>[
                      _AdaptiveFieldsRow(
                        children: <_FieldItem>[
                          _FieldItem(
                            flex: 24,
                            child: DropdownButtonFormField<TipoCaptacionPad>(
                              initialValue: _tipoCaptacionPad,
                              decoration:
                                  _inputDecoration('Tipo de captación PAD'),
                              items: TipoCaptacionPad.values
                                  .map(
                                    (TipoCaptacionPad value) =>
                                        DropdownMenuItem<TipoCaptacionPad>(
                                      value: value,
                                      child: Text(
                                        _tipoCaptacionPadLabel(value),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (TipoCaptacionPad? value) {
                                setState(() {
                                  _tipoCaptacionPad = value;
                                  if (value !=
                                      TipoCaptacionPad.presentadoPorServicio) {
                                    _servicioQuePresenta = null;
                                  }
                                });
                              },
                              validator: (TipoCaptacionPad? value) {
                                if (value == null) return 'Campo obligatorio';
                                return null;
                              },
                            ),
                          ),
                          if (_tipoCaptacionPad ==
                              TipoCaptacionPad.presentadoPorServicio)
                            _FieldItem(
                              flex: 24,
                              child: DropdownButtonFormField<ServicioQuePresenta>(
                                key: const ValueKey('servicio_que_presenta'),
                                initialValue: _servicioQuePresenta,
                                decoration:
                                    _inputDecoration('Servicio que presenta'),
                                items: ServicioQuePresenta.values
                                    .map(
                                      (ServicioQuePresenta value) =>
                                          DropdownMenuItem<
                                              ServicioQuePresenta>(
                                        value: value,
                                        child: Text(
                                          _servicioQuePresentaLabel(value),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (ServicioQuePresenta? value) {
                                  setState(
                                    () => _servicioQuePresenta = value,
                                  );
                                },
                                validator: (ServicioQuePresenta? value) {
                                  if (_tipoCaptacionPad ==
                                          TipoCaptacionPad
                                              .presentadoPorServicio &&
                                      value == null) {
                                    return 'Campo obligatorio';
                                  }
                                  return null;
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Contexto clínico',
                  child: Column(
                    children: <Widget>[
                      _AdaptiveFieldsRow(
                        children: <_FieldItem>[
                          _FieldItem(
                            flex: 18,
                            child: DropdownButtonFormField<
                                EspecialidadPrincipalTratante>(
                              initialValue: _especialidadPrincipalTratante,
                              decoration: _inputDecoration('Especialidad'),
                              items: EspecialidadPrincipalTratante.values
                                  .map(
                                    (EspecialidadPrincipalTratante value) =>
                                        DropdownMenuItem<
                                            EspecialidadPrincipalTratante>(
                                      value: value,
                                      child: Text(
                                        _especialidadPrincipalTratanteLabel(
                                          value,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  (EspecialidadPrincipalTratante? value) {
                                setState(
                                  () => _especialidadPrincipalTratante = value,
                                );
                              },
                            ),
                          ),
                          _FieldItem(
                            flex: 34,
                            child: TextFormField(
                              controller: _diagnosticoController,
                              decoration: _inputDecoration('Diagnóstico'),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Campo obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                          _FieldItem(
                            flex: 22,
                            child: TextFormField(
                              controller: _grupoRiesgoController,
                              decoration: _inputDecoration(
                                'Grupo relacionado de riesgo',
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Campo obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _AdaptiveFieldsRow(
                        children: <_FieldItem>[
                          _FieldItem(
                            flex: 18,
                            child: DropdownButtonFormField<OrigenPaciente>(
                              initialValue: _origenPaciente,
                              decoration:
                                  _inputDecoration('Origen del paciente'),
                              items: OrigenPaciente.values
                                  .map(
                                    (OrigenPaciente value) =>
                                        DropdownMenuItem<OrigenPaciente>(
                                      value: value,
                                      child: Text(
                                        _origenPacienteLabel(value),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (OrigenPaciente? value) {
                                setState(() => _origenPaciente = value);
                              },
                            ),
                          ),
                          _FieldItem(
                            flex: 38,
                            child: _MotivosField(
                              label: 'Motivo(s)',
                              options: _motivosOptions,
                              selected: _motivosSeleccionados,
                              onToggle: (String value) {
                                setState(() {
                                  if (_motivosSeleccionados.contains(value)) {
                                    _motivosSeleccionados.remove(value);
                                  } else {
                                    _motivosSeleccionados.add(value);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Decisión',
                  child: _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 18,
                        child: TextFormField(
                          controller: _unidadFuncionalOrigenController,
                          decoration:
                              _inputDecoration('Unidad funcional origen'),
                        ),
                      ),
                      _FieldItem(
                        flex: 16,
                        child: DropdownButtonFormField<DecisionPad>(
                          initialValue: _decision,
                          decoration: _inputDecoration('Decisión'),
                          items: DecisionPad.values
                              .map(
                                (DecisionPad value) =>
                                    DropdownMenuItem<DecisionPad>(
                                  value: value,
                                  child: Text(_decisionPadLabel(value)),
                                ),
                              )
                              .toList(),
                          onChanged: (DecisionPad? value) {
                            setState(() => _decision = value);
                          },
                        ),
                      ),
                      _FieldItem(
                        flex: 24,
                        child: TextFormField(
                          controller: _observacionesController,
                          decoration: _inputDecoration('Observaciones'),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomActionBar(
          onGuardar: _guardar,
          onAprobarIngreso: _aprobarIngreso,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFF2F4F7),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFD8DEE5)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2F3542),
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldItem {
  final int flex;
  final Widget child;

  const _FieldItem({
    required this.flex,
    required this.child,
  });
}

class _AdaptiveFieldsRow extends StatelessWidget {
  final List<_FieldItem> children;

  const _AdaptiveFieldsRow({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 1000;

        if (!isWide) {
          return Column(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                children[i].child,
                if (i != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              Expanded(
                flex: children[i].flex,
                child: children[i].child,
              ),
              if (i != children.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }
}

class _MotivosField extends StatelessWidget {
  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MotivosField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((String option) {
          final bool isSelected = selected.contains(option);
          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (_) => onToggle(option),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onGuardar;
  final VoidCallback onAprobarIngreso;

  const _BottomActionBar({
    required this.onGuardar,
    required this.onAprobarIngreso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FB),
        border: Border(
          top: BorderSide(color: Color(0xFFD8DEE5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: FilledButton(
                onPressed: onGuardar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A66),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar candidato'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onAprobarIngreso,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Aprobar para ingreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _sexoPacienteLabel(SexoPaciente value) {
  switch (value) {
    case SexoPaciente.femenino:
      return 'Femenino';
    case SexoPaciente.masculino:
      return 'Masculino';
    case SexoPaciente.otro:
      return 'Otro';
  }
}

String _tipoAseguramientoLabel(TipoAseguramiento value) {
  switch (value) {
    case TipoAseguramiento.eps:
      return 'EPS';
    case TipoAseguramiento.medicinaPrepagada:
      return 'Medicina prepagada';
    case TipoAseguramiento.poliza:
      return 'Póliza';
    case TipoAseguramiento.particular:
      return 'Particular';
    case TipoAseguramiento.otro:
      return 'Otro';
  }
}

String _regimenAseguramientoLabel(RegimenAseguramiento value) {
  switch (value) {
    case RegimenAseguramiento.contributivo:
      return 'Contributivo';
    case RegimenAseguramiento.subsidiado:
      return 'Subsidiado';
    case RegimenAseguramiento.especial:
      return 'Especial';
    case RegimenAseguramiento.particular:
      return 'Particular';
    case RegimenAseguramiento.noAplica:
      return 'No aplica';
  }
}

String _tipoCaptacionPadLabel(TipoCaptacionPad value) {
  switch (value) {
    case TipoCaptacionPad.busquedaActivaPad:
      return 'Búsqueda activa del PAD';
    case TipoCaptacionPad.presentadoPorServicio:
      return 'Presentado por el servicio';
  }
}

String _servicioQuePresentaLabel(ServicioQuePresenta value) {
  switch (value) {
    case ServicioQuePresenta.urgencias:
      return 'Urgencias';
    case ServicioQuePresenta.hospitalizacion:
      return 'Hospitalización';
    case ServicioQuePresenta.uci:
      return 'UCI';
    case ServicioQuePresenta.cirugia:
      return 'Cirugía';
    case ServicioQuePresenta.consultaExterna:
      return 'Consulta externa';
    case ServicioQuePresenta.otro:
      return 'Otro';
  }
}

String _origenPacienteLabel(OrigenPaciente value) {
  switch (value) {
    case OrigenPaciente.urgencias:
      return 'Urgencias';
    case OrigenPaciente.hospitalizacion:
      return 'Hospitalización';
    case OrigenPaciente.uci:
      return 'UCI';
    case OrigenPaciente.cirugia:
      return 'Cirugía';
    case OrigenPaciente.consultaExterna:
      return 'Consulta externa';
    case OrigenPaciente.otro:
      return 'Otro';
  }
}

String _especialidadPrincipalTratanteLabel(
  EspecialidadPrincipalTratante value,
) {
  switch (value) {
    case EspecialidadPrincipalTratante.medicinaInterna:
      return 'Medicina interna';
    case EspecialidadPrincipalTratante.cirugiaGeneral:
      return 'Cirugía general';
    case EspecialidadPrincipalTratante.ortopedia:
      return 'Ortopedia';
    case EspecialidadPrincipalTratante.ginecologia:
      return 'Ginecología';
    case EspecialidadPrincipalTratante.pediatria:
      return 'Pediatría';
  }
}

String _decisionPadLabel(DecisionPad value) {
  switch (value) {
    case DecisionPad.ingresoAprobado:
      return 'Ingreso aprobado';
    case DecisionPad.ingresoNoAprobado:
      return 'Ingreso no aprobado';
    case DecisionPad.pendienteValoracion:
      return 'Pendiente de valoración';
    case DecisionPad.requiereNuevaValoracion:
      return 'Requiere nueva valoración';
  }
}