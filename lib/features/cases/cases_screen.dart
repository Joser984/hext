import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/features/pad/summary/pad_summary_domain_adapter.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';
import 'package:hext/shared/widgets/app_chip.dart';
import 'package:hext/shared/widgets/filter_shell.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:hext/shared/widgets/module_header.dart';

class CensoScreen extends StatefulWidget {
  const CensoScreen({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  State<CensoScreen> createState() => _CensoScreenState();
}

class _CensoScreenState extends State<CensoScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final String seededSearch = widget.initialSearch?.trim() ?? '';
    if (seededSearch.isNotEmpty) {
      _searchController.text = seededSearch;
    }
  }

  static const String _allFilter = PadUiLabels.filterAll;

  String _situacionFilter = _allFilter;
  String _estadoPadFilter = _allFilter;
  String _unidadFuncionalFilter = _allFilter;

  static final List<String> _situacionOptions = <String>[
    _allFilter,
    ...PadCareSituationLabels.all,
  ];

  static final List<String> _estadoPadOptions = <String>[
    _allFilter,
    ...PadProcessStatusLabels.all,
  ];

  static const List<String> _unidadOptions =
      PadUiLabels.casesFunctionalUnitOptions;

  final List<CensoItem> _items = <CensoItem>[
    CensoItem(
      identificacion: '1045789632',
      nombreApellido: 'María Pérez Gómez',
      edad: 76,
      sexo: 'F',
      aseguradora: 'Nueva EPS',
      situacionAsistencial: PadCareSituationLabels.activeInPad,
      estadoPad: PadProcessStatusLabels.admissionApproved,
      fechaIngreso: DateTime(2026, 3, 20),
      fechaEgreso: null,
      especialidad: 'Medicina interna',
      unidadFuncionalOrigen: 'Medicina interna',
      barrio: 'Boston',
      diagnostico: 'Neumonía',
      observaciones: 'Paciente en seguimiento clínico y control diario.',
      motivoPrincipal: 'Finalizar tratamiento instaurado',
      motivosActivos: <String>[
        'Finalizar tratamiento instaurado',
        'Definir conducta medica',
      ],
      detalleClinicoResumido:
          'Paciente con mejoria parcial, requiere completar esquema terapeutico y seguimiento respiratorio.',
    ),
    CensoItem(
      identificacion: '2233445566',
      nombreApellido: 'José Martínez Ruiz',
      edad: 81,
      sexo: 'M',
      aseguradora: 'Sanitas',
      situacionAsistencial: PadCareSituationLabels.discharge,
      estadoPad: PadProcessStatusLabels.closed,
      fechaIngreso: DateTime(2026, 3, 10),
      fechaEgreso: DateTime(2026, 3, 22),
      especialidad: 'Ortopedia y traumatología',
      unidadFuncionalOrigen: 'Cirugía general',
      barrio: 'La Campiña',
      diagnostico: 'Fractura de cadera',
      observaciones: 'Egreso con educación al cuidador y cierre operativo.',
      motivoPrincipal: 'Curaciones y/o cuidado de heridas',
      motivosActivos: <String>['Curaciones y/o cuidado de heridas'],
      detalleClinicoResumido:
          'Lesion en fase final de cicatrizacion, egreso con plan de autocuidado.',
      resolucionPad: 'Alta exitosa',
    ),
    CensoItem(
      identificacion: '9988776655',
      nombreApellido: 'Ana Lucía Torres',
      edad: 69,
      sexo: 'F',
      aseguradora: 'Sura',
      situacionAsistencial: PadCareSituationLabels.readmission,
      estadoPad: PadProcessStatusLabels.underAssessment,
      fechaIngreso: DateTime(2026, 3, 28),
      fechaEgreso: null,
      especialidad: 'Cardiología',
      unidadFuncionalOrigen: 'Urgencias',
      barrio: 'Tacarigua',
      diagnostico: 'Insuficiencia cardíaca',
      observaciones: 'Pendiente definición médica y conducta definitiva.',
      motivosActivos: <String>[
        'Definir conducta medica',
        'Definir pertinencia ingreso PAD',
      ],
    ),
    CensoItem(
      identificacion: '5566778899',
      nombreApellido: 'Carlos Moreno',
      edad: 72,
      sexo: 'M',
      aseguradora: 'Coosalud',
      situacionAsistencial: PadCareSituationLabels.discharge,
      estadoPad: PadProcessStatusLabels.closed,
      fechaIngreso: null,
      fechaEgreso: null,
      especialidad: 'Endocrinología',
      unidadFuncionalOrigen: 'Hospitalización',
      barrio: 'Pozón',
      diagnostico: 'Diabetes mellitus',
      observaciones: 'Caso cerrado tras valoración y cierre administrativo.',
    ),
    CensoItem(
      identificacion: '3216549870',
      nombreApellido: 'Rosa Elena Vargas',
      edad: 83,
      sexo: 'F',
      aseguradora: 'Mutual Ser',
      situacionAsistencial: PadCareSituationLabels.hospitalExtension,
      estadoPad: PadProcessStatusLabels.underAssessment,
      fechaIngreso: null,
      fechaEgreso: null,
      especialidad: 'Medicina interna',
      unidadFuncionalOrigen: 'Medicina interna',
      barrio: 'Centro',
      diagnostico: 'Hipertensión arterial',
      observaciones: 'En valoración interdisciplinaria.',
    ),
    CensoItem(
      identificacion: '7894561230',
      nombreApellido: 'Luis Alberto Herrera',
      edad: 67,
      sexo: 'M',
      aseguradora: 'Nueva EPS',
      situacionAsistencial: PadCareSituationLabels.activeInPad,
      estadoPad: PadProcessStatusLabels.admissionApproved,
      fechaIngreso: DateTime(2026, 3, 26),
      fechaEgreso: null,
      especialidad: 'Neumología',
      unidadFuncionalOrigen: 'Hospitalización',
      barrio: 'San Fernando',
      diagnostico: 'EPOC',
      observaciones: 'Seguimiento operativo activo.',
      motivoPrincipal: 'Finalizar tratamiento instaurado',
      motivosActivos: <String>["Finalizar tratamiento instaurado"],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CensoItem> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();

    return _items.where((CensoItem item) {
      final String visibleSituacion = _situacionLabel(
        item.situacionAsistencial,
      );
      final bool matchesSearch =
          query.isEmpty ||
          item.identificacion.toLowerCase().contains(query) ||
          item.nombreApellido.toLowerCase().contains(query) ||
          item.aseguradora.toLowerCase().contains(query) ||
          visibleSituacion.toLowerCase().contains(query) ||
          item.situacionAsistencial.toLowerCase().contains(query) ||
          item.estadoPad.toLowerCase().contains(query) ||
          item.especialidad.toLowerCase().contains(query) ||
          item.unidadFuncionalOrigen.toLowerCase().contains(query) ||
          item.barrio.toLowerCase().contains(query) ||
          item.diagnostico.toLowerCase().contains(query) ||
          item.observaciones.toLowerCase().contains(query);

      final bool matchesSituacion =
          _situacionFilter == _allFilter ||
          _matchesSituacion(item.situacionAsistencial, _situacionFilter);

      final bool matchesEstadoPad =
          _estadoPadFilter == _allFilter || item.estadoPad == _estadoPadFilter;

      final bool matchesUnidad =
          _unidadFuncionalFilter == _allFilter ||
          item.unidadFuncionalOrigen == _unidadFuncionalFilter;

      return matchesSearch &&
          matchesSituacion &&
          matchesEstadoPad &&
          matchesUnidad;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _situacionFilter = _allFilter;
      _estadoPadFilter = _allFilter;
      _unidadFuncionalFilter = _allFilter;
    });
  }

  void _openEditCase(CensoItem item) {
    final String resolvedId =
        item.candidatoId != null && item.candidatoId!.trim().isNotEmpty
        ? item.candidatoId!
        : item.identificacion;

    final Map<String, dynamic> initialData = <String, dynamic>{
      'nombreCompleto': item.nombreApellido,
      'identificacion': item.identificacion,
      'edad': item.edad,
      'sexo': item.sexo == 'F'
          ? 'Femenino'
          : item.sexo == 'M'
          ? 'Masculino'
          : item.sexo,
      'aseguradora': item.aseguradora,
      'diagnostico': item.diagnostico,
      'unidadFuncionalOrigen': item.unidadFuncionalOrigen,
      'observaciones': item.observaciones,
      if (item.motivoPrincipal != null)
        'motivoIngresoPrincipal': item.motivoPrincipal,
      if (item.motivosActivos != null)
        'motivosIngresoActivos': item.motivosActivos,
    };

    context.push('/pad/editar/$resolvedId', extra: initialData);
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _situacionFilter != _allFilter ||
        _estadoPadFilter != _allFilter ||
        _unidadFuncionalFilter != _allFilter;
  }

  bool _matchesSituacion(String itemSituacion, String selectedSituacion) {
    final String item = _normalizeSituacion(itemSituacion);
    final String selected = _normalizeSituacion(selectedSituacion);

    if (selected == _normalizeSituacion(PadCareSituationLabels.activeInPad)) {
      return item == _normalizeSituacion(PadCareSituationLabels.activeInPad) ||
          item == _normalizeSituacion(PadCareSituationLabels.hospitalExtension);
    }

    return item == selected;
  }

  String _normalizeSituacion(String situacion) {
    final String normalized = situacion.trim().toLowerCase();
    if (normalized == 'activos en pad') {
      return _normalizeSituacion(PadCareSituationLabels.activeInPad);
    }
    if (normalized == 'reingreso de pad') {
      return _normalizeSituacion(PadCareSituationLabels.readmission);
    }
    if (normalized == 'en valoración' || normalized == 'en valoracion') {
      return _normalizeSituacion(PadCareSituationLabels.hospitalExtension);
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTable = constraints.maxWidth >= 1180;
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
                const ModuleHeader(
                  title: PadUiLabels.casesPageTitle,
                  subtitle: PadUiLabels.casesPageSubtitle,
                ),
                const SizedBox(height: 12),
                _buildFiltersShell(),
                const SizedBox(height: 12),
                _buildSectionHeader(theme),
                const SizedBox(height: 8),
                useTable ? _buildDesktopTable() : _buildMobileCards(),
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
          title: PadUiLabels.casesFiltersHeader,
          subtitle: PadUiLabels.casesFiltersSubtitle,
          fields: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: searchWidth,
                child: LightInput(
                  label: PadUiLabels.casesSearchLabel,
                  hint: PadUiLabels.casesSearchHint,
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightDropdown<String>(
                  label: PadUiLabels.careSituationLabel,
                  value: _situacionFilter,
                  items: _situacionOptions
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _situacionFilter = value);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightDropdown<String>(
                  label: PadUiLabels.processStatusLabel,
                  value: _estadoPadFilter,
                  items: _estadoPadOptions
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _estadoPadFilter = value);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: LightDropdown<String>(
                  label: PadUiLabels.functionalUnitLabel,
                  value: _unidadFuncionalFilter,
                  items: _unidadOptions
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _unidadFuncionalFilter = value);
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
                    PadUiLabels.clearFilters,
                    style: TextStyle(color: Color(0xFF5B6474)),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF17726D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(PadUiLabels.newCase),
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
          PadUiLabels.casesSectionTitle,
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
            '${_filteredItems.length} ${PadUiLabels.recordsSuffix}',
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

  Widget _buildDesktopTable() {
    final List<CensoItem> rows = _filteredItems;

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7ECF1))),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TableHeaderCell(
                  PadUiLabels.tableHeaderPatient,
                  flex: _TableFlex.paciente,
                ),
                _TableHeaderCell(
                  PadUiLabels.tableHeaderDiagnosis,
                  flex: _TableFlex.diagnostico,
                ),
                _TableHeaderCell(
                  PadUiLabels.tableHeaderSpecialty,
                  flex: _TableFlex.especialidad,
                ),
                _TableHeaderCell(
                  PadUiLabels.tableHeaderDates,
                  flex: _TableFlex.fechas,
                ),
                _TableHeaderCell(
                  PadUiLabels.tableHeaderFunctionalUnit,
                  flex: _TableFlex.unidad,
                ),
                _TableHeaderCell(
                  PadUiLabels.tableHeaderNeighborhood,
                  flex: _TableFlex.barrio,
                ),
                _TableHeaderCell(
                  PadUiLabels.tableHeaderObservations,
                  flex: _TableFlex.observaciones,
                ),
                _TableHeaderCell(
                  'ACCIONES',
                  flex: _TableFlex.acciones,
                  isLast: true,
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: _buildEmptyStateContent(isFiltered: _hasActiveFilters),
            )
          else
            ...rows.map(_buildDesktopRow),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(CensoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECF1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TableDataCell(
            flex: _TableFlex.paciente,
            child: _PatientCell(item: item),
          ),
          _TableDataCell(
            flex: _TableFlex.diagnostico,
            child: _SimpleCellText(item.diagnostico, maxLines: 2),
          ),
          _TableDataCell(
            flex: _TableFlex.especialidad,
            child: _SimpleCellText(item.especialidad, maxLines: 2),
          ),
          _TableDataCell(
            flex: _TableFlex.fechas,
            child: _DatesCell(item: item),
          ),
          _TableDataCell(
            flex: _TableFlex.unidad,
            child: _SimpleCellText(item.unidadFuncionalOrigen, maxLines: 2),
          ),
          _TableDataCell(
            flex: _TableFlex.barrio,
            child: _SimpleCellText(item.barrio, maxLines: 1),
          ),
          _TableDataCell(
            flex: _TableFlex.observaciones,
            child: _SimpleCellText(item.observaciones, maxLines: 2),
          ),
          _TableDataCell(
            flex: _TableFlex.acciones,
            isLast: true,
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openEditCase(item),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards() {
    final List<CensoItem> rows = _filteredItems;

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: _buildEmptyStateContent(isFiltered: _hasActiveFilters),
      );
    }

    return Column(
      children: rows
          .map(
            (CensoItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _PatientCell(item: item),
                    const SizedBox(height: 12),
                    _InfoLine(
                      label: PadUiLabels.careSituationLabel,
                      value: _situacionLabel(item.situacionAsistencial),
                    ),
                    _InfoLine(
                      label: PadUiLabels.processStatusLabel,
                      value: item.estadoPad,
                    ),
                    _InfoLine(
                      label: PadUiLabels.admissionDateLabel,
                      value: _formatDate(item.fechaIngreso),
                    ),
                    _InfoLine(
                      label: PadUiLabels.dischargeDateLabel,
                      value: _formatDate(item.fechaEgreso),
                    ),
                    _InfoLine(
                      label: PadUiLabels.stayDaysLabel,
                      value: item.diasEstancia?.toString() ?? '--',
                    ),
                    _InfoLine(
                      label: PadUiLabels.specialtyLabel,
                      value: item.especialidad,
                    ),
                    _InfoLine(
                      label: PadUiLabels.functionalUnitLabel,
                      value: item.unidadFuncionalOrigen,
                    ),
                    _InfoLine(
                      label: PadUiLabels.neighborhoodLabel,
                      value: item.barrio,
                    ),
                    _InfoLine(
                      label: PadUiLabels.diagnosisLabel,
                      value: item.diagnostico,
                    ),
                    _InfoLine(
                      label: PadUiLabels.observationsLabel,
                      value: item.observaciones,
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditCase(item),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _situacionLabel(String situacion) {
    return _CaseCareSituationUi.labelFor(situacion);
  }

  Widget _buildEmptyStateContent({required bool isFiltered}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          PadUiLabels.noResultsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF243247),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isFiltered
              ? PadUiLabels.noResultsWithFilters
              : PadUiLabels.noResultsSubtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (isFiltered)
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(PadUiLabels.clearFilters),
              ),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF17726D),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(PadUiLabels.newCase),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDCE3EA)),
    );
  }
}

class CensoItem {
  final String? candidatoId;
  final String identificacion;
  final String nombreApellido;
  final int edad;
  final String sexo;
  final String aseguradora;
  final String situacionAsistencial;
  final String estadoPad;
  final DateTime? fechaIngreso;
  final DateTime? fechaEgreso;
  final String especialidad;
  final String unidadFuncionalOrigen;
  final String barrio;
  final String diagnostico;
  final String observaciones;
  final String? motivoPrincipal;
  final String? motivoPrincipalLabel;
  final List<String>? motivosActivos;
  final List<String>? motivos;
  final String? detalleClinicoResumido;
  final String? resumenClinico;
  final String? detalleClinico;
  final String? resolucionPad;

  CensoItem({
    this.candidatoId,
    required this.identificacion,
    required this.nombreApellido,
    required this.edad,
    required this.sexo,
    required this.aseguradora,
    required this.situacionAsistencial,
    required this.estadoPad,
    required this.fechaIngreso,
    required this.fechaEgreso,
    required this.especialidad,
    required this.unidadFuncionalOrigen,
    required this.barrio,
    required this.diagnostico,
    required this.observaciones,
    this.motivoPrincipal,
    this.motivoPrincipalLabel,
    this.motivosActivos,
    this.motivos,
    this.detalleClinicoResumido,
    this.resumenClinico,
    this.detalleClinico,
    this.resolucionPad,
  });

  int? get diasEstancia {
    if (fechaIngreso == null) return null;
    final DateTime end = fechaEgreso ?? DateTime.now();
    return end.difference(fechaIngreso!).inDays;
  }
}

class _TableFlex {
  static const int paciente = 17;
  static const int diagnostico = 20;
  static const int especialidad = 14;
  static const int fechas = 8;
  static const int unidad = 12;
  static const int barrio = 14;
  static const int observaciones = 15;
  static const int acciones = 8;
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isLast;

  const _TableHeaderCell(this.text, {required this.flex, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 12),
        child: Text(
          text,
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

class _TableDataCell extends StatelessWidget {
  final int flex;
  final Widget child;
  final bool isLast;

  const _TableDataCell({
    required this.flex,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 12),
        child: child,
      ),
    );
  }
}

class _PatientCell extends StatelessWidget {
  final CensoItem item;

  const _PatientCell({required this.item});

  String _situacionLabel(String situacion) {
    return _CaseCareSituationUi.labelFor(situacion);
  }

  @override
  Widget build(BuildContext context) {
    final PadCaseRecord record = PadCaseRecord(
      motivoIngresoPrincipal: item.motivoPrincipal ?? item.motivoPrincipalLabel,
      motivosIngresoActivos: item.motivosActivos,
      motivos: item.motivos,
      detalleClinicoResumido: item.detalleClinicoResumido,
      resumenClinico: item.resumenClinico,
      detalleClinico: item.detalleClinico,
      observaciones: item.observaciones,
      situacionAsistencial: item.situacionAsistencial,
      estadoPad: item.estadoPad,
      resolucionPad: item.resolucionPad,
    );

    final summary = mapPadSummary(
      PadSummaryDomainAdapter.toPadCaseData(record),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.nombreApellido,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF243247),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.identificacion} · ${item.edad} años · ${item.sexo} · ${item.aseguradora}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.8, color: Color(0xFF748096)),
        ),
        const SizedBox(height: 6),
        Text(
          summary.shortDetail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.3,
            color: Color(0xFF8A94A6),
          ),
        ),
        const SizedBox(height: 8),
        AppChip(
          label: _situacionLabel(item.situacionAsistencial),
          tone: _CaseCareSituationUi.toneFor(item.situacionAsistencial),
          leadingDot: true,
        ),
      ],
    );
  }
}

class _DatesCell extends StatelessWidget {
  final CensoItem item;

  const _DatesCell({required this.item});

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildDateLine(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF748096)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> lines = <Widget>[];

    if (item.fechaIngreso != null) {
      lines.add(_buildDateLine('Ing: ${_formatDate(item.fechaIngreso)}'));
    }

    if (item.fechaEgreso != null) {
      lines.add(_buildDateLine('Egr: ${_formatDate(item.fechaEgreso)}'));
    }

    if (item.diasEstancia != null) {
      lines.add(_buildDateLine('${item.diasEstancia} d'));
    }

    if (lines.isEmpty) {
      return _buildDateLine('—');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.expand<Widget>((entry) {
        final int index = entry.key;
        final Widget line = entry.value;
        return <Widget>[if (index > 0) const SizedBox(height: 2), line];
      }).toList(),
    );
  }
}

class _SimpleCellText extends StatelessWidget {
  final String text;
  final int maxLines;

  const _SimpleCellText(this.text, {this.maxLines = 3});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.35,
        color: Color(0xFF748096),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: Color(0xFF5D6778),
          ),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CaseCareSituationUi {
  const _CaseCareSituationUi._();

  static String labelFor(String situacion) {
    switch (situacion.trim().toLowerCase()) {
      case 'activos en pad':
      case 'activo en pad':
        return PadCareSituationLabels.activeInPad;
      case 'extensión hospitalaria':
        return PadCareSituationLabels.hospitalExtension;
      case 'reingreso de pad':
        return PadCareSituationLabels.readmission;
      default:
        return situacion.trim();
    }
  }

  static AppChipTone toneFor(String situacion) {
    final String normalized = labelFor(situacion).trim().toLowerCase();
    if (normalized == PadCareSituationLabels.activeInPad.toLowerCase() ||
        normalized == PadCareSituationLabels.hospitalExtension.toLowerCase()) {
      return AppChipTone.success;
    }
    if (normalized == PadCareSituationLabels.readmission.toLowerCase()) {
      return AppChipTone.accent;
    }
    if (normalized == PadCareSituationLabels.discharge.toLowerCase()) {
      return AppChipTone.warning;
    }
    if (normalized == PadCareSituationLabels.noProgramAdmission.toLowerCase()) {
      return AppChipTone.danger;
    }
    return AppChipTone.neutral;
  }
}
