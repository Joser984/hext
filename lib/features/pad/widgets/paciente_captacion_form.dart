import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/features/pad/summary/pad_summary_compact.dart';
import 'package:hext/features/pad/summary/pad_summary_domain_adapter.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';
import 'package:hext/features/pad/services/pad_firestore_service.dart';

enum SexoPaciente { femenino, masculino, otro }

enum TipoAseguramiento { eps, medicinaPrepagada, poliza, particular, otro }

enum RegimenAseguramiento {
  contributivo,
  subsidiado,
  especial,
  particular,
  noAplica,
}

enum TipoCaptacionPad { busquedaActivaPad, presentadoPorServicio }

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

enum MotivoDetalleEstado { enCurso, finalizado }

enum ProcedimientoEstado { pendiente, realizado }

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
  final String? motivoIngresoPrincipal;
  final List<String> motivosIngresoActivos;
  final Map<String, dynamic> detalleMotivos;

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
    required this.motivoIngresoPrincipal,
    required this.motivosIngresoActivos,
    required this.detalleMotivos,
    required this.unidadFuncionalOrigen,
    required this.decision,
    required this.observaciones,
  });
}

class PacienteCaptacionForm extends StatefulWidget {
  const PacienteCaptacionForm({super.key, this.candidatoId, this.initialData});

  final String? candidatoId;
  final Map<String, dynamic>? initialData;

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

  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _grupoRiesgoController = TextEditingController();

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

  String? _selectedAdmissionReason;
  final Set<String> _selectedAdmissionReasonKeys = <String>{};

  DateTime? _fechaProbableFinalizacionTratamiento;
  MotivoDetalleEstado _estadoFinalizacionTratamiento =
      MotivoDetalleEstado.enCurso;
  final TextEditingController _observacionesTratamientoController =
      TextEditingController();

  final TextEditingController _heridasCadaCuantosDiasController =
      TextEditingController();
  final TextEditingController _heridasSesionesPlaneadasController =
      TextEditingController();
  final TextEditingController _heridasSesionesRealizadasController =
      TextEditingController();
  DateTime? _fechaProbableFinalizacionHeridas;
  MotivoDetalleEstado _estadoClinicaHeridas = MotivoDetalleEstado.enCurso;

  final List<_ProcedimientoPendienteItem> _procedimientosPendientes =
      <_ProcedimientoPendienteItem>[];

  bool get _isEditing =>
      widget.candidatoId != null && widget.candidatoId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _hydrateFromData(widget.initialData!);
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

    _aseguradoraController.text = (data['aseguradora'] as String?) ?? '';
    _diagnosticoController.text = (data['diagnostico'] as String?) ?? '';
    _grupoRiesgoController.text =
        (data['grupoRelacionadoRiesgo'] as String?) ?? '';
    _unidadFuncionalOrigenController.text =
        (data['unidadFuncionalOrigen'] as String?) ?? '';
    _observacionesController.text = (data['observaciones'] as String?) ?? '';

    _sexo = _findEnumByLabel<SexoPaciente>(
      SexoPaciente.values,
      data['sexo'] as String?,
      _sexoPacienteLabel,
    );
    _tipoAseguramiento = _findEnumByLabel<TipoAseguramiento>(
      TipoAseguramiento.values,
      data['tipoAseguramiento'] as String?,
      _tipoAseguramientoLabel,
    );
    _regimenAseguramiento = _findEnumByLabel<RegimenAseguramiento>(
      RegimenAseguramiento.values,
      data['regimenAseguramiento'] as String?,
      _regimenAseguramientoLabel,
    );
    _tipoCaptacionPad = _findEnumByLabel<TipoCaptacionPad>(
      TipoCaptacionPad.values,
      data['tipoCaptacionPad'] as String?,
      _tipoCaptacionPadLabel,
    );
    _servicioQuePresenta = _findEnumByLabel<ServicioQuePresenta>(
      ServicioQuePresenta.values,
      data['servicioQuePresenta'] as String?,
      _servicioQuePresentaLabel,
    );
    _origenPaciente = _findEnumByLabel<OrigenPaciente>(
      OrigenPaciente.values,
      data['origenPaciente'] as String?,
      _origenPacienteLabel,
    );
    _especialidadPrincipalTratante =
        _findEnumByLabel<EspecialidadPrincipalTratante>(
          EspecialidadPrincipalTratante.values,
          data['especialidadPrincipalTratante'] as String?,
          _especialidadPrincipalTratanteLabel,
        );
    _decision = _findEnumByLabel<DecisionPad>(
      DecisionPad.values,
      data['decision'] as String?,
      _decisionPadLabel,
    );

    final List<dynamic> legacyMotivos =
        (data['motivos'] as List<dynamic>?) ?? <dynamic>[];
    final List<String> activosPersistidos =
        (data['motivosIngresoActivos'] as List<dynamic>?)
            ?.map(
              (dynamic item) => _normalizeAdmissionReasonKey(item.toString()),
            )
            .whereType<String>()
            .toList() ??
        <String>[];
    final String? principalKey =
        _normalizeAdmissionReasonKey(
          data['motivoIngresoPrincipal']?.toString(),
        ) ??
        (legacyMotivos.isNotEmpty
            ? _normalizeAdmissionReasonKey(legacyMotivos.first.toString())
            : null);

    _selectedAdmissionReasonKeys
      ..clear()
      ..addAll(activosPersistidos);
    if (_selectedAdmissionReasonKeys.isEmpty && principalKey != null) {
      _selectedAdmissionReasonKeys.add(principalKey);
    }

    final String? resolvedPrimaryKey =
        principalKey ??
        (_selectedAdmissionReasonKeys.isNotEmpty
            ? _selectedAdmissionReasonKeys.first
            : null);
    _selectedAdmissionReason = _admissionReasonLabelFromKey(resolvedPrimaryKey);

    final Map<String, dynamic> detalleMotivos =
        (data['detalleMotivos'] as Map<dynamic, dynamic>?)?.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, dynamic>(key.toString(), value),
        ) ??
        <String, dynamic>{};

    final Map<String, dynamic> detalleFinalizar =
        (detalleMotivos[PadAdmissionReasonLabels.finishTreatment.key]
                as Map<dynamic, dynamic>?)
            ?.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ) ??
        <String, dynamic>{};
    _fechaProbableFinalizacionTratamiento = _parseDate(
      detalleFinalizar['fechaProbableFinalizacion'],
    );
    _estadoFinalizacionTratamiento = _motivoEstadoFromKey(
      detalleFinalizar['estado']?.toString(),
    );
    _observacionesTratamientoController.text =
        (detalleFinalizar['observaciones'] as String?) ?? '';

    final Map<String, dynamic> detalleHeridas =
        (detalleMotivos[PadAdmissionReasonLabels.woundCare.key]
                as Map<dynamic, dynamic>?)
            ?.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ) ??
        <String, dynamic>{};
    _heridasCadaCuantosDiasController.text =
        (detalleHeridas['frecuenciaDias'] ?? '').toString();
    _heridasSesionesPlaneadasController.text =
        (detalleHeridas['sesionesPlaneadas'] ?? '').toString();
    _heridasSesionesRealizadasController.text =
        (detalleHeridas['sesionesRealizadas'] ?? '').toString();
    _fechaProbableFinalizacionHeridas = _parseDate(
      detalleHeridas['fechaProbableFinalizacion'],
    );
    _estadoClinicaHeridas = _motivoEstadoFromKey(
      detalleHeridas['estado']?.toString(),
    );

    _procedimientosPendientes.clear();
    final Map<String, dynamic> detalleProcedimiento =
        (detalleMotivos[PadAdmissionReasonLabels.pendingProcedure.key]
                as Map<dynamic, dynamic>?)
            ?.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ) ??
        <String, dynamic>{};
    final List<dynamic> procedimientos =
        (detalleProcedimiento['procedimientos'] as List<dynamic>?) ??
        <dynamic>[];

    for (final dynamic item in procedimientos) {
      if (item is! Map<dynamic, dynamic>) continue;
      final _ProcedimientoPendienteItem procedimiento =
          _ProcedimientoPendienteItem();
      procedimiento.nombreController.text = (item['nombre'] as String?) ?? '';
      procedimiento.observacionController.text =
          (item['observacion'] as String?) ?? '';
      procedimiento.fechaProbable = _parseDate(item['fechaProbable']);
      procedimiento.estado = _procedimientoEstadoFromKey(
        item['estado']?.toString(),
      );
      _procedimientosPendientes.add(procedimiento);
    }

    if (_selectedAdmissionReasonKeys.contains(
          PadAdmissionReasonLabels.pendingProcedure.key,
        ) &&
        _procedimientosPendientes.isEmpty) {
      _procedimientosPendientes.add(_ProcedimientoPendienteItem());
    }
  }

  T? _findEnumByLabel<T>(
    Iterable<T> values,
    String? label,
    String Function(T) labelOf,
  ) {
    if (label == null || label.trim().isEmpty) return null;
    for (final T value in values) {
      if (labelOf(value) == label) {
        return value;
      }
    }
    return null;
  }

  String? _normalizeAdmissionReasonKey(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (option.key == rawValue || option.label == rawValue) {
        return option.key;
      }
    }
    return null;
  }

  String? _admissionReasonLabelFromKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (option.key == key) {
        return option.label;
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed == null) return null;
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  MotivoDetalleEstado _motivoEstadoFromKey(String? key) {
    return key == 'finalizado'
        ? MotivoDetalleEstado.finalizado
        : MotivoDetalleEstado.enCurso;
  }

  ProcedimientoEstado _procedimientoEstadoFromKey(String? key) {
    return key == 'realizado'
        ? ProcedimientoEstado.realizado
        : ProcedimientoEstado.pendiente;
  }

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
    _observacionesTratamientoController.dispose();
    _heridasCadaCuantosDiasController.dispose();
    _heridasSesionesPlaneadasController.dispose();
    _heridasSesionesRealizadasController.dispose();
    for (final _ProcedimientoPendienteItem p in _procedimientosPendientes) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedAdmissionReasonKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un motivo de ingreso.'),
        ),
      );
      return;
    }

    if (_selectedAdmissionReason != null) {
      final String? selectedPrimaryKey = _admissionReasonKeyFromLabel(
        _selectedAdmissionReason,
      );
      if (selectedPrimaryKey != null &&
          !_selectedAdmissionReasonKeys.contains(selectedPrimaryKey)) {
        _selectedAdmissionReasonKeys.add(selectedPrimaryKey);
      }
    }

    final String? motivoPrincipalKey = _admissionReasonKeyFromLabel(
      _selectedAdmissionReason,
    );
    final List<String> motivosActivos = _orderedSelectedReasonKeys();
    final String? resolvedPrincipalKey =
        motivoPrincipalKey ??
        (motivosActivos.isNotEmpty ? motivosActivos.first : null);
    final Map<String, dynamic> detalleMotivos = _buildDetalleMotivosForSave(
      motivosActivos,
    );

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
      motivos: motivosActivos.toSet(),
      motivoIngresoPrincipal: resolvedPrincipalKey,
      motivosIngresoActivos: motivosActivos,
      detalleMotivos: detalleMotivos,
      unidadFuncionalOrigen: _unidadFuncionalOrigenController.text.trim(),
      decision: _decision,
      observaciones: _observacionesController.text.trim(),
    );

    final Map<String, dynamic> data = <String, dynamic>{
      'nombreCompleto': paciente.nombreCompleto,
      'identificacion': paciente.identificacion,
      'sexo': _sexoPacienteLabel(paciente.sexo),
      'edad': paciente.edad,
      'tipoAseguramiento': paciente.tipoAseguramiento == null
          ? null
          : _tipoAseguramientoLabel(paciente.tipoAseguramiento!),
      'aseguradora': paciente.aseguradora,
      'regimenAseguramiento': paciente.regimenAseguramiento == null
          ? null
          : _regimenAseguramientoLabel(paciente.regimenAseguramiento!),
      'tipoCaptacionPad': _tipoCaptacionPadLabel(paciente.tipoCaptacionPad),
      'servicioQuePresenta': paciente.servicioQuePresenta == null
          ? null
          : _servicioQuePresentaLabel(paciente.servicioQuePresenta!),
      'origenPaciente': paciente.origenPaciente == null
          ? null
          : _origenPacienteLabel(paciente.origenPaciente!),
      'especialidadPrincipalTratante':
          paciente.especialidadPrincipalTratante == null
          ? null
          : _especialidadPrincipalTratanteLabel(
              paciente.especialidadPrincipalTratante!,
            ),
      'diagnostico': paciente.diagnostico,
      'grupoRelacionadoRiesgo': paciente.grupoRelacionadoRiesgo,
      'unidadFuncionalOrigen': paciente.unidadFuncionalOrigen,
      'decision': paciente.decision == null
          ? null
          : _decisionPadLabel(paciente.decision!),
      'observaciones': paciente.observaciones,
      // Nueva estructura persistida.
      'motivoIngresoPrincipal': paciente.motivoIngresoPrincipal,
      'motivosIngresoActivos': paciente.motivosIngresoActivos,
      'detalleMotivos': paciente.detalleMotivos,
      // Compatibilidad temporal.
      'motivos': paciente.motivos.toList(),
    };

    try {
      if (_isEditing) {
        await PadFirestoreService.actualizarCandidato(
          widget.candidatoId!,
          data,
        );
      } else {
        await PadFirestoreService.guardarCandidato(data);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(PadUiLabels.saveCaseError)));
      return;
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(PadUiLabels.caseSaved),
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
            'Motivo principal: ${paciente.motivoIngresoPrincipal ?? '-'}\n'
            'Motivos activos: ${paciente.motivosIngresoActivos.isEmpty ? '-' : paciente.motivosIngresoActivos.join(', ')}\n'
            'Detalle del motivo: ${_motivoDetalleSummary()}\n'
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
      const SnackBar(content: Text(PadUiLabels.caseApprovedForAdmission)),
    );
  }

  InputDecoration _inputDecoration(String label, {bool fixedHeight = true}) {
    return InputDecoration(
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: fixedHeight
          ? const BoxConstraints(minHeight: 40, maxHeight: 40)
          : null,
      hintStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.15,
        color: Color(0xFF8A94A6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD2DAE3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD2DAE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
    );
  }

  Future<void> _pickDate(
    ValueChanged<DateTime> onPicked, {
    DateTime? initialDate,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) {
      onPicked(DateTime(selected.year, selected.month, selected.day));
    }
  }

  int get _heridasSesionesPendientes {
    final int planeadas =
        int.tryParse(_heridasSesionesPlaneadasController.text) ?? 0;
    final int realizadas =
        int.tryParse(_heridasSesionesRealizadasController.text) ?? 0;
    final int pendiente = planeadas - realizadas;
    return pendiente < 0 ? 0 : pendiente;
  }

  DateTime? get _proximaSesionHeridas {
    final int frecuenciaDias =
        int.tryParse(_heridasCadaCuantosDiasController.text) ?? 0;
    if (frecuenciaDias <= 0 || _heridasSesionesPendientes <= 0) {
      return null;
    }

    final DateTime hoy = DateTime.now();
    final DateTime base = DateTime(hoy.year, hoy.month, hoy.day);
    return base.add(Duration(days: frecuenciaDias));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateOrDash(DateTime? date) {
    if (date == null) return '--';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? _dateIso(DateTime? date) {
    if (date == null) return null;
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }

  String? _admissionReasonKeyFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (option.label == label) {
        return option.key;
      }
    }
    return null;
  }

  String _motivoEstadoKey(MotivoDetalleEstado estado) {
    return estado == MotivoDetalleEstado.finalizado ? 'finalizado' : 'en_curso';
  }

  String _procedimientoEstadoKey(ProcedimientoEstado estado) {
    return estado == ProcedimientoEstado.realizado ? 'realizado' : 'pendiente';
  }

  Map<String, dynamic> _buildDetalleMotivosForSave(List<String> activeKeys) {
    final Map<String, dynamic> detalles = <String, dynamic>{};

    if (activeKeys.contains(PadAdmissionReasonLabels.finishTreatment.key)) {
      detalles[PadAdmissionReasonLabels.finishTreatment.key] =
          <String, dynamic>{
            'activo': true,
            'estado': _motivoEstadoKey(_estadoFinalizacionTratamiento),
            'fechaProbableFinalizacion': _dateIso(
              _fechaProbableFinalizacionTratamiento,
            ),
            'observaciones': _observacionesTratamientoController.text.trim(),
          };
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.woundCare.key)) {
      final int frecuenciaDias =
          int.tryParse(_heridasCadaCuantosDiasController.text) ?? 0;
      final int sesionesPlaneadas =
          int.tryParse(_heridasSesionesPlaneadasController.text) ?? 0;
      final int sesionesRealizadas =
          int.tryParse(_heridasSesionesRealizadasController.text) ?? 0;

      detalles[PadAdmissionReasonLabels.woundCare.key] = <String, dynamic>{
        'activo': true,
        'estado': _motivoEstadoKey(_estadoClinicaHeridas),
        'frecuenciaDias': frecuenciaDias,
        'sesionesPlaneadas': sesionesPlaneadas,
        'sesionesRealizadas': sesionesRealizadas,
        'sesionesPendientes': _heridasSesionesPendientes,
        'fechaProbableFinalizacion': _dateIso(
          _fechaProbableFinalizacionHeridas,
        ),
      };
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.pendingProcedure.key)) {
      detalles[PadAdmissionReasonLabels.pendingProcedure.key] =
          <String, dynamic>{
            'activo': true,
            'estado':
                _procedimientosPendientes.any(
                  (p) => p.estado == ProcedimientoEstado.pendiente,
                )
                ? 'en_curso'
                : 'finalizado',
            'procedimientos': _procedimientosPendientes
                .where(
                  (p) =>
                      p.nombreController.text.trim().isNotEmpty ||
                      p.observacionController.text.trim().isNotEmpty ||
                      p.fechaProbable != null,
                )
                .map(
                  (p) => <String, dynamic>{
                    'nombre': p.nombreController.text.trim(),
                    'fechaProbable': _dateIso(p.fechaProbable),
                    'estado': _procedimientoEstadoKey(p.estado),
                    'observacion': p.observacionController.text.trim(),
                  },
                )
                .toList(),
          };
    }

    return detalles;
  }

  List<String> _orderedSelectedReasonKeys() {
    final List<String> ordered = <String>[];
    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (_selectedAdmissionReasonKeys.contains(option.key)) {
        ordered.add(option.key);
      }
    }
    return ordered;
  }

  String _motivoDetalleSummary() {
    final List<String> activeKeys = _orderedSelectedReasonKeys();
    if (activeKeys.isEmpty) {
      return '-';
    }

    final List<String> chunks = <String>[];

    if (activeKeys.contains(PadAdmissionReasonLabels.finishTreatment.key)) {
      final String estado =
          _estadoFinalizacionTratamiento == MotivoDetalleEstado.finalizado
          ? 'Finalizado'
          : 'En curso';
      chunks.add(
        'Finalizar tratamiento: ${_formatDateOrDash(_fechaProbableFinalizacionTratamiento)} · $estado',
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.woundCare.key)) {
      final int planeadas =
          int.tryParse(_heridasSesionesPlaneadasController.text) ?? 0;
      final int realizadas =
          int.tryParse(_heridasSesionesRealizadasController.text) ?? 0;
      final int frecuenciaDias =
          int.tryParse(_heridasCadaCuantosDiasController.text) ?? 0;
      chunks.add(
        'Clínica de heridas: ${frecuenciaDias > 0 ? 'cada $frecuenciaDias días' : '--'} · Sesiones: $realizadas/$planeadas · Pendientes: $_heridasSesionesPendientes',
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.pendingProcedure.key)) {
      final int pendientes = _procedimientosPendientes
          .where((p) => p.estado == ProcedimientoEstado.pendiente)
          .length;
      final int realizados = _procedimientosPendientes
          .where((p) => p.estado == ProcedimientoEstado.realizado)
          .length;
      chunks.add(
        'Procedimiento pendiente: Pendientes $pendientes · Realizados $realizados',
      );
    }

    return chunks.join(' | ');
  }

  PadCaseData _buildPadCaseDataPreview() {
    final List<String> activeReasonLabels = _orderedSelectedReasonKeys()
        .map((String key) => _admissionReasonLabelFromKey(key) ?? key)
        .toList();

    final String detailSummary = _motivoDetalleSummary();

    String? situacion;
    if (_decision == DecisionPad.ingresoAprobado) {
      situacion = PadCareSituationLabels.activeInPad;
    } else if (_decision == DecisionPad.pendienteValoracion ||
        _decision == DecisionPad.requiereNuevaValoracion) {
      situacion = 'En valoracion';
    } else if (_decision == DecisionPad.ingresoNoAprobado) {
      situacion = 'No ingreso';
    }

    final PadCaseRecord record = PadCaseRecord(
      motivoIngresoPrincipal: _selectedAdmissionReason,
      motivosIngresoActivos: activeReasonLabels,
      detalleClinicoResumido: detailSummary == '-' ? null : detailSummary,
      observaciones: _observacionesController.text.trim(),
      situacionAsistencial: situacion,
      estadoPad: _decision == null ? null : _decisionPadLabel(_decision!),
    );

    return PadSummaryDomainAdapter.toPadCaseData(record);
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(value),
              style: TextStyle(
                fontSize: 14,
                color: value == null
                    ? const Color(0xFF7A869A)
                    : const Color(0xFF243247),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivoDetalleSection() {
    final List<String> activeKeys = _orderedSelectedReasonKeys();
    if (activeKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> sections = <Widget>[];

    if (activeKeys.contains(PadAdmissionReasonLabels.finishTreatment.key)) {
      sections.add(
        _SectionCard(
          title: PadAdmissionReasonLabels.finishTreatment.label,
          child: _buildDetalleFinalizarTratamiento(),
        ),
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.woundCare.key)) {
      sections.add(
        _SectionCard(
          title: PadAdmissionReasonLabels.woundCare.label,
          child: _buildDetalleClinicaHeridas(),
        ),
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.pendingProcedure.key)) {
      sections.add(
        _SectionCard(
          title: PadAdmissionReasonLabels.pendingProcedure.label,
          child: _buildDetalleProcedimientosPendientes(),
        ),
      );
    }

    return Column(children: <Widget>[const SizedBox(height: 12), ...sections]);
  }

  Widget _buildAdmissionReasonField() {
    return InputDecorator(
      decoration: _inputDecoration(
        PadUiLabels.admissionReasonField,
        fixedHeight: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PadAdmissionReasonLabels.all.map((
              PadAdmissionReasonOption option,
            ) {
              final bool selected = _selectedAdmissionReasonKeys.contains(
                option.key,
              );

              return FilterChip(
                label: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                    color: Color(0xFF1C2228),
                  ),
                ),
                selected: selected,
                onSelected: (_) => _toggleAdmissionReason(option),
                showCheckmark: false,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF06B6D4)
                      : const Color(0xFFD2DAE3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color(0xFFF7F8FA),
                selectedColor: const Color(0xFFE8F8FC),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedAdmissionReason,
            decoration: _inputDecoration('Motivo principal'),
            items: _orderedSelectedReasonKeys()
                .map(
                  (String key) => DropdownMenuItem<String>(
                    value: _admissionReasonLabelFromKey(key),
                    child: Text(_admissionReasonLabelFromKey(key) ?? key),
                  ),
                )
                .toList(),
            onChanged: _selectedAdmissionReasonKeys.isEmpty
                ? null
                : (String? value) {
                    setState(() {
                      _selectedAdmissionReason = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  void _toggleAdmissionReason(PadAdmissionReasonOption option) {
    setState(() {
      if (_selectedAdmissionReasonKeys.contains(option.key)) {
        _selectedAdmissionReasonKeys.remove(option.key);
        if (_selectedAdmissionReason == option.label) {
          final String? nextPrimary = _selectedAdmissionReasonKeys.isNotEmpty
              ? _admissionReasonLabelFromKey(_orderedSelectedReasonKeys().first)
              : null;
          _selectedAdmissionReason = nextPrimary;
        }
        return;
      }

      _selectedAdmissionReasonKeys.add(option.key);
      _selectedAdmissionReason ??= option.label;
      if (option.key == PadAdmissionReasonLabels.pendingProcedure.key &&
          _procedimientosPendientes.isEmpty) {
        _procedimientosPendientes.add(_ProcedimientoPendienteItem());
      }
    });
  }

  Widget _buildDetalleFinalizarTratamiento() {
    return _AdaptiveFieldsRow(
      children: <_FieldItem>[
        _FieldItem(
          flex: 18,
          child: _buildDatePickerField(
            label: 'Fecha probable de finalización',
            value: _fechaProbableFinalizacionTratamiento,
            onTap: () => _pickDate((DateTime date) {
              setState(() => _fechaProbableFinalizacionTratamiento = date);
            }, initialDate: _fechaProbableFinalizacionTratamiento),
          ),
        ),
        _FieldItem(
          flex: 14,
          child: DropdownButtonFormField<MotivoDetalleEstado>(
            initialValue: _estadoFinalizacionTratamiento,
            decoration: _inputDecoration('Estado del motivo'),
            items: const <DropdownMenuItem<MotivoDetalleEstado>>[
              DropdownMenuItem(
                value: MotivoDetalleEstado.enCurso,
                child: Text('En curso'),
              ),
              DropdownMenuItem(
                value: MotivoDetalleEstado.finalizado,
                child: Text('Finalizado'),
              ),
            ],
            onChanged: (MotivoDetalleEstado? value) {
              if (value == null) return;
              setState(() => _estadoFinalizacionTratamiento = value);
            },
          ),
        ),
        _FieldItem(
          flex: 24,
          child: TextFormField(
            controller: _observacionesTratamientoController,
            decoration: _inputDecoration('Observaciones del tratamiento'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleClinicaHeridas() {
    return Column(
      children: <Widget>[
        _AdaptiveFieldsRow(
          children: <_FieldItem>[
            _FieldItem(
              flex: 12,
              child: TextFormField(
                controller: _heridasCadaCuantosDiasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Frecuencia de sesiones'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FieldItem(
              flex: 12,
              child: TextFormField(
                controller: _heridasSesionesPlaneadasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Sesiones planeadas'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FieldItem(
              flex: 12,
              child: TextFormField(
                controller: _heridasSesionesRealizadasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Sesiones realizadas'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FieldItem(
              flex: 12,
              child: InputDecorator(
                decoration: _inputDecoration('Sesiones pendientes'),
                child: Text(
                  '$_heridasSesionesPendientes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF243247),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AdaptiveFieldsRow(
          children: <_FieldItem>[
            _FieldItem(
              flex: 12,
              child: InputDecorator(
                decoration: _inputDecoration('Próxima sesión'),
                child: Text(
                  _formatDateOrDash(_proximaSesionHeridas),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF243247),
                  ),
                ),
              ),
            ),
            _FieldItem(
              flex: 18,
              child: _buildDatePickerField(
                label: 'Fecha probable de finalización',
                value: _fechaProbableFinalizacionHeridas,
                onTap: () => _pickDate((DateTime date) {
                  setState(() => _fechaProbableFinalizacionHeridas = date);
                }, initialDate: _fechaProbableFinalizacionHeridas),
              ),
            ),
            _FieldItem(
              flex: 14,
              child: DropdownButtonFormField<MotivoDetalleEstado>(
                initialValue: _estadoClinicaHeridas,
                decoration: _inputDecoration('Estado del motivo'),
                items: const <DropdownMenuItem<MotivoDetalleEstado>>[
                  DropdownMenuItem(
                    value: MotivoDetalleEstado.enCurso,
                    child: Text('En curso'),
                  ),
                  DropdownMenuItem(
                    value: MotivoDetalleEstado.finalizado,
                    child: Text('Finalizado'),
                  ),
                ],
                onChanged: (MotivoDetalleEstado? value) {
                  if (value == null) return;
                  setState(() => _estadoClinicaHeridas = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetalleProcedimientosPendientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ..._procedimientosPendientes.asMap().entries.map((
          MapEntry<int, _ProcedimientoPendienteItem> entry,
        ) {
          final int index = entry.key;
          final _ProcedimientoPendienteItem item = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _procedimientosPendientes.length - 1 ? 10 : 12,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE3EA)),
              ),
              child: Column(
                children: <Widget>[
                  _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 24,
                        child: TextFormField(
                          controller: item.nombreController,
                          decoration: _inputDecoration(
                            'Nombre del procedimiento',
                          ),
                        ),
                      ),
                      _FieldItem(
                        flex: 18,
                        child: _buildDatePickerField(
                          label: 'Fecha probable',
                          value: item.fechaProbable,
                          onTap: () => _pickDate((DateTime date) {
                            setState(() => item.fechaProbable = date);
                          }, initialDate: item.fechaProbable),
                        ),
                      ),
                      _FieldItem(
                        flex: 14,
                        child: DropdownButtonFormField<ProcedimientoEstado>(
                          initialValue: item.estado,
                          decoration: _inputDecoration('Estado'),
                          items: const <DropdownMenuItem<ProcedimientoEstado>>[
                            DropdownMenuItem(
                              value: ProcedimientoEstado.pendiente,
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: ProcedimientoEstado.realizado,
                              child: Text('Realizado'),
                            ),
                          ],
                          onChanged: (ProcedimientoEstado? value) {
                            if (value == null) return;
                            setState(() => item.estado = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 30,
                        child: TextFormField(
                          controller: item.observacionController,
                          decoration: _inputDecoration('Observación'),
                        ),
                      ),
                      _FieldItem(
                        flex: 10,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Agregar procedimiento',
                                onPressed: () {
                                  setState(() {
                                    _procedimientosPendientes.add(
                                      _ProcedimientoPendienteItem(),
                                    );
                                  });
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Color(0xFF1E3A66),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar procedimiento',
                                onPressed: () {
                                  setState(() {
                                    if (_procedimientosPendientes.length == 1) {
                                      item.nombreController.clear();
                                      item.observacionController.clear();
                                      item.fechaProbable = null;
                                      item.estado =
                                          ProcedimientoEstado.pendiente;
                                      return;
                                    }

                                    final _ProcedimientoPendienteItem removed =
                                        _procedimientosPendientes.removeAt(
                                          index,
                                        );
                                    removed.dispose();
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = mapPadSummary(_buildPadCaseDataPreview());

    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: <Widget>[
                _SectionCard(
                  title: 'Resumen PAD compacto',
                  child: PadSummaryCompact(vm: summary),
                ),
                const SizedBox(height: 16),
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
                                      child: Text(
                                        _tipoAseguramientoLabel(value),
                                      ),
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
                              decoration: _inputDecoration(
                                'Tipo de captación PAD',
                              ),
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
                              child:
                                  DropdownButtonFormField<ServicioQuePresenta>(
                                    key: const ValueKey(
                                      'servicio_que_presenta',
                                    ),
                                    initialValue: _servicioQuePresenta,
                                    decoration: _inputDecoration(
                                      'Servicio que presenta',
                                    ),
                                    items: ServicioQuePresenta.values
                                        .map(
                                          (ServicioQuePresenta value) =>
                                              DropdownMenuItem<
                                                ServicioQuePresenta
                                              >(
                                                value: value,
                                                child: Text(
                                                  _servicioQuePresentaLabel(
                                                    value,
                                                  ),
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
                            child:
                                DropdownButtonFormField<
                                  EspecialidadPrincipalTratante
                                >(
                                  initialValue: _especialidadPrincipalTratante,
                                  decoration: _inputDecoration('Especialidad'),
                                  items: EspecialidadPrincipalTratante.values
                                      .map(
                                        (EspecialidadPrincipalTratante value) =>
                                            DropdownMenuItem<
                                              EspecialidadPrincipalTratante
                                            >(
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
                                          () => _especialidadPrincipalTratante =
                                              value,
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
                            flex: 56,
                            child: DropdownButtonFormField<OrigenPaciente>(
                              initialValue: _origenPaciente,
                              decoration: _inputDecoration(
                                'Origen del paciente',
                              ),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAdmissionReasonField(),
                      _buildMotivoDetalleSection(),
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
                          decoration: _inputDecoration(
                            'Unidad funcional origen',
                          ),
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

  const _SectionCard({required this.title, required this.child});

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

  const _FieldItem({required this.flex, required this.child});
}

class _AdaptiveFieldsRow extends StatelessWidget {
  final List<_FieldItem> children;

  const _AdaptiveFieldsRow({required this.children});

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
              Expanded(flex: children[i].flex, child: children[i].child),
              if (i != children.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
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
        border: Border(top: BorderSide(color: Color(0xFFD8DEE5))),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(PadUiLabels.saveCase),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onAprobarIngreso,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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

class _ProcedimientoPendienteItem {
  _ProcedimientoPendienteItem();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();
  DateTime? fechaProbable;
  ProcedimientoEstado estado = ProcedimientoEstado.pendiente;

  void dispose() {
    nombreController.dispose();
    observacionController.dispose();
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
