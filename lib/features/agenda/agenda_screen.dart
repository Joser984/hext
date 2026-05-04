import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hext/core/formatters/treatment_text_formatter.dart';
import 'package:hext/core/models/app_user.dart';
import 'package:hext/core/models/auxiliar_domiciliario.dart';
import 'package:hext/core/repositories/in_memory_personal_repo.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
import 'package:hext/features/agenda/data/agenda_repo.dart';
import 'package:hext/features/agenda/domain/agenda_shift_assigner.dart';
import 'package:hext/features/pad/utils/diagnosis_text_formatter.dart';
import 'package:hext/features/schedule/horarios_screen.dart';
import 'package:hext/shared/widgets/agenda_subnav.dart';
import 'package:hext/shared/widgets/filter_shell.dart';
import 'package:hext/shared/widgets/hext_page_shell.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({
    super.key,
    this.initialSearch,
    this.initialVisitId,
    this.initialPatientId,
    this.initialPendingId,
    this.sourceContext,
  });

  final String? initialSearch;
  final String? initialVisitId;
  final String? initialPatientId;
  final String? initialPendingId;
  final String? sourceContext;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const int _agendaNextDayCutoffHour = 16;
  static const LatLng _defaultMapCenter = LatLng(10.391049, -75.479426);
  static const bool _debugAgendaLogs = false;

  final FirestoreAgendaRepo _agendaRepo = FirestoreAgendaRepo();
  final AgendaShiftAssigner _shiftAssigner = const AgendaShiftAssigner();

  late final TextEditingController _buscarController;
  late final TextEditingController _fechaController;

  Timer? _clockTimer;
  StreamSubscription<List<AgendaEventRecord>>? _agendaSubscription;

  String? _turnoFiltro = 'Todos';
  String? _pendienteFiltro = 'Todos';
  String? _personalFiltro = 'Todos';

  final Map<String, _VisitOperationalStatus> _visitOperational =
      <String, _VisitOperationalStatus>{};

  bool _linkedFilterDismissed = false;
  bool _preferFullDayTimeline = false;

  List<String> _activeAuxiliares = kHorarioAuxiliaresRegistrados;
  Map<String, AuxiliarDomiciliario> _activeAuxiliaresByName =
      <String, AuxiliarDomiciliario>{};
  List<AgendaEventRecord> _allEvents = <AgendaEventRecord>[];

  String? get _linkedVisitId => widget.initialVisitId?.trim().isNotEmpty == true
      ? widget.initialVisitId!.trim()
      : null;

  String? get _linkedPatientId =>
      widget.initialPatientId?.trim().isNotEmpty == true
          ? widget.initialPatientId!.trim()
          : null;

  String? get _linkedPendingId =>
      widget.initialPendingId?.trim().isNotEmpty == true
          ? widget.initialPendingId!.trim()
          : null;

  bool get _hasLinkedIdentifiers =>
      !_linkedFilterDismissed &&
      (_linkedVisitId != null ||
          _linkedPatientId != null ||
          _linkedPendingId != null);

  bool _shouldUseNextOperationalDay([DateTime? nowOverride]) {
    final DateTime now = nowOverride ?? DateTime.now();
    final DateTime cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      _agendaNextDayCutoffHour,
    );
    return now.isAfter(cutoff);
  }

  DateTime _defaultAgendaFilterDate([DateTime? nowOverride]) {
    final DateTime now = nowOverride ?? DateTime.now();
    final DateTime baseDate = _shouldUseNextOperationalDay(now)
        ? now.add(const Duration(days: 1))
        : now;
    return DateTime(baseDate.year, baseDate.month, baseDate.day);
  }

  String _formatAgendaFilterDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  void _applyDefaultAgendaFilterDate() {
    _fechaController.text = _formatAgendaFilterDate(_defaultAgendaFilterDate());
  }

  @override
  void initState() {
    super.initState();

    final String seededSearch = widget.initialSearch?.trim() ?? '';
    _buscarController = TextEditingController(
      text: seededSearch.isNotEmpty ? seededSearch : '',
    );
    _fechaController = TextEditingController();

    if (_hasLinkedIdentifiers) {
      _fechaController.clear();
    } else {
      _applyDefaultAgendaFilterDate();
    }

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });

    _agendaSubscription = _agendaRepo.watchAgendaEvents().listen((
      List<AgendaEventRecord> events,
    ) {
      if (_debugAgendaLogs) {
        final String preview = events
            .take(5)
            .map(
              (event) =>
                  '${event.id}|${event.patientId}|${event.patientDisplay}|${event.fecha.toIso8601String()}|${event.hora}|${event.estadoAgenda}|${event.sourceType}|closed=${event.isClosed}',
            )
            .join(' ; ');
        debugPrint(
          '[AgendaScreen] watchAgendaEvents recibidos=${events.length}${preview.isEmpty ? '' : ' preview=$preview'}',
        );
      }
      if (!mounted) return;
      setState(() {
        _allEvents = events;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final List<AuxiliarDomiciliario> active = context
        .watch<InMemoryPersonalRepo>()
        .items
        .where((AuxiliarDomiciliario a) => a.activo)
        .toList();

    _activeAuxiliares = active
        .map((AuxiliarDomiciliario a) => a.nombreCompleto)
        .toList();
    _activeAuxiliaresByName = <String, AuxiliarDomiciliario>{
      for (final AuxiliarDomiciliario auxiliar in active)
        _slugifyName(auxiliar.nombreCompleto): auxiliar,
    };

    if (_activeAuxiliares.isEmpty) {
      _activeAuxiliares = kHorarioAuxiliaresRegistrados;
    }
  }

  _ResponsibleSummary _buildResponsibleSummary(_AgendaVisitItem item) {
    final String responsibleName =
        _AgendaFormatters.normalizeSpace(item.personalAsignado);
    if (responsibleName.isEmpty) {
      return const _ResponsibleSummary(
        displayName: 'SIN ASIGNAR',
        roleLabel: 'Asignación pendiente',
        activityLabel: 'Responsable por definir',
        isAssigned: false,
      );
    }

    final AuxiliarDomiciliario? responsibleRecord =
        _activeAuxiliaresByName[_slugifyName(responsibleName)];
    final AppUserRole? role = responsibleRecord != null
        ? _roleFromCargo(responsibleRecord.cargo)
        : _inferResponsibleRole(item);

    return _ResponsibleSummary(
      displayName: responsibleName.toUpperCase(),
      roleLabel: role == null ? 'Rol por confirmar' : _roleLabel(role),
      activityLabel: role == null
          ? _fallbackResponsibleActivity(item)
          : _activityLabelForRole(role, item),
      isAssigned: true,
    );
  }

  AppUserRole? _roleFromCargo(String cargo) {
    final String normalized = _slugifyName(cargo);
    if (normalized.contains('directora')) {
      return AppUserRole.directoraPrograma;
    }
    if (normalized.contains('medic')) {
      return AppUserRole.medico;
    }
    if (normalized.contains('herida') || normalized.contains('curacion')) {
      return AppUserRole.auxiliarEnfermeriaClinicaHeridas;
    }
    if (normalized.contains('coordin') || normalized.contains('operativ')) {
      return AppUserRole.auxiliarAdministrativa;
    }
    if (normalized.contains('auxiliar de enfermeria') ||
        normalized.contains('auxiliar domiciliario')) {
      return AppUserRole.auxiliarEnfermeria;
    }
    if (normalized.contains('admin')) {
      return AppUserRole.admin;
    }
    return null;
  }

  AppUserRole? _inferResponsibleRole(_AgendaVisitItem item) {
    final String source = _slugifyName(
      '${item.tipoActividadAgenda ?? ''} ${item.motivoKey} ${item.tratamiento}',
    );
    if (source.contains('herida') || source.contains('curacion')) {
      return AppUserRole.auxiliarEnfermeriaClinicaHeridas;
    }
    if (source.contains('infusor') ||
        source.contains('tratamiento') ||
        source.contains('visita pad')) {
      return AppUserRole.auxiliarEnfermeria;
    }
    if (source.contains('operativ')) {
      return AppUserRole.auxiliarAdministrativa;
    }
    if (source.contains('valoracion') ||
        source.contains('clinica') ||
        source.contains('procedimiento') ||
        source.contains('prequir')) {
      return AppUserRole.medico;
    }
    return null;
  }

  String _roleLabel(AppUserRole role) {
    switch (role) {
      case AppUserRole.admin:
        return 'Administrador';
      case AppUserRole.medico:
        return 'Médico';
      case AppUserRole.directoraPrograma:
        return 'Directora del programa';
      case AppUserRole.auxiliarAdministrativa:
        return 'Coordinación operativa';
      case AppUserRole.auxiliarEnfermeria:
        return 'Auxiliar de enfermería';
      case AppUserRole.auxiliarEnfermeriaClinicaHeridas:
        return 'Clínica de heridas';
    }
  }

  String _activityLabelForRole(AppUserRole role, _AgendaVisitItem item) {
    final String source = _slugifyName(
      '${item.tipoActividadAgenda ?? ''} ${item.motivoKey} ${item.tratamiento}',
    );
    switch (role) {
      case AppUserRole.directoraPrograma:
      case AppUserRole.medico:
        return 'Valoración clínica';
      case AppUserRole.auxiliarEnfermeria:
        if (source.contains('infusor')) {
          return 'Cambio de infusor';
        }
        if (source.contains('tratamiento')) {
          return 'Administración de tratamiento';
        }
        return 'Visita PAD';
      case AppUserRole.auxiliarEnfermeriaClinicaHeridas:
        return source.contains('curacion') ? 'Curación' : 'Clínica de heridas';
      case AppUserRole.auxiliarAdministrativa:
        return 'Seguimiento operativo';
      case AppUserRole.admin:
        return 'Actividad administrativa';
    }
  }

  String _fallbackResponsibleActivity(_AgendaVisitItem item) {
    final String tipoActividad = (item.tipoActividadAgenda ?? '').trim();
    if (tipoActividad.isNotEmpty) {
      return _AgendaFormatters.toSentenceCase(tipoActividad);
    }
    return 'Actividad por confirmar';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _agendaSubscription?.cancel();
    _buscarController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  _AgendaVisitItem _mapEventToVisitItem(AgendaEventRecord item) {
    String two(int value) => value.toString().padLeft(2, '0');

    final String fecha =
        '${two(item.fecha.day)}/${two(item.fecha.month)}/${item.fecha.year}';

    return _AgendaVisitItem(
      fecha: fecha,
      hora: item.hora,
      paciente: item.patientDisplay.toUpperCase(),
      patientId: item.patientId,
      visitId: item.id,
      pendingId: null,
      edad: null,
      sexo: null,
      aseguradora: null,
      dx: DiagnosisTextFormatter.formatForAgenda(item.dx),
      tratamiento: item.tratamiento,
      barrio: item.barrio.isEmpty ? null : item.barrio,
      direccion: item.direccion,
      referencia: item.referencia.isEmpty ? null : item.referencia,
      contacto: item.contacto,
      motivoKey: item.motivoKey,
      detalleMotivo: item.detalleMotivo,
      pendiente: _resolveVisibleAgendaStatus(item),
      personalAsignado: item.responsableNombre ?? '',
      fechaProbableFinalizacion: item.fechaProbableFinalizacion,
      pacienteCuentaConInfusor: item.pacienteCuentaConInfusor,
      antibioticoCandidatoInfusor: item.antibioticoCandidatoInfusor,
      antibioticoDetectado: item.antibioticoDetectado,
      requiereCambioDiarioInfusor: item.requiereCambioDiarioInfusor,
      programacionSugerida: item.programacionSugerida,
      frecuenciaTratamiento: item.frecuenciaTratamiento,
      frecuenciaTratamientoLabel: item.frecuenciaTratamientoLabel,
      tipoActividadAgenda: item.tipoActividadAgenda,
      verifiedLat: item.verifiedLat,
      verifiedLng: item.verifiedLng,
    );
  }

  String _resolveVisibleAgendaStatus(AgendaEventRecord item) {
    final String estado = item.estadoAgenda.trim().toLowerCase();
    if (estado != 'programada') {
      return item.estadoAgenda;
    }

    final bool alertaPrequirurgica48h =
        item.motivoKey == 'programacion_procedimiento' &&
        item.detalleMotivo['alertaPrequirurgica48h'] == true;
    if (alertaPrequirurgica48h) {
      return 'laboratorios prequirúrgicos pendientes';
    }

    final DateTime? scheduledAt = _combineEventDateAndHour(item.fecha, item.hora);
    if (scheduledAt == null || !scheduledAt.isBefore(DateTime.now())) {
      return item.estadoAgenda;
    }

    final Duration overdue = DateTime.now().difference(scheduledAt);
    if (overdue >= const Duration(hours: 2)) {
      return 'vencida sin cierre';
    }
    return 'pendiente de cierre';
  }

  DateTime? _combineEventDateAndHour(DateTime fecha, String hora) {
    final List<String> parts = hora.trim().split(':');
    if (parts.length != 2) {
      return null;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return DateTime(fecha.year, fecha.month, fecha.day, hour, minute);
  }

  AgendaAssignableVisit _toAssignableVisit(_AgendaVisitItem item) {
    return AgendaAssignableVisit(
      fecha: item.fecha,
      hora: item.hora,
      paciente: item.paciente,
      patientId: item.patientId,
      visitId: item.visitId,
      pendingId: item.pendingId,
      edad: item.edad,
      sexo: item.sexo,
      aseguradora: item.aseguradora,
      dx: item.dx,
      tratamiento: item.tratamiento,
      barrio: item.barrio,
      direccion: item.direccion,
      referencia: item.referencia,
      contacto: item.contacto,
      motivoKey: item.motivoKey,
      detalleMotivo: item.detalleMotivo,
      pendiente: item.pendiente,
      personalAsignado: item.personalAsignado,
      fechaProbableFinalizacion: item.fechaProbableFinalizacion,
      pacienteCuentaConInfusor: item.pacienteCuentaConInfusor,
      antibioticoCandidatoInfusor: item.antibioticoCandidatoInfusor,
      antibioticoDetectado: item.antibioticoDetectado,
      requiereCambioDiarioInfusor: item.requiereCambioDiarioInfusor,
      programacionSugerida: item.programacionSugerida,
      frecuenciaTratamiento: item.frecuenciaTratamiento,
      frecuenciaTratamientoLabel: item.frecuenciaTratamientoLabel,
      tipoActividadAgenda: item.tipoActividadAgenda,
    );
  }

  _AgendaVisitItem _fromAssignableVisit(AgendaAssignableVisit item) {
    return _AgendaVisitItem(
      fecha: item.fecha,
      hora: item.hora,
      paciente: item.paciente,
      patientId: item.patientId,
      visitId: item.visitId,
      pendingId: item.pendingId,
      edad: item.edad,
      sexo: item.sexo,
      aseguradora: item.aseguradora,
      dx: item.dx,
      tratamiento: item.tratamiento,
      barrio: item.barrio,
      direccion: item.direccion,
      referencia: item.referencia,
      contacto: item.contacto,
      motivoKey: item.motivoKey,
      detalleMotivo: item.detalleMotivo,
      pendiente: item.pendiente,
      personalAsignado: item.personalAsignado,
      fechaProbableFinalizacion: item.fechaProbableFinalizacion,
      pacienteCuentaConInfusor: item.pacienteCuentaConInfusor,
      antibioticoCandidatoInfusor: item.antibioticoCandidatoInfusor,
      antibioticoDetectado: item.antibioticoDetectado,
      requiereCambioDiarioInfusor: item.requiereCambioDiarioInfusor,
      programacionSugerida: item.programacionSugerida,
      frecuenciaTratamiento: item.frecuenciaTratamiento,
      frecuenciaTratamientoLabel: item.frecuenciaTratamientoLabel,
      tipoActividadAgenda: item.tipoActividadAgenda,
    );
  }

  List<String> get _personalOptions {
    final Set<String> values = _resolvedVisits
        .map((_AgendaVisitItem e) => e.personalAsignado.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();
    final List<String> list = values.toList()..sort();
    return <String>['Todos', ...list];
  }

  List<String> get _pendienteOptions {
    final Set<String> values = _resolvedVisits
        .map((_AgendaVisitItem e) => e.pendiente.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();
    final List<String> list = values.toList()..sort();
    return <String>['Todos', ...list];
  }

  bool get _hasActiveFilters {
    return _hasLinkedIdentifiers ||
        _buscarController.text.trim().isNotEmpty ||
        (_turnoFiltro != null && _turnoFiltro != 'Todos') ||
        (_pendienteFiltro != null && _pendienteFiltro != 'Todos') ||
        (_personalFiltro != null && _personalFiltro != 'Todos');
  }

  List<_AgendaVisitItem> get _resolvedVisits {
    final List<_AgendaVisitItem> recalculables = <_AgendaVisitItem>[];
    final List<_AgendaVisitItem> fijos = <_AgendaVisitItem>[];

    for (final AgendaEventRecord event in _allEvents) {
      final _AgendaVisitItem item = _mapEventToVisitItem(event);
      final bool locked = event.isClosed || event.estadoAgenda == 'finalizada';

      if (locked) {
        fijos.add(item);
      } else {
        recalculables.add(item);
      }
    }

    final List<AgendaAssignableVisit> assignable = recalculables
        .map(_toAssignableVisit)
        .toList();

    final List<AgendaAssignableVisit> resolved =
        _shiftAssigner.assignResponsibles(
      visits: assignable,
      activeAuxiliares: _activeAuxiliares,
    );

    return <_AgendaVisitItem>[
      ...fijos,
      ...resolved.map(_fromAssignableVisit),
    ]..sort(
        (_AgendaVisitItem a, _AgendaVisitItem b) =>
            _hourToInt(a.hora).compareTo(_hourToInt(b.hora)),
      );
  }

  List<_AgendaVisitItem> get _filteredVisits {
    final List<_AgendaVisitItem> resolvedVisits = _resolvedVisits;
    final String fecha = _fechaController.text.trim();
    final DateTime? selectedDate = _tryParseDate(fecha);
    final String selectedKey = selectedDate == null ? '' : _dateKey(selectedDate);
    final List<_AgendaVisitItem> filtered = resolvedVisits.where((
      _AgendaVisitItem item,
    ) {
      final String query = _buscarController.text.trim().toLowerCase();

      final bool matchesQuery =
          query.isEmpty ||
          item.paciente.toLowerCase().contains(query) ||
          item.dx.toLowerCase().contains(query) ||
          item.tratamiento.toLowerCase().contains(query) ||
          (item.tipoActividadAgenda ?? '').toLowerCase().contains(query) ||
          (item.antibioticoDetectado ?? '').toLowerCase().contains(query) ||
          item.direccion.toLowerCase().contains(query) ||
          item.contacto.toLowerCase().contains(query) ||
          item.pendiente.toLowerCase().contains(query) ||
          item.personalAsignado.toLowerCase().contains(query);

      final DateTime? itemDate = _tryParseDate(item.fecha);
      final String itemKey = itemDate == null ? '' : _dateKey(itemDate);
      final bool matchesFecha = fecha.isEmpty || itemKey == selectedKey;

      final bool matchesLinkedIdentifiers =
          !_hasLinkedIdentifiers ||
          ((_linkedVisitId == null || item.visitId == _linkedVisitId) &&
              (_linkedPatientId == null ||
                  item.patientId == _linkedPatientId) &&
              (_linkedPendingId == null || item.pendingId == _linkedPendingId));

      final bool matchesTurno =
          _turnoFiltro == null ||
          _turnoFiltro == 'Todos' ||
          _resolveTurno(item.hora) == _turnoFiltro;

      final bool matchesPendiente =
          _pendienteFiltro == null ||
          _pendienteFiltro == 'Todos' ||
          item.pendiente == _pendienteFiltro;

      final bool matchesPersonal =
          _personalFiltro == null ||
          _personalFiltro == 'Todos' ||
          item.personalAsignado == _personalFiltro;

      return matchesQuery &&
          matchesLinkedIdentifiers &&
          matchesFecha &&
          matchesTurno &&
          matchesPendiente &&
          matchesPersonal;
    }).toList()
      ..sort(
        (_AgendaVisitItem a, _AgendaVisitItem b) =>
            _hourToInt(a.hora).compareTo(_hourToInt(b.hora)),
      );

    final String resolvedPreview = resolvedVisits
        .take(5)
        .map(
          (item) =>
              '${item.visitId}|${item.patientId}|${item.paciente}|${item.fecha}|${item.hora}|${item.pendiente}|${item.personalAsignado}',
        )
        .join(' ; ');
    final String filteredPreview = filtered
        .take(5)
        .map(
          (item) =>
              '${item.visitId}|${item.patientId}|${item.paciente}|${item.fecha}|${item.hora}|${item.pendiente}|${item.personalAsignado}',
        )
        .join(' ; ');
    if (_debugAgendaLogs) {
      debugPrint(
        '[AgendaScreen] filtro fecha=$fecha query=${_buscarController.text.trim()} turno=$_turnoFiltro pendiente=$_pendienteFiltro personal=$_personalFiltro resolved=${resolvedVisits.length} filtered=${filtered.length}${resolvedPreview.isEmpty ? '' : ' resolvedPreview=$resolvedPreview'}${filteredPreview.isEmpty ? '' : ' filteredPreview=$filteredPreview'}',
      );
    }

    return filtered;
  }

  List<_AgendaRowData> get _displayRows {
    final List<_AgendaVisitItem> visits = _filteredVisits;

    if (_hasActiveFilters) {
      return visits
          .map(
            (_AgendaVisitItem item) =>
                _AgendaRowData(hora: item.hora, item: item),
          )
          .toList();
    }

    final Map<String, List<_AgendaVisitItem>> grouped =
        <String, List<_AgendaVisitItem>>{};
    for (final _AgendaVisitItem item in visits) {
      grouped.putIfAbsent(item.hora, () => <_AgendaVisitItem>[]).add(item);
    }

    final bool shouldCompactHours =
        !_preferFullDayTimeline &&
        visits.isNotEmpty &&
        visits.length <= 3;

    int startHour = 6;
    int endHour = 22;

    if (shouldCompactHours) {
      int? minHour;
      int? maxHour;
      for (final String hora in grouped.keys) {
        final int hour = _hourToInt(hora);
        minHour = minHour == null ? hour : (hour < minHour ? hour : minHour);
        maxHour = maxHour == null ? hour : (hour > maxHour ? hour : maxHour);
      }
      if (minHour != null && maxHour != null) {
        startHour = (minHour - 1).clamp(6, 22);
        endHour = (maxHour + 1).clamp(6, 22);
      }
    }

    final List<_AgendaRowData> rows = <_AgendaRowData>[];
    for (int hour = startHour; hour <= endHour; hour++) {
      final String key = '$hour:00';
      final List<_AgendaVisitItem> items =
          grouped[key] ?? <_AgendaVisitItem>[];

      if (items.isEmpty) {
        rows.add(_AgendaRowData(hora: key));
      } else {
        for (final _AgendaVisitItem item in items) {
          rows.add(_AgendaRowData(hora: key, item: item));
        }
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEmpty = _filteredVisits.isEmpty;

    return HextPageShell(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const HextPageHeader(
              title: 'Visitas',
              subtitle:
                  'Gestión de visitas, seguimiento operativo y control diario.',
              tabs: AgendaSubnav(section: AgendaSubnavSection.visitas),
            ),
            _buildFiltersShell(),
            const SizedBox(height: 10),
            _buildSectionHeader(theme),
            const SizedBox(height: 6),
            if (isEmpty)
              _buildEmptyAgendaState(constraints)
            else if (constraints.maxWidth < 900)
              _buildMobileAgenda()
            else
              SizedBox(
                height: 620,
                child: _AgendaGrid(
                  rows: _displayRows,
                  resolveResponsible: _buildResponsibleSummary,
                  onEditLocation: _openEditLocationDialog,
                  onVerifyLocation: _openSiteVerificationDialog,
                  onOpenVerifiedMap: (_AgendaVisitItem item) {
                    final double? lat = item.verifiedLat;
                    final double? lng = item.verifiedLng;
                    if (lat == null || lng == null) {
                      return;
                    }
                    unawaited(_openVerifiedMap(lat, lng));
                  },
                  emptyMessage: _hasLinkedIdentifiers
                      ? 'No se encontró una visita asociada a este pendiente.'
                      : 'No hay registros para mostrar.',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersShell() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double searchWidth = maxWidth >= 1280
            ? 320
            : maxWidth >= 900
                ? 280
                : maxWidth;
        final double fieldWidth = maxWidth >= 1280
            ? 185
            : maxWidth >= 900
                ? (maxWidth - 12) / 2
                : maxWidth;

        return FilterShell(
          title: 'Filtros',
          subtitle: 'Filtra y encuentra visitas rápidamente.',
          fields: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              SizedBox(
                width: searchWidth,
                child: LightInput(
                  label: 'Buscar',
                  hint: 'Buscar paciente, DX, contacto o personal...',
                  controller: _buscarController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightInput(
                  label: 'Fecha',
                  hint: 'Seleccionar',
                  controller: _fechaController,
                  readOnly: true,
                  onTap: _pickDate,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightDropdown<String>(
                  label: 'Turno',
                  value: _turnoFiltro ?? 'Todos',
                  items: const <String>['Todos', 'Mañana', 'Tarde', 'Noche']
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() => _turnoFiltro = value);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightDropdown<String>(
                  label: 'Pendiente',
                  value: _pendienteFiltro ?? 'Todos',
                  items: _pendienteOptions
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() => _pendienteFiltro = value);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightDropdown<String>(
                  label: 'Personal asignado',
                  value: _personalFiltro ?? 'Todos',
                  items: _personalOptions
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() => _personalFiltro = value);
                  },
                ),
              ),
            ],
          ),
          actions: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _exportAgendaPdf,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD7DCE3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 18,
                    color: Color(0xFF5B6474),
                  ),
                  label: const Text(
                    'Exportar PDF',
                    style: TextStyle(color: Color(0xFF5B6474)),
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD7DCE3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Color(0xFF5B6474),
                  ),
                  label: const Text(
                    'Limpiar filtros',
                    style: TextStyle(color: Color(0xFF5B6474)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyAgendaState(BoxConstraints constraints) {
    return Center(
      child: Container(
        width: constraints.maxWidth < 500 ? double.infinity : 440,
        margin: const EdgeInsets.symmetric(vertical: 48),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE3EA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.event_busy, size: 48, color: Color(0xFFB0B8C1)),
            const SizedBox(height: 16),
            const Text(
              'No hay visitas programadas para esta fecha',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF243247),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Puedes crear una nueva visita o revisar los horarios de auxiliares para planificar tu agenda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acción: Crear visita')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: HextColors.sidebar,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label:
                  const Text('Crear visita', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HorariosScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB0B8C1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.schedule,
                size: 18,
                color: Color(0xFF17726D),
              ),
              label: const Text(
                'Ir a horarios',
                style: TextStyle(fontSize: 14, color: Color(0xFF17726D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    final bool canCompact = !_hasActiveFilters && _filteredVisits.isNotEmpty;
    final bool compactActive =
        canCompact && !_preferFullDayTimeline && _filteredVisits.length <= 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: <Widget>[
            Text(
              'Visitas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF243247),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3F1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_filteredVisits.length} registros',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF17726D),
                ),
              ),
            ),
            if (compactActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Vista compacta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
          ],
        ),
        if (canCompact)
          SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: HextColors.primary,
            ),
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                label: Text('Compacta'),
                icon: Icon(Icons.compress_rounded, size: 16),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Día completo'),
                icon: Icon(Icons.view_stream_rounded, size: 16),
              ),
            ],
            selected: <bool>{_preferFullDayTimeline},
            onSelectionChanged: (Set<bool> selected) {
              if (selected.isEmpty) return;
              setState(() {
                _preferFullDayTimeline = selected.first;
              });
            },
          ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _tryParseDate(_fechaController.text) ?? now;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF17726D)),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _fechaController.text =
          '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    });
  }

  void _clearFilters() {
    setState(() {
      _linkedFilterDismissed = true;
      _buscarController.clear();
      _applyDefaultAgendaFilterDate();
      _turnoFiltro = 'Todos';
      _pendienteFiltro = 'Todos';
      _personalFiltro = 'Todos';
    });
  }

  Future<void> _exportAgendaPdf() async {
    final String fileName = _buildAgendaPdfFileName();
    final List<_AgendaVisitItem> visits = List<_AgendaVisitItem>.from(
      _filteredVisits,
    )..sort((a, b) => _hourToInt(a.hora).compareTo(_hourToInt(b.hora)));

    if (visits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay visitas para exportar.')),
      );
      return;
    }

    try {
      final pw.Document document = pw.Document();
      final DateTime exportDate =
          _tryParseDate(_fechaController.text) ?? DateTime.now();
      final List<_AgendaPdfRow> rows = visits
          .asMap()
          .entries
          .map(
            (entry) {
              final int index = entry.key;
              final _AgendaVisitItem item = entry.value;
              return _AgendaPdfRow(
                orden: '${index + 1}.',
                hora: item.hora.trim(),
                paciente: _AgendaFormatters.splitPaciente(item.paciente).nombre,
                tratamiento: _buildPdfTreatmentTitle(item),
                actividad: _buildPdfActivity(item),
                barrio: ((item.barrio ?? '').trim()).toUpperCase(),
                direccion: _buildPdfAddressLine(item),
                referencia: _buildPdfReference(item),
                contacto: _buildPdfContactNumbers(item.contacto),
                responsable: _buildResponsibleSummary(item).displayName,
                responsableRol: _buildPdfResponsibleRole(item),
                estado: _buildPdfStatus(item),
              );
            },
          )
          .toList();

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
          build: (pw.Context context) => <pw.Widget>[
            _buildAgendaPdfHeader(
              exportDate: exportDate,
              fileName: fileName,
              total: rows.length,
            ),
            pw.SizedBox(height: 10),
            _buildAgendaPdfTable(rows),
          ],
        ),
      );

      await Printing.layoutPdf(
        name: fileName,
        onLayout: (PdfPageFormat format) async => document.save(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible exportar el PDF: $error')),
      );
    }
  }

  String _buildPdfTreatmentTitle(_AgendaVisitItem item) {
    if (item.motivoKey == 'programacion_procedimiento') {
      final String procedureName = _readPdfProcedureName(item);
      if (procedureName.isNotEmpty) {
        return procedureName.toUpperCase();
      }
      return 'PROCEDIMIENTO QUIRURGICO';
    }

    return _formatTreatmentDisplay(item).mainLine;
  }

  String _buildPdfActivity(_AgendaVisitItem item) {
    if (item.motivoKey == 'programacion_procedimiento') {
      final String tipoActividad =
          _AgendaFormatters.toSentenceCase(item.tipoActividadAgenda ?? '');
      return tipoActividad.isEmpty ? 'Actividad programada' : tipoActividad;
    }

    final TreatmentDisplayData display = _formatTreatmentDisplay(item);
    final List<String> lines = <String>[];

    if ((display.frequencyLine ?? '').trim().isNotEmpty) {
      lines.add(display.frequencyLine!.trim());
    }

    if ((display.infusorLine ?? '').trim().isNotEmpty) {
      lines.add(display.infusorLine!.trim());
    }

    if (lines.isNotEmpty) {
      return lines.join('\n');
    }

    final String tipoActividad =
        _AgendaFormatters.toSentenceCase(item.tipoActividadAgenda ?? '');
    if (tipoActividad.isNotEmpty) {
      return tipoActividad;
    }

    if (item.requiereCambioDiarioInfusor) {
      return 'c/24 h\nInfusor: Sí';
    }

    return 'Actividad programada';
  }

  TreatmentDisplayData _formatTreatmentDisplay(_AgendaVisitItem item) {
    final List<String> tokens = _AgendaFormatters.splitTreatmentTokens(
      item.tratamiento,
      antibioticoDetectado: item.antibioticoDetectado,
    );

    return TreatmentTextFormatter.formatTreatment(<String, dynamic>{
      'nombreTratamiento': tokens.isNotEmpty ? tokens.first : item.tratamiento,
      'frecuencia': item.frecuenciaTratamientoLabel ?? item.frecuenciaTratamiento,
      'pacienteCuentaConInfusor': item.pacienteCuentaConInfusor,
    });
  }

  String _readPdfProcedureName(_AgendaVisitItem item) {
    final List<dynamic> candidates = <dynamic>[
      item.detalleMotivo['nombreProcedimiento'],
      item.detalleMotivo['procedimientoRequerido'],
      item.detalleMotivo['procedimientoProgramado'],
      item.tratamiento,
    ];
    for (final dynamic candidate in candidates) {
      final String value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _buildPdfAddressLine(_AgendaVisitItem item) {
    final String direccion = item.direccion.trim();
    if (direccion.isEmpty) {
      return 'Ubicación pendiente';
    }
    return _AgendaFormatters.toTitleCase(direccion);
  }

  String _buildPdfReference(_AgendaVisitItem item) {
    final String referencia = (item.referencia ?? '').trim();
    if (referencia.isEmpty) {
      return 'Sin referencia';
    }
    return 'Ref: ${_AgendaFormatters.toTitleCase(referencia)}';
  }

  String _buildPdfResponsibleRole(_AgendaVisitItem item) {
    final _ResponsibleSummary summary = _buildResponsibleSummary(item);
    switch (summary.roleLabel) {
      case 'Auxiliar de enfermería':
        return 'Aux. enfermería';
      case 'Coordinación operativa':
        return 'Coord. operativa';
      case 'Directora del programa':
        return 'Dir. programa';
      case 'Clínica de heridas':
        return 'Clínica heridas';
      case 'Administrador':
        return 'Administrador';
      case 'Médico':
        return 'Médico';
      default:
        return summary.roleLabel;
    }
  }

  String _buildPdfStatus(_AgendaVisitItem item) {
    final String pendiente = item.pendiente.trim();
    if (pendiente.isNotEmpty) {
      return _AgendaFormatters.toSentenceCase(pendiente);
    }
    if (item.personalAsignado.trim().isNotEmpty) {
      return 'Asignada';
    }
    return 'Pendiente';
  }

  String _buildPdfContactNumbers(String rawContact) {
    final List<String> entries = rawContact
        .split('|')
        .map(_AgendaFormatters.normalizeSpace)
        .where((String item) => item.isNotEmpty)
        .toList();
    final List<String> numbers = <String>[];

    for (final String entry in entries) {
      final List<String> parts = entry
          .split('·')
          .map(_AgendaFormatters.normalizeSpace)
          .where((String item) => item.isNotEmpty)
          .toList();
      for (final String part in parts) {
        final String digits = part.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 7 && !numbers.contains(digits)) {
          numbers.add(digits);
        }
      }
    }

    if (numbers.isEmpty) {
      return 'Sin contacto';
    }

    return 'Tel:\n${numbers.join('\n')}';
  }

  pw.Widget _buildAgendaPdfHeader({
    required DateTime exportDate,
    required String fileName,
    required int total,
  }) {
    final String day = exportDate.day.toString().padLeft(2, '0');
    final String month = exportDate.month.toString().padLeft(2, '0');
    final String year = exportDate.year.toString();
    final String search = _buscarController.text.trim();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'HEXT · AGENDA DE VISITAS',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Fecha operativa: $day/$month/$year',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  'Total: $total ${total == 1 ? 'visita' : 'visitas'}',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                if (search.isNotEmpty)
                  pw.Text(
                    'Filtro: $search',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.Text(
                  '$total visitas',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  fileName,
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 1.2, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildAgendaPdfTable(List<_AgendaPdfRow> rows) {
    const pw.TextStyle headerStyle = pw.TextStyle(
      fontSize: 7.4,
      color: PdfColors.white,
    );
    const pw.TextStyle bodyStyle = pw.TextStyle(
      fontSize: 7.3,
      lineSpacing: 0.15,
    );
    const double tableWidth = 760;

    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.SizedBox(
        width: tableWidth,
        child: pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.35),
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FixedColumnWidth(20),
            1: const pw.FixedColumnWidth(38),
            2: const pw.FixedColumnWidth(95),
            3: const pw.FixedColumnWidth(120),
            4: const pw.FixedColumnWidth(68),
            5: const pw.FixedColumnWidth(95),
            6: const pw.FixedColumnWidth(110),
            7: const pw.FixedColumnWidth(65),
            8: const pw.FixedColumnWidth(94),
            9: const pw.FixedColumnWidth(55),
          },
          children: <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal700),
              children: <pw.Widget>[
                _buildPdfHeaderCell('#', headerStyle),
                _buildPdfHeaderCell('Hora', headerStyle),
                _buildPdfHeaderCell('Paciente', headerStyle),
                _buildPdfHeaderCell('Tratamiento / actividad', headerStyle),
                _buildPdfHeaderCell('Barrio', headerStyle),
                _buildPdfHeaderCell('Dirección', headerStyle),
                _buildPdfHeaderCell('Punto de referencia', headerStyle),
                _buildPdfHeaderCell('Contacto', headerStyle),
                _buildPdfHeaderCell('Responsable', headerStyle),
                _buildPdfHeaderCell('Estado', headerStyle),
              ],
            ),
            ...rows.asMap().entries.map((entry) {
              final int index = entry.key;
              final _AgendaPdfRow row = entry.value;
              final PdfColor background = index.isEven
                  ? PdfColors.white
                  : PdfColors.grey50;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: background),
                verticalAlignment: pw.TableCellVerticalAlignment.top,
                children: <pw.Widget>[
                  _buildPdfCell(
                    row.orden,
                    bodyStyle,
                    align: pw.TextAlign.center,
                    verticalPadding: 3,
                  ),
                  _buildPdfCell(
                    row.hora,
                    bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    align: pw.TextAlign.center,
                    verticalPadding: 3,
                  ),
                  _buildPdfCell(
                    row.paciente,
                    bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    maxLines: 2,
                    verticalPadding: 3,
                  ),
                  _buildPdfTreatmentCell(row, bodyStyle),
                  _buildPdfCell(
                    row.barrio,
                    bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    maxLines: 2,
                    verticalPadding: 3,
                  ),
                  _buildPdfCell(
                    row.direccion,
                    bodyStyle,
                    maxLines: 2,
                    verticalPadding: 3,
                  ),
                  _buildPdfCell(
                    row.referencia,
                    bodyStyle,
                    maxLines: 2,
                    verticalPadding: 3,
                  ),
                  _buildPdfCell(
                    row.contacto,
                    bodyStyle,
                    maxLines: 4,
                    verticalPadding: 3,
                  ),
                  _buildPdfResponsibleCell(row, bodyStyle),
                  _buildPdfCell(
                    row.estado,
                    bodyStyle,
                    maxLines: 2,
                    verticalPadding: 3,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfHeaderCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text, style: style, maxLines: 2),
    );
  }

  pw.Widget _buildPdfTreatmentCell(_AgendaPdfRow row, pw.TextStyle bodyStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          pw.Text(
            row.tratamiento,
            style: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
            maxLines: 2,
          ),
          if (row.actividad.trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 1),
            pw.Text(
              row.actividad,
              style: bodyStyle,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfResponsibleCell(_AgendaPdfRow row, pw.TextStyle bodyStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          pw.Text(
            row.responsable,
            style: bodyStyle.copyWith(fontWeight: pw.FontWeight.bold),
            maxLines: 2,
          ),
          if (row.responsableRol.trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 1),
            pw.Text(
              row.responsableRol,
              style: bodyStyle,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
    int maxLines = 2,
    double verticalPadding = 4,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: verticalPadding),
      child: pw.Text(text, style: style, textAlign: align, maxLines: maxLines),
    );
  }

  String _buildAgendaPdfFileName() {
    final DateTime date =
        _tryParseDate(_fechaController.text) ?? DateTime.now();
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String dateToken = '$day-$month-$year';

    final bool includesAll =
        (_personalFiltro == null || _personalFiltro == 'Todos');
    final String? responsibleName = includesAll ? null : _personalFiltro;
    final String suffix = includesAll
        ? 'GENERAL'
        : _normalizeAgendaPdfFileToken(responsibleName ?? 'GENERAL');

    return 'Agenda_${dateToken}_$suffix.pdf';
  }

  String _normalizeAgendaPdfFileToken(String input) {
    final String normalized = _stripAccents(input)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'GENERAL' : normalized;
  }

  String _slugifyName(String input, {int maxLength = 40}) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    String value = _stripAccents(
      trimmed,
    ).replaceAll(RegExp(r'[\\/]+'), ' ').replaceAll(RegExp(r'\s+'), '-');

    value = value
        .replaceAll(RegExp(r'[^A-Za-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (value.length > maxLength) {
      value = value.substring(0, maxLength).replaceAll(RegExp(r'-+$'), '');
    }

    return value;
  }

  String _stripAccents(String input) {
    const Map<String, String> replacements = <String, String>{
      'Á': 'A',
      'À': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Ã': 'A',
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Ö': 'O',
      'Õ': 'O',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'Ñ': 'N',
      'ñ': 'n',
    };

    return input
        .split('')
        .map((String char) => replacements[char] ?? char)
        .join();
  }

  static String _resolveTurno(String hora) {
    final int hour = _hourToInt(hora);
    if (hour < 12) return 'Mañana';
    if (hour < 18) return 'Tarde';
    return 'Noche';
  }

  static int _hourToInt(String hora) {
    final String normalized = hora.trim().split(':').first;
    return int.tryParse(normalized) ?? 0;
  }

  static DateTime? _tryParseDate(String text) {
    final List<String> parts = text.split('/');
    if (parts.length != 3) return null;
    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _operationalNow() {
    final DateTime now = DateTime.now();
    final DateTime? selected = _tryParseDate(_fechaController.text);
    if (selected == null) return now;
    return DateTime(
      selected.year,
      selected.month,
      selected.day,
      now.hour,
      now.minute,
    );
  }

  Widget _buildMobileAgenda() {
    final DateTime now = _operationalNow();
    final List<_AgendaVisitItem> visits = List<_AgendaVisitItem>.from(
      _filteredVisits,
    )..sort((a, b) => _hourToInt(a.hora).compareTo(_hourToInt(b.hora)));

    final List<_AgendaVisitItem> ahora = visits.where((_AgendaVisitItem item) {
      final _VisitFlowState state = _stateFor(item).state;
      if (state == _VisitFlowState.enRuta ||
          state == _VisitFlowState.llego ||
          state == _VisitFlowState.enAtencion) {
        return true;
      }

      final DateTime? start = _visitDateTime(item);
      if (start == null) return false;
      final int minutesToStart = start.difference(now).inMinutes;
      return state == _VisitFlowState.pendiente && minutesToStart <= 30;
    }).toList();

    final List<_AgendaVisitItem> siguientes = visits
        .where((_AgendaVisitItem item) {
          final _VisitFlowState state = _stateFor(item).state;
          final DateTime? start = _visitDateTime(item);
          return state == _VisitFlowState.pendiente &&
              start != null &&
              start.isAfter(now);
        })
        .take(3)
        .toList();

    final List<_AgendaVisitItem> terminadas = visits.where((
      _AgendaVisitItem item,
    ) {
      return _stateFor(item).state == _VisitFlowState.finalizada;
    }).toList();

    final List<_AuxOperationRow> operationalRows = _buildAuxOperationRows(
      now: now,
      source: visits,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildOperationLivePanel(now: now, rows: operationalRows),
        const SizedBox(height: 12),
        _buildMobileSection(
          title: 'Ahora',
          items: ahora,
          empty: 'Sin visitas en curso por ahora.',
        ),
        const SizedBox(height: 12),
        _buildMobileSection(
          title: 'Siguientes',
          items: siguientes,
          empty: 'No hay próximas visitas en esta vista.',
        ),
        const SizedBox(height: 12),
        _buildMobileSection(
          title: 'Terminadas',
          items: terminadas,
          empty: 'No hay visitas finalizadas todavía.',
          collapsedStyle: true,
        ),
      ],
    );
  }

  Widget _buildMobileSection({
    required String title,
    required List<_AgendaVisitItem> items,
    required String empty,
    bool collapsedStyle = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              empty,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF748096)),
            )
          else
            Column(
              children: items.map((_AgendaVisitItem item) {
                return _MobileVisitCard(
                  item: item,
                  responsibleSummary: _buildResponsibleSummary(item),
                  state: _stateFor(item),
                  collapsed: collapsedStyle,
                  onStateTap: (_VisitFlowState next) =>
                      _updateVisitState(item: item, nextState: next),
                  onOpenMap: () => _openMap(item.direccion),
                  onPingLocation: () => _pingLocation(item),
                  onEditLocation: () => _openEditLocationDialog(item),
                  onVerifyLocation: () => _openSiteVerificationDialog(item),
                  onOpenVerifiedMap:
                      item.verifiedLat != null && item.verifiedLng != null
                          ? () => _openVerifiedMap(
                                item.verifiedLat!,
                                item.verifiedLng!,
                              )
                          : null,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  _VisitOperationalStatus _stateFor(_AgendaVisitItem item) {
    return _visitOperational[_visitKey(item)] ??
        const _VisitOperationalStatus(state: _VisitFlowState.pendiente);
  }

  String _visitKey(_AgendaVisitItem item) {
    return '${item.fecha}|${item.hora}|${item.paciente}';
  }

  DateTime? _visitDateTime(_AgendaVisitItem item) {
    final DateTime? date = _tryParseDate(item.fecha);
    if (date == null) return null;
    final int hour = _hourToInt(item.hora);
    return DateTime(date.year, date.month, date.day, hour);
  }

  void _updateVisitState({
    required _AgendaVisitItem item,
    required _VisitFlowState nextState,
  }) {
    final DateTime now = DateTime.now();
    final _VisitOperationalStatus next = _VisitOperationalStatus(
      state: nextState,
      reportedAt: now,
      onlineAt: now,
      locationSnapshot:
          nextState == _VisitFlowState.llego ? item.direccion : null,
    );

    setState(() {
      _visitOperational[_visitKey(item)] = next;
    });
  }

  void _pingLocation(_AgendaVisitItem item) {
    final String key = _visitKey(item);
    final DateTime now = DateTime.now();
    final _VisitOperationalStatus current =
        _visitOperational[key] ??
            const _VisitOperationalStatus(state: _VisitFlowState.pendiente);

    setState(() {
      _visitOperational[key] = current.copyWith(
        reportedAt: now,
        onlineAt: now,
        locationSnapshot: item.direccion,
      );
    });
  }

  Future<void> _openEditLocationDialog(_AgendaVisitItem item) async {
    final String patientId = (item.patientId ?? '').trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible identificar al paciente.')),
      );
      return;
    }
    try {
      debugPrint('OPEN_EDIT_LOCATION patientId=$patientId');
      final Map<String, dynamic> initialData = await _agendaRepo
          .fetchPatientLocation(patientId);
      if (!mounted) return;

      final _PatientLocationPayload? payload =
          await showDialog<_PatientLocationPayload>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EditLocationDialog(
          patientName: item.paciente,
          initialData: initialData,
        ),
      );
      if (payload == null) {
        return;
      }

      await _agendaRepo.updatePatientLocation(
        patientId: patientId,
        eventId: item.visitId,
        ubicacion: payload.toFirestoreMap(),
        updatedByRole: 'auxiliar_enfermeria',
      );
      await _refreshPatientLocation(patientId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación y contactos actualizados correctamente.'),
        ),
      );
    } catch (error) {
      debugPrint(
        '[AgendaScreen._openEditLocationDialog] patientId=$patientId error=$error',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible guardar la ubicación y contactos.'),
        ),
      );
    }
  }

  Future<void> _openSiteVerificationDialog(_AgendaVisitItem item) async {
    final String patientId = (item.patientId ?? '').trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible identificar al paciente.')),
      );
      return;
    }
    try {
      debugPrint('OPEN_VERIFY_LOCATION patientId=$patientId');
      final Map<String, dynamic> initialData = await _agendaRepo
          .fetchPatientLocation(patientId);
      if (!mounted) return;

      final _SiteVerificationPayload? payload =
          await showDialog<_SiteVerificationPayload>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _VerifyLocationDialog(
          patientName: item.paciente,
          initialData: initialData,
        ),
      );
      if (payload == null) {
        return;
      }

      await _agendaRepo.updatePatientSiteVerification(
        patientId: patientId,
        eventId: item.visitId,
        verification: payload.toFirestoreMap(),
        updatedBy: 'auxiliar_enfermeria',
      );
      await _refreshPatientLocation(patientId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificación en sitio guardada.')),
      );
    } catch (error) {
      debugPrint(
        '[AgendaScreen._openSiteVerificationDialog] patientId=$patientId error=$error',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible guardar la verificación en sitio.'),
        ),
      );
    }
  }

  Future<void> _refreshPatientLocation(String patientId) async {
    final Map<String, dynamic> updatedLocation = await _agendaRepo
        .fetchPatientLocation(patientId);
    if (!mounted) return;

    final String contactSummary = (updatedLocation['contacto'] ?? '')
        .toString()
        .trim();
    final String direccion = (updatedLocation['direccion'] ?? '')
        .toString()
        .trim();
    final String referencia = (updatedLocation['referencia'] ?? '')
        .toString()
        .trim();
    final String barrio = (updatedLocation['barrio'] ?? '').toString().trim();
    final double? verifiedLat = _readDouble(updatedLocation['lat']);
    final double? verifiedLng = _readDouble(updatedLocation['lng']);
    setState(() {
      _allEvents = _allEvents.map((event) {
        if (event.patientId.trim() != patientId) {
          return event;
        }
        return event.copyWith(
          direccion: direccion.isNotEmpty ? direccion : event.direccion,
          barrio: barrio.isNotEmpty ? barrio : event.barrio,
          referencia: referencia.isNotEmpty ? referencia : event.referencia,
          contacto: contactSummary.isEmpty ? event.contacto : contactSummary,
          verifiedLat: verifiedLat,
          verifiedLng: verifiedLng,
        );
      }).toList();
    });
  }

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString().trim());
  }

  Future<void> _openVerifiedMap(double lat, double lng) async {
    final Uri uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir Google Maps.')),
      );
    }
  }

  Widget _buildOperationLivePanel({
    required DateTime now,
    required List<_AuxOperationRow> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Operacion en campo · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'Sin auxiliares con asignacion en esta vista.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF748096)),
            )
          else
            Column(
              children: rows.map((_AuxOperationRow row) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7ECF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        row.auxiliar,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF243247),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.expectedLine,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF556074),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ubicacion real: ${row.liveLocationLine}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF748096),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estado: ${row.stateLine}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF748096),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  List<_AuxOperationRow> _buildAuxOperationRows({
    required DateTime now,
    required List<_AgendaVisitItem> source,
  }) {
    final Map<String, List<_AgendaVisitItem>> byAuxiliar =
        <String, List<_AgendaVisitItem>>{};

    for (final _AgendaVisitItem item in source) {
      final String auxiliar = item.personalAsignado.trim();
      if (auxiliar.isEmpty) continue;
      byAuxiliar.putIfAbsent(auxiliar, () => <_AgendaVisitItem>[]).add(item);
    }

    final List<_AuxOperationRow> rows = <_AuxOperationRow>[];
    for (final MapEntry<String, List<_AgendaVisitItem>> entry
        in byAuxiliar.entries) {
      final List<_AgendaVisitItem> visits = entry.value
        ..sort((a, b) => _hourToInt(a.hora).compareTo(_hourToInt(b.hora)));

      final _AgendaVisitItem? expected = _expectedVisitNow(visits, now);
      final _VisitOperationalStatus? latest = _latestStatus(visits);

      if (expected == null) {
        rows.add(
          _AuxOperationRow(
            auxiliar: entry.key,
            expectedLine: 'Sin visita activa en este momento.',
            liveLocationLine: latest?.locationSnapshot ?? 'Sin actualizacion',
            stateLine: latest == null
                ? 'Sin reporte'
                : '${_labelForState(latest.state)} · ${_formatShortTime(latest.onlineAt ?? latest.reportedAt)}',
          ),
        );
        continue;
      }

      final DateTime start = _visitDateTime(expected)!;
      final DateTime end = start.add(const Duration(minutes: 45));
      rows.add(
        _AuxOperationRow(
          auxiliar: entry.key,
          expectedLine:
              'Debería estar: ${_AgendaFormatters.toTitleCase(expected.paciente)} · ${_AgendaFormatters.toTitleCase(expected.barrio ?? expected.direccion)} · ${_formatShortTime(start)}-${_formatShortTime(end)}',
          liveLocationLine: latest?.locationSnapshot ?? 'Sin actualizacion',
          stateLine: latest == null
              ? 'Sin reporte'
              : '${_labelForState(latest.state)} · ${_formatShortTime(latest.onlineAt ?? latest.reportedAt)}',
        ),
      );
    }

    rows.sort((a, b) => a.auxiliar.compareTo(b.auxiliar));
    return rows;
  }

  _AgendaVisitItem? _expectedVisitNow(
    List<_AgendaVisitItem> visits,
    DateTime now,
  ) {
    for (final _AgendaVisitItem item in visits) {
      final DateTime? start = _visitDateTime(item);
      if (start == null) continue;
      final DateTime end = start.add(const Duration(minutes: 45));
      if (!now.isBefore(start) && now.isBefore(end)) {
        return item;
      }
    }

    for (final _AgendaVisitItem item in visits) {
      final DateTime? start = _visitDateTime(item);
      if (start != null && now.isBefore(start)) {
        return item;
      }
    }

    return visits.isNotEmpty ? visits.last : null;
  }

  _VisitOperationalStatus? _latestStatus(List<_AgendaVisitItem> visits) {
    _VisitOperationalStatus? latest;
    DateTime? latestAt;

    for (final _AgendaVisitItem item in visits) {
      final _VisitOperationalStatus? status =
          _visitOperational[_visitKey(item)];
      if (status == null) continue;
      final DateTime? when = status.onlineAt ?? status.reportedAt;
      if (when == null) continue;
      if (latestAt == null || when.isAfter(latestAt)) {
        latest = status;
        latestAt = when;
      }
    }

    return latest;
  }

  String _labelForState(_VisitFlowState state) {
    switch (state) {
      case _VisitFlowState.pendiente:
        return 'Pendiente';
      case _VisitFlowState.enRuta:
        return 'En ruta';
      case _VisitFlowState.llego:
        return 'Llego';
      case _VisitFlowState.enAtencion:
        return 'En atencion';
      case _VisitFlowState.finalizada:
        return 'Finalizada';
    }
  }

  String _formatShortTime(DateTime? time) {
    if (time == null) return '--:--';
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openMap(String address) async {
    final String query = Uri.encodeComponent('$address, Cartagena');
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir Maps.')),
      );
    }
  }
}

class _AgendaGrid extends StatelessWidget {
  final List<_AgendaRowData> rows;
  final String emptyMessage;
  final _ResponsibleSummary Function(_AgendaVisitItem item) resolveResponsible;
  final ValueChanged<_AgendaVisitItem> onEditLocation;
  final ValueChanged<_AgendaVisitItem> onVerifyLocation;
  final ValueChanged<_AgendaVisitItem> onOpenVerifiedMap;

  const _AgendaGrid({
    required this.rows,
    required this.emptyMessage,
    required this.resolveResponsible,
    required this.onEditLocation,
    required this.onVerifyLocation,
    required this.onOpenVerifiedMap,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE3EA)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Text(
            emptyMessage,
            style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tableWidth =
            constraints.maxWidth > _AgendaTableMetrics.minTotalWidth
                ? constraints.maxWidth
                : _AgendaTableMetrics.minTotalWidth;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE3EA)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE7ECF1))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: const _AgendaTableHeader(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE7ECF1),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return _AgendaTableRow(
                          row: rows[index],
                          resolveResponsible: resolveResponsible,
                          onEditLocation: onEditLocation,
                          onVerifyLocation: onVerifyLocation,
                          onOpenVerifiedMap: onOpenVerifiedMap,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AgendaTableHeader extends StatelessWidget {
  const _AgendaTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeaderCell('HORA', width: _AgendaTableMetrics.hora),
        _HeaderCell('PACIENTE', width: _AgendaTableMetrics.paciente),
        _HeaderCell('DIAGNÓSTICO', width: _AgendaTableMetrics.dx),
        _HeaderCell(
          'ACTIVIDAD/TRATAMIENTO',
          width: _AgendaTableMetrics.tratamiento,
        ),
        _HeaderCell('DIRECCIÓN', width: _AgendaTableMetrics.direccion),
        _HeaderCell('CONTACTO', width: _AgendaTableMetrics.contacto),
        _HeaderCell(
          'RESPONSABLE',
          width: _AgendaTableMetrics.personalAsignado,
          isLast: true,
        ),
      ],
    );
  }
}

class _AgendaTableRow extends StatelessWidget {
  final _AgendaRowData row;
  final _ResponsibleSummary Function(_AgendaVisitItem item) resolveResponsible;
  final ValueChanged<_AgendaVisitItem> onEditLocation;
  final ValueChanged<_AgendaVisitItem> onVerifyLocation;
  final ValueChanged<_AgendaVisitItem> onOpenVerifiedMap;

  const _AgendaTableRow({
    required this.row,
    required this.resolveResponsible,
    required this.onEditLocation,
    required this.onVerifyLocation,
    required this.onOpenVerifiedMap,
  });

  @override
  Widget build(BuildContext context) {
    final _AgendaVisitItem? item = row.item;
    final bool isEmpty = item == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _BodyCell(
            text: row.hora,
            width: _AgendaTableMetrics.hora,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF243247),
            ),
          ),
          _CustomBodyCell(
            width: _AgendaTableMetrics.paciente,
            child: isEmpty
                ? const SizedBox.shrink()
                : _AgendaPatientCell(item: item),
          ),
          _BodyCell(
            text: isEmpty
                ? ''
                : _AgendaFormatters.formatDiagnosis(
                    item.dx,
                    fallback: 'Sin diagnóstico',
                  ),
            width: _AgendaTableMetrics.dx,
          ),
          isEmpty
              ? _BodyCell(text: '', width: _AgendaTableMetrics.tratamiento)
              : _CustomBodyCell(
                  width: _AgendaTableMetrics.tratamiento,
                  child: _AgendaTreatmentCell(item: item),
                ),
          isEmpty
              ? _BodyCell(text: '', width: _AgendaTableMetrics.direccion)
              : _CustomBodyCell(
                  width: _AgendaTableMetrics.direccion,
                  child: _AddressBlock(
                    barrio: item.barrio,
                    direccion: item.direccion,
                    referencia: item.referencia,
                    onEditLocation: () => onEditLocation(item),
                    onVerifyLocation: () => onVerifyLocation(item),
                    hasVerifiedCoordinates:
                        item.verifiedLat != null && item.verifiedLng != null,
                    onOpenVerifiedMap:
                        item.verifiedLat != null && item.verifiedLng != null
                            ? () => onOpenVerifiedMap(item)
                            : null,
                  ),
                ),
          isEmpty
              ? const _BodyCell(
                  text: '',
                  width: _AgendaTableMetrics.contacto,
                )
              : _CustomBodyCell(
                  width: _AgendaTableMetrics.contacto,
                  child: _ContactBlock(contacto: item.contacto),
                ),
          isEmpty
              ? const _BodyCell(
                  text: '',
                  width: _AgendaTableMetrics.personalAsignado,
                  isLast: true,
                )
              : _CustomBodyCell(
                  width: _AgendaTableMetrics.personalAsignado,
                  child: _ResponsibleBlock(
                    summary: resolveResponsible(item),
                    compact: true,
                  ),
                ),
        ],
      ),
    );
  }
}

class _AgendaPatientCell extends StatelessWidget {
  final _AgendaVisitItem item;

  const _AgendaPatientCell({
    required this.item,
  });

  String _statusLabel() {
    final String pendiente = item.pendiente.trim();
    final String responsable = item.personalAsignado.trim();

    if (pendiente.isNotEmpty) {
      return 'Pendiente: ${_AgendaFormatters.toTitleCase(pendiente)}';
    }
    if (responsable.isNotEmpty) {
      return 'Visita asignada';
    }
    return 'Asignación pendiente';
  }

  Color _statusColor() {
    final String pendiente = item.pendiente.trim();
    final String responsable = item.personalAsignado.trim();

    if (pendiente.isNotEmpty) {
      return const Color(0xFF8F5A00);
    }
    if (responsable.isNotEmpty) {
      return const Color(0xFF17726D);
    }
    return const Color(0xFF9A6700);
  }

  String _metaLine() {
    final List<String> parts = <String>[];

    if (item.edad != null) {
      parts.add('${item.edad} años');
    }
    if ((item.sexo ?? '').trim().isNotEmpty) {
      parts.add(item.sexo!.trim());
    }
    if ((item.aseguradora ?? '').trim().isNotEmpty) {
      parts.add(item.aseguradora!.trim());
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final _PacienteParts parts = _AgendaFormatters.splitPaciente(item.paciente);
    final Color statusColor = _statusColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                parts.nombre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF243247),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _statusLabel(),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: statusColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (parts.identificacion.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            parts.identificacion,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF748096)),
          ),
        ],
        if (_metaLine().isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            _metaLine(),
            style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
          ),
        ],
      ],
    );
  }
}

class _AgendaTreatmentCell extends StatelessWidget {
  static const int _maxVisibleTreatments = 2;

  const _AgendaTreatmentCell({required this.item});

  final _AgendaVisitItem item;

  bool get _isProcedureEvent => item.motivoKey == 'programacion_procedimiento';

  String _readDetalleTrimmed(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      final String value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  List<String> _readDetalleList(List<dynamic> candidates) {
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
        final List<String> values = value
            .split(RegExp(r'[\n,;]+'))
            .map((String part) => part.trim())
            .where((String part) => part.isNotEmpty)
            .toList();
        if (values.isNotEmpty) {
          return values;
        }
      }
    }
    return <String>[];
  }

  String _procedureName() {
    return _readDetalleTrimmed(<dynamic>[
      item.detalleMotivo['nombreProcedimiento'],
      item.detalleMotivo['procedimientoRequerido'],
      item.detalleMotivo['procedimientoProgramado'],
      item.tratamiento,
    ]);
  }

  String? _procedureAnesthesiologyChip() {
    final String requiere = _readDetalleTrimmed(<dynamic>[
      item.detalleMotivo['requiereAnestesiologia'],
    ]).toLowerCase();
    final String realizada = _readDetalleTrimmed(<dynamic>[
      item.detalleMotivo['anestesiologiaRealizada'],
    ]).toLowerCase();

    if (requiere == 'por_confirmar' || realizada == 'por_confirmar') {
      return 'Anestesiologia por confirmar';
    }
    if (requiere == 'si' && realizada == 'si') {
      return 'Anestesiologia valorada';
    }
    if (requiere == 'si' && realizada != 'si') {
      return 'Anestesiologia pendiente';
    }
    return null;
  }

  List<String> _procedurePendingEvaluationChips() {
    final List<String> values = _readDetalleList(<dynamic>[
      item.detalleMotivo['valoracionesPendientes'],
    ]);
    final Set<String> seen = <String>{};
    final List<String> normalized = <String>[];
    for (final String value in values) {
      final String label = _AgendaFormatters.toTitleCase(value);
      final String key = label.toLowerCase();
      if (label.isEmpty || key.contains('anestesiolog') || !seen.add(key)) {
        continue;
      }
      normalized.add(label);
    }
    return normalized;
  }

  List<String> _procedureChips() {
    return <String>[
      ...?(() {
        final String? chip = _procedureAnesthesiologyChip();
        return chip == null ? null : <String>[chip];
      })(),
      ..._procedurePendingEvaluationChips(),
    ];
  }

  List<_AgendaTreatmentEntry> _treatmentEntries() {
    if (_isProcedureEvent) {
      return <_AgendaTreatmentEntry>[
        _AgendaTreatmentEntry(
          title: 'PROCEDIMIENTO QUIRURGICO',
          secondaryLines: <String>[
            _procedureName().isEmpty
                ? 'Procedimiento sin nombre registrado'
                : _procedureName(),
          ],
          chips: _procedureChips(),
        ),
      ];
    }

    final List<String> tokens = _AgendaFormatters.splitTreatmentTokens(
      item.tratamiento,
      antibioticoDetectado: item.antibioticoDetectado,
    );

    if (tokens.isEmpty) {
      final TreatmentDisplayData display = TreatmentTextFormatter.formatTreatment(
        <String, dynamic>{
          'nombreTratamiento': item.tratamiento,
          'frecuencia':
              item.frecuenciaTratamientoLabel ?? item.frecuenciaTratamiento,
          'pacienteCuentaConInfusor': item.pacienteCuentaConInfusor,
        },
      );
      return <_AgendaTreatmentEntry>[
        _AgendaTreatmentEntry(
          title: display.mainLine,
          secondaryLines: <String>[
            if ((display.frequencyLine ?? '').trim().isNotEmpty)
              display.frequencyLine!,
            if ((display.infusorLine ?? '').trim().isNotEmpty)
              display.infusorLine!,
          ],
          chips: const <String>[],
        ),
      ];
    }

    return tokens
        .map(
          (String token) {
            final TreatmentDisplayData display = TreatmentTextFormatter
                .formatTreatment(<String, dynamic>{
              'nombreTratamiento': token,
              'frecuencia':
                  item.frecuenciaTratamientoLabel ?? item.frecuenciaTratamiento,
              'pacienteCuentaConInfusor': item.pacienteCuentaConInfusor,
            });
            return _AgendaTreatmentEntry(
              title: display.mainLine,
              secondaryLines: <String>[
                if ((display.frequencyLine ?? '').trim().isNotEmpty)
                  display.frequencyLine!,
                if ((display.infusorLine ?? '').trim().isNotEmpty)
                  display.infusorLine!,
              ],
              chips: const <String>[],
            );
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<_AgendaTreatmentEntry> entries = _treatmentEntries();
    final List<_AgendaTreatmentEntry> visible = entries.take(
      _maxVisibleTreatments,
    ).toList();
    final int hiddenCount = entries.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int index = 0; index < visible.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 10),
          Text(
            visible[index].title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: Color(0xFF243247),
            ),
          ),
          for (int lineIndex = 0;
              lineIndex < visible[index].secondaryLines.length;
              lineIndex++) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              visible[index].secondaryLines[lineIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: lineIndex == 0 ? 12 : 11.5,
                height: 1.2,
                color: lineIndex == 0
                    ? const Color(0xFF5B6474)
                    : const Color(0xFF667085),
              ),
            ),
          ],
          if (visible[index].chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: visible[index].chips
                  .map(
                    (String chip) => _AgendaMetaChip(
                      label: chip,
                      backgroundColor: const Color(0xFFF3F4F6),
                      textColor: const Color(0xFF4B5563),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
        if (hiddenCount > 0) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '+$hiddenCount tratamientos mas',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }
}

class _AgendaTreatmentEntry {
  final String title;
  final List<String> secondaryLines;
  final List<String> chips;

  const _AgendaTreatmentEntry({
    required this.title,
    required this.secondaryLines,
    required this.chips,
  });
}

class _AgendaMetaChip extends StatelessWidget {
  const _AgendaMetaChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _AgendaVisitItem {
  final String fecha;
  final String hora;
  final String paciente;
  final String? patientId;
  final String? visitId;
  final String? pendingId;
  final int? edad;
  final String? sexo;
  final String? aseguradora;
  final String dx;
  final String tratamiento;
  final String? barrio;
  final String direccion;
  final String? referencia;
  final String contacto;
  final String motivoKey;
  final Map<String, dynamic> detalleMotivo;
  final String pendiente;
  final String personalAsignado;
  final DateTime? fechaProbableFinalizacion;
  final String? pacienteCuentaConInfusor;
  final bool antibioticoCandidatoInfusor;
  final String? antibioticoDetectado;
  final bool requiereCambioDiarioInfusor;
  final String? programacionSugerida;
  final String? frecuenciaTratamiento;
  final String? frecuenciaTratamientoLabel;
  final String? tipoActividadAgenda;
  final double? verifiedLat;
  final double? verifiedLng;

  _AgendaVisitItem({
    required this.fecha,
    required this.hora,
    required this.paciente,
    this.patientId,
    this.visitId,
    this.pendingId,
    this.edad,
    this.sexo,
    this.aseguradora,
    required this.dx,
    required this.tratamiento,
    this.barrio,
    required this.direccion,
    this.referencia,
    required this.contacto,
    this.motivoKey = '',
    this.detalleMotivo = const <String, dynamic>{},
    required this.pendiente,
    required this.personalAsignado,
    this.fechaProbableFinalizacion,
    this.pacienteCuentaConInfusor,
    this.antibioticoCandidatoInfusor = false,
    this.antibioticoDetectado,
    this.requiereCambioDiarioInfusor = false,
    this.programacionSugerida,
    this.frecuenciaTratamiento,
    this.frecuenciaTratamientoLabel,
    this.tipoActividadAgenda,
    this.verifiedLat,
    this.verifiedLng,
  });

  _AgendaVisitItem copyWith({
    String? fecha,
    String? hora,
    String? paciente,
    String? patientId,
    String? visitId,
    String? pendingId,
    int? edad,
    String? sexo,
    String? aseguradora,
    String? dx,
    String? tratamiento,
    String? barrio,
    String? direccion,
    String? referencia,
    String? contacto,
    String? motivoKey,
    Map<String, dynamic>? detalleMotivo,
    String? pendiente,
    String? personalAsignado,
    DateTime? fechaProbableFinalizacion,
    String? pacienteCuentaConInfusor,
    bool? antibioticoCandidatoInfusor,
    String? antibioticoDetectado,
    bool? requiereCambioDiarioInfusor,
    String? programacionSugerida,
    String? frecuenciaTratamiento,
    String? frecuenciaTratamientoLabel,
    String? tipoActividadAgenda,
    double? verifiedLat,
    double? verifiedLng,
  }) {
    return _AgendaVisitItem(
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      paciente: paciente ?? this.paciente,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      pendingId: pendingId ?? this.pendingId,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      aseguradora: aseguradora ?? this.aseguradora,
      dx: dx ?? this.dx,
      tratamiento: tratamiento ?? this.tratamiento,
      barrio: barrio ?? this.barrio,
      direccion: direccion ?? this.direccion,
      referencia: referencia ?? this.referencia,
      contacto: contacto ?? this.contacto,
      motivoKey: motivoKey ?? this.motivoKey,
      detalleMotivo: detalleMotivo ?? this.detalleMotivo,
      pendiente: pendiente ?? this.pendiente,
      personalAsignado: personalAsignado ?? this.personalAsignado,
      fechaProbableFinalizacion:
          fechaProbableFinalizacion ?? this.fechaProbableFinalizacion,
      pacienteCuentaConInfusor:
          pacienteCuentaConInfusor ?? this.pacienteCuentaConInfusor,
      antibioticoCandidatoInfusor:
          antibioticoCandidatoInfusor ?? this.antibioticoCandidatoInfusor,
      antibioticoDetectado: antibioticoDetectado ?? this.antibioticoDetectado,
      requiereCambioDiarioInfusor:
          requiereCambioDiarioInfusor ?? this.requiereCambioDiarioInfusor,
      programacionSugerida: programacionSugerida ?? this.programacionSugerida,
      frecuenciaTratamiento:
          frecuenciaTratamiento ?? this.frecuenciaTratamiento,
      frecuenciaTratamientoLabel:
          frecuenciaTratamientoLabel ?? this.frecuenciaTratamientoLabel,
      tipoActividadAgenda: tipoActividadAgenda ?? this.tipoActividadAgenda,
      verifiedLat: verifiedLat ?? this.verifiedLat,
      verifiedLng: verifiedLng ?? this.verifiedLng,
    );
  }
}

class _AgendaRowData {
  final String hora;
  final _AgendaVisitItem? item;

  _AgendaRowData({required this.hora, this.item});
}

class _AgendaPdfRow {
  const _AgendaPdfRow({
    required this.orden,
    required this.hora,
    required this.paciente,
    required this.tratamiento,
    required this.actividad,
    required this.barrio,
    required this.direccion,
    required this.referencia,
    required this.contacto,
    required this.responsable,
    required this.responsableRol,
    required this.estado,
  });

  final String orden;
  final String hora;
  final String paciente;
  final String tratamiento;
  final String actividad;
  final String barrio;
  final String direccion;
  final String referencia;
  final String contacto;
  final String responsable;
  final String responsableRol;
  final String estado;
}

class _PacienteParts {
  final String nombre;
  final String identificacion;

  const _PacienteParts({required this.nombre, required this.identificacion});
}

class _AgendaFormatters {
  static String normalizeSpace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String toTitleCase(String text, {String fallback = ''}) {
    final String normalized = normalizeSpace(text);
    if (normalized.isEmpty) return fallback;
    return normalized
        .split(' ')
        .map((String word) {
          if (word.isEmpty) return word;
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String toSentenceCase(String text, {String fallback = ''}) {
    final String normalized = normalizeSpace(text);
    if (normalized.isEmpty) return fallback;
    final String lower = normalized.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  static String formatDiagnosis(String text, {String fallback = ''}) {
    final String normalized = DiagnosisTextFormatter.formatForAgenda(text);
    return normalized.trim().isEmpty ? fallback : normalized;
  }

  static List<String> splitTreatmentTokens(
    String text, {
    String? antibioticoDetectado,
  }) {
    final Set<String> seen = <String>{};
    final List<String> tokens = <String>[];

    void addToken(String value) {
      final String normalized = normalizeSpace(value)
          .replaceAll(RegExp(r'^[\-\u2022]+'), '')
          .trim();
      if (normalized.isEmpty) return;
      final String key = normalized.toLowerCase();
      if (!seen.add(key)) return;
      tokens.add(normalized);
    }

    for (final String part in text.split(RegExp(r'[\n;,]+'))) {
      for (final String token in part.split('·')) {
        addToken(token);
      }
    }

    addToken(antibioticoDetectado ?? '');
    return tokens;
  }

  static String formatContact(String text, {String fallback = ''}) {
    final String normalized = normalizeSpace(text);
    if (normalized.isEmpty) return fallback;
    return normalized.replaceAll(' + ', ' · ').replaceAll(' - ', ' · ');
  }

  static _PacienteParts splitPaciente(String raw) {
    final String normalized = normalizeSpace(raw);
    final RegExp ccRegex = RegExp(
      r'^(.*?)\s+(CC|TI|NIT|CE|PA|RC|MS|AS)\s+(\d+)',
      caseSensitive: false,
    );
    final RegExpMatch? match = ccRegex.firstMatch(normalized);

    if (match != null) {
      final String nombreRaw = match.group(1) ?? '';
      final String tipoDoc = (match.group(2) ?? '').toUpperCase();
      final String numDoc = match.group(3) ?? '';
      return _PacienteParts(
        nombre: normalizeSpace(nombreRaw).toUpperCase(),
        identificacion: '$tipoDoc $numDoc',
      );
    }

    return _PacienteParts(
      nombre: normalized.toUpperCase(),
      identificacion: '',
    );
  }
}

class _AgendaTableMetrics {
  static const double columnGap = 12;
  static const int columnCount = 7;
  static const double hora = 70;
  static const double paciente = 190;
  static const double dx = 280;
  static const double tratamiento = 300;
  static const double direccion = 280;
  static const double contacto = 200;
  static const double personalAsignado = 200;

  static const double minTotalWidth =
      hora +
      paciente +
      dx +
      tratamiento +
      direccion +
      contacto +
      personalAsignado +
      ((columnCount - 1) * columnGap);
}

enum _VisitFlowState { pendiente, enRuta, llego, enAtencion, finalizada }

class _VisitOperationalStatus {
  final _VisitFlowState state;
  final DateTime? reportedAt;
  final DateTime? onlineAt;
  final String? locationSnapshot;

  const _VisitOperationalStatus({
    required this.state,
    this.reportedAt,
    this.onlineAt,
    this.locationSnapshot,
  });

  _VisitOperationalStatus copyWith({
    _VisitFlowState? state,
    DateTime? reportedAt,
    DateTime? onlineAt,
    String? locationSnapshot,
  }) {
    return _VisitOperationalStatus(
      state: state ?? this.state,
      reportedAt: reportedAt ?? this.reportedAt,
      onlineAt: onlineAt ?? this.onlineAt,
      locationSnapshot: locationSnapshot ?? this.locationSnapshot,
    );
  }
}

class _AuxOperationRow {
  final String auxiliar;
  final String expectedLine;
  final String liveLocationLine;
  final String stateLine;

  const _AuxOperationRow({
    required this.auxiliar,
    required this.expectedLine,
    required this.liveLocationLine,
    required this.stateLine,
  });
}

class _ResponsibleSummary {
  const _ResponsibleSummary({
    required this.displayName,
    required this.roleLabel,
    required this.activityLabel,
    required this.isAssigned,
  });

  final String displayName;
  final String roleLabel;
  final String activityLabel;
  final bool isAssigned;
}

class _ResponsibleBlock extends StatelessWidget {
  const _ResponsibleBlock({required this.summary, this.compact = false});

  final _ResponsibleSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color roleColor = summary.isAssigned
        ? const Color(0xFF667085)
        : const Color(0xFF9A6700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          summary.displayName,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243247),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          summary.roleLabel,
          maxLines: 1,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: roleColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          summary.activityLabel,
          maxLines: 1,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.2,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

class _MobileVisitCard extends StatelessWidget {
  const _MobileVisitCard({
    required this.item,
    required this.responsibleSummary,
    required this.state,
    required this.collapsed,
    required this.onStateTap,
    required this.onOpenMap,
    required this.onPingLocation,
    required this.onEditLocation,
    required this.onVerifyLocation,
    this.onOpenVerifiedMap,
  });

  final _AgendaVisitItem item;
  final _ResponsibleSummary responsibleSummary;
  final _VisitOperationalStatus state;
  final bool collapsed;
  final ValueChanged<_VisitFlowState> onStateTap;
  final VoidCallback onOpenMap;
  final VoidCallback onPingLocation;
  final VoidCallback onEditLocation;
  final VoidCallback onVerifyLocation;
  final VoidCallback? onOpenVerifiedMap;

  Color get _stateColor {
    switch (state.state) {
      case _VisitFlowState.pendiente:
        return const Color(0xFF2F6FA3);
      case _VisitFlowState.enRuta:
        return const Color(0xFF9A6700);
      case _VisitFlowState.llego:
        return const Color(0xFF0B6A67);
      case _VisitFlowState.enAtencion:
        return const Color(0xFF17726D);
      case _VisitFlowState.finalizada:
        return const Color(0xFF667085);
    }
  }

  String get _stateLabel {
    switch (state.state) {
      case _VisitFlowState.pendiente:
        return 'Pendiente';
      case _VisitFlowState.enRuta:
        return 'En ruta';
      case _VisitFlowState.llego:
        return 'Llegó';
      case _VisitFlowState.enAtencion:
        return 'En atención';
      case _VisitFlowState.finalizada:
        return 'Finalizada';
    }
  }

  String _nextLabel(_VisitFlowState next) {
    switch (next) {
      case _VisitFlowState.enRuta:
        return 'En ruta';
      case _VisitFlowState.llego:
        return 'Llegué';
      case _VisitFlowState.enAtencion:
        return 'En atención';
      case _VisitFlowState.finalizada:
        return 'Finalizar';
      case _VisitFlowState.pendiente:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final _PacienteParts parts = _AgendaFormatters.splitPaciente(item.paciente);
    final List<_VisitFlowState> quickActions = <_VisitFlowState>[
      _VisitFlowState.enRuta,
      _VisitFlowState.llego,
      _VisitFlowState.enAtencion,
      _VisitFlowState.finalizada,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: collapsed ? const Color(0xFFF8FAFC) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                item.hora,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF243247),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _stateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _stateLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _stateColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            parts.nombre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 4),
          _AddressBlock(
            barrio: item.barrio,
            direccion: item.direccion,
            referencia: item.referencia,
            compact: true,
            onEditLocation: onEditLocation,
            onVerifyLocation: onVerifyLocation,
            hasVerifiedCoordinates:
                item.verifiedLat != null && item.verifiedLng != null,
            onOpenVerifiedMap: onOpenVerifiedMap,
          ),
          const SizedBox(height: 8),
          const Text(
            'CONTACTO',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Color(0xFF98A2B3),
            ),
          ),
          const SizedBox(height: 6),
          _ContactBlock(contacto: item.contacto),
          const SizedBox(height: 10),
          const Text(
            'RESPONSABLE',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Color(0xFF98A2B3),
            ),
          ),
          const SizedBox(height: 6),
          _ResponsibleBlock(summary: responsibleSummary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Maps'),
              ),
              OutlinedButton.icon(
                onPressed: onPingLocation,
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: const Text('Actualizar ubicacion'),
              ),
              OutlinedButton.icon(
                onPressed: onEditLocation,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: const Text('Editar ubicación y contactos'),
              ),
              OutlinedButton.icon(
                onPressed: onVerifyLocation,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Verificar en sitio'),
              ),
              if (!collapsed)
                ...quickActions.map((action) {
                  final bool selected = state.state == action;
                  return FilledButton.tonal(
                    onPressed: () => onStateTap(action),
                    style: FilledButton.styleFrom(
                      backgroundColor: selected
                          ? _stateColor.withValues(alpha: 0.2)
                          : const Color(0xFFF2F4F7),
                      foregroundColor:
                          selected ? _stateColor : const Color(0xFF364152),
                    ),
                    child: Text(_nextLabel(action)),
                  );
                }),
            ],
          ),
          if (state.reportedAt != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Ultimo cambio: ${state.reportedAt!.hour.toString().padLeft(2, '0')}:${state.reportedAt!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF748096)),
            ),
          ],
          if (state.onlineAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'En linea: ${state.onlineAt!.hour.toString().padLeft(2, '0')}:${state.onlineAt!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF748096)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientLocationContact {
  const _PatientLocationContact({
    required this.nombre,
    required this.telefono,
    required this.parentesco,
    required this.esPrincipal,
  });

  final String nombre;
  final String telefono;
  final String parentesco;
  final bool esPrincipal;

  bool get isEmpty =>
      nombre.trim().isEmpty &&
      telefono.trim().isEmpty &&
      parentesco.trim().isEmpty;

  bool get isComplete =>
      nombre.trim().isNotEmpty &&
      telefono.trim().isNotEmpty &&
      parentesco.trim().isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'nombre': nombre.trim(),
    'telefono': telefono.trim(),
    'parentesco': parentesco.trim(),
    'esPrincipal': esPrincipal,
  };

  String toSummary() {
    final List<String> parts = <String>[];
    if (nombre.trim().isNotEmpty) {
      parts.add(nombre.trim());
    }
    if (parentesco.trim().isNotEmpty) {
      parts.add(parentesco.trim());
    }
    if (telefono.trim().isNotEmpty) {
      parts.add(telefono.trim());
    }
    return parts.join(' · ');
  }
}

class _PatientLocationPayload {
  const _PatientLocationPayload({
    required this.direccionAdministrativa,
    required this.barrio,
    required this.referenciaAdministrativa,
    required this.contactos,
    required this.observacionesAcceso,
  });

  final String direccionAdministrativa;
  final String barrio;
  final String referenciaAdministrativa;
  final List<_PatientLocationContact> contactos;
  final String observacionesAcceso;

  bool get hasMinimumOperativeData =>
      direccionAdministrativa.trim().isNotEmpty &&
      contactos.any((contact) => contact.isComplete);

  String get estadoUbicacion =>
      hasMinimumOperativeData
          ? 'completa_administrativa'
          : 'pendiente_administrativa';

  String get contactSummary {
    final List<_PatientLocationContact> ordered = contactos
        .where((contact) => !contact.isEmpty)
        .toList()
      ..sort((a, b) {
        if (a.esPrincipal == b.esPrincipal) {
          return 0;
        }
        return a.esPrincipal ? -1 : 1;
      });
    return ordered
        .map((contact) => contact.toSummary())
        .where((line) => line.trim().isNotEmpty)
        .join(' | ');
  }

  Map<String, dynamic> toFirestoreMap() => <String, dynamic>{
    'direccionAdministrativa': direccionAdministrativa.trim(),
    'barrio': barrio.trim(),
    'referenciaAdministrativa': referenciaAdministrativa.trim(),
    'contactos': contactos
        .where((contact) => !contact.isEmpty)
        .map((contact) => contact.toMap())
        .toList(),
    'observacionesAcceso': observacionesAcceso.trim(),
    'estadoUbicacion': estadoUbicacion,
  };
}

class _SiteVerificationPayload {
  const _SiteVerificationPayload({
    required this.confirmada,
    required this.lat,
    required this.lng,
    required this.direccionGeocodificada,
    required this.referenciaReal,
  });

  final bool confirmada;
  final double lat;
  final double lng;
  final String direccionGeocodificada;
  final String referenciaReal;

  Map<String, dynamic> toFirestoreMap() => <String, dynamic>{
    'confirmada': confirmada,
    'lat': lat,
    'lng': lng,
    'direccionReal': '',
    'direccionGeocodificada': direccionGeocodificada.trim(),
    'referenciaReal': referenciaReal.trim(),
    'contactoEfectivo': '',
    'observacion': '',
  };
}

class _VerifyLocationDialog extends StatefulWidget {
  const _VerifyLocationDialog({
    required this.patientName,
    required this.initialData,
  });

  final String patientName;
  final Map<String, dynamic> initialData;

  @override
  State<_VerifyLocationDialog> createState() => _VerifyLocationDialogState();
}

class _VerifyLocationDialogState extends State<_VerifyLocationDialog> {
  GoogleMapController? _mapController;
  late final TextEditingController _referenciaRealController;
  late LatLng _selectedLatLng;
  String _direccionGeocodificada = '';
  bool _saving = false;
  bool _loadingCurrentLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> verificacion =
        widget.initialData['verificacionEnSitio'] is Map
            ? Map<String, dynamic>.from(
                widget.initialData['verificacionEnSitio'] as Map,
              )
            : <String, dynamic>{};
    final double? lat = _readCoordinate(verificacion['lat']);
    final double? lng = _readCoordinate(verificacion['lng']);
    _selectedLatLng = lat != null && lng != null
        ? LatLng(lat, lng)
        : _AgendaScreenState._defaultMapCenter;
    _direccionGeocodificada =
        (verificacion['direccionGeocodificada'] ?? '').toString();
    _referenciaRealController = TextEditingController(
      text: (verificacion['referenciaReal'] ?? '').toString(),
    );
    unawaited(_bootstrapEmbeddedMap());
  }

  @override
  void dispose() {
    _referenciaRealController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  static double? _readCoordinate(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw == null) {
      return null;
    }
    return double.tryParse(raw.toString().trim());
  }

  Future<void> _initializeMapSelection() async {
    await _moveToCurrentLocation();
    await _reverseGeocode(_selectedLatLng, moveCamera: false);
    if (mounted) {
      setState(() {
        _loadingCurrentLocation = false;
      });
    }
  }

  Future<void> _bootstrapEmbeddedMap() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _locationError =
              'El mapa embebido no está disponible en web. Usa tu ubicación actual o abre Google Maps para validar el punto.';
        });
      }

      await _initializeMapSelection();
      return;
    }

    await _initializeMapSelection();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError =
                'GPS no disponible. Puedes mover el pin manualmente.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError =
                'Sin permiso de ubicación. Puedes mover el pin manualmente.';
          });
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();
      final LatLng next = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLatLng = next;
        _locationError = null;
      });
      await _mapController?.animateCamera(CameraUpdate.newLatLng(next));
      await _reverseGeocode(next, moveCamera: false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError =
              'No fue posible obtener tu ubicación. Puedes mover el pin manualmente.';
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng target, {bool moveCamera = true}) async {
    if (mounted) {
      setState(() {
        _selectedLatLng = target;
      });
    }
    if (moveCamera) {
      await _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    }
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      final Placemark first = placemarks.first;
      final List<String> parts = <String>[
        first.street ?? '',
        first.subLocality ?? '',
        first.locality ?? '',
      ].where((part) => part.trim().isNotEmpty).toList();
      if (!mounted) return;
      setState(() {
        _direccionGeocodificada = parts.join(', ');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _direccionGeocodificada = '';
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps?q=${_selectedLatLng.latitude},${_selectedLatLng.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _save() {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    Navigator.of(context).pop(
      _SiteVerificationPayload(
        confirmada: true,
        lat: _selectedLatLng.latitude,
        lng: _selectedLatLng.longitude,
        direccionGeocodificada: _direccionGeocodificada,
        referenciaReal: _referenciaRealController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool supportsEmbeddedMap =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Marcar ubicación en sitio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF243247),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _AgendaFormatters.toTitleCase(widget.patientName),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17726D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_locationError != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _locationError!,
                      style: const TextStyle(color: Color(0xFF8F5A00)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 360,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: supportsEmbeddedMap
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLatLng,
                              zoom: 16,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            onTap: (LatLng latLng) {
                              unawaited(_reverseGeocode(latLng));
                            },
                            markers: <Marker>{
                              Marker(
                                markerId: const MarkerId('site-verification'),
                                position: _selectedLatLng,
                                draggable: true,
                                onDragEnd: (LatLng latLng) {
                                  unawaited(_reverseGeocode(latLng, moveCamera: false));
                                },
                              ),
                            },
                          )
                        : Container(
                            color: const Color(0xFFF8FAFC),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              kIsWeb
                                  ? 'No se pudo cargar el mapa. Use coordenadas o abrir en Google Maps.'
                                  : 'El selector de mapa embebido no está disponible en esta plataforma. Usa Google Maps y confirma manualmente el pin.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF667085)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ActionChip(
                      label: Text(
                        'Lat ${_selectedLatLng.latitude.toStringAsFixed(6)}',
                      ),
                      onPressed: null,
                    ),
                    ActionChip(
                      label: Text(
                        'Lng ${_selectedLatLng.longitude.toStringAsFixed(6)}',
                      ),
                      onPressed: null,
                    ),
                    if (_loadingCurrentLocation)
                      const ActionChip(
                        label: Text('Buscando GPS...'),
                        onPressed: null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _moveToCurrentLocation(),
                      icon: const Icon(Icons.my_location_outlined),
                      style: _agendaOutlineButtonStyle(),
                      label: const Text('Usar mi ubicación'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _openGoogleMaps,
                      icon: const Icon(Icons.open_in_new_outlined),
                      style: _agendaOutlineButtonStyle(),
                      label: const Text('Abrir en Google Maps'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_direccionGeocodificada.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7ECF1)),
                    ),
                    child: Text(
                      _direccionGeocodificada,
                      style: const TextStyle(color: Color(0xFF475467)),
                    ),
                  ),
                if (_direccionGeocodificada.trim().isNotEmpty)
                  const SizedBox(height: 12),
                LightInput(
                  controller: _referenciaRealController,
                  label: 'Referencia real opcional',
                  enabled: !_saving,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: _agendaOutlineButtonStyle(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.verified_outlined),
                      style: _agendaPrimaryButtonStyle(),
                      label: const Text('Confirmar ubicación en sitio'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditLocationDialog extends StatefulWidget {
  const _EditLocationDialog({
    required this.patientName,
    required this.initialData,
  });

  final String patientName;
  final Map<String, dynamic> initialData;

  @override
  State<_EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends State<_EditLocationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _direccionController;
  late final TextEditingController _barrioController;
  late final TextEditingController _referenciaController;
  late final TextEditingController _observacionesController;
  late final List<TextEditingController> _contactNameControllers;
  late final List<TextEditingController> _contactPhoneControllers;
  late final List<TextEditingController> _contactRelationControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final List<dynamic> rawContacts = widget.initialData['contactos'] is List
        ? widget.initialData['contactos'] as List<dynamic>
        : const <dynamic>[];
    final List<Map<String, dynamic>> contacts =
        List<Map<String, dynamic>>.generate(
      2,
      (int index) {
        final dynamic raw = index < rawContacts.length ? rawContacts[index] : null;
        if (raw is Map) {
          return <String, dynamic>{
            'nombre': (raw['nombre'] ?? '').toString(),
            'telefono': (raw['telefono'] ?? '').toString(),
            'parentesco': (raw['parentesco'] ?? '').toString(),
            'esPrincipal': raw['esPrincipal'] == true,
          };
        }
        return <String, dynamic>{};
      },
    );

    _direccionController = TextEditingController(
      text: (widget.initialData['direccionAdministrativa'] ?? '').toString(),
    );
    _barrioController = TextEditingController(
      text: (widget.initialData['barrio'] ?? '').toString(),
    );
    _referenciaController = TextEditingController(
      text: (widget.initialData['referenciaAdministrativa'] ?? '').toString(),
    );
    _observacionesController = TextEditingController(
      text: (widget.initialData['observacionesAcceso'] ?? '').toString(),
    );
    _contactNameControllers = contacts
        .map((contact) => TextEditingController(text: (contact['nombre'] ?? '').toString()))
        .toList();
    _contactPhoneControllers = contacts
        .map((contact) => TextEditingController(text: (contact['telefono'] ?? '').toString()))
        .toList();
    _contactRelationControllers = contacts
        .map((contact) => TextEditingController(text: (contact['parentesco'] ?? '').toString()))
        .toList();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _barrioController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    for (final controller in _contactNameControllers) {
      controller.dispose();
    }
    for (final controller in _contactPhoneControllers) {
      controller.dispose();
    }
    for (final controller in _contactRelationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  _PatientLocationPayload _buildPayload() {
    final int principalIndex = List<int>.generate(2, (int index) => index)
        .firstWhere(
          (int index) {
            final String nombre = _contactNameControllers[index].text.trim();
            final String telefono = _contactPhoneControllers[index].text.trim();
            final String parentesco =
                _contactRelationControllers[index].text.trim();
            return nombre.isNotEmpty ||
                telefono.isNotEmpty ||
                parentesco.isNotEmpty;
          },
          orElse: () => 0,
        );
    final List<_PatientLocationContact> contactos =
        List<_PatientLocationContact>.generate(
      2,
      (int index) => _PatientLocationContact(
        nombre: _contactNameControllers[index].text,
        telefono: _contactPhoneControllers[index].text,
        parentesco: _contactRelationControllers[index].text,
        esPrincipal: index == principalIndex,
      ),
    );
    return _PatientLocationPayload(
      direccionAdministrativa: _direccionController.text,
      barrio: _barrioController.text,
      referenciaAdministrativa: _referenciaController.text,
      contactos: contactos,
      observacionesAcceso: _observacionesController.text,
    );
  }

  void _save() {
    if (_saving) return;
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final _PatientLocationPayload payload = _buildPayload();
    if (!payload.hasMinimumOperativeData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes registrar dirección completa y al menos un contacto completo.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    Navigator.of(context).pop(payload);
  }

  String? _validateContactField(int index, String? value, String field) {
    final String nombre = _contactNameControllers[index].text.trim();
    final String telefono = _contactPhoneControllers[index].text.trim();
    final String parentesco = _contactRelationControllers[index].text.trim();
    final bool anyFilled =
        nombre.isNotEmpty || telefono.isNotEmpty || parentesco.isNotEmpty;
    if (!anyFilled) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return '$field requerido';
    }
    return null;
  }

  Widget _buildContactSection({
    required String title,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 12),
          LightInput(
            controller: _contactNameControllers[index],
            label: 'Nombre',
            enabled: !_saving,
            validator: (value) => _validateContactField(index, value, 'Nombre'),
          ),
          const SizedBox(height: 12),
          LightInput(
            controller: _contactPhoneControllers[index],
            label: 'Teléfono',
            enabled: !_saving,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                _validateContactField(index, value, 'Teléfono'),
          ),
          const SizedBox(height: 12),
          LightInput(
            controller: _contactRelationControllers[index],
            label: 'Parentesco',
            enabled: !_saving,
            validator: (value) =>
                _validateContactField(index, value, 'Parentesco'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFields(BoxConstraints constraints) {
    final bool singleColumn = constraints.maxWidth < 620;

    if (singleColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildContactSection(title: 'Contacto 1', index: 0),
          const SizedBox(height: 12),
          _buildContactSection(title: 'Contacto 2', index: 1),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: (constraints.maxWidth - 12) / 2,
              child: _buildContactSection(title: 'Contacto 1', index: 0),
            ),
            SizedBox(
              width: (constraints.maxWidth - 12) / 2,
              child: _buildContactSection(title: 'Contacto 2', index: 1),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Editar ubicación y contactos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF243247),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Actualiza dirección, referencias de acceso y contactos para la visita domiciliaria.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _AgendaFormatters.toTitleCase(widget.patientName),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF17726D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LightInput(
                    controller: _barrioController,
                    label: 'Barrio',
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 12),
                  LightInput(
                    controller: _direccionController,
                    label: 'Dirección completa',
                    enabled: !_saving,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Dirección requerida'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  LightInput(
                    controller: _referenciaController,
                    label: 'Punto de referencia',
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) =>
                        _buildContactFields(constraints),
                  ),
                  const SizedBox(height: 16),
                  LightInput(
                    controller: _observacionesController,
                    label: 'Observaciones de acceso',
                    enabled: !_saving,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: _agendaOutlineButtonStyle(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: _agendaPrimaryButtonStyle(),
                        child: const Text('Guardar ubicación y contactos'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool isLast;

  const _HeaderCell(this.text, {required this.width, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 12),
        child: Text(
          text,
          maxLines: text == 'ACTIVIDAD/TRATAMIENTO' ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF748096),
          ),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final double width;
  final bool isLast;
  final TextStyle? style;

  const _BodyCell({
    required this.text,
    required this.width,
    this.isLast = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 12),
        child: Text(
          text,
          softWrap: true,
          style: style ??
              const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: Color(0xFF748096),
              ),
        ),
      ),
    );
  }
}

class _CustomBodyCell extends StatelessWidget {
  final double width;
  final Widget child;

  const _CustomBodyCell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: child,
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String? barrio;
  final String direccion;
  final String? referencia;
  final bool compact;
  final VoidCallback? onEditLocation;
  final VoidCallback? onVerifyLocation;
  final VoidCallback? onOpenVerifiedMap;
  final bool hasVerifiedCoordinates;

  const _AddressBlock({
    this.barrio,
    required this.direccion,
    this.referencia,
    this.compact = false,
    this.onEditLocation,
    this.onVerifyLocation,
    this.onOpenVerifiedMap,
    this.hasVerifiedCoordinates = false,
  });

  static String _safeTrimmedText(String? value) {
    return (value ?? '').trim();
  }

  static String _safeTitleCase(String text) {
    try {
      return _AgendaFormatters.toTitleCase(text);
    } catch (_) {
      return _AgendaFormatters.normalizeSpace(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String trimmedBarrio = _safeTrimmedText(barrio);
    final String trimmedDireccion = _safeTrimmedText(direccion);
    final String trimmedReferencia = (referencia ?? '').trim();
    final bool safeCompact = compact;
    final Color accentColor = const Color(0xFF17726D).withValues(alpha: 0.7);
    const TextStyle primaryLineStyle = TextStyle(
      fontSize: 13.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: Color(0xFF243247),
    );
    const TextStyle secondaryLineStyle = TextStyle(
      fontSize: 12,
      height: 1.2,
      color: Color(0xFF667085),
    );
    final String primaryLine = trimmedBarrio.isNotEmpty
      ? trimmedBarrio.toUpperCase()
        : trimmedDireccion.isNotEmpty
      ? _safeTitleCase(trimmedDireccion)
        : 'Ubicación pendiente';
    final String statusLine = hasVerifiedCoordinates
        ? 'Ubicación verificada'
        : trimmedDireccion.isNotEmpty
        ? 'Ubicación registrada'
        : 'Ubicación pendiente';
    final bool showActions = !safeCompact &&
        (onEditLocation != null ||
            onVerifyLocation != null ||
            (hasVerifiedCoordinates && onOpenVerifiedMap != null));
    final List<Widget> actionChildren = <Widget>[];

    if (onEditLocation != null) {
      actionChildren.add(
        _AddressInlineAction(
          icon: Icons.edit_location_alt_outlined,
          label: 'Editar ubicación y contactos',
          onTap: onEditLocation!,
        ),
      );
    }
    if (onVerifyLocation != null) {
      actionChildren.add(
        _AddressInlineAction(
          icon: Icons.fact_check_outlined,
          label: 'Verificar en sitio',
          onTap: onVerifyLocation!,
        ),
      );
    }
    if (hasVerifiedCoordinates && onOpenVerifiedMap != null) {
      actionChildren.add(
        _AddressInlineAction(
          icon: Icons.map_outlined,
          label: 'Ver en mapa',
          onTap: onOpenVerifiedMap!,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.place_outlined,
              size: 16,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.gps_fixed_outlined,
              size: 16,
              color: hasVerifiedCoordinates
                  ? accentColor
                  : const Color(0xFF98A2B3),
            ),
            const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                primaryLine,
                maxLines: safeCompact ? 1 : 2,
                overflow: safeCompact ? TextOverflow.ellipsis : null,
                style: primaryLineStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          statusLine,
          style: secondaryLineStyle.copyWith(color: const Color(0xFF98A2B3)),
        ),
        if (trimmedDireccion.isNotEmpty && trimmedBarrio.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            _safeTitleCase(trimmedDireccion),
            maxLines: safeCompact ? 2 : null,
            overflow: safeCompact ? TextOverflow.ellipsis : null,
            style: secondaryLineStyle,
          ),
        ],
        if (trimmedReferencia.isNotEmpty) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            _safeTitleCase(trimmedReferencia),
            maxLines: safeCompact ? 2 : null,
            overflow: safeCompact ? TextOverflow.ellipsis : null,
            style: secondaryLineStyle.copyWith(color: const Color(0xFF98A2B3)),
          ),
        ],
        if (showActions) ...<Widget>[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: actionChildren,
          ),
        ],
      ],
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.contacto});

  final String contacto;

  ({String name, String phone}) _splitPrimaryContact(String raw) {
    final List<String> parts = raw
        .split('·')
        .map((String item) => _AgendaFormatters.normalizeSpace(item))
        .where((String item) => item.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return (name: '', phone: '');
    }

    final List<String> phones = <String>[];
    final List<String> labels = <String>[];
    for (final String part in parts) {
      final String digits = part.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 7) {
        phones.add(digits);
      } else {
        labels.add(part);
      }
    }

    return (
      name: labels.isEmpty ? parts.first : labels.join(' · '),
      phone: phones.join(' · '),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> contacts = contacto
        .split('|')
        .map((String item) => _AgendaFormatters.normalizeSpace(item))
        .where((String item) => item.isNotEmpty)
        .toList();
    if (contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    final String primaryContact = _AgendaFormatters.formatContact(
      contacts.first,
      fallback: '',
    );
    final ({String name, String phone}) parsed = _splitPrimaryContact(
      primaryContact,
    );
    final int extraContacts = contacts.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (parsed.name.isNotEmpty)
          Text(
            parsed.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF243247),
            ),
          ),
        if (parsed.phone.isNotEmpty) ...<Widget>[
          if (parsed.name.isNotEmpty) const SizedBox(height: 2),
          Text(
            parsed.phone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.2,
              color: Color(0xFF667085),
            ),
          ),
        ] else if (parsed.name.isEmpty)
          Text(
            primaryContact,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF243247),
            ),
          ),
        if (extraContacts > 0) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            extraContacts == 1 ? '+1 contacto' : '+$extraContacts contactos',
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddressInlineAction extends StatelessWidget {
  const _AddressInlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 210),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 16, color: const Color(0xFF17726D)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: HextColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle _agendaOutlineButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF475467),
    side: const BorderSide(color: Color(0xFFD0D5DD)),
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

ButtonStyle _agendaPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: HextColors.primary,
    foregroundColor: Colors.white,
    disabledBackgroundColor: HextColors.borderSoft,
    disabledForegroundColor: HextColors.textMuted,
    overlayColor: HextColors.primarySoft,
    elevation: 0,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}
