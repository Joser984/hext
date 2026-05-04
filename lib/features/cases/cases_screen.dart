import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/core/repositories/caso_paciente_repo.dart';
import 'package:hext/core/models/caso_paciente.dart';
import 'package:hext/features/pad/summary/pad_summary_domain_adapter.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';
import 'package:hext/features/pad/utils/diagnosis_text_formatter.dart';
import 'package:hext/shared/widgets/app_chip.dart';
import 'package:hext/shared/widgets/filter_shell.dart';
import 'package:hext/shared/widgets/hext_loading_screen.dart';
import 'package:hext/shared/widgets/hext_logo.dart';
import 'package:hext/shared/widgets/hext_page_shell.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:hext/features/pad/egreso/egreso_pad_modal.dart';

class CensoScreen extends StatefulWidget {
  const CensoScreen({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  State<CensoScreen> createState() => _CensoScreenState();
}

class _CensoScreenState extends State<CensoScreen> {
    Widget _buildDesktopRow(CensoItem item) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7ECF1))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _TableDataCell(
              flex: _TableFlex.paciente,
              child: _PatientCell(item: item),
            ),
            _TableDataCell(
              flex: _TableFlex.diagnostico,
              child: _SimpleCellText(item.diagnostico),
            ),
            _TableDataCell(
              flex: _TableFlex.especialidad,
              child: _SimpleCellText(item.especialidad),
            ),
            _TableDataCell(
              flex: _TableFlex.fechas,
              child: _DatesCell(item: item),
            ),
            _TableDataCell(
              flex: _TableFlex.unidad,
              child: _SimpleCellText(item.unidadFuncionalOrigen),
            ),
            _TableDataCell(
              flex: _TableFlex.barrio,
              child: _SimpleCellText(item.barrio),
            ),
            _TableDataCell(
              flex: _TableFlex.observaciones,
              child: _SimpleCellText(item.observaciones),
            ),
            _TableDataCell(
              flex: _TableFlex.acciones,
              isLast: true,
              child: _RowActions(
                canDischarge: _canQuickDischarge(item),
                onEdit: () => _openEditCase(item),
                onDischarge: () => _handleQuickDischarge(item),
              ),
            ),
          ],
        ),
      );
    }
  static const String _allFilter = PadUiLabels.filterAll;

  // final CensoPacienteRepo _repo = CensoPacienteRepo();

  String _situacionFilter = _allFilter;
  String _estadoPadFilter = _allFilter;
  String _unidadFuncionalFilter = _allFilter;

  static final List<String> _situacionOptions = <String>[
    _allFilter,
    PadCareSituationLabels.hospitalExtension,
  ];

  static final List<String> _estadoPadOptions = <String>[
    _allFilter,
    ...PadProcessStatusLabels.all,
  ];

  static const List<String> _unidadOptionsFallback =
      PadUiLabels.casesFunctionalUnitOptions;

  static const double _rowActionButtonWidth = 118;

  final TextEditingController _searchController = TextEditingController();

  String? _tryReadString(dynamic Function() reader) {
    try {
      final dynamic value = reader();
      if (value == null) return null;
      final String text = value.toString().trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  DateTime? _tryReadDate(dynamic Function() reader) {
    try {
      final dynamic value = reader();
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim());
      }
      final dynamic maybeTimestamp = value;
      if (maybeTimestamp != null && maybeTimestamp.toDate is Function) {
        return maybeTimestamp.toDate() as DateTime?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  CensoItem _mapPacienteToItem(CensoPaciente p) {
    final String situacion = (p.situacionAsistencialLabel.trim().isNotEmpty)
        ? p.situacionAsistencialLabel.trim()
        : p.situacionAsistencialKey;

    final String estadoPad = ((p.resultadoPadLabel?.trim().isNotEmpty ?? false))
        ? p.resultadoPadLabel!.trim()
        : (p.resultadoPadKey ?? '');
    final String sexo = ((p.sexoLabel?.trim().isNotEmpty ?? false))
        ? p.sexoLabel!.trim()
        : (p.sexoKey ?? '');
    final String aseguradora =
        ((p.aseguradoraLabel?.trim().isNotEmpty ?? false))
        ? p.aseguradoraLabel!.trim()
        : (p.aseguradoraKey ?? '');
    final String especialidad =
        ((p.especialidadLabel?.trim().isNotEmpty ?? false))
        ? p.especialidadLabel!.trim()
        : (p.especialidadKey ?? '');

    return CensoItem(
      candidatoId: p.id,
      identificacion: p.identificacion,
      nombreApellido: p.nombreCompleto.toUpperCase(),
      edad: p.edad ?? 0,
      sexo: sexo,
      aseguradora: aseguradora,
      situacionAsistencial: situacion,
      estadoPad: estadoPad,
      fechaIngreso: p.fechaIngreso,
      fechaEgreso: p.fechaEgreso,
      especialidad: especialidad,
      unidadFuncionalOrigen:
          p.unidadFuncionalOrigenLabel ?? p.unidadFuncionalOrigenKey ?? '',
      barrio: p.barrio ?? '',
      diagnostico: DiagnosisTextFormatter.normalizeForStorage(
        p.diagnosticos ?? '',
      ),
      observaciones: p.observaciones ?? '',
      motivoPrincipal: null,
      motivoPrincipalLabel: null,
      motivosActivos: null,
      motivos: null,
      detalleClinicoResumido: null,
      resumenClinico: null,
      detalleClinico: null,
      resolucionPad: _tryReadString(() => (p as dynamic).resolucionPad),
      estadoCaso: _tryReadString(() => (p as dynamic).estadoCaso),
      tipoEgreso: _tryReadString(() => (p as dynamic).tipoEgreso),
      observacionEgreso:
          _tryReadString(() => (p as dynamic).observacionEgreso) ??
          _tryReadString(() => (p as dynamic).observacionCierre),
      fechaEgresoTs: _tryReadDate(() => (p as dynamic).fechaEgresoTs),
      actualizadoPor: _tryReadString(() => (p as dynamic).actualizadoPor),
      actualizadoEn: _tryReadDate(() => (p as dynamic).actualizadoEn),
      destinoTraslado: _tryReadString(() => (p as dynamic).destinoTraslado),
    );
  }

  List<CensoItem> _filterItems(List<CensoItem> source) {
    final String query = _searchController.text.trim().toLowerCase();

    return source.where((CensoItem item) {
      final String visibleSituacion = _situacionLabel(item.situacionAsistencial);

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
          item.observaciones.toLowerCase().contains(query) ||
          ((item.tipoEgreso?.isNotEmpty ?? false) &&
              item.tipoEgreso!.toLowerCase().contains(query)) ||
          ((item.observacionEgreso?.isNotEmpty ?? false) &&
              item.observacionEgreso!.toLowerCase().contains(query)) ||
          ((item.destinoTraslado?.isNotEmpty ?? false) &&
              item.destinoTraslado!.toLowerCase().contains(query));

      final bool matchesSituacion = _situacionFilter == _allFilter ||
          _matchesSituacion(item.situacionAsistencial, _situacionFilter);

      final bool matchesEstadoPad =
          _estadoPadFilter == _allFilter || item.estadoPad == _estadoPadFilter;

      final bool matchesUnidad = _unidadFuncionalFilter == _allFilter ||
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
        (item.candidatoId?.trim().isNotEmpty ?? false)
            ? item.candidatoId!.trim()
            : item.identificacion;

    debugPrint('edit: navegando a edición solo con id => $resolvedId');
    context.push('/pad/editar/$resolvedId');
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _situacionFilter != _allFilter ||
        _estadoPadFilter != _allFilter ||
        _unidadFuncionalFilter != _allFilter;
  }

  bool _canQuickDischarge(CensoItem item) {
    if (item.fechaEgreso != null) return false;

    final String situacion = item.situacionAsistencial.trim().toLowerCase();
    final String estado = item.estadoPad.trim().toLowerCase();

    final bool alreadyClosed = estado == 'egresado' ||
        estado == 'cerrado' ||
        estado == 'alta' ||
        situacion == 'egresado' ||
        situacion == 'cerrado' ||
        situacion == 'alta';

    if (alreadyClosed) return false;

    final bool activeLike =
        _matchesSituacion(
          item.situacionAsistencial,
          PadCareSituationLabels.hospitalExtension,
        ) ||
        _matchesSituacion(
          item.situacionAsistencial,
          PadCareSituationLabels.readmission,
        ) ||
        situacion == 'activo en pad' ||
        situacion == 'activos en pad' ||
        situacion == 'seguimiento' ||
        situacion == 'extensión hospitalaria' ||
        situacion == 'extension hospitalaria' ||
        situacion == 'en valoración' ||
        situacion == 'en valoracion';

    return activeLike;
  }

  Future<void> _handleQuickDischarge(CensoItem item) async {
    final bool? result = await showEgresoPadDialog(
      context: context,
      pacienteId: (item.candidatoId?.trim().isNotEmpty ?? false)
          ? item.candidatoId!.trim()
          : item.identificacion,
      pacienteNombre: item.nombreApellido,
      diagnostico: item.diagnostico,
      estadoActual: item.situacionAsistencial,
      initialTipoEgreso: item.tipoEgreso,
      initialCausaReingreso: null,
      initialCausaReingresoOtro: null,
      initialFechaEgreso: item.fechaEgreso,
    );

    if (!mounted || result != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paciente egresado correctamente.')),
    );
  }

  bool _matchesSituacion(String itemSituacion, String selectedSituacion) {
    final String item = _normalizeSituacion(itemSituacion);
    final String selected = _normalizeSituacion(selectedSituacion);

    if (selected ==
        _normalizeSituacion(PadCareSituationLabels.hospitalExtension)) {
      return item ==
          _normalizeSituacion(PadCareSituationLabels.hospitalExtension);
    }

    return item == selected;
  }

  String _normalizeSituacion(String situacion) {
    final String normalized = situacion.trim().toLowerCase();

    if (normalized == 'activos en pad') {
      return _normalizeSituacion(PadCareSituationLabels.hospitalExtension);
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

    return StreamBuilder<List<CensoPaciente>>(
      stream: CensoPacienteRepo().watchCenso(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const HextLoadingScreen(
            title: 'Cargando pacientes',
            subtitle: 'Sincronizando censo institucional',
            compact: true,
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final List<CensoPaciente> raw = snapshot.data ?? <CensoPaciente>[];
        final List<CensoItem> items = raw.map(_mapPacienteToItem).toList();
        final List<CensoItem> filtered = _filterItems(items);

        List<String> unidadOptions = items
            .map((e) => e.especialidad.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        unidadOptions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        unidadOptions.insert(0, PadUiLabels.filterAll);

        if (unidadOptions.length == 1) {
          unidadOptions = List<String>.from(_unidadOptionsFallback);
        }

        return HextPageShell(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useTable = constraints.maxWidth >= 1180;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const HextPageHeader(
                  title: PadUiLabels.casesPageTitle,
                  subtitle: PadUiLabels.casesPageSubtitle,
                ),
                _buildFiltersShell(unidadOptions),
                const SizedBox(height: 12),
                _buildSectionHeader(theme, filtered.length),
                const SizedBox(height: 8),
                useTable ? _buildDesktopTable(filtered) : _buildMobileCards(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFiltersShell([List<String>? unidadOptions]) {
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

        final List<String> unidadOpts = unidadOptions ?? _unidadOptionsFallback;

        return FilterShell(
          title: PadUiLabels.casesFiltersHeader,
          subtitle: PadUiLabels.casesFiltersSubtitle,
          fields: Wrap(
            spacing: 12,
            runSpacing: 8,
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
                  items: unidadOpts
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
          actions: SizedBox(
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
                PadUiLabels.clearFilters,
                style: TextStyle(color: Color(0xFF5B6474)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, int count) {
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
            '$count ${PadUiLabels.recordsSuffix}',
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

  Widget _buildDesktopTable(List<CensoItem> rows) {
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

  // ...existing code...



  Widget _buildMobileCards() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Vista móvil en desarrollo',
          style: TextStyle(color: Colors.grey[600], fontSize: 18),
        ),
      ),
    );
  }



  String _situacionLabel(String situacion) {
    return _CaseCareSituationUi.labelFor(situacion);
  }

  Widget _buildEmptyStateContent({required bool isFiltered}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HextLogo(size: 48),
        const SizedBox(height: 14),
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
  final String? estadoCaso;
  final String? tipoEgreso;
  final String? observacionEgreso;
  final DateTime? fechaEgresoTs;
  final String? actualizadoPor;
  final DateTime? actualizadoEn;
  final String? destinoTraslado;

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
    this.estadoCaso,
    this.tipoEgreso,
    this.observacionEgreso,
    this.fechaEgresoTs,
    this.actualizadoPor,
    this.actualizadoEn,
    this.destinoTraslado,
  });

  CensoItem copyWith({
    String? candidatoId,
    String? identificacion,
    String? nombreApellido,
    int? edad,
    String? sexo,
    String? aseguradora,
    String? situacionAsistencial,
    String? estadoPad,
    DateTime? fechaIngreso,
    DateTime? fechaEgreso,
    String? especialidad,
    String? unidadFuncionalOrigen,
    String? barrio,
    String? diagnostico,
    String? observaciones,
    String? motivoPrincipal,
    String? motivoPrincipalLabel,
    List<String>? motivosActivos,
    List<String>? motivos,
    String? detalleClinicoResumido,
    String? resumenClinico,
    String? detalleClinico,
    String? resolucionPad,
    String? estadoCaso,
    String? tipoEgreso,
    String? observacionEgreso,
    DateTime? fechaEgresoTs,
    String? actualizadoPor,
    DateTime? actualizadoEn,
    String? destinoTraslado,
  }) {
    return CensoItem(
      candidatoId: candidatoId ?? this.candidatoId,
      identificacion: identificacion ?? this.identificacion,
      nombreApellido: nombreApellido ?? this.nombreApellido,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      aseguradora: aseguradora ?? this.aseguradora,
      situacionAsistencial: situacionAsistencial ?? this.situacionAsistencial,
      estadoPad: estadoPad ?? this.estadoPad,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaEgreso: fechaEgreso ?? this.fechaEgreso,
      especialidad: especialidad ?? this.especialidad,
      unidadFuncionalOrigen:
          unidadFuncionalOrigen ?? this.unidadFuncionalOrigen,
      barrio: barrio ?? this.barrio,
      diagnostico: diagnostico ?? this.diagnostico,
      observaciones: observaciones ?? this.observaciones,
      motivoPrincipal: motivoPrincipal ?? this.motivoPrincipal,
      motivoPrincipalLabel: motivoPrincipalLabel ?? this.motivoPrincipalLabel,
      motivosActivos: motivosActivos ?? this.motivosActivos,
      motivos: motivos ?? this.motivos,
      detalleClinicoResumido:
          detalleClinicoResumido ?? this.detalleClinicoResumido,
      resumenClinico: resumenClinico ?? this.resumenClinico,
      detalleClinico: detalleClinico ?? this.detalleClinico,
      resolucionPad: resolucionPad ?? this.resolucionPad,
      estadoCaso: estadoCaso ?? this.estadoCaso,
      tipoEgreso: tipoEgreso ?? this.tipoEgreso,
      observacionEgreso: observacionEgreso ?? this.observacionEgreso,
      fechaEgresoTs: fechaEgresoTs ?? this.fechaEgresoTs,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      destinoTraslado: destinoTraslado ?? this.destinoTraslado,
    );
  }

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

  String _visibleStateLabel(CensoItem item) {
    if (item.fechaEgreso != null) return 'Egresado';

    final String estado = item.estadoPad.trim().toLowerCase();
    final String situacion = item.situacionAsistencial.trim().toLowerCase();

    if (estado == 'egresado' ||
        estado == 'cerrado' ||
        estado == 'alta' ||
        situacion == 'egresado' ||
        situacion == 'cerrado' ||
        situacion == 'alta') {
      return 'Egresado';
    }

    return _situacionLabel(item.situacionAsistencial);
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
      barrio: item.barrio,
    );

    final summary = mapPadSummary(
      PadSummaryDomainAdapter.toPadCaseData(record),
    );

    final String visibleLabel = _visibleStateLabel(item);

    String? tipoEgresoDetalle;
    String? destinoTrasladoDetalle;

    if ((item.tipoEgreso?.toLowerCase() ?? '') == 'traslado' &&
        (item.destinoTraslado?.isNotEmpty ?? false)) {
      tipoEgresoDetalle = 'Traslado';
      destinoTrasladoDetalle = item.destinoTraslado;
    } else if ((item.tipoEgreso?.isNotEmpty ?? false)) {
      tipoEgresoDetalle = item.tipoEgreso;
    }

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
          style: const TextStyle(
            fontSize: 12.8,
            color: Color(0xFF748096),
          ),
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
          label: visibleLabel,
          tone: _CaseCareSituationUi.toneFor(visibleLabel),
          leadingDot: true,
        ),
        if (tipoEgresoDetalle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tipo de egreso: $tipoEgresoDetalle',
                  style: const TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF243247),
                  ),
                ),
                if (destinoTrasladoDetalle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Destino del traslado: $destinoTrasladoDetalle',
                      style: const TextStyle(
                        fontSize: 13.2,
                        color: Color(0xFF243247),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.canDischarge,
    required this.onEdit,
    required this.onDischarge,
  });

  final bool canDischarge;
  final VoidCallback onEdit;
  final VoidCallback onDischarge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _CensoScreenState._rowActionButtonWidth * 2,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          SizedBox(
            width: _CensoScreenState._rowActionButtonWidth,
            height: 34,
            child: OutlinedButton(
              onPressed: onEdit,
              child: const Text('Editar'),
            ),
          ),
          SizedBox(
            width: _CensoScreenState._rowActionButtonWidth,
            height: 34,
            child: FilledButton(
              onPressed: canDischarge ? onDischarge : null,
              child: const Text('Egresar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ...existing code...

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

  const _SimpleCellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.35,
        color: Color(0xFF748096),
      ),
    );
  }
}

class _CaseCareSituationUi {
  const _CaseCareSituationUi._();

  static String labelFor(String situacion) {
    switch (situacion.trim().toLowerCase()) {
      case 'activos en pad':
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

    if (normalized ==
        PadCareSituationLabels.hospitalExtension.toLowerCase()) {
      return AppChipTone.success;
    }
    if (normalized == PadCareSituationLabels.readmission.toLowerCase()) {
      return AppChipTone.accent;
    }
    if (normalized == PadCareSituationLabels.discharge.toLowerCase()) {
      return AppChipTone.warning;
    }
    if (normalized ==
        PadCareSituationLabels.noProgramAdmission.toLowerCase()) {
      return AppChipTone.danger;
    }

    return AppChipTone.neutral;
  }
}
