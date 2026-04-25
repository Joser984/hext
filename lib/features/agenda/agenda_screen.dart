import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hext/core/models/auxiliar_domiciliario.dart';
import 'package:hext/core/repositories/in_memory_personal_repo.dart';
import 'package:hext/features/agenda/data/agenda_repo.dart';
import 'package:hext/features/agenda/domain/agenda_shift_assigner.dart';
import 'package:hext/features/schedule/horarios_screen.dart';
import 'package:hext/shared/widgets/agenda_subnav.dart';
import 'package:hext/shared/widgets/filter_shell.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:hext/shared/widgets/module_header.dart';
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
  final AgendaRepo _agendaRepo = FirestoreAgendaRepo();
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
      final DateTime now = DateTime.now();
      _fechaController.text =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });

    _agendaSubscription = _agendaRepo.watchAgendaEvents().listen((
      List<AgendaEventRecord> events,
    ) {
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

    if (_activeAuxiliares.isEmpty) {
      _activeAuxiliares = kHorarioAuxiliaresRegistrados;
    }
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
      paciente: item.patientDisplay,
      patientId: item.patientId,
      visitId: item.id,
      pendingId: null,
      edad: null,
      sexo: null,
      aseguradora: null,
      dx: item.dx,
      tratamiento: item.tratamiento,
      barrio: item.barrio.isEmpty ? null : item.barrio,
      direccion: item.direccion,
      referencia: item.referencia.isEmpty ? null : item.referencia,
      contacto: item.contacto,
      pendiente: item.estadoAgenda,
      personalAsignado: item.responsableNombre ?? '',
    );
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
      pendiente: item.pendiente,
      personalAsignado: item.personalAsignado,
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
      pendiente: item.pendiente,
      personalAsignado: item.personalAsignado,
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
    return _resolvedVisits.where((_AgendaVisitItem item) {
      final String query = _buscarController.text.trim().toLowerCase();
      final String fecha = _fechaController.text.trim();

      final bool matchesQuery =
          query.isEmpty ||
          item.paciente.toLowerCase().contains(query) ||
          item.dx.toLowerCase().contains(query) ||
          item.tratamiento.toLowerCase().contains(query) ||
          item.direccion.toLowerCase().contains(query) ||
          item.contacto.toLowerCase().contains(query) ||
          item.pendiente.toLowerCase().contains(query) ||
          item.personalAsignado.toLowerCase().contains(query);

      final bool matchesFecha = fecha.isEmpty || item.fecha == fecha;

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

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontalPadding =
              constraints.maxWidth >= 900 ? 16 : 12;
          final double topScrollOffset = constraints.maxWidth >= 900 ? 8 : 6;

          return Padding(
            padding: EdgeInsets.only(top: topScrollOffset),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ModuleHeader(
                    title: constraints.maxWidth >= 1100
                        ? 'Visitas asistenciales'
                        : 'Agenda asistencial',
                    subtitle:
                        'Gestión de visitas, seguimiento operativo y control diario.',
                  ),
                  const SizedBox(height: 8),
                  const AgendaSubnav(section: AgendaSubnavSection.visitas),
                  const SizedBox(height: 10),
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
                        emptyMessage: _hasLinkedIdentifiers
                            ? 'No se encontró una visita asociada a este pendiente.'
                            : 'No hay registros para mostrar.',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
                backgroundColor: const Color(0xFF17726D),
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
              selectedBackgroundColor: const Color(0xFF0F766E),
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
      _fechaController.clear();
      _turnoFiltro = 'Todos';
      _pendienteFiltro = 'Todos';
      _personalFiltro = 'Todos';
    });
  }

  void _exportAgendaPdf() {
    final String fileName = _buildAgendaPdfFileName();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exportando: $fileName')));
  }

  String _buildAgendaPdfFileName() {
    final DateTime date =
        _tryParseDate(_fechaController.text) ?? DateTime.now();
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String dateToken = '$day-$month-$year';

    final String nameToken = _slugifyName(_buscarController.text);
    if (nameToken.isEmpty) {
      return 'Agenda_$dateToken.pdf';
    }

    return 'Agenda_${dateToken}_$nameToken.pdf';
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
                  state: _stateFor(item),
                  collapsed: collapsedStyle,
                  onStateTap: (_VisitFlowState next) =>
                      _updateVisitState(item: item, nextState: next),
                  onOpenMap: () => _openMap(item.direccion),
                  onPingLocation: () => _pingLocation(item),
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

  const _AgendaGrid({required this.rows, required this.emptyMessage});

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
                        return _AgendaTableRow(row: rows[index]);
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

  const _AgendaTableRow({required this.row});

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
          _BodyCell(
            text: isEmpty
                ? ''
                : _AgendaFormatters.summarizeTreatment(
                    item.tratamiento,
                    fallback: 'Sin actividad',
                  ),
            width: _AgendaTableMetrics.tratamiento,
          ),
          isEmpty
              ? _BodyCell(text: '', width: _AgendaTableMetrics.direccion)
              : _CustomBodyCell(
                  width: _AgendaTableMetrics.direccion,
                  child: _AddressBlock(
                    barrio: item.barrio,
                    direccion: item.direccion,
                    referencia: item.referencia,
                  ),
                ),
          _BodyCell(
            text: isEmpty
                ? ''
                : _AgendaFormatters.formatContact(
                    item.contacto,
                    fallback: '--',
                  ),
            width: _AgendaTableMetrics.contacto,
          ),
          _BodyCell(
            text: isEmpty
                ? ''
                : _AgendaFormatters.toTitleCase(
                    item.personalAsignado,
                    fallback: '--',
                  ),
            width: _AgendaTableMetrics.personalAsignado,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _AgendaPatientCell extends StatelessWidget {
  final _AgendaVisitItem item;

  const _AgendaPatientCell({required this.item});

  String _statusLabel() {
    final String pendiente = item.pendiente.trim();
    final String responsable = item.personalAsignado.trim();

    if (pendiente.isNotEmpty) {
      return 'Pendiente: ${_AgendaFormatters.toTitleCase(pendiente)}';
    }
    if (responsable.isNotEmpty) {
      return 'Visita asignada';
    }
    return 'Visita programada';
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
    return const Color(0xFF2F6FA3);
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

    return parts.isEmpty ? '--' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final _PacienteParts parts = _AgendaFormatters.splitPaciente(item.paciente);
    final Color statusColor = _statusColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          parts.nombre,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF243247),
          ),
        ),
        const SizedBox(height: 4),
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
          const SizedBox(height: 8),
          Text(
            parts.identificacion,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF748096)),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _metaLine(),
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
        ),
      ],
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
  final String pendiente;
  final String personalAsignado;

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
    required this.pendiente,
    required this.personalAsignado,
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
    String? pendiente,
    String? personalAsignado,
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
      pendiente: pendiente ?? this.pendiente,
      personalAsignado: personalAsignado ?? this.personalAsignado,
    );
  }
}

class _AgendaRowData {
  final String hora;
  final _AgendaVisitItem? item;

  _AgendaRowData({required this.hora, this.item});
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
    final String normalized = normalizeSpace(text);
    if (normalized.isEmpty) return fallback;

    final List<String> parts = normalized
        .split(RegExp(r'\s+\+\s+'))
        .map((String e) => toSentenceCase(e.trim()))
        .where((String e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return fallback;
    if (parts.length == 1) return parts.first;

    return parts.join(' +\n');
  }

  static String summarizeTreatment(String text, {String fallback = ''}) {
    final List<String> parts = text
        .split('·')
        .map((String e) => normalizeSpace(e))
        .where((String e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return fallback;

    final int take = parts.length >= 2 ? 2 : 1;
    final String summary = parts.take(take).map(toSentenceCase).join(' · ');
    return parts.length > take ? '$summary…' : summary;
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
        nombre: toTitleCase(nombreRaw),
        identificacion: '$tipoDoc $numDoc',
      );
    }

    return _PacienteParts(nombre: toTitleCase(normalized), identificacion: '');
  }
}

class _AgendaTableMetrics {
  static const double hora = 78;
  static const double paciente = 280;
  static const double dx = 355;
  static const double tratamiento = 355;
  static const double direccion = 340;
  static const double contacto = 230;
  static const double personalAsignado = 200;

  static const double minTotalWidth =
      hora +
      paciente +
      dx +
      tratamiento +
      direccion +
      contacto +
      personalAsignado;
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

class _MobileVisitCard extends StatelessWidget {
  const _MobileVisitCard({
    required this.item,
    required this.state,
    required this.collapsed,
    required this.onStateTap,
    required this.onOpenMap,
    required this.onPingLocation,
  });

  final _AgendaVisitItem item;
  final _VisitOperationalStatus state;
  final bool collapsed;
  final ValueChanged<_VisitFlowState> onStateTap;
  final VoidCallback onOpenMap;
  final VoidCallback onPingLocation;

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
                  color: _stateColor.withOpacity(0.12),
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
          Text(
            _AgendaFormatters.toTitleCase(
              item.personalAsignado,
              fallback: 'Sin asignar',
            ),
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF556074)),
          ),
          const SizedBox(height: 4),
          _AddressBlock(
            barrio: item.barrio,
            direccion: item.direccion,
            referencia: item.referencia,
            compact: true,
          ),
          const SizedBox(height: 8),
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
              if (!collapsed)
                ...quickActions.map((action) {
                  final bool selected = state.state == action;
                  return FilledButton.tonal(
                    onPressed: () => onStateTap(action),
                    style: FilledButton.styleFrom(
                      backgroundColor: selected
                          ? _stateColor.withOpacity(0.2)
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

  const _AddressBlock({
    this.barrio,
    required this.direccion,
    this.referencia,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle baseStyle = TextStyle(
      fontSize: 13.5,
      height: 1.35,
      color: Color(0xFF748096),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (barrio != null && barrio!.isNotEmpty)
          Text(
            _AgendaFormatters.toTitleCase(barrio!),
            style: baseStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        Text(
          _AgendaFormatters.toTitleCase(direccion, fallback: 'Sin dirección'),
          style: baseStyle,
        ),
        if (referencia != null && referencia!.isNotEmpty)
          Text(
            _AgendaFormatters.toTitleCase(referencia!),
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: baseStyle.copyWith(
              fontSize: 12.5,
              color: const Color(0xFFA0AEBE),
              height: 1.3,
            ),
          ),
      ],
    );
  }
}