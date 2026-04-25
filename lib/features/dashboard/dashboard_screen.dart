import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/core/repositories/ops_firestore_repo.dart';
import 'package:hext/core/repositories/caso_paciente_repo.dart';
import 'package:hext/core/models/caso_paciente.dart';
import 'package:hext/shared/widgets/module_header.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum DashboardDateFilter { hoy, semana, mes, anio, rango }

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardDateFilter _selectedFilter = DashboardDateFilter.hoy;
  DateTimeRange? _customRange;
  final OpsFirestoreRepo _opsRepo = OpsFirestoreRepo();

  static const Color _pageBg = Color(0xFFF5F6F8);
  static const Color _cardBg = Colors.white;
  static const Color _borderColor = Color(0xFFE2E6EA);
  static const Color _titleColor = Color(0xFF1F2937);
  static const Color _textColor = Color(0xFF4B5563);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF17726D);

  final List<_MetricEvent> _origenRecords = <_MetricEvent>[];
  final List<_MetricEvent> _especialidadRecords = <_MetricEvent>[];
  List<_CandidateItem> _candidatos = <_CandidateItem>[];
  List<_VisitItem> _visitas = <_VisitItem>[];
  List<_SimpleEventItem> _noIngresos = <_SimpleEventItem>[];
  List<_RecentActivityItem> _actividad = <_RecentActivityItem>[];
  List<_DailyPadStatPoint> _dailyStats = <_DailyPadStatPoint>[];
  Timer? _clockTimer;
  StreamSubscription<List<OpsVisitRecord>>? _visitsSubscription;
  StreamSubscription<List<OpsPendingRecord>>? _pendingSubscription;
  // --- Censo ---
  List<CensoPaciente> _pacientes = <CensoPaciente>[];
  StreamSubscription<List<CensoPaciente>>? _censoSubscription;

  @override
  void initState() {
    super.initState();
    _bindFirestore();
    _bindCenso();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _visitsSubscription?.cancel();
    _pendingSubscription?.cancel();
    _censoSubscription?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
  void _bindCenso() {
    _censoSubscription = CensoPacienteRepo().watchCenso().listen(
      (List<CensoPaciente> records) {
        if (!mounted) return;
        setState(() {
          _pacientes = records;
        });
      },
      onError: (Object error, StackTrace stackTrace) {},
    );
  }

  void _bindFirestore() {
    _visitsSubscription = _opsRepo.watchVisits().listen(
      (List<OpsVisitRecord> records) {
        if (!mounted) return;
        setState(() {
          _visitas = records.map(_mapVisitFromRecord).toList();
          _noIngresos = records
              .where(
                (OpsVisitRecord r) => r.status.toLowerCase() == 'no_ingreso',
              )
              .map(
                (OpsVisitRecord r) => _SimpleEventItem(
                  title: r.patientName,
                  subtitle: 'No ingreso',
                  trailing: r.doctor,
                  date: r.date,
                ),
              )
              .toList();
          _actividad = records
              .take(12)
              .map(
                (OpsVisitRecord r) => _RecentActivityItem(
                  title: r.status.toLowerCase() == 'realizada'
                      ? PadUiLabels.activityApprovedAdmission
                      : PadUiLabels.caseReassessed,
                  subtitle: r.patientName,
                  date: r.date,
                  kind: r.status.toLowerCase() == 'realizada'
                      ? _ActivityKind.alta
                      : _ActivityKind.reingreso,
                ),
              )
              .toList();
          _dailyStats = _buildDailyStats(records);
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        // Repo already falls back to local fixtures when Firestore is blocked.
      },
    );

    _pendingSubscription = _opsRepo.watchPendings().listen(
      (List<OpsPendingRecord> records) {
        if (!mounted) return;
        setState(() {
          _candidatos = records
              .where(
                (OpsPendingRecord r) =>
                    (r.status ?? 'pendiente').toLowerCase() != 'resuelto',
              )
              .take(8)
              .map(
                (OpsPendingRecord r) => _CandidateItem(
                  patientName: r.paciente,
                  detail: '${r.tipo} · pendiente de gestión',
                  actionLabel: PadUiLabels.openCaseAction,
                  date: r.vencimiento,
                ),
              )
              .toList();
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        // Repo already falls back to local fixtures when Firestore is blocked.
      },
    );
  }

  _VisitItem _mapVisitFromRecord(OpsVisitRecord visit) {
    return _VisitItem(
      date: visit.date,
      patientName: visit.patientName,
      patientId: visit.patientId,
      visitId: visit.visitId,
      pendingId: visit.pendingId,
      modality: visit.modality,
      doctor: visit.doctor,
      auxiliar: visit.auxiliar,
      location: visit.location,
      status: visit.status,
      durationMinutes: visit.durationMinutes,
    );
  }

  List<_DailyPadStatPoint> _buildDailyStats(List<OpsVisitRecord> records) {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final Map<String, int> visitsByDay = <String, int>{};
    final Map<String, int> dischargesByDay = <String, int>{};

    for (final OpsVisitRecord record in records) {
      final DateTime day = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      if (day.isBefore(start)) continue;
      final String key = '${day.year}-${day.month}-${day.day}';
      visitsByDay[key] = (visitsByDay[key] ?? 0) + 1;
      if (record.status.toLowerCase() == 'realizada') {
        dischargesByDay[key] = (dischargesByDay[key] ?? 0) + 1;
      }
    }

    return List<_DailyPadStatPoint>.generate(30, (int i) {
      final DateTime day = start.add(Duration(days: i));
      final String key = '${day.year}-${day.month}-${day.day}';
      return _DailyPadStatPoint(
        date: day,
        amanecen: visitsByDay[key] ?? 0,
        egresan: dischargesByDay[key] ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final _DateBounds bounds = _resolveDateBounds();
    debugPrint('Rango dashboard: \\u001b[32m${bounds.start} -> ${bounds.end}\\u001b[0m');
    debugPrint('Total _visitas: ${_visitas.length}');
    for (final v in _visitas) {
      debugPrint('VISITA: paciente=${v.patientName} fecha=${v.date} status=${v.status}');
    }
    debugPrint('Total _candidatos: ${_candidatos.length}');
    debugPrint('Total _noIngresos: ${_noIngresos.length}');
    debugPrint('Total _actividad: ${_actividad.length}');
    debugPrint('Total _dailyStats: ${_dailyStats.length}');

    final List<_CandidateItem> candidatos = _filterByRange<_CandidateItem>(
      _candidatos,
      bounds,
      (_CandidateItem item) => item.date,
    );
    debugPrint('Candidatos tras filtro: ${candidatos.length}');
    final List<_VisitItem> visitas = _filterByRange<_VisitItem>(
      _visitas,
      bounds,
      (_VisitItem item) => item.date,
    );
    debugPrint('Visitas tras filtro: ${visitas.length}');
    final DateTime now = DateTime.now();
    final _NowSnapshot nowSnapshot = _buildNowSnapshot(
      source: _visitas,
      now: now,
    );
    final List<_VisitItem> proximas = _buildUpcomingVisits(
      source: visitas,
      now: now,
    );
    final List<_SimpleEventItem> noIngresos = _filterByRange<_SimpleEventItem>(
      _noIngresos,
      bounds,
      (_SimpleEventItem item) => item.date,
    );
    debugPrint('NoIngresos tras filtro: ${noIngresos.length}');
    final List<_RecentActivityItem> actividad =
        _filterByRange<_RecentActivityItem>(
          _actividad,
          bounds,
          (_RecentActivityItem item) => item.date,
        );
    debugPrint('Actividad tras filtro: ${actividad.length}');
    final List<_DailyPadStatPoint> dailyStats =
        _filterByRange<_DailyPadStatPoint>(
          _dailyStats,
          bounds,
          (_DailyPadStatPoint item) => item.date,
        );
    debugPrint('DailyStats tras filtro: ${dailyStats.length}');

    final List<_SmallMetric> origenes = _aggregateMetrics(
      labels: <String>[
        PadUiLabels.captureOriginActiveSearch,
        PadUiLabels.captureOriginFromService,
      ],
      source: _origenRecords,
      bounds: bounds,
    );
    final List<_SmallMetric> especialidades = _aggregateMetrics(
      labels: <String>[
        PadUiLabels.specialtyInternalMedicine,
        PadUiLabels.specialtySurgery,
        PadUiLabels.specialtyOrthopedics,
        PadUiLabels.specialtyOthers,
      ],
      source: _especialidadRecords,
      bounds: bounds,
    );
    final List<_KpiItem> kpis = _buildKpis(
      bounds: bounds,
      pacientes: _pacientes,
      candidatos: candidatos,
      visitas: visitas,
      noIngresos: noIngresos,
    );
    debugPrint('KPIs: ${kpis.map((k) => '${k.label}: ${k.value}').join(' | ')}');
    final bool secondaryMetricsAllZero =
        _allMetricsZero(origenes) && _allMetricsZero(especialidades);
    final int nonZeroDailyPoints = dailyStats
        .where((p) => (p.amanecen + p.egresan) > 0)
        .length;
    final bool lowDensityMode =
        nowSnapshot.items.isEmpty &&
        proximas.isEmpty &&
        candidatos.isEmpty &&
        noIngresos.isEmpty &&
        actividad.length <= 1 &&
        secondaryMetricsAllZero &&
        nonZeroDailyPoints <= 1;

    return Container(
      color: _pageBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTopHeader(context, bounds),
              const SizedBox(height: 20),
              _buildKpiSection(kpis),
              const SizedBox(height: 24),
              _buildNowCard(now: now, snapshot: nowSnapshot),
              const SizedBox(height: 24),
              _ResponsiveTwoColumn(
                left: _buildVisitsCard(proximas),
                right: _buildActivityCard(actividad),
              ),
              if (!lowDensityMode) ...<Widget>[
                const SizedBox(height: 24),
                _ResponsiveTwoColumn(
                  left: _buildSmallMetricsCard(
                    title: PadUiLabels.captureOriginSectionTitle,
                    metrics: origenes,
                  ),
                  right: _buildSmallMetricsCard(
                    title: PadUiLabels.specialtiesSectionTitle,
                    metrics: especialidades,
                  ),
                ),
                const SizedBox(height: 24),
                _ResponsiveTwoColumn(
                  left: _buildCandidatesCard(candidatos),
                  right: _buildNoIngresosCard(noIngresos),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Vista operativa compacta',
                  subtitle:
                      'Actividad baja: se prioriza la capa operativa superior.',
                  child: _buildActionableEmptyState(
                    title:
                        'Sin señales operativas secundarias relevantes para este corte.',
                    ctaLabel: 'Revisar agenda completa',
                    onTap: () => context.go('/schedule'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildDailyBehaviorCard(
                dailyStats,
                compactMode: lowDensityMode || nonZeroDailyPoints <= 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _allMetricsZero(List<_SmallMetric> metrics) {
    for (final _SmallMetric metric in metrics) {
      final int? value = int.tryParse(metric.value.trim());
      if ((value ?? 0) > 0) return false;
    }
    return true;
  }

  Widget _buildTopHeader(BuildContext context, _DateBounds bounds) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool desktop = constraints.maxWidth >= 980;
          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: ModuleHeader(
                    title: PadUiLabels.dashboardTitle,
                    subtitle:
                        '${PadUiLabels.dashboardSubtitle} · ${_rangeSummaryLabel(bounds)}',
                  ),
                ),
                const SizedBox(width: 16),
                _buildDateFilters(),
              ],
            );
          }
          return _buildDateFilters();
        },
      ),
    );
  }

  Widget _buildDateFilters() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Wrap(
        spacing: 4,
        children: DashboardDateFilter.values.map((DashboardDateFilter filter) {
          final bool selected = _selectedFilter == filter;
          final bool hasActiveCustomRange =
              filter == DashboardDateFilter.rango &&
              selected &&
              _customRange != null;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _onDateFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? hasActiveCustomRange
                          ? const Color(0xFFE8F3F1)
                          : Colors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(
                        color: hasActiveCustomRange
                            ? const Color(0xFF17726D)
                            : _borderColor,
                      )
                    : Border.all(color: Colors.transparent),
              ),
              child: _buildFilterLabel(filter, selected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterLabel(DashboardDateFilter filter, bool selected) {
    final bool showRangeSummary =
        filter == DashboardDateFilter.rango && selected && _customRange != null;

    if (!showRangeSummary) {
      return Text(
        _filterLabel(filter),
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _titleColor : _mutedColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'Rango',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _titleColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatDate(_customRange!.start)} - ${_formatDate(_customRange!.end)}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _primary,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  String _filterLabel(DashboardDateFilter filter) {
    switch (filter) {
      case DashboardDateFilter.hoy:
        return 'Hoy';
      case DashboardDateFilter.semana:
        return 'Semana';
      case DashboardDateFilter.mes:
        return 'Mes';
      case DashboardDateFilter.rango:
        return 'Rango';
      case DashboardDateFilter.anio:
        return 'Año';
    }
  }

  Future<void> _onDateFilterSelected(DashboardDateFilter filter) async {
    if (filter == DashboardDateFilter.rango) {
      final DateTime now = DateTime.now();
      final DateTimeRange initial =
          _customRange ??
          DateTimeRange(
            start: DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 6)),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          );

      final _RangeDialogResult? result = await _openRangeSelector(
        now: now,
        initial: initial,
      );
      if (!mounted || result == null) return;

      if (result.clear) {
        setState(() {
          _customRange = null;
          _selectedFilter = DashboardDateFilter.hoy;
        });
        return;
      }

      if (result.range == null) return;

      setState(() {
        _selectedFilter = DashboardDateFilter.rango;
        _customRange = _normalizedDayRange(result.range!);
      });
      return;
    }
    if (filter == DashboardDateFilter.anio) {
      final DateTime now = DateTime.now();
      final DateTime startOfYear = DateTime(now.year, 1, 1);
      final DateTime endOfNow =
          DateTime(now.year, now.month, now.day, 23, 59, 59);
      setState(() {
        _selectedFilter = DashboardDateFilter.anio;
        _customRange = DateTimeRange(start: startOfYear, end: endOfNow);
      });
      return;
    }

    setState(() => _selectedFilter = filter);
  }

  Future<_RangeDialogResult?> _openRangeSelector({
    required DateTime now,
    required DateTimeRange initial,
  }) {
    final bool desktop = MediaQuery.sizeOf(context).width >= 980;

    return showDialog<_RangeDialogResult>(
      context: context,
      barrierColor: desktop ? Colors.black.withValues(alpha: 0.12) : null,
      builder: (BuildContext dialogContext) {
        return _CompactRangeDialog(
          initialRange: initial,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 1),
          anchoredDesktop: desktop,
        );
      },
    );
  }

  DateTimeRange _normalizedDayRange(DateTimeRange range) {
    final DateTime start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final DateTime end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return DateTimeRange(start: start, end: end);
  }

  _DateBounds _resolveDateBounds() {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    switch (_selectedFilter) {
      case DashboardDateFilter.hoy:
        return _DateBounds(start: todayStart, end: todayEnd);
      case DashboardDateFilter.semana:
        final DateTime weekStart = todayStart.subtract(
          Duration(days: todayStart.weekday - DateTime.monday),
        );
        final DateTime weekEnd = weekStart.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return _DateBounds(start: weekStart, end: weekEnd);
      case DashboardDateFilter.mes:
        final DateTime monthStart = DateTime(now.year, now.month, 1);
        final DateTime monthEnd = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
        );
        return _DateBounds(start: monthStart, end: monthEnd);
      case DashboardDateFilter.anio:
        final DateTime startOfYear = DateTime(now.year, 1, 1);
        final DateTime endOfNow =
            DateTime(now.year, now.month, now.day, 23, 59, 59);
        return _DateBounds(start: startOfYear, end: endOfNow);
      case DashboardDateFilter.rango:
        if (_customRange != null) {
          return _DateBounds(
            start: _customRange!.start,
            end: _customRange!.end,
          );
        }
        return _DateBounds(start: todayStart, end: todayEnd);
    }
  }

  List<T> _filterByRange<T>(
    List<T> source,
    _DateBounds bounds,
    DateTime Function(T item) dateOf,
  ) {
    return source.where((T item) {
      final DateTime date = dateOf(item);
      return !date.isBefore(bounds.start) && !date.isAfter(bounds.end);
    }).toList();
  }

  _NowSnapshot _buildNowSnapshot({
    required List<_VisitItem> source,
    required DateTime now,
  }) {
    final List<_VisitNowItem> items = <_VisitNowItem>[];
    _VisitItem? nextVisit;

    for (final _VisitItem visit in source) {
      if (!_sameDay(visit.date, now)) continue;
      if (visit.status.toLowerCase() == 'realizada') continue;

      final DateTime end = visit.date.add(
        Duration(minutes: visit.durationMinutes),
      );

      if (now.isAfter(visit.date) && now.isBefore(end)) {
        items.add(_VisitNowItem(visit: visit, state: _NowState.enCurso));
        continue;
      }

      if (now.isBefore(visit.date)) {
        final int minutes = visit.date.difference(now).inMinutes;
        if (minutes <= 30) {
          items.add(_VisitNowItem(visit: visit, state: _NowState.porIniciar));
        }
        if (nextVisit == null || visit.date.isBefore(nextVisit.date)) {
          nextVisit = visit;
        }
        continue;
      }

      if (now.isAfter(end)) {
        items.add(_VisitNowItem(visit: visit, state: _NowState.retrasada));
      }
    }

    items.sort(
      (_VisitNowItem a, _VisitNowItem b) =>
          a.visit.date.compareTo(b.visit.date),
    );

    return _NowSnapshot(items: items, nextVisit: nextVisit);
  }

  List<_VisitItem> _buildUpcomingVisits({
    required List<_VisitItem> source,
    required DateTime now,
  }) {
    final List<_VisitItem> items = source.where((_VisitItem item) {
      return item.status.toLowerCase() != 'realizada' && item.date.isAfter(now);
    }).toList()
      ..sort((_VisitItem a, _VisitItem b) => a.date.compareTo(b.date));

    return items.take(5).toList();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_SmallMetric> _aggregateMetrics({
    required List<String> labels,
    required List<_MetricEvent> source,
    required _DateBounds bounds,
  }) {
    final List<_MetricEvent> filtered = _filterByRange<_MetricEvent>(
      source,
      bounds,
      (_MetricEvent item) => item.date,
    );
    return labels.map((String label) {
      final int count =
          filtered.where((_MetricEvent e) => e.label == label).length;
      return _SmallMetric(label: label, value: '$count');
    }).toList();
  }

  // Catálogo de causas válidas de reingreso
  static const List<String> causasReingresoValidas = <String>[
    'COMORBILIDADES DESCOMPENSADAS',
    'FACTORES SOCIALES O DE SOPORTE NO FAVORABLES',
    'NECESIDAD DE ESCALAMIENTO DEL NIVEL DE ATENCIÓN POR EVOLUCIÓN CLÍNICA',
    'PROGRESIÓN DE LA PATOLOGÍA DE BASE',
    'REQUERIMIENTO DE ATENCIÓN INTRAHOSPITALARIA',
    'REACCION ADVERSA A MEDICAMENTO',
    'NO AVAL ADMINISTRATIVO',
  ];

  List<_KpiItem> _buildKpis({
    required _DateBounds bounds,
    required List<CensoPaciente> pacientes,
    required List<_CandidateItem> candidatos,
    required List<_VisitItem> visitas,
    required List<_SimpleEventItem> noIngresos,
  }) {
    final List<CensoPaciente> enRango = pacientes.where((p) {
      final DateTime? ingreso = p.fechaIngreso;
      final DateTime? egreso = p.fechaEgreso;
      if (ingreso == null) return false;
      return !ingreso.isAfter(bounds.end) && (egreso == null || !egreso.isBefore(bounds.start));
    }).toList();

    final int pacientesActuales = enRango.where((p) {
      return p.fechaEgreso == null || p.fechaEgreso!.isAfter(bounds.end);
    }).length;

    String? getCausaReingresoOtro(dynamic p) {
      try {
        // Si el modelo se amplía, agregar aquí el acceso seguro
        if (p != null && p.toJson != null) {
          final map = p.toJson();
          if (map is Map && map.containsKey('causaReingresoOtro')) {
            final val = map['causaReingresoOtro'];
            if (val is String) return val.trim();
          }
        }
      } catch (_) {}
      return null;
    }

    final int reingresos = enRango.where((p) {
      final String? tipoEgreso = p.tipoEgreso?.trim();
      final String? causaReingreso = p.causaReingreso?.trim();
      final String? causaReingresoOtro = getCausaReingresoOtro(p);
      final DateTime? egreso = p.fechaEgreso;
      final bool esReingresoValido =
          tipoEgreso == 'Retorno intrahospitalario' &&
          causaReingreso != null &&
          causaReingreso.isNotEmpty &&
          (causaReingreso != 'Otro' ||
              (causaReingresoOtro != null && causaReingresoOtro.isNotEmpty)) &&
          egreso != null && !egreso.isBefore(bounds.start) && !egreso.isAfter(bounds.end);
      return esReingresoValido;
    }).length;

    final int altas = enRango.where((p) {
      final DateTime? egreso = p.fechaEgreso;
      final String? tipoEgreso = p.tipoEgreso?.trim();
      final String? causaReingreso = p.causaReingreso?.trim();
      final String? causaReingresoOtro = getCausaReingresoOtro(p);
      final bool esReingresoValido =
          tipoEgreso == 'Retorno intrahospitalario' &&
          causaReingreso != null &&
          causaReingreso.isNotEmpty &&
          (causaReingreso != 'Otro' ||
              (causaReingresoOtro != null && causaReingresoOtro.isNotEmpty)) &&
          egreso != null && !egreso.isBefore(bounds.start) && !egreso.isAfter(bounds.end);
      return egreso != null && !egreso.isBefore(bounds.start) && !egreso.isAfter(bounds.end) && !esReingresoValido;
    }).length;

    final List<int> estancias = enRango
        .where((p) {
          return p.fechaIngreso != null &&
              p.fechaEgreso != null &&
              !p.fechaEgreso!.isBefore(bounds.start) &&
              !p.fechaEgreso!.isAfter(bounds.end);
        })
        .map((p) => p.fechaEgreso!.difference(p.fechaIngreso!).inDays + 1)
        .toList();

    final double promedioEstancia = estancias.isEmpty
        ? 0
        : estancias.reduce((a, b) => a + b) / estancias.length;

    return <_KpiItem>[
      _KpiItem(
        label: PadUiLabels.kpiCurrentPatients,
        value: '$pacientesActuales',
        valueColor: const Color(0xFF1E88E5),
      ),
      _KpiItem(
        label: PadUiLabels.kpiDischarges,
        value: '$altas',
        valueColor: const Color(0xFF43A047),
      ),
      _KpiItem(
        label: PadUiLabels.kpiReadmissions,
        value: '$reingresos',
        valueColor: const Color(0xFF8E24AA),
      ),
      _KpiItem(
        label: PadUiLabels.kpiAverageStayDays,
        value: promedioEstancia.toStringAsFixed(1),
        valueColor: const Color(0xFF3949AB),
      ),
      _KpiItem(
        label: PadUiLabels.kpiNoAdmissions,
        value: '${noIngresos.length}',
        valueColor: const Color(0xFFFB8C00),
      ),
      _KpiItem(
        label: PadUiLabels.casesPendingDefinition,
        value: '${candidatos.length}',
        valueColor: const Color(0xFFE53935),
      ),
      _KpiItem(
        label: PadUiLabels.kpiTodayVisits,
        value: '${visitas.length}',
        valueColor: const Color(0xFF00897B),
      ),
    ];
  }

  String _rangeSummaryLabel(_DateBounds bounds) {
    if (_selectedFilter == DashboardDateFilter.hoy) {
      return 'Hoy';
    }
    return '${_formatDate(bounds.start)} - ${_formatDate(bounds.end)}';
  }

  String _formatDate(DateTime date) {
    const List<String> month = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final String day = date.day.toString().padLeft(2, '0');
    return '$day ${month[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _weekdayLetter(DateTime date) {
    const List<String> letters = <String>['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letters[date.weekday - 1];
  }
    Widget _buildKpiSection(List<_KpiItem> kpis) {
    if (kpis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: const Center(
          child: Text(
            'No hay indicadores para mostrar (KPIs vacíos)',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: kpis.map((item) {
        return SizedBox(
          width: 170,
          height: 112,
          child: _SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: item.valueColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallMetricsCard({
    required String title,
    required List<_SmallMetric> metrics,
  }) {
    return _SectionCard(
      title: title,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: metrics.map((item) {
          return Container(
            constraints: const BoxConstraints(minWidth: 150),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 14, color: _textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCandidatesCard(List<_CandidateItem> candidatos) {
    if (candidatos.isEmpty) {
      return _SectionCard(
        title: PadUiLabels.casesPendingDefinition,
        child: _buildActionableEmptyState(
          title: 'No hay casos por definir para el periodo seleccionado.',
          ctaLabel: 'Crear nuevo caso',
          onTap: () => context.go('/pad/nuevo'),
        ),
      );
    }

    return _SectionCard(
      title: PadUiLabels.casesPendingDefinition,
      child: Column(
        children: candidatos.asMap().entries.map((entry) {
          final int index = entry.key;
          final _CandidateItem item = entry.value;
          return Column(
            children: <Widget>[
              if (index > 0) const Divider(height: 1, color: _borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: Color(0xFFE53935),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.detail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(item.actionLabel),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNowCard({
    required DateTime now,
    required _NowSnapshot snapshot,
  }) {
    return _SectionCard(
      title: 'Ahora mismo',
      subtitle: 'Hora actual ${_formatTime(now)} · operación en curso',
      child: snapshot.items.isEmpty
          ? _buildNowEmptyState(snapshot.nextVisit)
          : Column(
              children: snapshot.items.asMap().entries.map((entry) {
                final int index = entry.key;
                final _VisitNowItem item = entry.value;

                return Column(
                  children: <Widget>[
                    if (index > 0)
                      const Divider(height: 1, color: _borderColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2FBFA),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFD6F0ED),
                              ),
                            ),
                            child: const Icon(
                              Icons.timelapse_rounded,
                              size: 18,
                              color: Color(0xFF0F9D94),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${_formatTime(item.visit.date)} · ${item.visit.patientName}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: _titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.visit.auxiliar} · ${item.visit.modality}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _MapLocationLink(
                                  label: item.visit.location,
                                  onTap: () => _openLocationInMaps(
                                    location: item.visit.location,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              _StatusPill(label: _nowStateLabel(item.state)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 34,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _openVisitInAgenda(item.visit),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primary,
                                    side: const BorderSide(color: _borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Abrir visita',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNowEmptyState(_VisitItem? nextVisit) {
    if (nextVisit == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: const <Widget>[
                Icon(
                  Icons.timelapse_outlined,
                  size: 18,
                  color: Color(0xFF5E6A7D),
                ),
                SizedBox(width: 8),
                Text(
                  'No hay visitas en curso',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando entren visitas activas aparecerán aquí para seguimiento operativo inmediato.',
              style: TextStyle(fontSize: 13.5, color: _textColor),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/schedule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: const Text('Ver agenda de hoy'),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'No hay visitas en curso',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Siguiente visita: ${_formatTime(nextVisit.date)} · ${nextVisit.patientName} · ${nextVisit.modality} · ${nextVisit.auxiliar}',
            style: const TextStyle(fontSize: 14, color: _textColor),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _openVisitInAgenda(nextVisit),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.route_rounded, size: 16),
              label: const Text('Ver ruta/agenda'),
            ),
          ),
        ],
      ),
    );
  }

  void _openVisitInAgenda(_VisitItem visit) {
    final String? itemId =
        (visit.visitId != null && visit.visitId!.trim().isNotEmpty)
            ? visit.visitId
            : visit.pendingId;
    final String route = Uri(
      path: '/schedule',
      queryParameters: <String, String>{
        'source': 'dashboard',
        if (itemId != null && itemId.trim().isNotEmpty) 'itemId': itemId,
        if (visit.visitId != null && visit.visitId!.trim().isNotEmpty)
          'visitId': visit.visitId!,
        if (visit.patientId != null && visit.patientId!.trim().isNotEmpty)
          'patientId': visit.patientId!,
        if (visit.pendingId != null && visit.pendingId!.trim().isNotEmpty)
          'pendingId': visit.pendingId!,
      },
    ).toString();
    context.go(route);
  }

  String _nowStateLabel(_NowState state) {
    switch (state) {
      case _NowState.enCurso:
        return 'En curso';
      case _NowState.porIniciar:
        return 'Por iniciar';
      case _NowState.retrasada:
        return 'Retrasada';
    }
  }

  Future<void> _openLocationInMaps({required String location}) async {
    final String query = Uri.encodeComponent('$location, Cartagena');
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

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

  Widget _buildVisitsCard(List<_VisitItem> visitas) {
    return _SectionCard(
      title: PadUiLabels.upcomingMedicalAssessments,
      child: visitas.isEmpty
          ? _buildActionableEmptyState(
              title: 'No hay próximas valoraciones para hoy.',
              ctaLabel: 'Programar visita',
              onTap: () => context.go('/schedule'),
            )
          : Column(
              children: visitas.asMap().entries.map((entry) {
                final int index = entry.key;
                final _VisitItem item = entry.value;
                return Column(
                  children: <Widget>[
                    if (index > 0)
                      const Divider(height: 1, color: _borderColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2FBFA),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFD6F0ED),
                              ),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              size: 18,
                              color: Color(0xFF0F9D94),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${_formatDate(item.date)} · ${_formatTime(item.date)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _mutedColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.patientName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: _titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.modality} · ${item.auxiliar}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _MapLocationLink(
                                  label: item.location,
                                  onTap: () => _openLocationInMaps(
                                    location: item.location,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatusPill(label: item.status),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNoIngresosCard(List<_SimpleEventItem> noIngresos) {
    if (noIngresos.isEmpty) {
      return _SectionCard(
        title: PadUiLabels.recentNoAdmissions,
        child: _buildActionableEmptyState(
          title: 'No se registran no ingresos recientes.',
          ctaLabel: 'Revisar pacientes',
          onTap: () => context.go('/cases'),
        ),
      );
    }

    return _SectionCard(
      title: PadUiLabels.recentNoAdmissions,
      child: Column(
        children: noIngresos.asMap().entries.map((entry) {
          final int index = entry.key;
          final _SimpleEventItem item = entry.value;
          return Column(
            children: <Widget>[
              if (index > 0) const Divider(height: 1, color: _borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.not_interested_rounded,
                      color: Color(0xFFFB8C00),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.subtitle} · ${_formatDate(item.date)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.trailing,
                      style: const TextStyle(fontSize: 13, color: _mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityCard(List<_RecentActivityItem> actividad) {
    if (actividad.isEmpty) {
      return _SectionCard(
        title: PadUiLabels.recentActivity,
        child: _buildActionableEmptyState(
          title: 'Aún no se registra actividad reciente.',
          ctaLabel: 'Ir a pendientes',
          onTap: () => context.go('/pending'),
        ),
      );
    }

    final bool compact = actividad.length <= 1;

    return _SectionCard(
      title: PadUiLabels.recentActivity,
      child: Column(
        children: actividad.asMap().entries.map((entry) {
          final int index = entry.key;
          final _RecentActivityItem item = entry.value;
          return Column(
            children: <Widget>[
              if (index > 0) const Divider(height: 1, color: _borderColor),
              Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.history,
                      size: 20,
                      color: Color(0xFF607D8B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: compact ? 16 : 18,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: compact ? 13 : 14,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(item.date),
                      style: const TextStyle(fontSize: 13, color: _mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyBehaviorCard(
    List<_DailyPadStatPoint> dailyStats, {
    bool compactMode = false,
  }) {
    final List<_DailyPadStatPoint> nonZeroPoints = dailyStats
        .where((p) => (p.amanecen + p.egresan) > 0)
        .toList();

    if (nonZeroPoints.isEmpty) {
      return _SectionCard(
        title: PadUiLabels.dailyPadBehavior,
        subtitle: PadUiLabels.dailyPadBehaviorSubtitle,
        child: _buildActionableEmptyState(
          title: 'No hay datos diarios para graficar en este rango.',
          ctaLabel: 'Ver mes actual',
          onTap: () => _onDateFilterSelected(DashboardDateFilter.mes),
        ),
      );
    }

    final bool sparse = compactMode || nonZeroPoints.length <= 3;
    final List<_DailyPadStatPoint> chartPoints =
        sparse ? nonZeroPoints : dailyStats;
    final double chartHeight = sparse ? 130 : 220;

    final int maxValue = chartPoints
        .map((e) => e.amanecen > e.egresan ? e.amanecen : e.egresan)
        .fold<int>(0, (prev, next) => next > prev ? next : prev);

    return _SectionCard(
      title: PadUiLabels.dailyPadBehavior,
      subtitle: PadUiLabels.dailyPadBehaviorSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: const <Widget>[
              _LegendDot(
                label: PadUiLabels.legendMorningCensus,
                color: Color(0xFF17726D),
              ),
              _LegendDot(
                label: PadUiLabels.legendDischarges,
                color: Color(0xFFB0BEC5),
              ),
            ],
          ),
          SizedBox(height: sparse ? 12 : 18),
          SizedBox(
            height: chartHeight,
            child: sparse
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: chartPoints.map((item) {
                        return SizedBox(
                          width: 52,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  _Bar(
                                    value: item.amanecen,
                                    max: maxValue,
                                    color: const Color(0xFF17726D),
                                    compact: true,
                                    maxPixels: 64,
                                  ),
                                  const SizedBox(width: 5),
                                  _Bar(
                                    value: item.egresan,
                                    max: maxValue,
                                    color: const Color(0xFFB0BEC5),
                                    compact: true,
                                    maxPixels: 64,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _weekdayLetter(item.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _mutedColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chartPoints.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      _Bar(
                                        value: item.amanecen,
                                        max: maxValue,
                                        color: const Color(0xFF17726D),
                                      ),
                                      const SizedBox(width: 6),
                                      _Bar(
                                        value: item.egresan,
                                        max: maxValue,
                                        color: const Color(0xFFB0BEC5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _weekdayLetter(item.date),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableEmptyState({
    required String title,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _mutedColor,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(ctaLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsiveTwoColumn({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 1100;

        if (!isWide) {
          return Column(
            children: <Widget>[left, const SizedBox(height: 24), right],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: left),
              const SizedBox(width: 24),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _DashboardScreenState._cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DashboardScreenState._borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _DashboardScreenState._titleColor,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: _DashboardScreenState._mutedColor,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final String normalized = label.toLowerCase();

    Color bg = const Color(0xFFFFF8ED);
    Color border = const Color(0xFFF4DFC0);
    Color text = const Color(0xFF9A6700);

    if (normalized == 'realizada' || normalized == 'en curso') {
      bg = const Color(0xFFF1F8F6);
      border = const Color(0xFFD9ECE7);
      text = const Color(0xFF17726D);
    } else if (normalized == 'retrasada') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFF6D1D1);
      text = const Color(0xFFB42318);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: _DashboardScreenState._textColor,
          ),
        ),
      ],
    );
  }
}

class _MapLocationLink extends StatelessWidget {
  const _MapLocationLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.place_outlined,
              size: 16,
              color: _DashboardScreenState._primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _DashboardScreenState._primary,
                  decoration: TextDecoration.underline,
                  decorationColor: _DashboardScreenState._primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final bool compact;
  final double maxPixels;

  const _Bar({
    required this.value,
    required this.max,
    required this.color,
    this.compact = false,
    this.maxPixels = 150,
  });

  @override
  Widget build(BuildContext context) {
    final double height = max == 0 ? 0 : (value / max) * maxPixels;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (!compact)
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 12,
              color: _DashboardScreenState._mutedColor,
            ),
          ),
        SizedBox(height: compact ? 0 : 8),
        Container(
          width: compact ? 14 : 20,
          height: height.clamp(compact ? 4 : 8, maxPixels),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final Color valueColor;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class _SmallMetric {
  final String label;
  final String value;

  const _SmallMetric({required this.label, required this.value});
}

class _CandidateItem {
  final String patientName;
  final String detail;
  final String actionLabel;
  final DateTime date;

  const _CandidateItem({
    required this.patientName,
    required this.detail,
    required this.actionLabel,
    required this.date,
  });
}

class _VisitItem {
  final DateTime date;
  final String patientName;
  final String? patientId;
  final String? visitId;
  final String? pendingId;
  final String modality;
  final String doctor;
  final String auxiliar;
  final String location;
  final String status;
  final int durationMinutes;

  const _VisitItem({
    required this.date,
    required this.patientName,
    this.patientId,
    this.visitId,
    this.pendingId,
    required this.modality,
    required this.doctor,
    required this.auxiliar,
    required this.location,
    required this.status,
    this.durationMinutes = 60,
  });
}

class _VisitNowItem {
  final _VisitItem visit;
  final _NowState state;

  const _VisitNowItem({required this.visit, required this.state});
}

class _NowSnapshot {
  final List<_VisitNowItem> items;
  final _VisitItem? nextVisit;

  const _NowSnapshot({required this.items, required this.nextVisit});
}

class _SimpleEventItem {
  final String title;
  final String subtitle;
  final String trailing;
  final DateTime date;

  const _SimpleEventItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.date,
  });
}

class _RecentActivityItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final _ActivityKind kind;

  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.kind,
  });
}

class _DailyPadStatPoint {
  final DateTime date;
  final int amanecen;
  final int egresan;

  const _DailyPadStatPoint({
    required this.date,
    required this.amanecen,
    required this.egresan,
  });
}

class _MetricEvent {
  final String label;
  final DateTime date;

  const _MetricEvent({required this.label, required this.date});
}

class _DateBounds {
  final DateTime start;
  final DateTime end;

  const _DateBounds({required this.start, required this.end});
}

class _RangeDialogResult {
  final DateTimeRange? range;
  final bool clear;

  const _RangeDialogResult({this.range, this.clear = false});
}

enum _RangePreset { hoy, semana, mes, ultimos7 }

class _CompactRangeDialog extends StatefulWidget {
  const _CompactRangeDialog({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    this.anchoredDesktop = false,
  });

  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool anchoredDesktop;

  @override
  State<_CompactRangeDialog> createState() => _CompactRangeDialogState();
}

class _CompactRangeDialogState extends State<_CompactRangeDialog> {
  late DateTime _start;
  late DateTime _end;
  _RangePreset? _preset;

  @override
  void initState() {
    super.initState();
    _start = DateTime(
      widget.initialRange.start.year,
      widget.initialRange.start.month,
      widget.initialRange.start.day,
    );
    _end = DateTime(
      widget.initialRange.end.year,
      widget.initialRange.end.month,
      widget.initialRange.end.day,
      23,
      59,
      59,
    );
    _preset = _detectPreset(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: 460,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E6EA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Seleccionar rango',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _presetChip(_RangePreset.hoy, 'Hoy'),
              _presetChip(_RangePreset.semana, 'Semana'),
              _presetChip(_RangePreset.mes, 'Mes'),
              _presetChip(_RangePreset.ultimos7, 'Últimos 7 días'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _dateField(
                  label: 'Fecha inicial',
                  value: _start,
                  onTap: () => _pickStart(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'Fecha final',
                  value: _end,
                  onTap: () => _pickEnd(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(const _RangeDialogResult(clear: true));
                },
                child: const Text('Limpiar'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canApply
                    ? () {
                        Navigator.of(context).pop(
                          _RangeDialogResult(
                            range: DateTimeRange(start: _start, end: _end),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF17726D),
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.anchoredDesktop) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 108, right: 28, left: 24),
            child: Material(type: MaterialType.transparency, child: content),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: content,
    );
  }

  bool get _canApply => !_end.isBefore(_start);

  Widget _presetChip(_RangePreset preset, String label) {
    final bool selected = _preset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _applyPreset(preset),
      selectedColor: const Color(0xFFE8F3F1),
      side: const BorderSide(color: Color(0xFFD9E2E7)),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF17726D) : const Color(0xFF4B5563),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD9E2E7)),
          color: const Color(0xFFFFFFFF),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: ${_dateLabel(value)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _applyPreset(_RangePreset preset) {
    final DateTime now = DateTime.now();
    final DateTime base = DateTime(now.year, now.month, now.day);

    late DateTime start;
    late DateTime end;

    switch (preset) {
      case _RangePreset.hoy:
        start = base;
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case _RangePreset.semana:
        start = base.subtract(Duration(days: base.weekday - DateTime.monday));
        end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case _RangePreset.mes:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case _RangePreset.ultimos7:
        start = base.subtract(const Duration(days: 6));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    setState(() {
      _preset = preset;
      _start = start;
      _end = end;
    });
  }

  _RangePreset? _detectPreset(DateTime start, DateTime end) {
    final DateTime now = DateTime.now();
    final DateTime base = DateTime(now.year, now.month, now.day);
    final DateTime todayStart = base;
    final DateTime todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );
    final DateTime weekStart = base.subtract(
      Duration(days: base.weekday - DateTime.monday),
    );
    final DateTime weekEnd = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    final DateTime monthStart = DateTime(now.year, now.month, 1);
    final DateTime monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final DateTime last7Start = base.subtract(const Duration(days: 6));

    bool matches(DateTime from, DateTime to) {
      return _sameDay(start, from) && _sameDay(end, to);
    }

    if (matches(todayStart, todayEnd)) return _RangePreset.hoy;
    if (matches(weekStart, weekEnd)) return _RangePreset.semana;
    if (matches(monthStart, monthEnd)) return _RangePreset.mes;
    if (matches(last7Start, todayEnd)) return _RangePreset.ultimos7;
    return null;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDate: _start,
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(picked.year, picked.month, picked.day);
      if (_start.isAfter(_end)) {
        _end = DateTime(_start.year, _start.month, _start.day, 23, 59, 59);
      }
      _preset = _detectPreset(_start, _end);
    });
  }

  Future<void> _pickEnd(BuildContext context) async {
    final DateTime initial = _end.isBefore(_start) ? _start : _end;
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDate: initial,
    );
    if (picked == null) return;
    setState(() {
      _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      if (_end.isBefore(_start)) {
        _start = DateTime(picked.year, picked.month, picked.day);
      }
      _preset = _detectPreset(_start, _end);
    });
  }
}

enum _ActivityKind { alta, reingreso }

enum _NowState { enCurso, porIniciar, retrasada }