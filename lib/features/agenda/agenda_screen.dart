import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hext/core/models/auxiliar_domiciliario.dart';
import 'package:hext/core/repositories/in_memory_personal_repo.dart';
import 'package:hext/features/schedule/horarios_screen.dart';
import 'package:hext/shared/widgets/agenda_subnav.dart';
import 'package:hext/shared/widgets/filter_shell.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:hext/shared/widgets/module_header.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({
    super.key,
    this.initialSearch,
  });

  final String? initialSearch;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final TextEditingController _buscarController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController(
    text: '30/03/2026',
  );

  String? _turnoFiltro = 'Todos';
  String? _pendienteFiltro = 'Todos';
  String? _personalFiltro = 'Todos';

  List<String> _activeAuxiliares = kHorarioAuxiliaresRegistrados;

  @override
  void initState() {
    super.initState();
    final String seededSearch = widget.initialSearch?.trim() ?? '';
    if (seededSearch.isNotEmpty) {
      _buscarController.text = seededSearch;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final List<AuxiliarDomiciliario> active = context
        .watch<InMemoryPersonalRepo>()
        .items
        .where((AuxiliarDomiciliario a) => a.activo)
        .toList();
    _activeAuxiliares =
        active.map((AuxiliarDomiciliario a) => a.nombreCompleto).toList();
    if (_activeAuxiliares.isEmpty) {
      _activeAuxiliares = kHorarioAuxiliaresRegistrados;
    }
  }



  final List<_AgendaVisitItem> _allVisits = <_AgendaVisitItem>[
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '6:00',
      paciente: 'GLORIA CRISTINA VARGAS DE ROJANO CC 30769875',
      edad: 76,
      sexo: 'F',
      aseguradora: 'Nueva EPS',
      dx: 'CELULITIS MIEMBRO INFERIOR IZQUIERDO + INSUFICIENCIA VENOSA',
      tratamiento:
          'AMLODIPINO TAB 10MG VO CADA DÍA · CARVEDILOL TAB 6.25MG VO CADA 12 HORAS · '
          'LINAGLIPTINA TAB 5MG VO CADA DÍA · TRIMETOPRIM SULFAMETOXAZOL 3 AMP IV CADA 8 HORAS · '
          'FI: 25/03/2026 · FF: 30/03/2026 · PARACETAMOL 1GR IV CADA 8 HORAS',
      direccion: 'BARRIO BOSTON CRR 46 N° 31D - 32',
      contacto: '3245304998 + 3245897047',
      pendiente: '',
      personalAsignado: 'LUIS CASTRO',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '7:00',
      paciente: 'YOVANNE JOSE PEREZ BARRIOS CC 73578984',
      edad: 68,
      sexo: 'F',
      aseguradora: 'Sura',
      dx: 'GLUCOMETRÍAS PRECOMIDAS Y A LAS 9 PM · L031 - CELULITIS DE OTRAS PARTES DE LOS MIEMBROS',
      tratamiento:
          'CLINDAMICINA 600 MG ENDOVENOSO CADA 8 HORAS · PARACETAMOL 1 GR IV CADA 8 HORAS · '
          'ENOXAPARINA 80 MG SC CADA 24 HORAS',
      direccion:
          'LA CAMPIÑA TRV 47 # 23-44 · ENTRANDO POR EL PATILLAZO · 3 CUADRAS EN TODA LA ESQUINA',
      contacto: '3242313723 + 3014541144',
      pendiente: '',
      personalAsignado: '',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '8:00',
      paciente: 'ANA CANDELARIA PEREZ HERRERA CC 33153174',
      edad: 70,
      sexo: 'F',
      aseguradora: 'Coosalud',
      dx: 'L031 - CELULITIS DE OTRAS PARTES DE LOS MIEMBROS + DIABETES',
      tratamiento:
          'TRIMETOPRIM/SULFAMETOXAZOL 3 AMP IV CADA 12 HORAS · PARACETAMOL 1 GR IV CADA 12 HORAS · '
          'LINAGLIPTINA 5 MG VO CADA DÍA + GLUCOMETRÍAS PRECOMIDAS Y A LAS 21 HORAS',
      direccion:
          'TACARIGUA MZ 14 LOTE 20 · REFERENCIA: ENTRANDO POR CLÍNICA BARÚ, AL FINAL AL FRENTE DE LA TIENDA TIZAN 2',
      contacto: '3215261361 + 3222252817',
      pendiente: '',
      personalAsignado: 'LUIS CASTRO',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '14:00',
      paciente: 'ANA CANDELARIA PEREZ HERRERA CC 33153174',
      edad: 70,
      sexo: 'F',
      aseguradora: 'Coosalud',
      dx: 'L031 - CELULITIS DE OTRAS PARTES DE LOS MIEMBROS + DIABETES',
      tratamiento:
          'TRIMETOPRIM/SULFAMETOXAZOL 3 AMP IV CADA 12 HORAS · PARACETAMOL 1 GR IV CADA 12 HORAS · '
          'LINAGLIPTINA 5 MG VO CADA DÍA + GLUCOMETRÍAS PRECOMIDAS Y A LAS 21 HORAS',
      direccion:
          'TACARIGUA MZ 14 LOTE 20 · REFERENCIA: ENTRANDO POR CLÍNICA BARÚ, AL FINAL AL FRENTE DE LA TIENDA TIZAN 2',
      contacto: '3215261361 + 3222252817',
      pendiente: '',
      personalAsignado: '',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '14:00',
      paciente: 'GLORIA CRISTINA VARGAS DE ROJANO CC 30769875',
      edad: 76,
      sexo: 'F',
      aseguradora: 'Nueva EPS',
      dx: 'CELULITIS MIEMBRO INFERIOR IZQUIERDO + INSUFICIENCIA VENOSA',
      tratamiento:
          'AMLODIPINO TAB 10MG VO CADA DÍA · CARVEDILOL TAB 6.25MG VO CADA 12 HORAS · '
          'LINAGLIPTINA TAB 5MG VO CADA DÍA · TRIMETOPRIM SULFAMETOXAZOL 3 AMP IV CADA 8 HORAS · '
          'FI: 25/03/2026 · FF: 30/03/2026 · PARACETAMOL 1GR IV CADA 8 HORAS',
      direccion: 'BARRIO BOSTON CRR 46 N° 31D - 32',
      contacto: '3245304998 + 3245897047',
      pendiente: '',
      personalAsignado: 'LUIS CASTRO',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '20:00',
      paciente: 'ANA CANDELARIA PEREZ HERRERA CC 33153174',
      edad: 70,
      sexo: 'F',
      aseguradora: 'Coosalud',
      dx: 'L031 - CELULITIS DE OTRAS PARTES DE LOS MIEMBROS + DIABETES',
      tratamiento:
          'TRIMETOPRIM/SULFAMETOXAZOL 3 AMP IV CADA 12 HORAS · PARACETAMOL 1 GR IV CADA 12 HORAS · '
          'LINAGLIPTINA 5 MG VO CADA DÍA + GLUCOMETRÍAS PRECOMIDAS Y A LAS 21 HORAS',
      direccion:
          'TACARIGUA MZ 14 LOTE 20 · REFERENCIA: ENTRANDO POR CLÍNICA BARÚ, AL FINAL AL FRENTE DE LA TIENDA TIZAN 2',
      contacto: '3215261361 + 3222252817',
      pendiente: '',
      personalAsignado: 'LUIS CASTRO',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '21:00',
      paciente: 'GLORIA CRISTINA VARGAS DE ROJANO CC 30769875',
      edad: 76,
      sexo: 'F',
      aseguradora: 'Nueva EPS',
      dx: 'CELULITIS MIEMBRO INFERIOR IZQUIERDO + INSUFICIENCIA VENOSA',
      tratamiento:
          'AMLODIPINO TAB 10MG VO CADA DÍA · CARVEDILOL TAB 6.25MG VO CADA 12 HORAS · '
          'LINAGLIPTINA TAB 5MG VO CADA DÍA · TRIMETOPRIM SULFAMETOXAZOL 3 AMP IV CADA 8 HORAS · '
          'FI: 25/03/2026 · FF: 30/03/2026 · PARACETAMOL 1GR IV CADA 8 HORAS',
      direccion: 'BARRIO BOSTON CRR 46 N° 31D - 32',
      contacto: '3245304998 + 3245897047',
      pendiente: '',
      personalAsignado: 'LUIS CASTRO',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '22:00',
      paciente: 'JUAN DAVID FERIA PERTUZ CC 1007154767',
      edad: 49,
      sexo: 'M',
      aseguradora: 'Sanitas',
      dx: 'FRACTURA SUPRA E INTERCONDÍLEA DE HÚMERO DERECHO',
      tratamiento: 'PARACETAMOL 2 GR IV CADA 12 HORAS',
      direccion:
          'SAN FERNANDO · SECTOR NUEVA JERUSALÉN · CALLE LOS PALENQUEROS MZ 7 LOT 14 2 PISO',
      contacto: '3043835121 + 3024683411',
      pendiente: '',
      personalAsignado: 'LUIS CASTRO',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '9:00',
      paciente: 'EMIRONEL MEZA PADILLA 73000202 (PAPÁ DE CECILIA)',
      edad: 63,
      sexo: 'M',
      aseguradora: 'Mutual Ser',
      dx: 'L030 - CELULITIS DE LOS DEDOS DE LA MANO Y DEL PIE',
      tratamiento: 'CURACIÓN POR CLÍNICA DE HERIDA + PARACETAMOL CADA 12 HORAS',
      direccion:
          'BARRIO EL POZÓN MZ 139 A LOTE 5 · SECTOR LOS LAURELES · REFERENCIA: COLEGIO BONI',
      contacto: '3044544816',
      pendiente: 'CURACIÓN',
      personalAsignado: '',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '10:00',
      paciente: 'ROSA ARRIETA ATENCIO CC 45456552',
      edad: 72,
      sexo: 'F',
      aseguradora: 'Nueva EPS',
      dx: 'L984 - ÚLCERA CRÓNICA DE LA PIEL + E106 - DIABETES MELLITUS INSULINODEPENDIENTE',
      tratamiento: 'CURACIÓN POR CLÍNICA DE HERIDA',
      direccion:
          'CARACOLES MZ 65 L 5 · ENTRANDO POR EL SEMÁFORO DE LA PRINCIPAL · RESTAURANTE LA MARQUEZA',
      contacto: '3005687846',
      pendiente: 'CURACIÓN',
      personalAsignado: '',
    ),
    _AgendaVisitItem(
      fecha: '30/03/2026',
      hora: '17:00',
      paciente: 'JHORDAN JESITH MELENDEZ ALCALA CC 1050038030',
      edad: 29,
      sexo: 'M',
      aseguradora: 'Sura',
      dx: 'S923 - FRACTURA DE HUESO DEL METATARSO + S932 - RUPTURA DE LIGAMENTOS A NIVEL DEL TOBILLO Y DEL PIE',
      tratamiento:
          'DIPIRONA 1 GR IV CADA 12 HR + PARACETAMOL 1 GR IV CADA 12 HR',
      direccion:
          'TURBACO CALLE 4 # 5-30 · BARRIO CALLE LA ESTRELLA · SECTOR EL BOLSILLO',
      contacto: '3206700469 - 3212948616',
      pendiente: '',
      personalAsignado: 'NATALY VERGARA',
    ),
  ];

  List<String> get _personalOptions {
    final Set<String> values = _resolvedVisits
        .map((_AgendaVisitItem e) => e.personalAsignado.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();
    final List<String> list = values.toList()..sort();
    return <String>['Todos', ...list];
  }

  List<String> get _pendienteOptions {
    final Set<String> values = _allVisits
        .map((_AgendaVisitItem e) => e.pendiente.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();
    final List<String> list = values.toList()..sort();
    return <String>['Todos', ...list];
  }

  bool get _hasActiveFilters {
    return _buscarController.text.trim().isNotEmpty ||
        (_turnoFiltro != null && _turnoFiltro != 'Todos') ||
        (_pendienteFiltro != null && _pendienteFiltro != 'Todos') ||
        (_personalFiltro != null && _personalFiltro != 'Todos');
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
          matchesFecha &&
          matchesTurno &&
          matchesPendiente &&
          matchesPersonal;
    }).toList()..sort(
      (_AgendaVisitItem a, _AgendaVisitItem b) =>
          _hourToInt(a.hora).compareTo(_hourToInt(b.hora)),
    );
  }

  List<_AgendaVisitItem> get _resolvedVisits {
    final Map<String, List<_AgendaVisitItem>> grouped =
        <String, List<_AgendaVisitItem>>{};

    for (final _AgendaVisitItem item in _allVisits) {
      final String key = '${item.fecha}|${item.hora}';
      grouped.putIfAbsent(key, () => <_AgendaVisitItem>[]).add(item);
    }

    final List<_AgendaVisitItem> resolved = <_AgendaVisitItem>[];

    for (final MapEntry<String, List<_AgendaVisitItem>> entry
        in grouped.entries) {
      final List<_AgendaVisitItem> slotItems = entry.value;

      if (slotItems.isEmpty) {
        continue;
      }

      final DateTime? parsedDate = _tryParseDate(slotItems.first.fecha);
      if (parsedDate == null) {
        resolved.addAll(slotItems);
        continue;
      }

      final List<String> responsibles =
          AgendaResponsibleResolver.resolveResponsiblesForSlot(
        date: parsedDate,
        hora: slotItems.first.hora,
        nombres: _activeAuxiliares,
      );

      if (responsibles.isEmpty) {
        resolved.addAll(
          slotItems.map(
            (_AgendaVisitItem item) => item.copyWith(personalAsignado: ''),
          ),
        );
        continue;
      }

      for (int i = 0; i < slotItems.length; i++) {
        final _AgendaVisitItem item = slotItems[i];
        final String responsible = responsibles[i % responsibles.length];
        resolved.add(item.copyWith(personalAsignado: responsible));
      }
    }

    return resolved;
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

    final List<_AgendaRowData> rows = <_AgendaRowData>[];
    for (int hour = 6; hour <= 22; hour++) {
      final String key = '$hour:00';
      final List<_AgendaVisitItem> items = grouped[key] ?? <_AgendaVisitItem>[];

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
  void dispose() {
    _buscarController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontalPadding = constraints.maxWidth >= 900
              ? 16
              : 12;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ModuleHeader(
                  title: 'Agenda asistencial',
                  subtitle:
                      'Gestión de visitas, seguimiento operativo y control diario.',
                ),
                const SizedBox(height: 10),
                const AgendaSubnav(section: AgendaSubnavSection.visitas),
                const SizedBox(height: 12),
                _buildFiltersShell(),
                const SizedBox(height: 12),
                _buildSectionHeader(theme),
                const SizedBox(height: 8),
                SizedBox(height: 620, child: _AgendaGrid(rows: _displayRows)),
              ],
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
          title: 'Filtros y acciones',
          subtitle: 'Organiza la agenda con una vista clara y operativa.',
          fields: Wrap(
            spacing: 12,
            runSpacing: 12,
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
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD7DCE3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Acción: Nueva visita')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF17726D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva visita'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      children: <Widget>[
        Text(
          'Visitas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF243247),
          ),
        ),
        const SizedBox(width: 10),
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
          '${selected.day.toString().padLeft(2, '0')}/'
          '${selected.month.toString().padLeft(2, '0')}/'
          '${selected.year}';
    });
  }

  void _clearFilters() {
    setState(() {
      _buscarController.clear();
      _fechaController.clear();
      _turnoFiltro = 'Todos';
      _pendienteFiltro = 'Todos';
      _personalFiltro = 'Todos';
    });
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

}

class _AgendaGrid extends StatelessWidget {
  final List<_AgendaRowData> rows;

  const _AgendaGrid({required this.rows});

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
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Text(
            'No hay registros para mostrar.',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
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
          _BodyCell(
            text: isEmpty
                ? ''
                : _AgendaFormatters.formatAddress(
                    item.direccion,
                    fallback: 'Sin dirección',
                  ),
            width: _AgendaTableMetrics.direccion,
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
  final int? edad;
  final String? sexo;
  final String? aseguradora;
  final String dx;
  final String tratamiento;
  final String direccion;
  final String contacto;
  final String pendiente;
  final String personalAsignado;

  _AgendaVisitItem({
    required this.fecha,
    required this.hora,
    required this.paciente,
    this.edad,
    this.sexo,
    this.aseguradora,
    required this.dx,
    required this.tratamiento,
    required this.direccion,
    required this.contacto,
    required this.pendiente,
    required this.personalAsignado,
  });

  _AgendaVisitItem copyWith({
    String? fecha,
    String? hora,
    String? paciente,
    int? edad,
    String? sexo,
    String? aseguradora,
    String? dx,
    String? tratamiento,
    String? direccion,
    String? contacto,
    String? pendiente,
    String? personalAsignado,
  }) {
    return _AgendaVisitItem(
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      paciente: paciente ?? this.paciente,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      aseguradora: aseguradora ?? this.aseguradora,
      dx: dx ?? this.dx,
      tratamiento: tratamiento ?? this.tratamiento,
      direccion: direccion ?? this.direccion,
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

  static String formatAddress(String text, {String fallback = ''}) {
    final String normalized = normalizeSpace(text);
    if (normalized.isEmpty) return fallback;

    final List<String> rawParts = normalized
        .split('·')
        .map((String e) => normalizeSpace(e))
        .where((String e) => e.isNotEmpty)
        .toList();

    if (rawParts.isEmpty) return fallback;

    final List<String> lines = <String>[];

    for (final String rawPart in rawParts) {
      final String lower = rawPart.toLowerCase();

      if (lower.startsWith('referencia:')) {
        final String value = rawPart.substring('referencia:'.length).trim();
        lines.add('Referencia: ${toSentenceCase(value)}');
        continue;
      }

      if (lower.startsWith('punto de referencia:')) {
        final String value = rawPart
            .substring('punto de referencia:'.length)
            .trim();
        lines.add('Punto de referencia: ${toSentenceCase(value)}');
        continue;
      }

      lines.add(toSentenceCase(rawPart));
    }

    return lines.join('\n');
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
          style:
              style ??
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
      child: Padding(padding: const EdgeInsets.only(right: 12), child: child),
    );
  }
}
