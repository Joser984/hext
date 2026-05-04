// Última actualización: 13/04/2026
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hext/core/models/auxiliar_domiciliario.dart';
import 'package:hext/core/repositories/in_memory_personal_repo.dart';
import 'package:hext/core/scheduling/aux_schedule_generator.dart'
    show kRotationAnchorMonday;
import 'package:hext/features/schedule/data/imported_schedule_plan.dart';
import 'package:hext/features/schedule/data/scheduled_shift_repo.dart';
import 'package:hext/features/schedule/models/scheduled_shift.dart';
import 'package:hext/core/utils/colombia_holidays.dart';
import 'package:hext/shared/widgets/app_chip.dart';
import 'package:hext/shared/widgets/agenda_subnav.dart';
import 'package:hext/shared/widgets/hext_page_shell.dart';
import 'package:hext/app/hext_design_system.dart';

// Formatea texto clínico: inserta salto de línea después de símbolos o números de sección
String formatClinicalText(String text) {
  // Inserta salto de línea después de patrones como 1. , 1.1 , 2.1- , ** , + , %, etc.
  final regex = RegExp(r'(\d+\.\d*[-]?|\d+\.|\*\*|\+|%)');
  return text.replaceAllMapped(regex, (match) {
    final str = match.group(0)!;
    // Si no está al inicio, agrega salto de línea antes
    if (match.start > 0 && text[match.start - 1] != '\n') {
      return '\n$str';
    }
    return str;
  }).replaceAll(RegExp(r' +'), ' ').replaceAll(RegExp(r'\n +'), '\n').trim();
}

const List<String> kHorarioAuxiliaresRegistrados = <String>[
  'Luis Orozco',
  'Katerine Cabarcas',
  'Nataly Vergara',
];

const TwoAuxSundayPolicy kHorarioTwoAuxSundayPolicy =
    TwoAuxSundayPolicy.contingencyJ;

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final FirestoreScheduledShiftRepo _scheduledShiftRepo =
      FirestoreScheduledShiftRepo();

  StreamSubscription<List<ScheduledShift>>? _scheduledShiftsSubscription;
  ImportedScheduleDataset? _importedScheduleDataset;
  ImportedScheduleMonthData? _firestoreWindowData;

  @override
  void initState() {
    super.initState();
    _loadImportedScheduleDataset();
    _bindFirestoreWindow();
  }

  @override
  void dispose() {
    _scheduledShiftsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadImportedScheduleDataset() async {
    final ImportedScheduleDataset? dataset =
        await ImportedScheduleDataset.loadDefault();
    if (!mounted || dataset == null) return;
    setState(() {
      _importedScheduleDataset = dataset;
    });
  }

  void _bindFirestoreWindow() {
    _scheduledShiftsSubscription?.cancel();
    final List<DateTime> visibleDays = buildCenteredDateWindow(_focusedMonth);
    final DateTime start = visibleDays.first;
    final DateTime endExclusive = visibleDays.last.add(const Duration(days: 1));
    _scheduledShiftsSubscription = _scheduledShiftRepo.watchRange(
      start: start,
      endExclusive: endExclusive,
    ).listen((
      List<ScheduledShift> items,
    ) {
      if (!mounted) return;
      final ImportedScheduleMonthData? windowData = items.isEmpty
          ? null
          : ImportedScheduleDataset.fromEntries(
              items,
            ).windowFor(anchorDate: _focusedMonth, visibleDays: visibleDays);
      setState(() {
        _firestoreWindowData = windowData;
      });
    });
  }

  // Franja resumen compacta arriba de la matriz
  Widget _buildCompactSummaryBar(GeneratedMonthPlan plan, int totalAuxiliares) {
    int critical = 0;
    int alert = 0;
    int info = 0;
    for (final summary in plan.weeklySummaries) {
      if (summary.status == WeeklyHoursStatus.invalid) {
        critical++;
      } else if (summary.status == WeeklyHoursStatus.alert) {
        alert++;
      } else {
        info++;
      }
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: HextColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HextColors.bordeSuave),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Auxiliares activos',
                style: TextStyle(fontSize: 13, color: HextColors.textoSecundario),
              ),
              Text(
                '$totalAuxiliares',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HextColors.textoPrincipal,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Mes',
                style: TextStyle(fontSize: 13, color: HextColors.textoSecundario),
              ),
              Text(
                _monthYearLabel(_focusedMonth),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HextColors.textoPrincipal,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text(
                'Críticas',
                style: TextStyle(fontSize: 13, color: HextColors.estadoError),
              ),
              Text(
                '$critical',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HextColors.estadoError,
                ),
              ),
              const Text(
                'Alertas',
                style: TextStyle(fontSize: 13, color: HextColors.estadoAdvertencia),
              ),
              Text(
                '$alert',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HextColors.estadoAdvertencia,
                ),
              ),
              const Text(
                'Informativas',
                style: TextStyle(fontSize: 13, color: HextColors.verdePrincipal),
              ),
              Text(
                '$info',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HextColors.verdePrincipal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper para minHeight de empty states
  double _emptyStateMinHeight(BuildContext context, bool isEmpty) {
    return _isEmptyStateCompact(context, isEmpty) ? 130 : 0;
  }

  // Helper para detectar desktop por ancho
  bool _isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1024;
  }

  // Helper para compactar estados vacíos
  bool _isEmptyStateCompact(BuildContext context, bool isEmpty) {
    return _isDesktop(context) && isEmpty;
  }

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  /// Con 2 auxiliares, el domingo puede manejarse como contingencia J/L.
  final TwoAuxSundayPolicy _twoAuxSundayPolicy = kHorarioTwoAuxSundayPolicy;

  /// Manual overrides: auxiliarNombre → date → ScheduleCode.
  /// Keyed by month start so overrides reset when navigating months.
  final Map<DateTime, Map<String, Map<DateTime, ScheduleCode>>>
  _overridesByMonth = <DateTime, Map<String, Map<DateTime, ScheduleCode>>>{};

  Map<String, Map<DateTime, ScheduleCode>> get _currentOverrides {
    final DateTime key = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    return _overridesByMonth.putIfAbsent(
      key,
      () => <String, Map<DateTime, ScheduleCode>>{},
    );
  }

  void _applyOverride(String auxiliarNombre, DateTime date, ScheduleCode code) {
    setState(() {
      _currentOverrides.putIfAbsent(
        auxiliarNombre,
        () => <DateTime, ScheduleCode>{},
      )[DateTime(date.year, date.month, date.day)] = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = buildCenteredDateWindow(_focusedMonth);

    final List<AuxiliarDomiciliario> activeAuxiliares = context
        .watch<InMemoryPersonalRepo>()
        .items
        .where((AuxiliarDomiciliario a) => a.activo)
        .toList();
      final List<String> nombresActivos = activeAuxiliares
        .map((AuxiliarDomiciliario a) => a.nombreCompleto)
        .toList();
    final ImportedScheduleMonthData? importedMonth =
        _firestoreWindowData ??
        _importedScheduleDataset?.windowFor(
          anchorDate: _focusedMonth,
          visibleDays: days,
        );
      final List<String> auxiliaresFuente = importedMonth?.auxiliarNames ?? nombresActivos;
      final bool auxiliaresFuenteValidos =
        auxiliaresFuente.isNotEmpty && auxiliaresFuente.length <= 3;
      final bool usingSafeFallbackAuxiliares = !auxiliaresFuenteValidos;
      final List<String> auxiliaresRegistrados = auxiliaresFuenteValidos
        ? auxiliaresFuente
        : kHorarioAuxiliaresRegistrados;

    final GeneratedMonthPlan plan =
        importedMonth == null
        ? _generateMonthPlan(
            year: _focusedMonth.year,
            month: _focusedMonth.month,
            nombres: auxiliaresRegistrados,
            visibleDays: days,
            twoAuxSundayPolicy: _twoAuxSundayPolicy,
            overrides: _currentOverrides,
          )
        : _buildImportedMonthPlan(
            month: _focusedMonth,
            importedMonth: importedMonth,
            visibleDays: days,
            overrides: _currentOverrides,
          );

    return HextPageShell(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const HextPageHeader(
              title: 'Horarios',
              subtitle:
                  'Ventana operativa de 31 días con cobertura prioritaria M/T y control semanal de horas.',
              tabs: AgendaSubnav(section: AgendaSubnavSection.horarios),
            ),
            if (usingSafeFallbackAuxiliares) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFD39A)),
                ),
                child: Text(
                  importedMonth == null
                      ? 'Horarios requiere entre 1 y 3 auxiliares activos. Se cargó una base temporal para evitar el bloqueo mientras se sincroniza la información.'
                      : 'El plan importado trae una cantidad no soportada de auxiliares. Se cargó una base temporal para mantener la vista operativa.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8F5A00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildCompactSummaryBar(plan, auxiliaresRegistrados.length),
            const SizedBox(height: 14),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _goPreviousMonth,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: HextColors.bordeTarjeta),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: HextColors.blanco,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: HextColors.textoSuave,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _monthYearLabel(
                              DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month - 1,
                                1,
                              ),
                            ).split(' ').first,
                            style: const TextStyle(
                              fontSize: 13,
                              color: HextColors.textoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ScheduleMatrixCard(
                    days: days,
                    focusedMonth: _focusedMonth,
                    auxiliares: plan.auxiliares,
                    weeklySummaries: plan.weeklySummaries,
                    onCellTap: _showCellPicker,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _goNextMonth,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: HextColors.bordeTarjeta),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _monthYearLabel(
                              DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month + 1,
                                1,
                              ),
                            ).split(' ').first,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5B6474),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Color(0xFF5B6474),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            _buildLegendCard(),
            const SizedBox(height: 10),
            _buildConventionsCard(plan, auxiliaresRegistrados),
            const SizedBox(height: 16),
            _buildWeeklyAlertsCard(plan.weeklySummaries),
          ],
        );
      },
    );
  }

  Widget _buildLegendCard() {
    const List<_LegendItemData> legendItems = <_LegendItemData>[
      _LegendItemData(code: ScheduleCode.m, label: 'Base AM · 06:00–14:00'),
      _LegendItemData(code: ScheduleCode.t, label: 'Base PM · 14:00–22:00'),
      _LegendItemData(
        code: ScheduleCode.r,
        label: 'Refuerzo · 08:00–17:00 · 8 h efectivas',
      ),
      _LegendItemData(
        code: ScheduleCode.j,
        label: 'Cobertura completa · 06:00–22:00',
      ),
      _LegendItemData(
        code: ScheduleCode.f,
        label: 'Festivo especial · 8 h',
      ),
      _LegendItemData(
        code: ScheduleCode.h4,
        label: 'Ajuste operativo · 4 h',
      ),
      _LegendItemData(code: ScheduleCode.l, label: 'Libre'),
      _LegendItemData(code: ScheduleCode.i, label: 'Incapacidad'),
      _LegendItemData(code: ScheduleCode.v, label: 'Vacaciones'),
      _LegendItemData(code: ScheduleCode.p, label: 'Permiso'),
      _LegendItemData(code: ScheduleCode.a, label: 'Ausencia'),
      _LegendItemData(code: ScheduleCode.s, label: 'Suspensión'),
      _LegendItemData(code: ScheduleCode.x, label: 'Pendiente'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Convenciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: legendItems
                .map(
                  (_LegendItemData item) => AppChip(
                    label: '${item.code.label} · ${item.label}',
                    tone: _chipToneForCode(item.code),
                    leadingDot: true,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              AppChip(
                label: 'Domingos/festivos resaltados en rojo suave',
                tone: AppChipTone.warning,
                leadingDot: true,
              ),
              AppChip(
                label: 'Novedades I/V/P/A/S con alta visibilidad',
                tone: AppChipTone.danger,
                leadingDot: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConventionsCard(GeneratedMonthPlan plan, List<String> nombres) {
    final bool isTwoAux = nombres.length == 2;

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          visualDensity: VisualDensity.compact,
          title: const Text(
            'Criterios de programación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          subtitle: const Text(
            'Cobertura prioritaria: M y T · R opcional · objetivo semanal 44 h',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF8A9BB0)),
          ),
          iconColor: const Color(0xFF5F6B7A),
          collapsedIconColor: const Color(0xFF8A9BB0),
          children: <Widget>[
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: <Widget>[
                const _MiniInfo(text: 'M y T son cobertura obligatoria.'),
                const _MiniInfo(
                  text: 'R es opcional y cae primero si sobra carga.',
                ),
                const _MiniInfo(text: 'Si alguien se pasa, R cubre.'),
                const _MiniInfo(
                  text: 'Si el excedido es R, se disminuye o se libera.',
                ),
                const _MiniInfo(text: 'En domingos y festivos no aparece R.'),
                const _MiniInfo(
                  text: 'Ante novedad, R cubre el vacío de M o T.',
                ),
                _MiniInfo(
                  text: isTwoAux
                      ? 'Con 2 auxiliares, el domingo usa J/L por contingencia y alterna.'
                      : 'Con 3 auxiliares, domingos y festivos se reparten con equilibrio.',
                ),
                const _MiniInfo(
                  text: 'Objetivo semanal: 44 h o 42 h según fecha.',
                ),
                const _MiniInfo(
                  text: 'Se marca ALERTA cuando la semana supera el objetivo.',
                ),
                const _MiniInfo(
                  text:
                      'Se marca EXCESO cuando la semana supera objetivo + 12 h.',
                ),
                _MiniInfo(
                  text:
                      'Domingos trabajados: ${plan.notes.maxWorkedSundaysRuleDescription}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAlertsCard(List<WeeklyHoursSummary> summaries) {
    final List<WeeklyHoursSummary> critical = summaries
        .where((WeeklyHoursSummary s) => s.status == WeeklyHoursStatus.invalid)
        .toList();
    final List<WeeklyHoursSummary> alert = summaries
        .where((WeeklyHoursSummary s) => s.status == WeeklyHoursStatus.alert)
        .toList();
    final List<WeeklyHoursSummary> info = summaries
        .where((WeeklyHoursSummary s) => s.status == WeeklyHoursStatus.ok)
        .toList();

    final bool isEmpty = critical.isEmpty && alert.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      constraints: BoxConstraints(
        minHeight: _emptyStateMinHeight(context, isEmpty),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Horas semanales y alertas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AppChip(
                label: 'Critico: ${critical.length}',
                tone: AppChipTone.danger,
                leadingDot: true,
              ),
              AppChip(
                label: 'Alerta: ${alert.length}',
                tone: AppChipTone.warning,
                leadingDot: true,
              ),
              AppChip(
                label: 'Informativo: ${info.length}',
                tone: AppChipTone.neutral,
                leadingDot: true,
              ),
            ],
          ),
          if (critical.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _buildSeverityGroup(
              title: 'Critico',
              tone: AppChipTone.danger,
              items: critical,
            ),
          ],
          if (alert.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _buildSeverityGroup(
              title: 'Alerta',
              tone: AppChipTone.warning,
              items: alert,
            ),
          ],
          if (isEmpty) ...<Widget>[
            const SizedBox(height: 10),
            const Text(
              'Sin eventos criticos ni alertas activas en la semana.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5B6474)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeverityGroup({
    required String title,
    required AppChipTone tone,
    required List<WeeklyHoursSummary> items,
  }) {
    final List<WeeklyHoursSummary> sorted = List<WeeklyHoursSummary>.from(items)
      ..sort((WeeklyHoursSummary a, WeeklyHoursSummary b) {
        final int byName = a.auxiliarNombre.compareTo(b.auxiliarNombre);
        if (byName != 0) return byName;
        return a.weekOrdinal.compareTo(b.weekOrdinal);
      });

    const int maxVisibleChips = 8;
    final List<WeeklyHoursSummary> visible = sorted
        .take(maxVisibleChips)
        .toList();
    final int hiddenCount = sorted.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF243247),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ...visible.map(
              (WeeklyHoursSummary item) => AppChip(
                label:
                    '${item.auxiliarNombre} · S${item.weekOrdinal} · ${item.totalHours} h',
                tone: tone,
                leadingDot: true,
              ),
            ),
            if (hiddenCount > 0)
              AppChip(label: '+$hiddenCount más', tone: AppChipTone.neutral),
          ],
        ),
      ],
    );
  }

  void _goPreviousMonth() {
    setState(() {
      _focusedMonth = _shiftWindowCenterByMonth(_focusedMonth, -1);
    });
    _bindFirestoreWindow();
  }

  void _goNextMonth() {
    setState(() {
      _focusedMonth = _shiftWindowCenterByMonth(_focusedMonth, 1);
    });
    _bindFirestoreWindow();
  }

  Future<void> _showCellPicker(
    String auxiliarNombre,
    DateTime date,
    ScheduleCode current,
  ) async {
    final ScheduleCode? selected = await showModalBottomSheet<ScheduleCode>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$auxiliarNombre · ${_formatDate(date)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF243247),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Turno actual: ${current.label} · ${current.fullName}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6D7884),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ScheduleCode.values.map((ScheduleCode code) {
                    final bool isSelected = code == current;
                    final _CodePalette palette = code._palette;
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.foreground.withValues(alpha: 0.12)
                              : palette.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? palette.foreground
                                : palette.border,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              code.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: palette.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              code.fullName.split(' · ').first,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF6D7884),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != current) {
      _applyOverride(auxiliarNombre, date, selected);
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFDDE4E8)),
    );
  }
}

class _ScheduleMatrixCard extends StatelessWidget {
  const _ScheduleMatrixCard({
    required this.days,
    required this.focusedMonth,
    required this.auxiliares,
    required this.weeklySummaries,
    required this.onCellTap,
  });

  final List<DateTime> days;
  final DateTime focusedMonth;
  final List<AuxiliarMonthlySchedule> auxiliares;
  final List<WeeklyHoursSummary> weeklySummaries;
  final void Function(
    String auxiliarNombre,
    DateTime date,
    ScheduleCode current,
  )
  onCellTap;

  static const double nameColumnWidth = 208;
  static const double dayCellWidth = 34;
  static const double headerCellHeight = 26;
  static const double rowHeight = 40;
  static const double summaryColumnWidth = 104;

  @override
  Widget build(BuildContext context) {
    final double tableWidth =
        nameColumnWidth + (days.length * dayCellWidth) + summaryColumnWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: _CenteredScheduleScroller(
        days: days,
        focusedMonth: focusedMonth,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(),
              ...auxiliares.map(
                (AuxiliarMonthlySchedule a) => _buildAuxiliarRow(a),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: nameColumnWidth,
            height: headerCellHeight * 2,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F2F0),
              border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Auxiliares',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: HextColors.verdePrincipal,
                ),
              ),
            ),
          ),
          ...days.map(
            (DateTime date) => Column(
              children: <Widget>[
                _HeaderDayCell(
                  text: _weekdayLetter(date),
                  width: dayCellWidth,
                  height: headerCellHeight,
                  isSpecial: _isSpecialDay(date),
                  isTop: true,
                  isToday: _isToday(date),
                  isSelectedWeek: isDateInSelectedWeek(date, focusedMonth),
                  isOutOfMonth: false,
                ),
                _HeaderDayCell(
                  text: '${date.day}',
                  width: dayCellWidth,
                  height: headerCellHeight,
                  isSpecial: _isSpecialDay(date),
                  isTop: false,
                  isToday: _isToday(date),
                  isSelectedWeek: isDateInSelectedWeek(date, focusedMonth),
                  isOutOfMonth: false,
                ),
              ],
            ),
          ),
          Container(
            width: summaryColumnWidth,
            height: headerCellHeight * 2,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9F8),
              border: Border(left: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
            ),
            child: const Text(
              'Horas\nAlertas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D6772),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuxiliarRow(AuxiliarMonthlySchedule auxiliar) {
    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          _AuxiliarNameCell(
            width: nameColumnWidth,
            height: rowHeight,
            text: auxiliar.auxiliarNombre,
            weeklyHours: _selectedWeekHours(auxiliar.auxiliarNombre),
          ),
          ...days.map((DateTime day) {
            final DateTime key = _onlyDate(day);
            final ScheduleCode code =
                auxiliar.assignments[key] ?? ScheduleCode.x;

            const bool isOutOfMonth = false;
            final String? specialName = holidayName(day);
            final String suffix = specialName == null ? '' : ' · $specialName';

            return _ScheduleCodeCell(
              code: code,
              width: dayCellWidth,
              height: rowHeight,
              isSpecialDay: !isOutOfMonth && _isSpecialDay(day),
              isToday: _isToday(day),
              isSelectedWeek: isDateInSelectedWeek(day, focusedMonth),
              isOutOfMonth: isOutOfMonth,
              tooltip:
                  '${auxiliar.auxiliarNombre} · ${_formatDate(day)}$suffix · ${code.fullName}',
              onTap: () => onCellTap(auxiliar.auxiliarNombre, day, code),
            );
          }),
          _AuxiliarSummaryCell(
            width: summaryColumnWidth,
            height: rowHeight,
            monthlyHours: _monthlyHours(auxiliar.auxiliarNombre),
            criticalCount: _statusCount(
              auxiliar.auxiliarNombre,
              WeeklyHoursStatus.invalid,
            ),
            alertCount: _statusCount(
              auxiliar.auxiliarNombre,
              WeeklyHoursStatus.alert,
            ),
          ),
        ],
      ),
    );
  }

  int _monthlyHours(String auxiliarNombre) {
    return weeklySummaries
        .where((WeeklyHoursSummary s) => s.auxiliarNombre == auxiliarNombre)
        .fold<int>(
          0,
          (int sum, WeeklyHoursSummary item) => sum + item.totalHours,
        );
  }

  int _statusCount(String auxiliarNombre, WeeklyHoursStatus status) {
    return weeklySummaries
        .where(
          (WeeklyHoursSummary s) =>
              s.auxiliarNombre == auxiliarNombre && s.status == status,
        )
        .length;
  }

  int _selectedWeekHours(String auxiliarNombre) {
    final DateTime selectedWeekStart = startOfWeek(focusedMonth);
    for (final WeeklyHoursSummary summary in weeklySummaries) {
      if (summary.auxiliarNombre == auxiliarNombre &&
          isSameDate(summary.weekStart, selectedWeekStart)) {
        return summary.totalHours;
      }
    }
    return 0;
  }
}

class _CenteredScheduleScroller extends StatefulWidget {
  const _CenteredScheduleScroller({
    required this.days,
    required this.focusedMonth,
    required this.child,
  });

  final List<DateTime> days;
  final DateTime focusedMonth;
  final Widget child;

  @override
  State<_CenteredScheduleScroller> createState() =>
      _CenteredScheduleScrollerState();
}

class _CenteredScheduleScrollerState extends State<_CenteredScheduleScroller> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerFocusedDate();
    });
  }

  @override
  void didUpdateWidget(covariant _CenteredScheduleScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth.year != widget.focusedMonth.year ||
        oldWidget.focusedMonth.month != widget.focusedMonth.month ||
        oldWidget.focusedMonth.day != widget.focusedMonth.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerFocusedDate();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerFocusedDate() {
    if (!_controller.hasClients) return;

    final int targetIndex = widget.days.indexWhere(
      (DateTime day) =>
          day.year == widget.focusedMonth.year &&
          day.month == widget.focusedMonth.month &&
          day.day == widget.focusedMonth.day,
    );
    if (targetIndex < 0) return;

    final double viewportWidth = _controller.position.viewportDimension;
    final double targetCenter =
        _ScheduleMatrixCard.nameColumnWidth +
        (targetIndex * _ScheduleMatrixCard.dayCellWidth) +
        (_ScheduleMatrixCard.dayCellWidth / 2);
    final double desiredOffset = targetCenter - (viewportWidth / 2);
    final double maxOffset = _controller.position.maxScrollExtent;
    final double clampedOffset = desiredOffset.clamp(0.0, maxOffset);

    _controller.jumpTo(clampedOffset);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    );
  }
}

class _HeaderDayCell extends StatelessWidget {
  const _HeaderDayCell({
    required this.text,
    required this.width,
    required this.height,
    required this.isSpecial,
    required this.isTop,
    this.isToday = false,
    this.isSelectedWeek = false,
    this.isOutOfMonth = false,
  });

  final String text;
  final double width;
  final double height;
  final bool isSpecial;
  final bool isTop;
  final bool isToday;
  final bool isSelectedWeek;
  final bool isOutOfMonth;

  @override
  Widget build(BuildContext context) {
    final Color background = isToday
        ? (isTop ? const Color(0xFFF2F7F5) : const Color(0xFFF7FBFA))
        : isSelectedWeek
        ? (isTop ? const Color(0xFFF5F8F7) : const Color(0xFFFAFCFB))
        : isOutOfMonth
        ? (isTop ? const Color(0xFFF6F7F8) : const Color(0xFFFAFBFB))
        : isSpecial
        ? (isTop ? const Color(0xFFF8F1F0) : const Color(0xFFFCF7F6))
        : (isTop ? const Color(0xFFF4F8F7) : const Color(0xFFFBFCFC));

    final Color foreground = isToday
        ? const Color(0xFF17726D)
        : isSelectedWeek
        ? const Color(0xFF17726D)
        : isOutOfMonth
        ? const Color(0xFFB5BEC7)
        : isSpecial
        ? const Color(0xFFB45151)
        : const Color(0xFF17726D);

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: BorderSide(
              color: isToday ? const Color(0xFFD7E7E2) : const Color(0xFFE5E7EB),
              width: isToday ? 1 : 0.5,
            ),
            bottom: BorderSide(
              color: isToday || isSelectedWeek
                  ? const Color(0xFFD7E7E2)
                  : const Color(0xFFE5E7EB),
              width: isToday ? 1 : 0.5,
            ),
          ),
        ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTop ? 12 : 12.5,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

class _AuxiliarNameCell extends StatelessWidget {
  const _AuxiliarNameCell({
    required this.width,
    required this.height,
    required this.text,
    required this.weeklyHours,
  });

  final double width;
  final double height;
  final String text;
  final int weeklyHours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFCFC),
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF243247),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$weeklyHours h',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: _weeklyHoursColor(weeklyHours),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuxiliarSummaryCell extends StatelessWidget {
  const _AuxiliarSummaryCell({
    required this.width,
    required this.height,
    required this.monthlyHours,
    required this.criticalCount,
    required this.alertCount,
  });

  final double width;
  final double height;
  final int monthlyHours;
  final int criticalCount;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFCFC),
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$monthlyHours h',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF243247),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'C:$criticalCount A:$alertCount',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6D7884),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCodeCell extends StatelessWidget {
  const _ScheduleCodeCell({
    required this.code,
    required this.width,
    required this.height,
    required this.isSpecialDay,
    required this.tooltip,
    required this.onTap,
    this.isToday = false,
    this.isSelectedWeek = false,
    this.isOutOfMonth = false,
  });

  final ScheduleCode code;
  final double width;
  final double height;
  final bool isSpecialDay;
  final bool isToday;
  final bool isSelectedWeek;
  final bool isOutOfMonth;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _CodePalette palette = code._palette;

    final Color background = isToday
        ? const Color(0xFFF8FBFA)
        : isSelectedWeek
        ? const Color(0xFFFBFCFC)
        : isOutOfMonth
        ? const Color(0xFFF7F8F9)
        : isSpecialDay
        ? const Color(0xFFFCF8F7)
        : palette.background;

    final Color foreground = isToday
        ? const Color(0xFF17726D)
        : isSelectedWeek && !code.isInstitutionalShift
        ? palette.foreground
        : isSelectedWeek
        ? const Color(0xFF4E6A67)
        : isOutOfMonth
        ? const Color(0xFFD0D7DF)
        : code.isInstitutionalShift
        ? const Color(0xFF5F6B7A)
        : palette.foreground;

    final Color rightBorder = isOutOfMonth
        ? const Color(0xFFEAECEF)
        : isSpecialDay
        ? const Color(0xFFF1E4E1)
        : palette.border;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            border: Border(
              right: BorderSide(
                color: isToday ? const Color(0xFFD7E7E2) : rightBorder,
                width: isToday ? 1 : 0.5,
              ),
              bottom: BorderSide(
                color: isSelectedWeek
                    ? const Color(0xFFE5EDE9)
                    : Colors.transparent,
                width: isSelectedWeek ? 0.5 : 0,
              ),
            ),
          ),
          child: Text(
            code.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E8EA)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D6772)),
      ),
    );
  }
}

class _LegendItemData {
  const _LegendItemData({required this.code, required this.label});

  final ScheduleCode code;
  final String label;
}

AppChipTone _chipToneForCode(ScheduleCode code) {
  switch (code) {
    case ScheduleCode.m:
      return AppChipTone.neutral;
    case ScheduleCode.t:
      return AppChipTone.neutral;
    case ScheduleCode.r:
      return AppChipTone.warning;
    case ScheduleCode.j:
      return AppChipTone.neutral;
    case ScheduleCode.f:
      return AppChipTone.warning;
    case ScheduleCode.h4:
      return AppChipTone.neutral;
    case ScheduleCode.l:
      return AppChipTone.neutral;
    case ScheduleCode.i:
    case ScheduleCode.a:
    case ScheduleCode.s:
    case ScheduleCode.x:
      return AppChipTone.danger;
    case ScheduleCode.v:
      return AppChipTone.neutral;
    case ScheduleCode.p:
      return AppChipTone.warning;
  }
}

enum TwoAuxSundayPolicy { contingencyJ, normalMT }

enum ScheduleCode { m, t, r, j, f, h4, l, i, v, p, a, s, x }

extension ScheduleCodeX on ScheduleCode {
  static ScheduleCode fromImportedTurno(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'M':
        return ScheduleCode.m;
      case 'T':
        return ScheduleCode.t;
      case 'R':
        return ScheduleCode.r;
      case 'C':
      case 'J':
        return ScheduleCode.j;
      case 'F':
        return ScheduleCode.f;
      case '4H':
        return ScheduleCode.h4;
      case 'L':
        return ScheduleCode.l;
      case 'I':
        return ScheduleCode.i;
      case 'V':
        return ScheduleCode.v;
      case 'P':
        return ScheduleCode.p;
      case 'A':
        return ScheduleCode.a;
      case 'S':
        return ScheduleCode.s;
      default:
        return ScheduleCode.x;
    }
  }

  String get label {
    switch (this) {
      case ScheduleCode.m:
        return 'M';
      case ScheduleCode.t:
        return 'T';
      case ScheduleCode.r:
        return 'R';
      case ScheduleCode.j:
        return 'C';
      case ScheduleCode.f:
        return 'F';
      case ScheduleCode.h4:
        return '4H';
      case ScheduleCode.l:
        return 'L';
      case ScheduleCode.i:
        return 'I';
      case ScheduleCode.v:
        return 'V';
      case ScheduleCode.p:
        return 'P';
      case ScheduleCode.a:
        return 'A';
      case ScheduleCode.s:
        return 'S';
      case ScheduleCode.x:
        return 'X';
    }
  }

  String get fullName {
    if (this == ScheduleCode.j) {
      return 'Cobertura completa · 06:00–22:00';
    }
    if (this == ScheduleCode.f) {
      return 'Festivo especial · 8 h';
    }
    if (this == ScheduleCode.h4) {
      return 'Ajuste operativo · 4 h';
    }
    switch (this) {
      case ScheduleCode.m:
        return 'Base AM · 06:00–14:00';
      case ScheduleCode.t:
        return 'Base PM · 14:00–22:00';
      case ScheduleCode.r:
        return 'Refuerzo · 08:00–17:00 · 8 h efectivas';
      case ScheduleCode.j:
        return 'Jornada completa · 06:00–22:00';
      case ScheduleCode.f:
        return 'Festivo especial · 8 h';
      case ScheduleCode.h4:
        return 'Ajuste operativo · 4 h';
      case ScheduleCode.l:
        return 'Libre';
      case ScheduleCode.i:
        return 'Incapacidad';
      case ScheduleCode.v:
        return 'Vacaciones';
      case ScheduleCode.p:
        return 'Permiso';
      case ScheduleCode.a:
        return 'Ausencia';
      case ScheduleCode.s:
        return 'Suspensión';
      case ScheduleCode.x:
        return 'Pendiente';
    }
  }

  int get hours {
    switch (this) {
      case ScheduleCode.m:
        return 8;
      case ScheduleCode.t:
        return 8;
      case ScheduleCode.r:
        return 8;
      case ScheduleCode.j:
        return 16;
      case ScheduleCode.f:
        return 8;
      case ScheduleCode.h4:
        return 4;
      case ScheduleCode.l:
      case ScheduleCode.i:
      case ScheduleCode.v:
      case ScheduleCode.p:
      case ScheduleCode.a:
      case ScheduleCode.s:
      case ScheduleCode.x:
        return 0;
    }
  }

  bool get isInstitutionalShift {
    return this == ScheduleCode.m ||
        this == ScheduleCode.t ||
        this == ScheduleCode.r ||
        this == ScheduleCode.j ||
        this == ScheduleCode.f ||
        this == ScheduleCode.h4;
  }

  bool get isWorkingShift => hours > 0;

  _CodePalette get _palette {
    const _CodePalette institutional = _CodePalette(
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF5F6B7A),
      border: Color(0xFFE5E7EB),
    );

    switch (this) {
      case ScheduleCode.m:
        return institutional;
      case ScheduleCode.t:
        return institutional;
      case ScheduleCode.r:
        return institutional;
      case ScheduleCode.j:
        return institutional;
      case ScheduleCode.f:
        return institutional;
      case ScheduleCode.h4:
        return institutional;
      case ScheduleCode.l:
        return const _CodePalette(
          background: Color(0xFFFBFCFC),
          foreground: Color(0xFF98A2AE),
          border: Color(0xFFE5E7EB),
        );
      case ScheduleCode.i:
        return const _CodePalette(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFFB42318),
          border: Color(0xFFF0D5D5),
        );
      case ScheduleCode.v:
        return const _CodePalette(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFF726A5D),
          border: Color(0xFFE6E0D7),
        );
      case ScheduleCode.p:
        return const _CodePalette(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFF946200),
          border: Color(0xFFEEDDB6),
        );
      case ScheduleCode.a:
        return const _CodePalette(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFFB04B65),
          border: Color(0xFFEED3DA),
        );
      case ScheduleCode.s:
        return const _CodePalette(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFFB42318),
          border: Color(0xFFF0D5D5),
        );
      case ScheduleCode.x:
        return const _CodePalette(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFFB42318),
          border: Color(0xFFEFD0D0),
        );
    }
  }
}

class _CodePalette {
  const _CodePalette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class AuxiliarMonthlySchedule {
  const AuxiliarMonthlySchedule({
    required this.auxiliarNombre,
    required this.assignments,
  });

  final String auxiliarNombre;
  final Map<DateTime, ScheduleCode> assignments;
}

class GeneratedMonthPlan {
  const GeneratedMonthPlan({
    required this.auxiliares,
    required this.weeklySummaries,
    required this.notes,
  });

  final List<AuxiliarMonthlySchedule> auxiliares;
  final List<WeeklyHoursSummary> weeklySummaries;
  final PlanNotes notes;
}

class PlanNotes {
  const PlanNotes({required this.maxWorkedSundaysRuleDescription});

  final String maxWorkedSundaysRuleDescription;
}

class WeeklyHoursSummary {
  const WeeklyHoursSummary({
    required this.auxiliarNombre,
    required this.weekStart,
    required this.weekOrdinal,
    required this.totalHours,
    required this.targetHours,
    required this.effectiveTargetHours,
    required this.displayedDays,
    required this.freeDays,
    required this.isPartialWeek,
    required this.status,
  });

  final String auxiliarNombre;
  final DateTime weekStart;
  final int weekOrdinal;
  final int totalHours;
  final int targetHours;
  final int effectiveTargetHours;
  final int displayedDays;
  final int freeDays;
  final bool isPartialWeek;
  final WeeklyHoursStatus status;
}

enum WeeklyHoursStatus { ok, alert, invalid }

extension WeeklyHoursStatusX on WeeklyHoursStatus {
  String get label {
    switch (this) {
      case WeeklyHoursStatus.ok:
        return 'OK';
      case WeeklyHoursStatus.alert:
        return 'ALERTA';
      case WeeklyHoursStatus.invalid:
        return 'EXCESO';
    }
  }
}

class _SpecialLoad {
  int workedSundays = 0;
  int workedSpecialDays = 0;
  int? lastSpecialOrder;
  DateTime? lastJDate;
}

class _RestCandidate {
  const _RestCandidate.dropReserve({required this.day})
    : reserveIndex = null,
      reserveCoverage = null;

  const _RestCandidate.swapCoverage({
    required this.day,
    required this.reserveIndex,
    required this.reserveCoverage,
  });

  final DateTime day;
  final int? reserveIndex;
  final ScheduleCode? reserveCoverage;

  bool get isDropReserve => reserveIndex == null;
}

GeneratedMonthPlan _buildImportedMonthPlan({
  required DateTime month,
  required ImportedScheduleMonthData importedMonth,
  required List<DateTime> visibleDays,
  Map<String, Map<DateTime, ScheduleCode>> overrides =
      const <String, Map<DateTime, ScheduleCode>>{},
}) {
  final DateTime normalizedMonth = DateTime(month.year, month.month, 1);
  final List<DateTime> days = visibleDays;
  final List<String> nombres = importedMonth.auxiliarNames;
  final List<String> baseNombres = nombres.take(3).toList();

  final GeneratedMonthPlan basePlan = _generateMonthPlan(
    year: normalizedMonth.year,
    month: normalizedMonth.month,
    nombres: baseNombres,
    visibleDays: days,
    twoAuxSundayPolicy: kHorarioTwoAuxSundayPolicy,
  );

  final List<AuxiliarMonthlySchedule> auxiliares = <AuxiliarMonthlySchedule>[];

  for (int index = 0; index < nombres.length; index++) {
    final String nombre = nombres[index];
    final Map<DateTime, ScheduleCode> assignments =
        index < basePlan.auxiliares.length
        ? Map<DateTime, ScheduleCode>.from(
            basePlan.auxiliares[index].assignments,
          )
        : <DateTime, ScheduleCode>{
            for (final DateTime day in days) _onlyDate(day): ScheduleCode.l,
          };

    final Map<DateTime, ScheduledShift> importedAssignments =
        importedMonth.entriesByAuxiliar[nombre] ??
        const <DateTime, ScheduledShift>{};
    importedAssignments.forEach((
      DateTime date,
      ScheduledShift entry,
    ) {
      assignments[_onlyDate(date)] = ScheduleCodeX.fromImportedTurno(entry.turno);
    });

    final Map<DateTime, ScheduleCode>? manualOverrides = overrides[nombre];
    if (manualOverrides != null) {
      manualOverrides.forEach((DateTime date, ScheduleCode code) {
        assignments[_onlyDate(date)] = code;
      });
    }

    auxiliares.add(
      AuxiliarMonthlySchedule(
        auxiliarNombre: nombre,
        assignments: assignments,
      ),
    );
  }

  final List<WeeklyHoursSummary> weeklySummaries = _buildWeeklySummaries(
    days: days,
    auxiliares: auxiliares,
  );

  return GeneratedMonthPlan(
    auxiliares: auxiliares,
    weeklySummaries: weeklySummaries,
    notes: const PlanNotes(
      maxWorkedSundaysRuleDescription:
          'Horario importado HEXT activo; fuera de los dias cargados se conserva base operativa.',
    ),
  );
}

GeneratedMonthPlan _generateMonthPlan({
  required int year,
  required int month,
  required List<String> nombres,
  List<DateTime>? visibleDays,
  required TwoAuxSundayPolicy twoAuxSundayPolicy,
  Map<String, Map<DateTime, ScheduleCode>> overrides =
      const <String, Map<DateTime, ScheduleCode>>{},
}) {
  if (nombres.isEmpty || nombres.length > 3) {
    throw Exception('Solo se permiten 1, 2 o 3 auxiliares de enfermería.');
  }

  final List<DateTime> days =
      visibleDays ?? _daysOfMonth(DateTime(year, month, 1));
  final int totalAuxiliares = nombres.length;

  final List<Map<DateTime, ScheduleCode>> assignments =
      List<Map<DateTime, ScheduleCode>>.generate(
        totalAuxiliares,
        (_) => <DateTime, ScheduleCode>{},
      );

  final List<_SpecialLoad> loads = List<_SpecialLoad>.generate(
    totalAuxiliares,
    (_) => _SpecialLoad(),
  );

  int specialOrder = 0;

  for (final DateTime day in days) {
    final DateTime key = _onlyDate(day);

    if (_isSpecialDay(day)) {
      _assignSpecialDay(
        day: day,
        key: key,
        totalAuxiliares: totalAuxiliares,
        assignments: assignments,
        loads: loads,
        specialOrder: specialOrder,
        twoAuxSundayPolicy: twoAuxSundayPolicy,
      );
      specialOrder += 1;
      continue;
    }

    _assignRegularDay(
      day: day,
      key: key,
      totalAuxiliares: totalAuxiliares,
      assignments: assignments,
    );
  }

  if (totalAuxiliares == 3) {
    _rebalanceOptionalRToRest(days: days, assignments: assignments);
  }

  // Apply manual overrides after auto-generation and rebalance.
  for (int i = 0; i < nombres.length; i++) {
    final Map<DateTime, ScheduleCode>? byName = overrides[nombres[i]];
    if (byName == null) continue;
    byName.forEach((DateTime date, ScheduleCode code) {
      assignments[i][DateTime(date.year, date.month, date.day)] = code;
    });
  }

  final List<AuxiliarMonthlySchedule> auxiliares =
      List<AuxiliarMonthlySchedule>.generate(
        totalAuxiliares,
        (int index) => AuxiliarMonthlySchedule(
          auxiliarNombre: nombres[index],
          assignments: assignments[index],
        ),
      );

  final List<WeeklyHoursSummary> weeklySummaries = _buildWeeklySummaries(
    days: days,
    auxiliares: auxiliares,
  );

  return GeneratedMonthPlan(
    auxiliares: auxiliares,
    weeklySummaries: weeklySummaries,
    notes: const PlanNotes(
      maxWorkedSundaysRuleDescription:
          'máximo objetivo 2; si el mes no cierra con 3 auxiliares, se prioriza cobertura y se marca alerta',
    ),
  );
}

void _assignRegularDay({
  required DateTime day,
  required DateTime key,
  required int totalAuxiliares,
  required List<Map<DateTime, ScheduleCode>> assignments,
}) {
  final int weekDelta = _weeksBetween(
    _mondayOfWeek(kRotationAnchorMonday),
    _mondayOfWeek(day),
  );

  switch (totalAuxiliares) {
    case 1:
      assignments[0][key] = weekDelta.isEven ? ScheduleCode.m : ScheduleCode.t;
      return;

    case 2:
      if (weekDelta.isEven) {
        assignments[0][key] = ScheduleCode.m;
        assignments[1][key] = ScheduleCode.t;
      } else {
        assignments[0][key] = ScheduleCode.t;
        assignments[1][key] = ScheduleCode.m;
      }
      return;

    case 3:
      final int cycle = ((weekDelta % 3) + 3) % 3;
      const List<List<ScheduleCode>> rotations = <List<ScheduleCode>>[
        <ScheduleCode>[ScheduleCode.m, ScheduleCode.t, ScheduleCode.r],
        <ScheduleCode>[ScheduleCode.t, ScheduleCode.r, ScheduleCode.m],
        <ScheduleCode>[ScheduleCode.r, ScheduleCode.m, ScheduleCode.t],
      ];

      for (int i = 0; i < 3; i++) {
        assignments[i][key] = rotations[cycle][i];
      }
      return;

    default:
      return;
  }
}

void _assignSpecialDay({
  required DateTime day,
  required DateTime key,
  required int totalAuxiliares,
  required List<Map<DateTime, ScheduleCode>> assignments,
  required List<_SpecialLoad> loads,
  required int specialOrder,
  required TwoAuxSundayPolicy twoAuxSundayPolicy,
}) {
  final bool isSunday = day.weekday == DateTime.sunday;

  if (totalAuxiliares == 1) {
    final ScheduleCode code = isSunday
        ? ScheduleCode.j
        : _orderedSpecialShifts(specialOrder).first;
    assignments[0][key] = code;
    _registerSpecialLoad(
      load: loads[0],
      date: day,
      specialOrder: specialOrder,
      isJ: code == ScheduleCode.j,
    );
    return;
  }

  if (totalAuxiliares == 2 &&
      isSunday &&
      twoAuxSundayPolicy == TwoAuxSundayPolicy.contingencyJ) {
    final int worker = _pickSundayJWorker(date: day, loads: loads);
    final int rest = worker == 0 ? 1 : 0;

    assignments[worker][key] = ScheduleCode.j;
    assignments[rest][key] = ScheduleCode.l;

    _registerSpecialLoad(
      load: loads[worker],
      date: day,
      specialOrder: specialOrder,
      isJ: true,
    );
    return;
  }

  final List<ScheduleCode> shifts = _orderedSpecialShifts(specialOrder);
  final List<int> workers = _pickFairSpecialWorkers(
    date: day,
    loads: loads,
    count: 2,
  );

  for (int auxiliarIndex = 0; auxiliarIndex < totalAuxiliares; auxiliarIndex++) {
    if (auxiliarIndex == workers[0]) {
      assignments[auxiliarIndex][key] = shifts[0];
    } else if (auxiliarIndex == workers[1]) {
      assignments[auxiliarIndex][key] = shifts[1];
    } else {
      assignments[auxiliarIndex][key] = ScheduleCode.l;
    }
  }

  _registerSpecialLoad(
    load: loads[workers[0]],
    date: day,
    specialOrder: specialOrder,
    isJ: false,
  );
  _registerSpecialLoad(
    load: loads[workers[1]],
    date: day,
    specialOrder: specialOrder,
    isJ: false,
  );
}

void _registerSpecialLoad({
  required _SpecialLoad load,
  required DateTime date,
  required int specialOrder,
  required bool isJ,
}) {
  load.workedSpecialDays += 1;
  load.lastSpecialOrder = specialOrder;

  if (date.weekday == DateTime.sunday) {
    load.workedSundays += 1;
  }
  if (isJ) {
    load.lastJDate = _onlyDate(date);
  }
}

int _pickSundayJWorker({
  required DateTime date,
  required List<_SpecialLoad> loads,
}) {
  final List<int> candidates = List<int>.generate(
    loads.length,
    (int index) => index,
  );

  candidates.sort((int a, int b) {
    final _SpecialLoad loadA = loads[a];
    final _SpecialLoad loadB = loads[b];

    final bool aWasLastSundayJ =
        loadA.lastJDate != null &&
        _onlyDate(date).difference(loadA.lastJDate!).inDays == 7;
    final bool bWasLastSundayJ =
        loadB.lastJDate != null &&
        _onlyDate(date).difference(loadB.lastJDate!).inDays == 7;

    final int consecutiveCompare = (aWasLastSundayJ ? 1 : 0).compareTo(
      bWasLastSundayJ ? 1 : 0,
    );
    if (consecutiveCompare != 0) return consecutiveCompare;

    final int sundayCompare = loadA.workedSundays.compareTo(
      loadB.workedSundays,
    );
    if (sundayCompare != 0) return sundayCompare;

    final int specialCompare = loadA.workedSpecialDays.compareTo(
      loadB.workedSpecialDays,
    );
    if (specialCompare != 0) return specialCompare;

    final int lastA = loadA.lastSpecialOrder ?? -9999;
    final int lastB = loadB.lastSpecialOrder ?? -9999;
    final int restCompare = lastA.compareTo(lastB);
    if (restCompare != 0) return restCompare;

    return a.compareTo(b);
  });

  return candidates.first;
}

List<int> _pickFairSpecialWorkers({
  required DateTime date,
  required List<_SpecialLoad> loads,
  required int count,
}) {
  final bool isSunday = date.weekday == DateTime.sunday;

  final List<int> sorted = List<int>.generate(
    loads.length,
    (int index) => index,
  );

  sorted.sort((int a, int b) {
    final _SpecialLoad loadA = loads[a];
    final _SpecialLoad loadB = loads[b];

    if (isSunday) {
      final int sundayCompare = loadA.workedSundays.compareTo(
        loadB.workedSundays,
      );
      if (sundayCompare != 0) return sundayCompare;
    }

    final int specialCompare = loadA.workedSpecialDays.compareTo(
      loadB.workedSpecialDays,
    );
    if (specialCompare != 0) return specialCompare;

    final int lastA = loadA.lastSpecialOrder ?? -9999;
    final int lastB = loadB.lastSpecialOrder ?? -9999;
    final int restCompare = lastA.compareTo(lastB);
    if (restCompare != 0) return restCompare;

    return a.compareTo(b);
  });

  if (!isSunday) {
    return sorted.take(count).toList();
  }

  final List<int> underPreferredCap = sorted
      .where((int index) => loads[index].workedSundays < 2)
      .toList();

  if (underPreferredCap.length >= count) {
    return underPreferredCap.take(count).toList();
  }

  final List<int> result = <int>[...underPreferredCap];
  for (final int index in sorted) {
    if (!result.contains(index)) {
      result.add(index);
      if (result.length == count) break;
    }
  }

  return result;
}

List<ScheduleCode> _orderedSpecialShifts(int specialOrder) {
  return specialOrder.isEven
      ? <ScheduleCode>[ScheduleCode.m, ScheduleCode.t]
      : <ScheduleCode>[ScheduleCode.t, ScheduleCode.m];
}

/// Rebalanceo suave:
/// si con 3 auxiliares alguien quedó pasado del objetivo semanal y aún no tiene
/// día libre, se intenta convertir un R de día normal en L.
/// Así se respeta M/T y R cae primero.
void _rebalanceOptionalRToRest({
  required List<DateTime> days,
  required List<Map<DateTime, ScheduleCode>> assignments,
}) {
  final Map<DateTime, List<DateTime>> weeks = _groupDaysByWeek(days);

  final List<DateTime> weekStarts = weeks.keys.toList()
    ..sort((DateTime a, DateTime b) => a.compareTo(b));

  for (final DateTime weekStart in weekStarts) {
    final List<DateTime> weekDays = weeks[weekStart] ?? <DateTime>[];

    // No fuerces rebalances en semanas parciales del borde del mes.
    if (weekDays.length < 7) {
      continue;
    }

    final int targetHours = _weeklyTargetHoursForWeek(weekStart);

    bool changedInWeek = true;
    while (changedInWeek) {
      changedInWeek = false;

      final List<int> weeklyHours = List<int>.generate(
        assignments.length,
        (int index) => _sumHoursForWeek(
          assignments: assignments[index],
          weekDays: weekDays,
        ),
      );

      final List<int> freeDays = List<int>.generate(
        assignments.length,
        (int index) => _sumFreeDaysForWeek(
          assignments: assignments[index],
          weekDays: weekDays,
        ),
      );

      final List<int> needingRelief =
          List<int>.generate(assignments.length, (int index) => index)
            ..sort((int a, int b) {
              final int freeCompare = freeDays[a].compareTo(freeDays[b]);
              if (freeCompare != 0) return freeCompare;
              return weeklyHours[b].compareTo(weeklyHours[a]);
            });

      for (final int auxiliarIndex in needingRelief) {
        // La prioridad es dar 1 L a quien está pasado y no tiene libre.
        if (freeDays[auxiliarIndex] > 0) {
          continue;
        }
        if (weeklyHours[auxiliarIndex] <= targetHours) {
          continue;
        }

        final _RestCandidate? candidate = _findRestCandidate(
          auxiliarIndex: auxiliarIndex,
          weekDays: weekDays,
          assignments: assignments,
          weeklyHours: weeklyHours,
        );

        if (candidate == null) {
          continue;
        }

        assignments[auxiliarIndex][candidate.day] = ScheduleCode.l;

        if (!candidate.isDropReserve) {
          assignments[candidate.reserveIndex!][candidate.day] =
              candidate.reserveCoverage!;
        }

        changedInWeek = true;
        break;
      }
    }
  }
}

_RestCandidate? _findRestCandidate({
  required int auxiliarIndex,
  required List<DateTime> weekDays,
  required List<Map<DateTime, ScheduleCode>> assignments,
  required List<int> weeklyHours,
}) {
  // 1) Primero cae R, porque es opcional.
  for (final DateTime day in weekDays) {
    final DateTime key = _onlyDate(day);

    if (_isSpecialDay(day)) {
      continue;
    }

    final ScheduleCode currentCode =
        assignments[auxiliarIndex][key] ?? ScheduleCode.x;

    if (currentCode != ScheduleCode.r) {
      continue;
    }

    final bool keepsCoverage = _dayKeepsMandatoryCoverage(
      assignments: assignments,
      day: key,
      overrideAuxiliarIndex: auxiliarIndex,
      overrideCode: ScheduleCode.l,
    );

    if (keepsCoverage) {
      return _RestCandidate.dropReserve(day: key);
    }
  }

  // 2) Si está en M o T, R toma su lugar y el excedido pasa a L.
  for (final DateTime day in weekDays) {
    final DateTime key = _onlyDate(day);

    if (_isSpecialDay(day)) {
      continue;
    }

    final ScheduleCode overloadedCode =
        assignments[auxiliarIndex][key] ?? ScheduleCode.x;

    if (overloadedCode != ScheduleCode.m && overloadedCode != ScheduleCode.t) {
      continue;
    }

    final List<int> reserveCandidates =
        List<int>.generate(assignments.length, (int index) => index)
            .where(
              (int index) =>
                  index != auxiliarIndex &&
                  (assignments[index][key] ?? ScheduleCode.x) == ScheduleCode.r,
            )
            .toList()
          ..sort((int a, int b) => weeklyHours[a].compareTo(weeklyHours[b]));

    for (final int reserveIndex in reserveCandidates) {
      final bool keepsCoverage = _dayKeepsMandatoryCoverageWithSwap(
        assignments: assignments,
        day: key,
        overloadedIndex: auxiliarIndex,
        reserveIndex: reserveIndex,
        reserveCoverage: overloadedCode,
      );

      if (!keepsCoverage) {
        continue;
      }

      return _RestCandidate.swapCoverage(
        day: key,
        reserveIndex: reserveIndex,
        reserveCoverage: overloadedCode,
      );
    }
  }

  return null;
}

bool _dayKeepsMandatoryCoverage({
  required List<Map<DateTime, ScheduleCode>> assignments,
  required DateTime day,
  required int overrideAuxiliarIndex,
  required ScheduleCode overrideCode,
}) {
  bool hasM = false;
  bool hasT = false;

  for (int i = 0; i < assignments.length; i++) {
    final ScheduleCode code = i == overrideAuxiliarIndex
        ? overrideCode
        : (assignments[i][day] ?? ScheduleCode.x);

    if (code == ScheduleCode.m) {
      hasM = true;
    } else if (code == ScheduleCode.t) {
      hasT = true;
    }
  }

  return hasM && hasT;
}

bool _dayKeepsMandatoryCoverageWithSwap({
  required List<Map<DateTime, ScheduleCode>> assignments,
  required DateTime day,
  required int overloadedIndex,
  required int reserveIndex,
  required ScheduleCode reserveCoverage,
}) {
  bool hasM = false;
  bool hasT = false;

  for (int i = 0; i < assignments.length; i++) {
    late final ScheduleCode code;

    if (i == overloadedIndex) {
      code = ScheduleCode.l;
    } else if (i == reserveIndex) {
      code = reserveCoverage;
    } else {
      code = assignments[i][day] ?? ScheduleCode.x;
    }

    if (code == ScheduleCode.m) {
      hasM = true;
    } else if (code == ScheduleCode.t) {
      hasT = true;
    }
  }

  return hasM && hasT;
}

List<WeeklyHoursSummary> _buildWeeklySummaries({
  required List<DateTime> days,
  required List<AuxiliarMonthlySchedule> auxiliares,
}) {
  final Map<DateTime, List<DateTime>> weeks = _groupDaysByWeek(days);
  final List<DateTime> weekStarts = weeks.keys.toList()
    ..sort((DateTime a, DateTime b) => a.compareTo(b));

  final List<WeeklyHoursSummary> result = <WeeklyHoursSummary>[];

  for (
    int auxiliarIndex = 0;
    auxiliarIndex < auxiliares.length;
    auxiliarIndex++
  ) {
    final AuxiliarMonthlySchedule auxiliar = auxiliares[auxiliarIndex];

    for (int weekIndex = 0; weekIndex < weekStarts.length; weekIndex++) {
      final DateTime weekStart = weekStarts[weekIndex];
      final List<DateTime> weekDays = weeks[weekStart] ?? <DateTime>[];

      final int totalHours = _sumHoursForWeek(
        assignments: auxiliar.assignments,
        weekDays: weekDays,
      );

      final int freeDays = _sumFreeDaysForWeek(
        assignments: auxiliar.assignments,
        weekDays: weekDays,
      );

      final int targetHours = _weeklyTargetHoursForWeek(weekStart);
      final int effectiveTargetHours = _effectiveTargetHoursForDisplayedDays(
        targetHours: targetHours,
        displayedDays: weekDays.length,
      );

      final bool isPartialWeek = weekDays.length < 7;

      final WeeklyHoursStatus status = _hoursStatus(
        totalHours: totalHours,
        targetHours: effectiveTargetHours,
      );

      result.add(
        WeeklyHoursSummary(
          auxiliarNombre: auxiliar.auxiliarNombre,
          weekStart: weekStart,
          weekOrdinal: weekIndex + 1,
          totalHours: totalHours,
          targetHours: targetHours,
          effectiveTargetHours: effectiveTargetHours,
          displayedDays: weekDays.length,
          freeDays: freeDays,
          isPartialWeek: isPartialWeek,
          status: status,
        ),
      );
    }
  }

  return result;
}

WeeklyHoursStatus _hoursStatus({
  required int totalHours,
  required int targetHours,
}) {
  if (totalHours > (targetHours + 12)) {
    return WeeklyHoursStatus.invalid;
  }
  if (totalHours > targetHours) {
    return WeeklyHoursStatus.alert;
  }
  return WeeklyHoursStatus.ok;
}

int _weeklyTargetHoursForWeek(DateTime weekStart) {
  final DateTime cutoff = DateTime(2026, 7, 15);
  return weekStart.isBefore(cutoff) ? 44 : 42;
}

int _effectiveTargetHoursForDisplayedDays({
  required int targetHours,
  required int displayedDays,
}) {
  return targetHours;
}

int _sumHoursForWeek({
  required Map<DateTime, ScheduleCode> assignments,
  required List<DateTime> weekDays,
}) {
  int total = 0;
  for (final DateTime day in weekDays) {
    final ScheduleCode code = assignments[_onlyDate(day)] ?? ScheduleCode.x;
    total += code.hours;
  }
  return total;
}

int _sumFreeDaysForWeek({
  required Map<DateTime, ScheduleCode> assignments,
  required List<DateTime> weekDays,
}) {
  int total = 0;
  for (final DateTime day in weekDays) {
    final ScheduleCode code = assignments[_onlyDate(day)] ?? ScheduleCode.x;
    if (code == ScheduleCode.l) {
      total += 1;
    }
  }
  return total;
}

Map<DateTime, List<DateTime>> _groupDaysByWeek(List<DateTime> days) {
  final Map<DateTime, List<DateTime>> result = <DateTime, List<DateTime>>{};

  for (final DateTime day in days) {
    final DateTime weekStart = _mondayOfWeek(day);
    result.putIfAbsent(weekStart, () => <DateTime>[]).add(day);
  }

  return result;
}

List<DateTime> _daysOfMonth(DateTime month) {
  final DateTime start = DateTime(month.year, month.month, 1);
  final DateTime end = DateTime(month.year, month.month + 1, 0);

  return List<DateTime>.generate(
    end.day,
    (int index) => DateTime(start.year, start.month, index + 1),
  );
}

List<DateTime> buildCenteredDateWindow(DateTime centerDate) {
  final DateTime normalized = _onlyDate(centerDate);
  final DateTime startDate = normalized.subtract(const Duration(days: 15));
  return List<DateTime>.generate(
    31,
    (int index) => startDate.add(Duration(days: index)),
  );
}

DateTime _shiftWindowCenterByMonth(DateTime centerDate, int monthDelta) {
  final DateTime normalized = _onlyDate(centerDate);
  final int targetYear = normalized.year + ((normalized.month - 1 + monthDelta) ~/ 12);
  final int targetMonth = ((normalized.month - 1 + monthDelta) % 12 + 12) % 12 + 1;
  final int lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final int safeDay = normalized.day <= lastDayOfTargetMonth
      ? normalized.day
      : lastDayOfTargetMonth;
  return DateTime(targetYear, targetMonth, safeDay);
}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _onlyDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime startOfWeek(DateTime date) {
  return _mondayOfWeek(date);
}

DateTime endOfWeek(DateTime date) {
  return startOfWeek(date).add(const Duration(days: 6));
}

bool isDateInSelectedWeek(DateTime date, DateTime selectedWeekDate) {
  final DateTime start = startOfWeek(selectedWeekDate);
  final DateTime end = endOfWeek(selectedWeekDate);
  final DateTime normalized = _onlyDate(date);
  return !normalized.isBefore(start) && !normalized.isAfter(end);
}

DateTime _mondayOfWeek(DateTime date) {
  final DateTime d = _onlyDate(date);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

int _weeksBetween(DateTime mondayA, DateTime mondayB) {
  return mondayB.difference(mondayA).inDays ~/ 7;
}

String _formatDate(DateTime date) {
  final String d = date.day.toString().padLeft(2, '0');
  final String m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _weekdayLetter(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'L';
    case DateTime.tuesday:
      return 'M';
    case DateTime.wednesday:
      return 'X';
    case DateTime.thursday:
      return 'J';
    case DateTime.friday:
      return 'V';
    case DateTime.saturday:
      return 'S';
    case DateTime.sunday:
      return 'D';
    default:
      return '';
  }
}

String _monthYearLabel(DateTime date) {
  const List<String> months = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return '${months[date.month - 1]} ${date.year}';
}

bool _isToday(DateTime date) {
  final DateTime now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

Color _weeklyHoursColor(int weeklyHours) {
  if (weeklyHours > 56) {
    return const Color(0xFFB42318);
  }
  if (weeklyHours > 44) {
    return const Color(0xFF9A6700);
  }
  return const Color(0xFF8A9BB0);
}

bool _isSpecialDay(DateTime date) {
  return date.weekday == DateTime.sunday || isColombiaHoliday(date);
}

class AgendaResponsibleResolver {
  const AgendaResponsibleResolver._();

  static List<String> resolveResponsiblesForSlot({
    required DateTime date,
    required String hora,
    List<String> nombres = kHorarioAuxiliaresRegistrados,
  }) {
    final GeneratedMonthPlan plan = _generateMonthPlan(
      year: date.year,
      month: date.month,
      nombres: nombres,
      twoAuxSundayPolicy: kHorarioTwoAuxSundayPolicy,
    );

    final DateTime key = _onlyDate(date);
    final List<ScheduleCode> expectedCodes = _expectedCoverageCodesForHora(
      hora,
    );

    if (expectedCodes.isEmpty) {
      return const <String>[];
    }

    final List<String> result = <String>[];

    for (final ScheduleCode expectedCode in expectedCodes) {
      for (final AuxiliarMonthlySchedule auxiliar in plan.auxiliares) {
        final ScheduleCode code = auxiliar.assignments[key] ?? ScheduleCode.x;
        if (code == expectedCode) {
          result.add(auxiliar.auxiliarNombre);
          break;
        }
      }
    }

    return result;
  }

  static List<ScheduleCode> _expectedCoverageCodesForHora(String hora) {
    final int hour = int.tryParse(hora.trim().split(':').first) ?? -1;

    if (hour >= 6 && hour <= 13) {
      return <ScheduleCode>[ScheduleCode.m];
    }

    if (hour == 14) {
      return <ScheduleCode>[ScheduleCode.m, ScheduleCode.t];
    }

    if (hour >= 15 && hour <= 22) {
      return <ScheduleCode>[ScheduleCode.t];
    }

    return const <ScheduleCode>[];
  }
}
