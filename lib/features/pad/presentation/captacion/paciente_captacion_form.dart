import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
import 'package:hext/features/pad/catalogs/aseguradoras_catalog.dart';
import 'package:hext/features/pad/catalogs/barrios_catalog.dart';
import 'package:hext/features/pad/catalogs/barrios_catalog_service.dart';
import 'package:hext/features/pad/catalogs/municipios_catalog.dart';
import 'package:hext/features/pad/catalogs/municipios_catalog_service.dart';
import 'package:hext/features/pad/services/pad_firestore_service.dart';
import 'package:hext/features/pad/presentation/captacion/widgets/pad_form_fields.dart';
import 'package:hext/features/pad/presentation/captacion/widgets/pad_form_grid.dart';
import 'package:hext/features/pad/presentation/captacion/widgets/pad_form_section_card.dart';
import 'package:hext/features/pad/presentation/captacion/widgets/pad_form_styles.dart';
import 'package:hext/features/pad/utils/diagnosis_text_formatter.dart';
import 'package:hext/shared/widgets/hext_button.dart';
import 'package:hext/shared/widgets/hext_modal.dart';
import 'package:hext/shared/widgets/hext_page_shell.dart';
import 'paciente_captacion_catalogs.dart';
import 'paciente_captacion_helpers.dart';
import 'paciente_captacion_labels.dart';
import 'paciente_captacion_models.dart';

class PacienteCaptacionForm extends StatefulWidget {
  const PacienteCaptacionForm({super.key, this.candidatoId, this.initialData});

  final String? candidatoId;
  final Map<String, dynamic>? initialData;

  @override
  State<PacienteCaptacionForm> createState() => _PacienteCaptacionFormState();
}

class _PacienteCaptacionFormState extends State<PacienteCaptacionForm> {
  // Pendientes PAD (Fase 1)
  List<String> _pendientes = [];
  bool _pendientesCargando = false;
  List<String> _municipiosDisponibles = List<String>.from(municipiosBolivar);
  List<String> _barriosDisponibles = List<String>.from(kBarriosCartagena);
  String _municipioCatalogoActual = _municipioCartagena;
  @override
  void initState() {
    super.initState();
    if (_municipioController.text.trim().isEmpty) {
      _municipioController.text = _municipioCartagena;
    }
    _bootstrapForm();
    _cargarCatalogosUbicacion();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    if (!_isEditing && (widget.candidatoId?.isEmpty ?? true)) return;
    setState(() => _pendientesCargando = true);
    try {
      final String? patientId = widget.candidatoId;
      if (patientId == null || patientId.isEmpty) return;
      // FirestoreAgendaRepo no es necesario aquí
      final query = await FirebaseFirestore.instance
          .collection('agenda_events')
          .where('patientId', isEqualTo: patientId)
          .where('isClosed', isEqualTo: false)
          .get();
      final now = DateTime.now();
      final proximos3dias = now.add(const Duration(days: 3));
      final List<String> pendientes = [];
      for (final doc in query.docs) {
        final data = doc.data();
        final estadoAgenda = (data['estadoAgenda'] ?? '').toString();
        final responsableId = (data['responsableId'] ?? '').toString();
        final responsableNombre = (data['responsableNombre'] ?? '').toString();
        final fechaFinRaw = data['fechaProbableFinalizacion'];
        DateTime? fechaFin;
        if (fechaFinRaw is Timestamp) {
          fechaFin = fechaFinRaw.toDate();
        } else if (fechaFinRaw is DateTime) {
          fechaFin = fechaFinRaw;
        }
        // 1. Agenda vencida/no cerrada
        if (estadoAgenda != 'cerrada' && estadoAgenda != 'finalizada') {
          final fecha = data['fecha'];
          DateTime? fechaEvento;
          if (fecha is Timestamp) fechaEvento = fecha.toDate();
          if (fechaEvento != null && fechaEvento.isBefore(now)) {
            pendientes.add('Agenda vencida/no cerrada');
            break;
          }
        }
        // 2. Agenda sin responsable
        if (responsableId.isEmpty && responsableNombre.isEmpty) {
          pendientes.add('Agenda sin responsable asignado');
          break;
        }
        // 3. Tratamiento próximo a finalizar
        if (fechaFin != null &&
            fechaFin.isAfter(now) &&
            fechaFin.isBefore(proximos3dias)) {
          pendientes.add(
            'Tratamiento próximo a finalizar (${fechaFin.day.toString().padLeft(2, '0')}/${fechaFin.month.toString().padLeft(2, '0')})',
          );
          break;
        }
      }
      if (_alertaPrequirurgica48h) {
        pendientes.add(
          'Procedimiento dentro de 48 horas con laboratorios/estudios pendientes.',
        );
      }
      setState(() {
        _pendientes = pendientes;
        _pendientesCargando = false;
      });
    } catch (e) {
      setState(() {
        _pendientes = ['Error al cargar pendientes'];
        _pendientesCargando = false;
      });
    }
  }

  // --- UI helpers for visual order ---
  Widget _simpleSectionCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return PadFormSectionCard(
      title: title,
      icon: _sectionIconData(title),
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  PadFormGridItem _gridItem(Widget child, {int span = 1}) {
    return PadFormGridItem(child: child, span: span);
  }

  IconData _sectionIconData(String title) {
    switch (title.trim().toLowerCase()) {
      case 'datos básicos':
        return Icons.person_outline_rounded;
      case 'aseguramiento':
        return Icons.shield_outlined;
      case 'captación pad':
        return Icons.campaign_outlined;
      case 'contexto clínico':
        return Icons.favorite_border_rounded;
      case 'motivos pad programables':
        return Icons.format_list_bulleted_rounded;
      case 'decisión de ingreso':
        return Icons.task_alt_outlined;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  String? _aseguradoraCatalogKey;
  final _formKey = GlobalKey<FormState>();
  bool _isHydrating = false;
  bool get _isEditing => (widget.candidatoId ?? '').trim().isNotEmpty;
  DateTime? _fechaVisita;
  TimeOfDay? _horaVisita;
  // Estado para enums y selección
  SexoPaciente? _sexo;
  TipoAseguramiento? _tipoAseguramiento;
  RegimenAseguramiento? _regimenAseguramiento;
  TipoCaptacionPad? _tipoCaptacionPad;
  EspecialidadPrincipalTratante? _especialidadPrincipalTratante;
  DecisionPad? _decision;
  String? _frecuenciaTratamientoKey;
  String? _frecuenciaCuracionKey;
  String? _pacienteCuentaConInfusor;
  // Estado mínimo para motivos y fechas
  final List<String> _motivoIngresoPadOptions = [
    'Finalizar tratamiento',
    'Clínica de heridas',
    'Programación de procedimiento',
  ];
  List<String> _motivosIngresoActivos = [];
  String? _motivosIngresoError;
  DateTime? _fechaInicioTratamiento;
  DateTime? _fechaPrimeraVisitaTratamiento;
  TimeOfDay? _horaPrimeraVisitaTratamiento;
  DateTime? _fechaFinTratamiento;
  DateTime? _fechaPrimeraCuracion;
  TimeOfDay? _horaPrimeraCuracion;
  DateTime? _fechaProbableCierre;
  DateTime? _fechaProcedimiento;
  DateTime? _fechaValoracionAnestesiologia;
  TimeOfDay? _horaProcedimiento;
  bool? _requiereAuxiliarEnfermeria;
  String? _requiereAnestesiologia;
  String? _anestesiologiaRealizada;
  String? _laboratoriosPrequirurgicosEstado;
  // Controladores de campos
  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _identificacionController =
      TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _aseguradoraController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _grupoRiesgoController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _fechaVisitaController = TextEditingController();
  final TextEditingController _horaVisitaController = TextEditingController();
  final TextEditingController _unidadFuncionalOrigenController =
      TextEditingController();
  final TextEditingController _tratamientoPendienteController =
      TextEditingController();
  final TextEditingController _tratamientoComplementarioController =
      TextEditingController();
  final TextEditingController _frecuenciaPautaController =
      TextEditingController();
  final TextEditingController _fechaInicioTratamientoController =
      TextEditingController();
  final TextEditingController _fechaPrimeraVisitaTratamientoController =
      TextEditingController();
  final TextEditingController _horaPrimeraVisitaTratamientoController =
      TextEditingController();
  final TextEditingController _fechaFinTratamientoController =
      TextEditingController();
  final TextEditingController _observacionesTratamientoController =
      TextEditingController();
  final TextEditingController _tipoHeridaController = TextEditingController();
  final TextEditingController _ubicacionAnatomicaController =
      TextEditingController();
  final TextEditingController _frecuenciaCuracionController =
      TextEditingController();
  final TextEditingController _fechaPrimeraCuracionController =
      TextEditingController();
  final TextEditingController _fechaProbableCierreController =
      TextEditingController();
  final TextEditingController _horaPrimeraCuracionController =
      TextEditingController();
  final TextEditingController _requiereInsumosController =
      TextEditingController();
  final TextEditingController _observacionesHeridaController =
      TextEditingController();
  final TextEditingController _procedimientoRequeridoController =
      TextEditingController();
  final TextEditingController _fechaProcedimientoController =
      TextEditingController();
  final TextEditingController _horaProcedimientoController =
      TextEditingController();
  final TextEditingController _lugarProcedimientoController =
      TextEditingController();
  final TextEditingController _fechaValoracionAnestesiologiaController =
      TextEditingController();
  final TextEditingController _observacionesAnestesiologiaController =
      TextEditingController();
  final TextEditingController _valoracionesRequeridasController =
      TextEditingController();
  final TextEditingController _valoracionesPendientesController =
      TextEditingController();
  final TextEditingController _observacionesProcedimientoController =
      TextEditingController();
  static const String _municipioCartagena = 'Cartagena de Indias';
  static const List<String> _frecuenciaTratamientoOptions = <String>[
    'Cada 24 horas',
    'Cada 12 horas',
    'Cada 8 horas',
    'Cada 6 horas',
  ];
  static const List<String> _infusorOptions = <String>[
    'si',
    'no',
    'por_confirmar',
  ];
  static const List<String> _laboratoriosPrequirurgicosOptions = <String>[
    'cargados_procesados',
    'pendientes_cargar',
    'pendientes_procesar',
    'no_aplica',
  ];
  static const List<String> _antibioticosCandidatosInfusor = <String>[
    'aztreonam',
    'cefazolina',
    'cefepime',
    'cefepima',
    'ceftazidime',
    'ceftazidima',
    'ceftriaxona',
    'clindamicina',
    'oxacilina',
    'piperacilina tazobactam',
    'vancomicina',
    'meropenem',
  ];
  static const List<String> _frecuenciaCuracionOptions = <String>[
    'Diaria',
    'Cada 48 horas',
    'Cada 72 horas / Cada 3 días',
    'Semanal',
    'Según criterio clínico',
  ];
  static const List<String> _requiereAnestesiologiaOptions = <String>[
    'si',
    'no',
    'por_confirmar',
  ];
  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _identificacionController.dispose();
    _edadController.dispose();
    _municipioController.dispose();
    _barrioController.dispose();
    _especialidadController.dispose();
    _aseguradoraController.dispose();
    _diagnosticoController.dispose();
    _grupoRiesgoController.dispose();
    _observacionesController.dispose();
    _fechaVisitaController.dispose();
    _horaVisitaController.dispose();
    _unidadFuncionalOrigenController.dispose();
    _tratamientoPendienteController.dispose();
    _tratamientoComplementarioController.dispose();
    _frecuenciaPautaController.dispose();
    _fechaInicioTratamientoController.dispose();
    _fechaPrimeraVisitaTratamientoController.dispose();
    _horaPrimeraVisitaTratamientoController.dispose();
    _fechaFinTratamientoController.dispose();
    _observacionesTratamientoController.dispose();
    _tipoHeridaController.dispose();
    _ubicacionAnatomicaController.dispose();
    _frecuenciaCuracionController.dispose();
    _fechaPrimeraCuracionController.dispose();
    _horaPrimeraCuracionController.dispose();
    _fechaProbableCierreController.dispose();
    _requiereInsumosController.dispose();
    _observacionesHeridaController.dispose();
    _procedimientoRequeridoController.dispose();
    _fechaProcedimientoController.dispose();
    _horaProcedimientoController.dispose();
    _lugarProcedimientoController.dispose();
    _fechaValoracionAnestesiologiaController.dispose();
    _observacionesAnestesiologiaController.dispose();
    _valoracionesRequeridasController.dispose();
    _valoracionesPendientesController.dispose();
    _observacionesProcedimientoController.dispose();
    super.dispose();
  }

  String? _motivoIngresoKeyFromLabel(String? label) {
    switch ((label ?? '').trim()) {
      case 'Finalizar tratamiento':
        return 'finalizar_tratamiento';
      case 'clinica_heridas':
      case 'Clínica de heridas':
        return 'clinica_heridas';
      case 'programacion_procedimiento':
      case 'Programación de procedimiento':
        return 'programacion_procedimiento';
      default:
        return null;
    }
  }

  String _motivoIngresoLabelFromKey(String key) {
    switch (key.trim()) {
      case 'finalizar_tratamiento':
        return 'Finalizar tratamiento';
      case 'clinica_heridas':
        return 'Clínica de heridas';
      case 'programacion_procedimiento':
        return 'Programación de procedimiento';
      default:
        return key;
    }
  }

  List<String> _normalizeMotivosIngresoActivos(Iterable<String> values) {
    final Set<String> selected = values
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();

    return _motivoIngresoPadOptions
        .map(_motivoIngresoKeyFromLabel)
        .whereType<String>()
        .where(selected.contains)
        .toList();
  }

  void _toggleMotivoIngreso(String motivoKey, bool selected) {
    final List<String> next = List<String>.from(_motivosIngresoActivos);

    if (selected) {
      if (!next.contains(motivoKey)) {
        next.add(motivoKey);
      }
    } else {
      next.remove(motivoKey);
    }

    setState(() {
      _motivosIngresoActivos = _normalizeMotivosIngresoActivos(next);
      _motivosIngresoError = null;
    });
  }

  bool get _usaBarriosCartagena =>
      _municipioEsCartagena(_municipioController.text);

  bool _municipioEsCartagena(String value) {
    final String municipio = value.trim().toLowerCase();
    return municipio == 'cartagena de indias' || municipio == 'cartagena';
  }

  Future<void> _cargarCatalogosUbicacion() async {
    final List<String> municipios =
        await MunicipiosCatalogService.obtenerMunicipios(municipiosBolivar);
    if (!mounted) return;

    setState(() {
      _municipiosDisponibles = municipios;
    });

    await _cargarBarriosPorMunicipio(
      _municipioController.text,
      force: true,
    );
  }

  Future<void> _cargarBarriosPorMunicipio(
    String rawMunicipio, {
    bool force = false,
  }) async {
    final String municipio = _normalizeMunicipio(rawMunicipio);
    if (!force &&
        municipio.toLowerCase() == _municipioCatalogoActual.toLowerCase()) {
      return;
    }

    final List<String> barrios = await BarriosCatalogService.obtenerBarrios(
      _municipioEsCartagena(municipio)
          ? kBarriosCartagena
          : const <String>[],
      municipio: municipio,
    );
    if (!mounted) return;

    setState(() {
      _municipioCatalogoActual = municipio;
      _barriosDisponibles = barrios;
    });
  }

  void _onMunicipioChanged(String value) {
    final String municipio = _normalizeMunicipio(value);
    if (municipio.toLowerCase() != _municipioCatalogoActual.toLowerCase()) {
      _barrioController.clear();
    }
    setState(() {});
    _cargarBarriosPorMunicipio(value);
  }

  void _onNombreCompletoChanged(String value) {
    final String normalized = _toTitleCase(value);
    if (normalized == value) return;

    _nombreCompletoController.value = _nombreCompletoController.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }

  bool _horaDentroHorarioOperativo(TimeOfDay? value) {
    if (value == null) return false;
    final int totalMinutes = value.hour * 60 + value.minute;
    return totalMinutes >= 360 && totalMinutes <= 1320;
  }

  bool _isSameCalendarDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _shouldRecommendNextDayStart(DateTime? fechaSugerida) {
    if (fechaSugerida == null) return false;
    final DateTime now = DateTime.now();
    return _isSameCalendarDate(fechaSugerida, now) && now.hour > 14;
  }

  DateTime _nextDay(DateTime value) {
    final DateTime next = value.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day);
  }

  void _moveSuggestedVisitsToNextDay() {
    if (_shouldRecommendNextDayStart(_fechaPrimeraVisitaTratamiento) &&
        _fechaPrimeraVisitaTratamiento != null) {
      _fechaPrimeraVisitaTratamiento = _nextDay(
        _fechaPrimeraVisitaTratamiento!,
      );
      _syncTratamientoControllers();
    }
    if (_shouldRecommendNextDayStart(_fechaPrimeraCuracion) &&
        _fechaPrimeraCuracion != null) {
      _fechaPrimeraCuracion = _nextDay(_fechaPrimeraCuracion!);
      _syncHeridaControllers();
    }
  }

  Future<bool> _confirmOperationalSchedulingWarnings() async {
    final List<String> warnings = <String>[];
    final bool recomiendaMananaTratamiento =
        _motivosIngresoActivos.contains('finalizar_tratamiento') &&
        _shouldRecommendNextDayStart(_fechaPrimeraVisitaTratamiento);
    final bool recomiendaMananaHeridas =
        _motivosIngresoActivos.contains('clinica_heridas') &&
        _shouldRecommendNextDayStart(_fechaPrimeraCuracion);
    final bool recomiendaManana =
        recomiendaMananaTratamiento || recomiendaMananaHeridas;

    if (recomiendaManana) {
      warnings.add(
        'La fecha sugerida es hoy, pero ya pasó la hora operativa recomendada para iniciar programación. Se recomienda iniciar agenda desde mañana.',
      );
    }

    if (_motivosIngresoActivos.contains('finalizar_tratamiento') &&
        _frecuenciaTratamientoKey == 'Cada 6 horas') {
      warnings.add(
        'La frecuencia Cada 6 horas puede requerir horarios nocturnos fuera de la ventana PAD 06:00 a 22:00.',
      );
    }

    if (_motivosIngresoActivos.contains('programacion_procedimiento') &&
        _alertaPrequirurgica48h) {
      warnings.add(
        'Procedimiento dentro de 48 horas con laboratorios/estudios pendientes.',
      );
    }

    if (warnings.isEmpty) {
      return true;
    }

    final String? action = await showHextDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return HextModal(
          title: recomiendaManana
              ? 'Recomendación operativa'
              : 'Advertencia operativa',
          subtitle:
              'Validación previa antes de guardar el caso en la operación PAD.',
          onClose: () => Navigator.of(context).pop('cancel'),
          actions: <Widget>[
            HextButton.neutral(
              label: 'Cancelar',
              onPressed: () => Navigator.of(context).pop('cancel'),
            ),
            if (recomiendaManana)
              HextButton.secondary(
                label: 'Mover a mañana',
                onPressed: () => Navigator.of(context).pop('tomorrow'),
              ),
            HextButton.primary(
              label: recomiendaManana ? 'Continuar hoy' : 'Continuar',
              onPressed: () => Navigator.of(context).pop('continue'),
            ),
          ],
          child: Text(warnings.join('\n\n')),
        );
      },
    );

    if (action == 'tomorrow') {
      setState(_moveSuggestedVisitsToNextDay);
      return true;
    }

    return action == 'continue';
  }

  String? _frecuenciaTratamientoFromLabel(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    for (final String option in _frecuenciaTratamientoOptions) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    return null;
  }

  String? _frecuenciaCuracionFromLabel(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    for (final String option in _frecuenciaCuracionOptions) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    return null;
  }

  String _normalizeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  String? _detectAntibioticoCandidatoInfusor(String tratamiento) {
    final String normalized = _normalizeSearchText(tratamiento);
    if (normalized.isEmpty) return null;
    for (final String antibiotico in _antibioticosCandidatosInfusor) {
      if (normalized.contains(_normalizeSearchText(antibiotico))) {
        return antibiotico;
      }
    }
    return null;
  }

  bool get _isAntibioticoCandidatoInfusor =>
      _detectAntibioticoCandidatoInfusor(
        _tratamientoPendienteController.text,
      ) !=
      null;

  String? get _antibioticoDetectadoInfusor =>
      _detectAntibioticoCandidatoInfusor(_tratamientoPendienteController.text);

  String? _labelInfusor(String? value) {
    switch ((value ?? '').trim()) {
      case 'si':
        return 'Sí';
      case 'no':
        return 'No';
      case 'por_confirmar':
        return 'Por confirmar';
      default:
        return null;
    }
  }

  String? _laboratoriosPrequirurgicosLabel(String? value) {
    switch ((value ?? '').trim()) {
      case 'cargados_procesados':
        return 'Cargados y procesados';
      case 'pendientes_cargar':
        return 'Pendientes por cargar';
      case 'pendientes_procesar':
        return 'Pendientes por procesar';
      case 'no_aplica':
        return 'No aplica';
      default:
        return null;
    }
  }

  DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  bool get _procedimientoDentroDe48Horas {
    final DateTime? scheduled = _combineDateAndTime(
      _fechaProcedimiento,
      _horaProcedimiento,
    );
    if (scheduled == null) return false;
    final DateTime now = DateTime.now();
    final DateTime limit = now.add(const Duration(hours: 48));
    return !scheduled.isBefore(now) && !scheduled.isAfter(limit);
  }

  bool get _prequirurgicosPendientes =>
      _laboratoriosPrequirurgicosEstado == 'pendientes_cargar' ||
      _laboratoriosPrequirurgicosEstado == 'pendientes_procesar';

  bool get _alertaPrequirurgica48h =>
      _procedimientoDentroDe48Horas && _prequirurgicosPendientes;
  String _normalizeMunicipio(String value) {
    final String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return _municipioCartagena;
    if (cleaned.toLowerCase().contains('cartagena')) {
      return _municipioCartagena;
    }
    return _toTitleCase(cleaned);
  }

  String _motivoIngresoDisplayLabel(String key) {
    switch (key.trim()) {
      case 'finalizar_tratamiento':
        return 'Finalizar tratamiento';
      case 'clinica_heridas':
        return 'Cl\u00ednica de heridas';
      case 'programacion_procedimiento':
        return 'Programaci\u00f3n de procedimiento';
      default:
        return _motivoIngresoLabelFromKey(key);
    }
  }

  OrigenPaciente? _origenPacienteFromText(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final OrigenPaciente option in origenPacienteOptions) {
      if (origenPacienteLabel(option).toLowerCase() == normalized) {
        return option;
      }
    }

    return null;
  }

  Future<void> _bootstrapForm() async {
    final String patientId = (widget.candidatoId ?? '').trim();
    debugPrint(
      '[PacienteCaptacionForm._bootstrapForm] patientId recibido=$patientId',
    );

    final Map<String, dynamic>? inlineData = widget.initialData;
    if (inlineData != null && inlineData.isNotEmpty) {
      debugPrint(
        '[PacienteCaptacionForm._bootstrapForm] usando initialData para hidratar',
      );
      _hydrateFromData(inlineData);
      return;
    }

    if (!_isEditing) {
      return;
    }

    setState(() {
      _isHydrating = true;
    });

    try {
      final Map<String, dynamic>? data =
          await PadFirestoreService.obtenerCensoPaciente(patientId);
      debugPrint(
        '[PacienteCaptacionForm._bootstrapForm] documento encontrado=${data != null}',
      );
      debugPrint(
        '[PacienteCaptacionForm._bootstrapForm] payload leído desde Firestore=$data',
      );
      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró el episodio PAD.')),
          );
        }
        return;
      }
      _hydrateFromData(data);
    } catch (e) {
      debugPrint('[PacienteCaptacionForm._bootstrapForm] error=$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el episodio PAD.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHydrating = false;
        });
      } else {
        _isHydrating = false;
      }
    }
  }

  T? _readEnumValue<T>(
    List<T> values,
    String Function(T value) labelOf,
    List<dynamic> candidates,
  ) {
    for (final dynamic candidate in candidates) {
      final String raw = (candidate ?? '').toString().trim();
      if (raw.isEmpty) continue;

      for (final T value in values) {
        // Soporta enums Dart modernos, strings y objetos legacy
        String enumName;
        try {
          enumName = (value as dynamic).name;
        } catch (_) {
          enumName = value.toString().split('.').last;
        }
        if (enumName == raw) {
          return value;
        }
      }

      final T? byLabel = findEnumByLabel<T>(values, raw, labelOf);
      if (byLabel != null) {
        return byLabel;
      }
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic entryValue) =>
            MapEntry(key.toString(), entryValue),
      );
    }
    return <String, dynamic>{};
  }

  String _readTrimmed(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      final String value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  List<String> _splitListText(String raw) {
    return raw
        .split(RegExp(r'[\n,;]+'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
  }

  List<String> _readStringListCandidate(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      if (candidate is List) {
        final List<String> values = candidate
            .map((dynamic value) => value.toString().trim())
            .where((String value) => value.isNotEmpty)
            .toList();
        if (values.isNotEmpty) {
          return values;
        }
      }
      final String value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) {
        final List<String> parsed = _splitListText(value);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    }
    return <String>[];
  }

  bool _readBool(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      if (candidate is bool) return candidate;
      final String value = (candidate ?? '').toString().trim().toLowerCase();
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    return false;
  }

  DateTime? _readDateCandidate(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      final DateTime? parsed = _readDateTime(candidate);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  TimeOfDay? _readTimeCandidate(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      final TimeOfDay? parsed = _readTimeOfDay(candidate?.toString());
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  void _hydrateFromData(Map<String, dynamic> data) {
    final Map<String, dynamic> detalleMotivos = _asMap(data['detalleMotivos']);
    final Map<String, dynamic> finalizar = _asMap(
      detalleMotivos['finalizar_tratamiento'],
    );
    final Map<String, dynamic> finalizarDetalle = _asMap(
      finalizar['detalleMotivo'],
    );
    final Map<String, dynamic> heridas = _asMap(
      detalleMotivos['clinica_heridas'],
    );
    final Map<String, dynamic> heridasDetalle = _asMap(
      heridas['detalleMotivo'],
    );
    final Map<String, dynamic> procedimiento = _asMap(
      detalleMotivos['programacion_procedimiento'],
    );
    final Map<String, dynamic> procedimientoDetalle = _asMap(
      procedimiento['detalleMotivo'],
    );

    final List<String> motivosActivos = <String>[
      ...((data['motivosIngresoActivos'] as List?) ?? const <dynamic>[])
          .map(
            (dynamic value) =>
                _motivoIngresoKeyFromLabel(value.toString().trim()) ??
                value.toString().trim(),
          )
          .where((String value) => value.isNotEmpty),
      for (final MapEntry<String, dynamic> entry in detalleMotivos.entries)
        if (_asMap(entry.value)['activo'] == true) entry.key.trim(),
    ];

    _nombreCompletoController.text = _readTrimmed(<dynamic>[
      data['nombreCompleto'],
      data['nombre'],
    ]);
    _identificacionController.text = _readTrimmed(<dynamic>[
      data['identificacion'],
      data['documento'],
    ]);
    _edadController.text = _readTrimmed(<dynamic>[data['edad']]);
    _municipioController.text = _readTrimmed(<dynamic>[data['municipio']]);
    if (_municipioController.text.isEmpty) {
      _municipioController.text = _municipioCartagena;
    }
    _barrioController.text = _readTrimmed(<dynamic>[data['barrio']]);
    _aseguradoraController.text = _readTrimmed(<dynamic>[
      data['aseguradoraLabel'],
      data['aseguradora'],
    ]);
    _aseguradoraCatalogKey = _readTrimmed(<dynamic>[
      data['aseguradoraKey'],
      data['aseguradora'],
    ]);
    if ((_aseguradoraCatalogKey ?? '').isEmpty) {
      _aseguradoraCatalogKey = null;
    }
    _diagnosticoController.text = _readTrimmed(<dynamic>[
      data['diagnostico'],
      data['diagnosticos'],
    ]);
    _grupoRiesgoController.text = _readTrimmed(<dynamic>[
      data['grupoRelacionadoRiesgo'],
    ]);
    _observacionesController.text = _readTrimmed(<dynamic>[
      data['observaciones'],
    ]);
    _unidadFuncionalOrigenController.text = _readTrimmed(<dynamic>[
      data['unidadFuncionalOrigenLabel'],
      data['unidadFuncionalOrigen'],
      data['unidadFuncionalEgreso'],
    ]);

    _sexo = _readEnumValue<SexoPaciente>(
      SexoPaciente.values,
      sexoPacienteLabel,
      <dynamic>[data['sexoKey'], data['sexoLabel'], data['sexo']],
    );
    _tipoAseguramiento = _readEnumValue<TipoAseguramiento>(
      TipoAseguramiento.values,
      tipoAseguramientoLabel,
      <dynamic>[
        data['tipoAseguramientoKey'],
        data['tipoAseguramientoLabel'],
        data['tipoAseguramiento'],
      ],
    );
    _regimenAseguramiento = _readEnumValue<RegimenAseguramiento>(
      RegimenAseguramiento.values,
      regimenAseguramientoLabel,
      <dynamic>[
        data['regimenAseguramientoKey'],
        data['regimenAseguramientoLabel'],
        data['regimenAseguramiento'],
      ],
    );
    _tipoCaptacionPad = _readEnumValue<TipoCaptacionPad>(
      TipoCaptacionPad.values,
      tipoCaptacionPadLabel,
      <dynamic>[
        data['tipoCaptacionPadKey'],
        data['tipoCaptacionPadLabel'],
        data['tipoCaptacionPad'],
      ],
    );
    _especialidadPrincipalTratante =
        _readEnumValue<EspecialidadPrincipalTratante>(
          EspecialidadPrincipalTratante.values,
          especialidadPrincipalTratanteLabel,
          <dynamic>[
            data['especialidadKey'],
            data['especialidadLabel'],
            data['especialidadPrincipalTratante'],
          ],
        );
    _especialidadController.text = _especialidadPrincipalTratante == null
        ? _readTrimmed(<dynamic>[
            data['especialidadLabel'],
            data['especialidadPrincipalTratante'],
          ])
        : especialidadPrincipalTratanteLabel(_especialidadPrincipalTratante!);
    _decision = _readEnumValue<DecisionPad>(
      DecisionPad.values,
      decisionPadLabel,
      <dynamic>[
        data['resultadoPadKey'],
        data['resultadoPadLabel'],
        data['decision'],
      ],
    );

    _motivosIngresoActivos = _normalizeMotivosIngresoActivos(motivosActivos);
    _motivosIngresoError = null;

    _fechaVisita = _readDateCandidate(<dynamic>[data['fechaVisita']]);
    _horaVisita = _readTimeCandidate(<dynamic>[data['horaVisita']]);
    _syncVisitaControllers();

    _tratamientoPendienteController.text = _readTrimmed(<dynamic>[
      finalizar['tratamientoPrincipal'],
      finalizarDetalle['tratamientoPrincipal'],
      finalizar['tratamientoAFinalizar'],
      finalizarDetalle['tratamientoAFinalizar'],
    ]);
    _tratamientoComplementarioController.text = _readTrimmed(<dynamic>[
      finalizar['tratamientoComplementario'],
      finalizarDetalle['tratamientoComplementario'],
    ]);
    _frecuenciaTratamientoKey =
        _readTrimmed(<dynamic>[
          finalizar['frecuenciaTratamiento'],
          finalizarDetalle['frecuenciaTratamiento'],
          _frecuenciaTratamientoFromLabel(
            _readTrimmed(<dynamic>[
              finalizar['frecuenciaTratamientoLabel'],
              finalizarDetalle['frecuenciaTratamientoLabel'],
            ]),
          ),
        ]).isEmpty
        ? null
        : _readTrimmed(<dynamic>[
            finalizar['frecuenciaTratamiento'],
            finalizarDetalle['frecuenciaTratamiento'],
            _frecuenciaTratamientoFromLabel(
              _readTrimmed(<dynamic>[
                finalizar['frecuenciaTratamientoLabel'],
                finalizarDetalle['frecuenciaTratamientoLabel'],
              ]),
            ),
          ]);
    _frecuenciaPautaController.text = _readTrimmed(<dynamic>[
      finalizar['frecuenciaTratamientoLabel'],
      finalizarDetalle['frecuenciaTratamientoLabel'],
      _frecuenciaTratamientoKey,
    ]);
    _fechaFinTratamiento = _readDateCandidate(<dynamic>[
      finalizar['fechaProbableFinalizacion'],
      finalizarDetalle['fechaProbableFinalizacion'],
    ]);
    _fechaPrimeraVisitaTratamiento = _readDateCandidate(<dynamic>[
      finalizar['fechaSugeridaVisita'],
      finalizarDetalle['fechaSugeridaVisita'],
      finalizar['fechaVisita'],
      finalizar['fechaPrimeraVisita'],
    ]);
    _horaPrimeraVisitaTratamiento = _readTimeCandidate(<dynamic>[
      finalizar['horaSugeridaVisita'],
      finalizarDetalle['horaSugeridaVisita'],
      finalizar['horaVisita'],
      finalizar['horaPrimeraVisita'],
    ]);
    _observacionesTratamientoController.text = _readTrimmed(<dynamic>[
      finalizar['observaciones'],
      finalizarDetalle['observaciones'],
    ]);
    _pacienteCuentaConInfusor =
        _readTrimmed(<dynamic>[
          finalizar['pacienteCuentaConInfusor'],
          finalizarDetalle['pacienteCuentaConInfusor'],
        ]).isEmpty
        ? null
        : _readTrimmed(<dynamic>[
            finalizar['pacienteCuentaConInfusor'],
            finalizarDetalle['pacienteCuentaConInfusor'],
          ]);
    _syncTratamientoControllers();

    _tipoHeridaController.text = _readTrimmed(<dynamic>[
      heridas['tipoHerida'],
      heridasDetalle['tipoHerida'],
    ]);
    _ubicacionAnatomicaController.text = _readTrimmed(<dynamic>[
      heridas['ubicacionAnatomica'],
      heridasDetalle['ubicacionAnatomica'],
    ]);
    _frecuenciaCuracionKey =
        _readTrimmed(<dynamic>[
          heridas['frecuenciaCuracion'],
          heridasDetalle['frecuenciaCuracion'],
          _frecuenciaCuracionFromLabel(
            _readTrimmed(<dynamic>[
              heridas['frecuenciaCuracionLabel'],
              heridasDetalle['frecuenciaCuracionLabel'],
            ]),
          ),
        ]).isEmpty
        ? null
        : _readTrimmed(<dynamic>[
            heridas['frecuenciaCuracion'],
            heridasDetalle['frecuenciaCuracion'],
            _frecuenciaCuracionFromLabel(
              _readTrimmed(<dynamic>[
                heridas['frecuenciaCuracionLabel'],
                heridasDetalle['frecuenciaCuracionLabel'],
              ]),
            ),
          ]);
    _frecuenciaCuracionController.text = _readTrimmed(<dynamic>[
      heridas['frecuenciaCuracionLabel'],
      heridasDetalle['frecuenciaCuracionLabel'],
      _frecuenciaCuracionKey,
    ]);
    _fechaPrimeraCuracion = _readDateCandidate(<dynamic>[
      heridas['fechaSugeridaVisita'],
      heridasDetalle['fechaSugeridaVisita'],
      heridas['fechaVisita'],
      heridas['fechaPrimeraVisita'],
      heridas['fechaPrimeraCuracion'],
    ]);
    _horaPrimeraCuracion = _readTimeCandidate(<dynamic>[
      heridas['horaSugeridaVisita'],
      heridasDetalle['horaSugeridaVisita'],
      heridas['horaVisita'],
      heridas['horaPrimeraVisita'],
      heridas['horaPrimeraCuracion'],
    ]);
    _fechaProbableCierre = _readDateCandidate(<dynamic>[
      heridas['fechaProbableCierre'],
      heridasDetalle['fechaProbableCierre'],
    ]);
    _requiereInsumosController.text = _readTrimmed(<dynamic>[
      heridas['requiereInsumosEspeciales'],
      heridasDetalle['requiereInsumosEspeciales'],
    ]);
    _observacionesHeridaController.text = _readTrimmed(<dynamic>[
      heridas['observaciones'],
      heridasDetalle['observaciones'],
    ]);
    _syncHeridaControllers();

    _procedimientoRequeridoController.text = _readTrimmed(<dynamic>[
      procedimiento['procedimientoProgramado'],
      procedimiento['procedimientoRequerido'],
      procedimientoDetalle['procedimientoProgramado'],
    ]);
    _fechaProcedimiento = _readDateCandidate(<dynamic>[
      procedimiento['fechaVisita'],
      procedimiento['fechaProgramada'],
      procedimiento['fechaProcedimiento'],
      procedimientoDetalle['fechaProcedimiento'],
    ]);
    _horaProcedimiento = _readTimeCandidate(<dynamic>[
      procedimiento['horaVisita'],
      procedimiento['horaProgramada'],
      procedimiento['horaProcedimiento'],
      procedimientoDetalle['horaProcedimiento'],
    ]);
    _requiereAuxiliarEnfermeria = _readBool(<dynamic>[
      procedimiento['requierePreparacionPrevia'],
      procedimiento['requiereAuxiliarEnfermeria'],
      procedimientoDetalle['requierePreparacionPrevia'],
    ]);
    _lugarProcedimientoController.text = _readTrimmed(<dynamic>[
      procedimiento['lugarProcedimiento'],
      procedimientoDetalle['lugarProcedimiento'],
    ]);
    _requiereAnestesiologia = _readTrimmed(<dynamic>[
      procedimiento['requiereAnestesiologia'],
      procedimientoDetalle['requiereAnestesiologia'],
    ]);
    _laboratoriosPrequirurgicosEstado = _readTrimmed(<dynamic>[
      procedimiento['laboratoriosPrequirurgicosEstado'],
      procedimientoDetalle['laboratoriosPrequirurgicosEstado'],
    ]).isEmpty
        ? null
        : _readTrimmed(<dynamic>[
            procedimiento['laboratoriosPrequirurgicosEstado'],
            procedimientoDetalle['laboratoriosPrequirurgicosEstado'],
          ]);
    _anestesiologiaRealizada = _readTrimmed(<dynamic>[
      procedimiento['anestesiologiaRealizada'],
      procedimientoDetalle['anestesiologiaRealizada'],
    ]);
    _fechaValoracionAnestesiologia = _readDateCandidate(<dynamic>[
      procedimiento['fechaValoracionAnestesiologia'],
      procedimientoDetalle['fechaValoracionAnestesiologia'],
    ]);
    _observacionesAnestesiologiaController.text = _readTrimmed(<dynamic>[
      procedimiento['observacionesAnestesiologia'],
      procedimientoDetalle['observacionesAnestesiologia'],
    ]);
    _valoracionesRequeridasController.text = _readStringListCandidate(<dynamic>[
      procedimiento['valoracionesRequeridas'],
      procedimientoDetalle['valoracionesRequeridas'],
    ]).join(', ');
    _valoracionesPendientesController.text = _readStringListCandidate(<dynamic>[
      procedimiento['valoracionesPendientes'],
      procedimientoDetalle['valoracionesPendientes'],
    ]).join(', ');
    _observacionesProcedimientoController.text = _readTrimmed(<dynamic>[
      procedimiento['observaciones'],
      procedimientoDetalle['observaciones'],
    ]);
    _syncProcedimientoControllers();
    _syncAseguradoraFromStoredValue();

    debugPrint(
      '[PacienteCaptacionForm._hydrateFromData] nombreCompleto cargado=${_nombreCompletoController.text}',
    );
    debugPrint(
      '[PacienteCaptacionForm._hydrateFromData] identificacion cargada=${_identificacionController.text}',
    );
    debugPrint(
      '[PacienteCaptacionForm._hydrateFromData] aseguradora cargada=${_aseguradoraController.text}',
    );
    debugPrint(
      '[PacienteCaptacionForm._hydrateFromData] detalleMotivos cargado=$detalleMotivos',
    );
    debugPrint(
      '[PacienteCaptacionForm._hydrateFromData] motivos activos cargados=$_motivosIngresoActivos',
    );

    if (mounted) {
      setState(() {});
    }

    _cargarBarriosPorMunicipio(_municipioController.text, force: true);
    _cargarPendientes();
  }

  bool get _decisionPermiteAgendaPorMotivo =>
      _decision == DecisionPad.ingresoAprobado;

  bool _hasAgendaCompleta({
    required DateTime? fecha,
    required TimeOfDay? hora,
  }) {
    return fecha != null && hora != null;
  }

  Map<String, dynamic> _buildMotivoAgendaMetadata({
    required String motivoKey,
    required String motivoLabel,
    required DateTime? fechaVisita,
    required TimeOfDay? horaVisita,
  }) {
    return <String, dynamic>{
      'activo': true,
      'motivoKey': motivoKey,
      'motivoLabel': motivoLabel,
      'motivoAgenda': motivoLabel,
      'fechaVisita': fechaVisita,
      'horaVisita': _formatHoraVisita(horaVisita),
      'sourceType': 'paciente_pad',
      'estadoAgenda': 'programada',
      'disponibleParaAgenda':
          _decisionPermiteAgendaPorMotivo &&
          _hasAgendaCompleta(fecha: fechaVisita, hora: horaVisita),
    };
  }

  String? _validateMotivosProgramables() {
    if (_motivosIngresoActivos.isEmpty) {
      return 'Seleccione al menos un motivo programable.';
    }

    if (_motivosIngresoActivos.contains('finalizar_tratamiento')) {
      if (_tratamientoPendienteController.text.trim().isEmpty) {
        return 'Complete el tratamiento principal.';
      }
      if ((_frecuenciaTratamientoKey ?? '').trim().isEmpty) {
        return 'Seleccione la frecuencia del tratamiento.';
      }
      if (_fechaFinTratamiento == null) {
        return 'Complete la fecha probable de finalización.';
      }
      if (_fechaPrimeraVisitaTratamiento == null ||
          _horaPrimeraVisitaTratamiento == null) {
        return 'Finalizar tratamiento requiere fecha y hora sugerida de visita.';
      }
      if (_fechaFinTratamiento != null &&
          _fechaPrimeraVisitaTratamiento != null &&
          _fechaFinTratamiento!.isBefore(_fechaPrimeraVisitaTratamiento!)) {
        return 'La fecha de finalización no puede ser anterior a la primera visita.';
      }
      if (!_horaDentroHorarioOperativo(_horaPrimeraVisitaTratamiento)) {
        return 'La hora sugerida de visita debe estar entre 06:00 y 22:00.';
      }
    }

    if (_motivosIngresoActivos.contains('clinica_heridas')) {
      if (_tipoHeridaController.text.trim().isEmpty) {
        return 'Complete el tipo de herida.';
      }
      if (_ubicacionAnatomicaController.text.trim().isEmpty) {
        return 'Complete la ubicación anatómica.';
      }
      if (_frecuenciaCuracionController.text.trim().isEmpty) {
        return 'Complete la frecuencia de curación.';
      }
      if (_fechaPrimeraCuracion == null || _horaPrimeraCuracion == null) {
        return 'Clínica de heridas requiere fecha y hora de primera visita.';
      }
      if (!_horaDentroHorarioOperativo(_horaPrimeraCuracion)) {
        return 'La hora sugerida de visita debe estar entre 06:00 y 22:00.';
      }
    }

    if (_motivosIngresoActivos.contains('programacion_procedimiento')) {
      if (_procedimientoRequeridoController.text.trim().isEmpty) {
        return 'Complete el procedimiento programado.';
      }
      if (_fechaProcedimiento == null || _horaProcedimiento == null) {
        return 'Programación de procedimiento requiere fecha y hora.';
      }
      if (_procedimientoDentroDe48Horas) {
        if ((_laboratoriosPrequirurgicosEstado ?? '').isEmpty) {
          return 'Seleccione el estado de laboratorios/estudios prequirúrgicos.';
        }
      }
    }

    if (_decisionPermiteAgendaPorMotivo) {
      for (final String motivoKey in _motivosIngresoActivos) {
        switch (motivoKey) {
          case 'finalizar_tratamiento':
            if (!_hasAgendaCompleta(
              fecha: _fechaPrimeraVisitaTratamiento,
              hora: _horaPrimeraVisitaTratamiento,
            )) {
              return 'Complete fecha y hora de visita para Finalizar tratamiento.';
            }
            break;
          case 'clinica_heridas':
            if (!_hasAgendaCompleta(
              fecha: _fechaPrimeraCuracion,
              hora: _horaPrimeraCuracion,
            )) {
              return 'Complete fecha y hora de visita para Clínica de heridas.';
            }
            break;
          case 'programacion_procedimiento':
            if (!_hasAgendaCompleta(
              fecha: _fechaProcedimiento,
              hora: _horaProcedimiento,
            )) {
              return 'Complete fecha y hora de visita para Programación de procedimiento.';
            }
            break;
        }
      }
    }

    return null;
  }

  String _toTitleCase(String value) {
    final List<String> words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    return words
        .map((String word) {
          final String lower = word.toLowerCase();
          if (lower.length <= 1) {
            return lower.toUpperCase();
          }
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  Map<String, dynamic> _buildPayload() {
    final String municipio = _normalizeMunicipio(_municipioController.text);
    final String nombreCompleto = _toTitleCase(_nombreCompletoController.text);
    final String identificacion = _identificacionController.text.trim();
    final String barrio = _barrioController.text.trim();
    final String aseguradora = _aseguradoraController.text.trim();
    final String unidadFuncionalOrigen = _unidadFuncionalOrigenController.text
        .trim();
    final String diagnostico = DiagnosisTextFormatter.normalizeForStorage(
      _diagnosticoController.text.trim(),
    );
    final String grupoRelacionadoRiesgo = _grupoRiesgoController.text.trim();
    final String observaciones = _observacionesController.text.trim();
    final List<String> motivosActivos = _normalizeMotivosIngresoActivos(
      _motivosIngresoActivos,
    );
    final String? antibioticoDetectadoInfusor = _antibioticoDetectadoInfusor;
    final bool antibioticoCandidatoInfusor =
        antibioticoDetectadoInfusor != null &&
        antibioticoDetectadoInfusor.trim().isNotEmpty;
    final bool usaInfusor = _pacienteCuentaConInfusor == 'si';
    final String programacionSugeridaInfusor =
      antibioticoCandidatoInfusor && usaInfusor
        ? 'cambio_diario_infusor'
        : antibioticoCandidatoInfusor &&
              _pacienteCuentaConInfusor == 'por_confirmar'
        ? 'pendiente_confirmacion_infusor'
        : 'segun_frecuencia';
    final String? motivoPrincipalKey = motivosActivos.isEmpty
        ? null
        : motivosActivos.first;
    final String? motivoPrincipalLabel = motivoPrincipalKey == null
        ? null
        : _motivoIngresoDisplayLabel(motivoPrincipalKey);
    final Map<String, dynamic> detalleMotivos = <String, dynamic>{};

    // Finalizar tratamiento
    if (motivosActivos.contains('finalizar_tratamiento')) {
      final String motivoLabel = _motivoIngresoDisplayLabel(
        'finalizar_tratamiento',
      );
      detalleMotivos['finalizar_tratamiento'] = <String, dynamic>{
        ..._buildMotivoAgendaMetadata(
          motivoKey: 'finalizar_tratamiento',
          motivoLabel: motivoLabel,
          fechaVisita: _fechaPrimeraVisitaTratamiento,
          horaVisita: _horaPrimeraVisitaTratamiento,
        ),
        'detalleMotivo': <String, dynamic>{
          'tratamientoAFinalizar': _tratamientoPendienteController.text.trim(),
          'tratamientoPrincipal': _tratamientoPendienteController.text.trim(),
          'tratamientoComplementario': _tratamientoComplementarioController.text
              .trim(),
          'antibioticoCandidatoInfusor': antibioticoCandidatoInfusor,
          'antibioticoDetectado': antibioticoDetectadoInfusor,
          'requiereValidacionInfusor': antibioticoCandidatoInfusor,
          'pacienteCuentaConInfusor': _pacienteCuentaConInfusor,
          'usaInfusor': usaInfusor,
          'programacionSugerida': programacionSugeridaInfusor,
          'frecuenciaTratamiento': _frecuenciaTratamientoKey,
          'frecuenciaTratamientoLabel': _frecuenciaPautaController.text.trim(),
          'fechaSugeridaVisita': _fechaPrimeraVisitaTratamiento,
          'horaSugeridaVisita': _formatHoraVisita(
            _horaPrimeraVisitaTratamiento,
          ),
          'fechaProbableFinalizacion': _fechaFinTratamiento,
          'observaciones': _observacionesTratamientoController.text.trim(),
        },
        'tratamientoAFinalizar': _tratamientoPendienteController.text.trim(),
        'tratamientoPrincipal': _tratamientoPendienteController.text.trim(),
        'tratamientoComplementario': _tratamientoComplementarioController.text
            .trim(),
        'antibioticoCandidatoInfusor': antibioticoCandidatoInfusor,
        'antibioticoDetectado': antibioticoDetectadoInfusor,
        'requiereValidacionInfusor': antibioticoCandidatoInfusor,
        'pacienteCuentaConInfusor': _pacienteCuentaConInfusor,
        'usaInfusor': usaInfusor,
        'programacionSugerida': programacionSugeridaInfusor,
        'frecuenciaTratamiento': _frecuenciaTratamientoKey,
        'frecuenciaTratamientoLabel': _frecuenciaPautaController.text.trim(),
        'fechaSugeridaVisita': _fechaPrimeraVisitaTratamiento,
        'horaSugeridaVisita': _formatHoraVisita(_horaPrimeraVisitaTratamiento),
        'fechaProbableFinalizacion': _fechaFinTratamiento,
        'fechaPrimeraVisita': _fechaPrimeraVisitaTratamiento,
        'horaPrimeraVisita': _formatHoraVisita(_horaPrimeraVisitaTratamiento),
        'observaciones': _observacionesTratamientoController.text.trim(),
      };
    }

    // Clínica de heridas
    if (motivosActivos.contains('clinica_heridas')) {
      final String motivoLabel = _motivoIngresoDisplayLabel('clinica_heridas');
      detalleMotivos['clinica_heridas'] = <String, dynamic>{
        ..._buildMotivoAgendaMetadata(
          motivoKey: 'clinica_heridas',
          motivoLabel: motivoLabel,
          fechaVisita: _fechaPrimeraCuracion,
          horaVisita: _horaPrimeraCuracion,
        ),
        'detalleMotivo': <String, dynamic>{
          'tipoHerida': _tipoHeridaController.text.trim(),
          'ubicacionAnatomica': _ubicacionAnatomicaController.text.trim(),
          'frecuenciaCuracion': _frecuenciaCuracionKey,
          'frecuenciaCuracionLabel': _frecuenciaCuracionController.text.trim(),
          'fechaSugeridaVisita': _fechaPrimeraCuracion,
          'horaSugeridaVisita': _formatHoraVisita(_horaPrimeraCuracion),
          'requiereInsumosEspeciales': _requiereInsumosController.text.trim(),
          'observaciones': _observacionesHeridaController.text.trim(),
        },
        'tipoHerida': _tipoHeridaController.text.trim(),
        'ubicacionAnatomica': _ubicacionAnatomicaController.text.trim(),
        'frecuenciaCuracion': _frecuenciaCuracionKey,
        'frecuenciaCuracionLabel': _frecuenciaCuracionController.text.trim(),
        'fechaPrimeraCuracion': _fechaPrimeraCuracion,
        'horaPrimeraCuracion': _formatHoraVisita(_horaPrimeraCuracion),
        'fechaSugeridaVisita': _fechaPrimeraCuracion,
        'horaSugeridaVisita': _formatHoraVisita(_horaPrimeraCuracion),
        'fechaPrimeraVisita': _fechaPrimeraCuracion,
        'horaPrimeraVisita': _formatHoraVisita(_horaPrimeraCuracion),
        'fechaProbableCierre': _fechaProbableCierre,
        'requiereInsumosEspeciales': _requiereInsumosController.text.trim(),
        'observaciones': _observacionesHeridaController.text.trim(),
      };
    }

    // Programación de procedimiento
    if (motivosActivos.contains('programacion_procedimiento')) {
      final String motivoLabel = _motivoIngresoDisplayLabel(
        'programacion_procedimiento',
      );
      final String? laboratoriosPrequirurgicosLabel =
          _laboratoriosPrequirurgicosLabel(_laboratoriosPrequirurgicosEstado);
      detalleMotivos['programacion_procedimiento'] = <String, dynamic>{
        ..._buildMotivoAgendaMetadata(
          motivoKey: 'programacion_procedimiento',
          motivoLabel: motivoLabel,
          fechaVisita: _fechaProcedimiento,
          horaVisita: _horaProcedimiento,
        ),
        'detalleMotivo': <String, dynamic>{
          'activo': true,
          'estado': 'pendiente',
          'nombreProcedimiento': _procedimientoRequeridoController.text.trim(),
          'procedimientoProgramado': _procedimientoRequeridoController.text
              .trim(),
          'fechaProcedimiento': _fechaProcedimiento,
          'horaProcedimiento': _formatHoraVisita(_horaProcedimiento),
          'fechaProgramada': _fechaProcedimiento,
          'horaProgramada': _formatHoraVisita(_horaProcedimiento),
          'requiereAnestesiologia': _requiereAnestesiologia,
            'laboratoriosPrequirurgicosEstado':
              _laboratoriosPrequirurgicosEstado,
            'laboratoriosPrequirurgicosLabel': laboratoriosPrequirurgicosLabel,
            'alertaPrequirurgica48h': _alertaPrequirurgica48h,
          'anestesiologiaRealizada': _anestesiologiaRealizada,
          'fechaValoracionAnestesiologia': _fechaValoracionAnestesiologia,
          'observacionesAnestesiologia': _observacionesAnestesiologiaController
              .text
              .trim(),
          'valoracionesRequeridas': _splitListText(
            _valoracionesRequeridasController.text,
          ),
          'valoracionesPendientes': _splitListText(
            _valoracionesPendientesController.text,
          ),
          'requierePreparacionPrevia': _requiereAuxiliarEnfermeria ?? false,
          'observaciones': _observacionesProcedimientoController.text.trim(),
        },
        'activo': true,
        'estado': 'pendiente',
        'nombreProcedimiento': _procedimientoRequeridoController.text.trim(),
        'procedimientoProgramado': _procedimientoRequeridoController.text
            .trim(),
        'procedimientoRequerido': _procedimientoRequeridoController.text.trim(),
        'fechaProcedimiento': _fechaProcedimiento,
        'horaProcedimiento': _formatHoraVisita(_horaProcedimiento),
        'fechaProgramada': _fechaProcedimiento,
        'horaProgramada': _formatHoraVisita(_horaProcedimiento),
        'requiereAnestesiologia': _requiereAnestesiologia,
        'laboratoriosPrequirurgicosEstado': _laboratoriosPrequirurgicosEstado,
        'laboratoriosPrequirurgicosLabel': laboratoriosPrequirurgicosLabel,
        'alertaPrequirurgica48h': _alertaPrequirurgica48h,
        'anestesiologiaRealizada': _anestesiologiaRealizada,
        'fechaValoracionAnestesiologia': _fechaValoracionAnestesiologia,
        'observacionesAnestesiologia': _observacionesAnestesiologiaController
            .text
            .trim(),
        'valoracionesRequeridas': _splitListText(
          _valoracionesRequeridasController.text,
        ),
        'valoracionesPendientes': _splitListText(
          _valoracionesPendientesController.text,
        ),
        'requiereAuxiliarEnfermeria': _requiereAuxiliarEnfermeria ?? false,
        'requierePreparacionPrevia': _requiereAuxiliarEnfermeria ?? false,
        'lugarProcedimiento': _lugarProcedimientoController.text.trim(),
        'observaciones': _observacionesProcedimientoController.text.trim(),
      };
    }

    return <String, dynamic>{
      'nombreCompleto': nombreCompleto,
      'identificacion': identificacion,
      'sexo': _sexo?.name,
      'sexoKey': _sexo?.name,
      'sexoLabel': _sexo == null ? null : sexoPacienteLabel(_sexo!),
      'edad': int.tryParse(_edadController.text.trim()),
      'municipio': municipio,
      'barrio': barrio,
      'tipoAseguramiento': _tipoAseguramiento?.name,
      'tipoAseguramientoKey': _tipoAseguramiento?.name,
      'tipoAseguramientoLabel': _tipoAseguramiento == null
          ? null
          : tipoAseguramientoLabel(_tipoAseguramiento!),
      'aseguradora': aseguradora,
      'aseguradoraKey': (_aseguradoraCatalogKey ?? aseguradora).trim().isEmpty
          ? null
          : (_aseguradoraCatalogKey ?? aseguradora).trim(),
      'aseguradoraLabel': aseguradora.isEmpty ? null : aseguradora,
      'regimenAseguramiento': _regimenAseguramiento?.name,
      'regimenAseguramientoKey': _regimenAseguramiento?.name,
      'regimenAseguramientoLabel': _regimenAseguramiento == null
          ? null
          : regimenAseguramientoLabel(_regimenAseguramiento!),
      'tipoCaptacionPad': _tipoCaptacionPad?.name,
      'tipoCaptacionPadKey': _tipoCaptacionPad?.name,
      'tipoCaptacionPadLabel': _tipoCaptacionPad == null
          ? null
          : tipoCaptacionPadLabel(_tipoCaptacionPad!),
      'unidadFuncionalEgreso': unidadFuncionalOrigen,
      'unidadFuncionalOrigen': unidadFuncionalOrigen,
      'unidadFuncionalOrigenKey': unidadFuncionalOrigen.isEmpty
          ? null
          : unidadFuncionalOrigen,
      'unidadFuncionalOrigenLabel': unidadFuncionalOrigen.isEmpty
          ? null
          : unidadFuncionalOrigen,
      'especialidadPrincipalTratante': _especialidadPrincipalTratante?.name,
      'especialidadKey': _especialidadPrincipalTratante?.name,
      'especialidadLabel': _especialidadPrincipalTratante == null
          ? null
          : especialidadPrincipalTratanteLabel(_especialidadPrincipalTratante!),
      'diagnostico': diagnostico,
      'diagnosticos': diagnostico,
      'grupoRelacionadoRiesgo': grupoRelacionadoRiesgo,
      'decision': _decision?.name,
      'resultadoPadKey': _decision?.name,
      'resultadoPadLabel': _decision == null
          ? null
          : decisionPadLabel(_decision!),
      'situacionAsistencialLabel': _caseStatusLabel(),
      'motivoIngresoPad': motivoPrincipalLabel,
      'motivoIngresoPrincipal': motivoPrincipalKey,
      'motivosIngresoActivos': motivosActivos,
      'detalleMotivos': detalleMotivos,
      'observaciones': observaciones,
      'fechaVisita': _fechaVisita,
      'horaVisita': _formatHoraVisita(_horaVisita),
    };
  }

  Future<void> _guardar() async {
    if (_isHydrating) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? motivosError = _validateMotivosProgramables();
    if (motivosError != null) {
      setState(() {
        _motivosIngresoError = motivosError;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(motivosError)));
      return;
    }

    final bool confirmedWarnings =
        await _confirmOperationalSchedulingWarnings();
    if (!confirmedWarnings) return;

    _municipioController.text = _normalizeMunicipio(_municipioController.text);
    await MunicipiosCatalogService.guardarMunicipio(
      _municipioController.text,
      semilla: municipiosBolivar,
    );
    _barrioController.text = _barrioController.text.trim();
    await BarriosCatalogService.guardarBarrio(
      _barrioController.text,
      municipio: _municipioController.text.trim(),
      semilla: _usaBarriosCartagena ? kBarriosCartagena : const <String>[],
    );
    if (_barrioController.text.isNotEmpty &&
        !_barriosDisponibles.any(
          (String option) =>
              option.toLowerCase() == _barrioController.text.toLowerCase(),
        )) {
      setState(() {
        _barriosDisponibles = <String>[
          ..._barriosDisponibles,
          _barrioController.text,
        ];
      });
    }

    final Map<String, dynamic> data = _buildPayload();
    debugPrint(
      '[PacienteCaptacionForm._guardar] unidadFuncionalOrigen=${data['unidadFuncionalOrigen']} motivoIngresoPad=${data['motivoIngresoPad']} fechaVisita=${data['fechaVisita']} horaVisita=${data['horaVisita']}',
    );
    debugPrint(
      '[PacienteCaptacionForm._guardar] nombreCompleto=${data['nombreCompleto']} identificacion=${data['identificacion']} tipoAseguramiento=${data['tipoAseguramiento']} regimenAseguramiento=${data['regimenAseguramiento']} aseguradora=${data['aseguradora']} aseguradoraLabel=${data['aseguradoraLabel']} decision=${data['decision']} detalleMotivos=${data['detalleMotivos']}',
    );
    debugPrint('[PacienteCaptacionForm._guardar] modo edición=$_isEditing');

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guardado exitoso.')));

      context.go('/cases');
    } catch (e) {
      debugPrint('Error al guardar candidato PAD: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el candidato PAD.')),
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

  void _syncVisitaControllers() {
    _fechaVisitaController.text = _fechaVisita == null
        ? ''
        : _formatFechaVisita(_fechaVisita!);
    _horaVisitaController.text = _formatHoraVisita(_horaVisita) ?? '';
  }

  void _syncTratamientoControllers() {
    _fechaInicioTratamientoController.text = _fechaInicioTratamiento == null
        ? ''
        : _formatFechaVisita(_fechaInicioTratamiento!);
    _fechaPrimeraVisitaTratamientoController.text =
        _fechaPrimeraVisitaTratamiento == null
        ? ''
        : _formatFechaVisita(_fechaPrimeraVisitaTratamiento!);
    _horaPrimeraVisitaTratamientoController.text =
        _formatHoraVisita(_horaPrimeraVisitaTratamiento) ?? '';
    _fechaFinTratamientoController.text = _fechaFinTratamiento == null
        ? ''
        : _formatFechaVisita(_fechaFinTratamiento!);
  }

  void _syncHeridaControllers() {
    _fechaPrimeraCuracionController.text = _fechaPrimeraCuracion == null
        ? ''
        : _formatFechaVisita(_fechaPrimeraCuracion!);
    _horaPrimeraCuracionController.text =
        _formatHoraVisita(_horaPrimeraCuracion) ?? '';
    _fechaProbableCierreController.text = _fechaProbableCierre == null
        ? ''
        : _formatFechaVisita(_fechaProbableCierre!);
  }

  void _syncProcedimientoControllers() {
    _fechaProcedimientoController.text = _fechaProcedimiento == null
        ? ''
        : _formatFechaVisita(_fechaProcedimiento!);
    _horaProcedimientoController.text =
        _formatHoraVisita(_horaProcedimiento) ?? '';
    _fechaValoracionAnestesiologiaController.text =
        _fechaValoracionAnestesiologia == null
        ? ''
        : _formatFechaVisita(_fechaValoracionAnestesiologia!);
  }

  Future<void> _pickFechaGenerica({
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = currentValue ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickHoraGenerica({
    required TimeOfDay? currentValue,
    required ValueChanged<TimeOfDay?> onPicked,
  }) async {
    final TimeOfDay fallbackNow = TimeOfDay.now();
    final TimeOfDay initialTime = TimeOfDay(
      hour: (currentValue ?? fallbackNow).hour,
      minute: 0,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return;
    onPicked(TimeOfDay(hour: picked.hour, minute: 0));
  }

  String _formatFechaVisita(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String? _formatHoraVisita(TimeOfDay? value) {
    if (value == null) return null;
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final String normalized = value.trim();
      if (normalized.isEmpty) return null;
      final DateTime? isoValue = DateTime.tryParse(normalized);
      if (isoValue != null) return isoValue;
      final List<String> parts = normalized.split('/');
      if (parts.length == 3) {
        final int? day = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        final int? year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  TimeOfDay? _readTimeOfDay(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    final List<String> parts = normalized.split(':');
    if (parts.length < 2) return null;
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
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

  String _caseStatusLabel() {
    if (_decision == DecisionPad.ingresoAprobado) {
      return 'Activo en PAD';
    }
    if (_decision == DecisionPad.ingresoNoAprobado) {
      return 'No aprobado';
    }
    if (_decision == DecisionPad.requiereNuevaValoracion) {
      return 'Requiere nueva valoración';
    }
    return 'En valoración';
  }

  Widget _buildAseguradoraField() {
    if (_tipoAseguramiento == TipoAseguramiento.particular) {
      return PadTextInput(
        controller: _aseguradoraController,
        label: 'Aseguradora',
        readOnly: true,
      );
    }

    if (_tipoAseguramiento == TipoAseguramiento.otro) {
      return PadTextInput(
        controller: _aseguradoraController,
        label: 'Aseguradora',
        hint: 'Especificar entidad',
      );
    }

    final List<dynamic> options = aseguradorasPorTipo(
      catalogTipoFromAseguramiento(_tipoAseguramiento),
    );

    if (options.isEmpty) {
      return PadTextInput(
        controller: _aseguradoraController,
        label: 'Aseguradora',
        enabled: false,
      );
    }

    final bool selectedExists = options.any(
      (dynamic option) => option.value == _aseguradoraCatalogKey,
    );

    return PadSelectInput<String>(
      value: selectedExists ? _aseguradoraCatalogKey : null,
      label: 'Aseguradora',
      dropdownItems: options.map<DropdownMenuItem<String>>((dynamic option) {
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

  EspecialidadPrincipalTratante? _especialidadFromText(String value) {
    final String normalized = value.trim().toLowerCase();

    for (final EspecialidadPrincipalTratante option
        in EspecialidadPrincipalTratante.values) {
      if (especialidadPrincipalTratanteLabel(option).toLowerCase() ==
          normalized) {
        return option;
      }
    }

    return null;
  }

  Widget _buildMotivosProgramablesSection() {
    return _simpleSectionCard(
      title: 'Motivos PAD programables',
      children: <Widget>[
        Text(
          'Seleccione uno o varios motivos. Cada motivo puede programarse de forma independiente.',
          style: PadFormTextStyles.textoAuxiliar,
        ),
        const SizedBox(height: PadFormMetrics.gap),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: PadFormMetrics.gap,
          runSpacing: PadFormMetrics.gap,
          children: _motivoIngresoPadOptions.map((String option) {
            final String motivoKey = _motivoIngresoKeyFromLabel(option)!;
            final bool selected = _motivosIngresoActivos.contains(motivoKey);
            return PadSelectableChip(
              label: option,
              selected: selected,
              onSelected: (bool value) => _toggleMotivoIngreso(motivoKey, value),
            );
          }).toList(),
        ),
        if (_motivosIngresoError != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_motivosIngresoError!, style: PadFormTextStyles.error),
        ],
        if (_motivosIngresoActivos.contains(
          'finalizar_tratamiento',
        )) ...<Widget>[
          const SizedBox(height: PadFormMetrics.gapSeccion),
          _buildMotivoBlock(
            title: 'Finalizar tratamiento',
            children: <Widget>[
              PadFormGrid(
                alignment: WrapAlignment.center,
                children: <PadFormGridItem>[
                  _gridItem(
                    PadTextInput(
                  controller: _tratamientoPendienteController,
                  label: 'Tratamiento principal',
                  onChanged: (String value) {
                    final bool candidato =
                        _detectAntibioticoCandidatoInfusor(value) != null;
                    setState(() {
                      if (!candidato) {
                        _pacienteCuentaConInfusor = null;
                      }
                    });
                  },
                    ),
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _tratamientoComplementarioController,
                      label: 'Tratamiento complementario opcional',
                      hint: 'Opcional',
                    ),
                  ),
                  _gridItem(
                    PadSelectInput<String>(
                      label: 'Frecuencia del tratamiento',
                      value: _frecuenciaTratamientoKey,
                      dropdownItems: _frecuenciaTratamientoOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _frecuenciaTratamientoKey = value;
                          _frecuenciaPautaController.text = value ?? '';
                        });
                      },
                      validator: (String? value) =>
                          value == null || value.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                  ),
                  if (_isAntibioticoCandidatoInfusor)
                    _gridItem(
                      PadSelectInput<String>(
                        label: '¿Paciente cuenta con infusor?',
                        value: _pacienteCuentaConInfusor,
                        dropdownItems: _infusorOptions
                            .map(
                              (String option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(_labelInfusor(option) ?? option),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _pacienteCuentaConInfusor = value;
                          });
                        },
                      ),
                    ),
                  _gridItem(
                    PadDateInput(
                      controller: _fechaFinTratamientoController,
                      label: 'Fecha probable de finalización',
                      onTap: () => _pickFechaGenerica(
                        currentValue: _fechaFinTratamiento,
                        onPicked: (DateTime? value) {
                          setState(() {
                            _fechaFinTratamiento = value;
                            _syncTratamientoControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadTimeInput(
                      controller: _horaPrimeraVisitaTratamientoController,
                      label: 'Hora sugerida de visita',
                      onTap: () => _pickHoraGenerica(
                        currentValue: _horaPrimeraVisitaTratamiento,
                        onPicked: (TimeOfDay? value) {
                          setState(() {
                            _horaPrimeraVisitaTratamiento = value;
                            _syncTratamientoControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadDateInput(
                      controller: _fechaPrimeraVisitaTratamientoController,
                      label: 'Fecha sugerida de visita',
                      onTap: () => _pickFechaGenerica(
                        currentValue: _fechaPrimeraVisitaTratamiento,
                        onPicked: (DateTime? value) {
                          setState(() {
                            _fechaPrimeraVisitaTratamiento = value;
                            _syncTratamientoControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _observacionesTratamientoController,
                      label: 'Observaciones',
                    ),
                    span: 2,
                  ),
                ],
              ),
              if (_isAntibioticoCandidatoInfusor) ...<Widget>[
                const SizedBox(height: PadFormMetrics.gapSeccion),
                Text(
                  'Tratamiento candidato a manejo con infusor. Si el paciente cuenta con infusor y el esquema está validado, programar una visita diaria para cambio de tratamiento/infusor.',
                  style: PadFormTextStyles.textoAuxiliar,
                ),
              ],
            ],
          ),
        ],
        if (_motivosIngresoActivos.contains('clinica_heridas')) ...<Widget>[
          const SizedBox(height: PadFormMetrics.gapSeccion),
          _buildMotivoBlock(
            title: 'Clínica de heridas',
            children: <Widget>[
              PadFormGrid(
                alignment: WrapAlignment.center,
                children: <PadFormGridItem>[
                  _gridItem(
                    PadTextInput(
                  controller: _tipoHeridaController,
                  label: 'Tipo de herida',
                    ),
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _ubicacionAnatomicaController,
                      label: 'Ubicación anatómica',
                    ),
                  ),
                  _gridItem(
                    PadDateInput(
                      controller: _fechaPrimeraCuracionController,
                      label: 'Fecha de primera visita',
                      onTap: () => _pickFechaGenerica(
                        currentValue: _fechaPrimeraCuracion,
                        onPicked: (DateTime? value) {
                          setState(() {
                            _fechaPrimeraCuracion = value;
                            _syncHeridaControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadTimeInput(
                      controller: _horaPrimeraCuracionController,
                      label: 'Hora de primera visita',
                      onTap: () => _pickHoraGenerica(
                        currentValue: _horaPrimeraCuracion,
                        onPicked: (TimeOfDay? value) {
                          setState(() {
                            _horaPrimeraCuracion = value;
                            _syncHeridaControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _requiereInsumosController,
                      label: 'Requiere insumos especiales',
                    ),
                  ),
                  _gridItem(
                    PadSelectInput<String>(
                      label: 'Frecuencia de curación',
                      value: _frecuenciaCuracionKey,
                      dropdownItems: _frecuenciaCuracionOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _frecuenciaCuracionKey = value;
                          _frecuenciaCuracionController.text = value ?? '';
                        });
                      },
                      validator: (String? value) =>
                          value == null || value.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _observacionesHeridaController,
                      label: 'Observaciones',
                    ),
                    span: 2,
                  ),
                ],
              ),
            ],
          ),
        ],
        if (_motivosIngresoActivos.contains(
          'programacion_procedimiento',
        )) ...<Widget>[
          const SizedBox(height: PadFormMetrics.gapSeccion),
          _buildMotivoBlock(
            title: 'Programación de procedimiento',
            children: <Widget>[
              PadFormGrid(
                alignment: WrapAlignment.start,
                children: <PadFormGridItem>[
                  _gridItem(
                    PadTextInput(
                      controller: _procedimientoRequeridoController,
                      label: 'Procedimiento programado',
                    ),
                    span: 2,
                  ),
                  _gridItem(
                    PadDateInput(
                      controller: _fechaProcedimientoController,
                      label: 'Fecha del procedimiento',
                      onTap: () => _pickFechaGenerica(
                        currentValue: _fechaProcedimiento,
                        onPicked: (DateTime? value) {
                          setState(() {
                            _fechaProcedimiento = value;
                            _syncProcedimientoControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadTimeInput(
                      controller: _horaProcedimientoController,
                      label: 'Hora del procedimiento',
                      onTap: () => _pickHoraGenerica(
                        currentValue: _horaProcedimiento,
                        onPicked: (TimeOfDay? value) {
                          setState(() {
                            _horaProcedimiento = value;
                            _syncProcedimientoControllers();
                          });
                        },
                      ),
                    ),
                  ),
                  _gridItem(
                    PadSelectInput<String>(
                      label: 'Requiere anestesiologia',
                      value: _requiereAnestesiologia,
                      dropdownItems: _requiereAnestesiologiaOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _requiereAnestesiologia = value;
                        });
                      },
                    ),
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _valoracionesPendientesController,
                      label: 'Otras valoraciones pendientes',
                      hint: 'Ej: anestesiologia, laboratorio prequirurgico',
                    ),
                    span: 2,
                  ),
                  _gridItem(
                    PadTextInput(
                      controller: _observacionesProcedimientoController,
                      label: 'Observaciones',
                    ),
                    span: 1,
                  ),
                ],
              ),
              const SizedBox(height: PadFormMetrics.gap),
              PadFormGrid(
                alignment: WrapAlignment.start,
                children: <PadFormGridItem>[
                  _gridItem(
                    PadSelectInput<String>(
                      label: 'Laboratorios/estudios prequirúrgicos',
                      value: _laboratoriosPrequirurgicosEstado,
                      dropdownItems: _laboratoriosPrequirurgicosOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                _laboratoriosPrequirurgicosLabel(option) ??
                                    option,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _laboratoriosPrequirurgicosEstado = value;
                        });
                      },
                      validator: (String? value) {
                        if (_procedimientoDentroDe48Horas &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Campo obligatorio';
                        }
                        return null;
                      },
                    ),
                    span: 2,
                  ),
                ],
              ),
              if (_alertaPrequirurgica48h) ...<Widget>[
                const SizedBox(height: PadFormMetrics.labelGap),
                Text(
                  'Procedimiento dentro de 48 horas con laboratorios/estudios pendientes.',
                  style: PadFormTextStyles.error,
                ),
              ],
              if (_requiereAnestesiologia == 'si') ...<Widget>[
                const SizedBox(height: PadFormMetrics.gap),
                PadFormGrid(
                  alignment: WrapAlignment.start,
                  children: <PadFormGridItem>[
                    _gridItem(
                      PadSelectInput<String>(
                        label: 'Estado de anestesiologia',
                        value:
                            _anestesiologiaRealizada == 'si' ||
                                _anestesiologiaRealizada == 'no'
                            ? _anestesiologiaRealizada
                            : null,
                        dropdownItems: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'no',
                            child: Text('Pendiente'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'si',
                            child: Text('Realizada'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _anestesiologiaRealizada = value;
                          });
                        },
                      ),
                    ),
                    if (_anestesiologiaRealizada == 'si')
                      _gridItem(
                        PadDateInput(
                          controller: _fechaValoracionAnestesiologiaController,
                          label: 'Fecha valoracion anestesiologia',
                          onTap: () => _pickFechaGenerica(
                            currentValue: _fechaValoracionAnestesiologia,
                            onPicked: (DateTime? value) {
                              setState(() {
                                _fechaValoracionAnestesiologia = value;
                                _syncProcedimientoControllers();
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMotivoBlock({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PadFormMetrics.paddingSubtarjeta),
      decoration: BoxDecoration(
        color: PadFormColors.blanco,
        borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
        border: Border.all(color: PadFormColors.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: PadFormTextStyles.tituloSubseccion),
          const SizedBox(height: PadFormMetrics.gap),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEstadoCasoSection() {
    return _simpleSectionCard(
      title: 'Estado del caso',
      trailing: PadStatusBadge(label: _caseStatusLabel()),
      children: <Widget>[
        Text(
          'Seguimiento operativo y alertas activas del episodio PAD.',
          style: PadFormTextStyles.textoAuxiliar,
        ),
        if (_pendientesCargando) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Verificando pendientes...',
                style: PadFormTextStyles.textoAuxiliar,
              ),
            ],
          ),
        ],
        if (_pendientes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: PadFormColors.fondoAdvertencia,
              borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
              border: Border.all(color: PadFormColors.bordeSuave),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.warning_amber_rounded,
                      color: PadFormColors.textoAdvertencia,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pendientes activos',
                      style: HextTextStyles.tablePrimary.copyWith(
                        color: PadFormColors.textoAdvertencia,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ..._pendientes.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $p',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (!_pendientesCargando) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Sin pendientes operativos activos.',
            style: PadFormTextStyles.textoAuxiliar,
          ),
        ],
      ],
    );
  }

  Widget _buildDatosBasicosSectionNew() {
    return _simpleSectionCard(
      title: 'Datos básicos',
      children: <Widget>[
        PadFormGrid(
          children: <PadFormGridItem>[
            _gridItem(
              PadTextInput(
                controller: _nombreCompletoController,
                label: 'Nombre completo',
                onChanged: _onNombreCompletoChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
            ),
            _gridItem(
              PadTextInput(
                controller: _identificacionController,
                label: 'Identificación',
                keyboardType: TextInputType.number,
              ),
            ),
            _gridItem(
              PadTextInput(
                controller: _edadController,
                label: 'Edad',
                keyboardType: TextInputType.number,
              ),
            ),
            _gridItem(
              PadSelectInput<SexoPaciente>(
                label: 'Sexo',
                value: _sexo,
                dropdownItems: SexoPaciente.values
                    .map(
                      (e) => DropdownMenuItem<SexoPaciente>(
                        value: e,
                        child: Text(sexoPacienteLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _sexo = v),
              ),
            ),
            _gridItem(
              PadAutocompleteInput(
                sourceController: _municipioController,
                label: 'Municipio',
                options: _municipiosDisponibles,
                onChanged: _onMunicipioChanged,
              ),
              span: 2,
            ),
            _gridItem(
              PadAutocompleteInput(
                sourceController: _barrioController,
                label: 'Barrio',
                options: _barriosDisponibles,
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Campo obligatorio'
                    : null,
              ),
              span: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAseguramientoSectionNew() {
    return _simpleSectionCard(
      title: 'Aseguramiento',
      children: <Widget>[
        PadFormGrid(
          children: <PadFormGridItem>[
            _gridItem(
              PadSelectInput<TipoAseguramiento>(
                label: 'Tipo de aseguramiento',
                value: _tipoAseguramiento,
                dropdownItems: TipoAseguramiento.values
                    .map(
                      (e) => DropdownMenuItem<TipoAseguramiento>(
                        value: e,
                        child: Text(tipoAseguramientoLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _onTipoAseguramientoChanged(v)),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
            ),
            _gridItem(
              PadSelectInput<RegimenAseguramiento>(
                label: 'Régimen',
                value: _regimenAseguramiento,
                dropdownItems: RegimenAseguramiento.values
                    .map(
                      (e) => DropdownMenuItem<RegimenAseguramiento>(
                        value: e,
                        child: Text(regimenAseguramientoLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _regimenAseguramiento = v),
              ),
            ),
            _gridItem(_buildAseguradoraField(), span: 2),
          ],
        ),
      ],
    );
  }

  Widget _buildCaptacionSectionNew() {
    return _simpleSectionCard(
      title: 'Captación PAD',
      children: <Widget>[
        PadFormGrid(
          children: <PadFormGridItem>[
            _gridItem(
              PadSelectInput<TipoCaptacionPad>(
                label: 'Tipo de captación PAD',
                value: _tipoCaptacionPad,
                dropdownItems: TipoCaptacionPad.values
                    .map(
                      (e) => DropdownMenuItem<TipoCaptacionPad>(
                        value: e,
                        child: Text(tipoCaptacionPadLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipoCaptacionPad = v),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
              span: 2,
            ),
            _gridItem(
              PadSelectInput<OrigenPaciente>(
                label: 'Unidad funcional origen',
                value: _origenPacienteFromText(
                  _unidadFuncionalOrigenController.text,
                ),
                dropdownItems: origenPacienteOptions
                    .map(
                      (OrigenPaciente option) => DropdownMenuItem<OrigenPaciente>(
                        value: option,
                        child: Text(origenPacienteLabel(option)),
                      ),
                    )
                    .toList(),
                onChanged: (OrigenPaciente? value) {
                  setState(() {
                    _unidadFuncionalOrigenController.text = value == null
                        ? ''
                        : origenPacienteLabel(value);
                  });
                },
              ),
              span: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextoClinicoSectionNew() {
    return _simpleSectionCard(
      title: 'Contexto clínico',
      children: <Widget>[
        PadFormGrid(
          children: <PadFormGridItem>[
            _gridItem(
              PadAutocompleteInput(
                sourceController: _especialidadController,
                label: 'Especialidad principal tratante',
                options: EspecialidadPrincipalTratante.values
                    .map(especialidadPrincipalTratanteLabel)
                    .toList(),
                onChanged: (String value) {
                  setState(() {
                    _especialidadPrincipalTratante = _especialidadFromText(value);
                  });
                },
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obligatorio';
                  }
                  if (_especialidadPrincipalTratante == null) {
                    return 'Seleccione una especialidad válida';
                  }
                  return null;
                },
              ),
              span: 1,
            ),
            _gridItem(
              PadSelectInput<String>(
                label: 'Grupo relacionado de riesgo',
                value: grupoRiesgoOptions.contains(
                      _grupoRiesgoController.text.trim(),
                    )
                    ? _grupoRiesgoController.text.trim()
                    : null,
                dropdownItems: grupoRiesgoOptions
                    .map(
                      (String option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    _grupoRiesgoController.text = value ?? '';
                  });
                },
              ),
              span: 3,
            ),
            _gridItem(
              PadTextInput(
                controller: _diagnosticoController,
                label: 'Diagnóstico',
                onChanged: (String value) {
                  final String normalized =
                      DiagnosisTextFormatter.normalizeForStorage(value);
                  if (normalized == value) return;
                  _diagnosticoController.value =
                      _diagnosticoController.value.copyWith(
                        text: normalized,
                        selection: TextSelection.collapsed(
                          offset: normalized.length,
                        ),
                        composing: TextRange.empty,
                      );
                },
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              span: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecisionSectionNew() {
    return _simpleSectionCard(
      title: 'Decisión de ingreso',
      children: <Widget>[
        PadFormGrid(
          children: <PadFormGridItem>[
            _gridItem(
              PadSelectInput<DecisionPad>(
                label: 'Resultado de la valoración',
                value: _decision,
                dropdownItems: DecisionPad.values
                    .map(
                      (e) => DropdownMenuItem<DecisionPad>(
                        value: e,
                        child: Text(decisionPadLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _decision = v),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
              span: 1,
            ),
            _gridItem(
              PadTextInput(
                controller: _observacionesController,
                label: 'Observaciones',
              ),
              span: 3,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return HextPageShell(
      maxWidth: HextDimens.pageMaxWidthForm,
      builder: (BuildContext context, BoxConstraints constraints) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              HextPageHeader(
                title: _isEditing ? 'Editar caso PAD' : 'Nuevo caso PAD',
                subtitle:
                    'Captación clínica, validación operativa y programación inicial del paciente.',
              ),
              _buildEstadoCasoSection(),
              _buildDatosBasicosSectionNew(),
              _buildAseguramientoSectionNew(),
              _buildCaptacionSectionNew(),
              _buildContextoClinicoSectionNew(),
              _buildMotivosProgramablesSection(),
              _buildDecisionSectionNew(),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: padFormFooterDecoration(),
                padding: const EdgeInsets.all(12),
                child: _buildActions(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: PadFormMetrics.gap,
      runSpacing: PadFormMetrics.gap,
      alignment: WrapAlignment.end,
      children: <Widget>[
        PadNeutralButton(label: 'CANCELAR', onPressed: _cancelar),
        PadSecondaryButton(label: 'GUARDAR BORRADOR', onPressed: () {}),
        PadPrimaryButton(label: 'GUARDAR PACIENTE', onPressed: _guardar),
      ],
    );
  }
}
