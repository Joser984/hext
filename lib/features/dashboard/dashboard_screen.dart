import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/core/repositories/ops_firestore_repo.dart';
import 'package:hext/core/repositories/caso_paciente_repo.dart';
import 'package:hext/core/models/caso_paciente.dart';
import 'package:hext/features/dashboard/models/dashboard_view_models.dart';
import 'package:hext/shared/widgets/module_header.dart';
import 'package:hext/features/dashboard/widgets/dashboard_common_widgets.dart';
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

  final List<MetricEvent> _origenRecords = <MetricEvent>[];
  final List<MetricEvent> _especialidadRecords = <MetricEvent>[];
  List<CandidateItem> _candidatos = <CandidateItem>[];
  List<VisitItem> _visitas = <VisitItem>[];
  List<SimpleEventItem> _noIngresos = <SimpleEventItem>[];
  List<RecentActivityItem<_ActivityKind>> _actividad =
      <RecentActivityItem<_ActivityKind>>[];
  List<DailyPadStatPoint> _dailyStats = <DailyPadStatPoint>[];
  List<DailyPadStatPoint> _trendDailyStats = <DailyPadStatPoint>[];
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
    _censoSubscription = CensoPacienteRepo().watchCenso().listen((
      List<CensoPaciente> records,
    ) {
      if (!mounted) return;
      setState(() {
        _pacientes = records;
        _refreshDailyStats();
      });
    }, onError: (Object error, StackTrace stackTrace) {});
  }

  void _refreshDailyStats() {
    final DateTimeRange selectedRange = DateTimeRange(
      start: _resolveDateBounds().start,
      end: _resolveDateBounds().end,
    );
    final DateBounds trendBounds = _resolveTrendVisualBounds();
    final DateTimeRange trendRange = DateTimeRange(
      start: trendBounds.start,
      end: trendBounds.end,
    );
    _dailyStats = _buildDailyStatsFromPacientes(_pacientes, selectedRange);
    _trendDailyStats = _buildDailyStatsFromPacientes(_pacientes, trendRange);
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
                (OpsVisitRecord r) => SimpleEventItem(
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
                (OpsVisitRecord r) => RecentActivityItem<_ActivityKind>(
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
                (OpsPendingRecord r) => CandidateItem(
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

  VisitItem _mapVisitFromRecord(OpsVisitRecord visit) {
    return VisitItem(
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

  // --- NUEVA FUNCIÓN PARA DAILY STATS DESDE PACIENTES ---
  List<DailyPadStatPoint> _buildDailyStatsFromPacientes(
    List<CensoPaciente> pacientes,
    DateTimeRange range,
  ) {
    DateTime onlyDate(DateTime value) {
      return DateTime(value.year, value.month, value.day);
    }

    final start = onlyDate(range.start);
    final end = onlyDate(range.end);

    final result = <DailyPadStatPoint>[];

    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final amanecen = pacientes.where((p) {
        final ingreso = _parseDateFlexible(p.fechaIngreso);
        if (ingreso == null) return false;
        final ingresoDay = onlyDate(ingreso);
        final egreso = _parseDateFlexible(p.fechaEgreso);
        final egresoDay = egreso == null ? null : onlyDate(egreso);
        final yaIngreso = !ingresoDay.isAfter(day);
        final noHaEgresadoAntesDelDia =
            egresoDay == null || egresoDay.isAfter(day);
        return yaIngreso && noHaEgresadoAntesDelDia;
      }).length;

      final egresan = pacientes.where((p) {
        final egreso = _parseDateFlexible(p.fechaEgreso);
        if (egreso == null) return false;
        final egresoDay = onlyDate(egreso);
        return egresoDay == day;
      }).length;

      if (amanecen > 0 || egresan > 0) {
        result.add(
          DailyPadStatPoint(date: day, amanecen: amanecen, egresan: egresan),
        );
      }
    }

    return result;
  }

  // Helper para parsear fechas flexiblemente
  DateTime? _parseDateFlexible(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    // Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp' && value.toDate != null) {
      try {
        return value.toDate();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final DateBounds bounds = _resolveDateBounds();

    final List<CandidateItem> candidatos = _filterByRange<CandidateItem>(
      _candidatos,
      bounds,
      (CandidateItem item) => item.date,
    );
    final List<VisitItem> visitas = _filterByRange<VisitItem>(
      _visitas,
      bounds,
      (VisitItem item) => item.date,
    );
    final DateTime now = DateTime.now();
    final NowSnapshot<_NowState> nowSnapshot = _buildNowSnapshot(
      source: _visitas,
      now: now,
    );
    final List<VisitItem> proximas = _buildUpcomingVisits(
      source: visitas,
      now: now,
    );
    final List<SimpleEventItem> noIngresos = _filterByRange<SimpleEventItem>(
      _noIngresos,
      bounds,
      (SimpleEventItem item) => item.date,
    );
    final List<RecentActivityItem<_ActivityKind>> actividad =
        _filterByRange<RecentActivityItem<_ActivityKind>>(
          _actividad,
          bounds,
          (RecentActivityItem<_ActivityKind> item) => item.date,
        );
    final List<DailyPadStatPoint> dailyStats =
        _filterByRange<DailyPadStatPoint>(
          _dailyStats,
          bounds,
          (DailyPadStatPoint item) => item.date,
        );

    final List<SmallMetric> origenes = _aggregateMetrics(
      labels: <String>[
        PadUiLabels.captureOriginActiveSearch,
        PadUiLabels.captureOriginFromService,
      ],
      source: _origenRecords,
      bounds: bounds,
    );
    final List<SmallMetric> especialidades = _aggregateMetrics(
      labels: <String>[
        PadUiLabels.specialtyInternalMedicine,
        PadUiLabels.specialtySurgery,
        PadUiLabels.specialtyOrthopedics,
        PadUiLabels.specialtyOthers,
      ],
      source: _especialidadRecords,
      bounds: bounds,
    );
    final List<KpiItem> kpis = _buildKpis(
      bounds: bounds,
      pacientes: _pacientes,
      candidatos: candidatos,
      visitas: visitas,
      noIngresos: noIngresos,
    );
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
                SectionCard(
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
                _trendDailyStats,
                compactMode: lowDensityMode || nonZeroDailyPoints <= 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _allMetricsZero(List<SmallMetric> metrics) {
    for (final SmallMetric metric in metrics) {
      final int? value = int.tryParse(metric.value.trim());
      if ((value ?? 0) > 0) return false;
    }
    return true;
  }

  Widget _buildTopHeader(BuildContext context, DateBounds bounds) {
    return SurfaceCard(
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

      final RangeDialogResult? result = await _openRangeSelector(
        now: now,
        initial: initial,
      );
      if (!mounted || result == null) return;

      if (result.clear) {
        setState(() {
          _customRange = null;
          _selectedFilter = DashboardDateFilter.hoy;
          _refreshDailyStats();
        });
        return;
      }

      if (result.range == null) return;

      setState(() {
        _selectedFilter = DashboardDateFilter.rango;
        _customRange = _normalizedDayRange(result.range!);
        _refreshDailyStats();
      });
      return;
    }
    if (filter == DashboardDateFilter.anio) {
      final DateTime now = DateTime.now();
      final DateTime startOfYear = DateTime(now.year, 1, 1);
      final DateTime endOfNow = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      );
      setState(() {
        _selectedFilter = DashboardDateFilter.anio;
        _customRange = DateTimeRange(start: startOfYear, end: endOfNow);
        _refreshDailyStats();
      });
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _refreshDailyStats();
    });
  }

  Future<RangeDialogResult?> _openRangeSelector({
    required DateTime now,
    required DateTimeRange initial,
  }) {
    final bool desktop = MediaQuery.sizeOf(context).width >= 980;

    return showDialog<RangeDialogResult>(
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

  DateBounds _resolveDateBounds() {
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
        return DateBounds(start: todayStart, end: todayEnd);
      case DashboardDateFilter.semana:
        final DateTime weekStart = todayStart.subtract(
          Duration(days: todayStart.weekday - DateTime.monday),
        );
        final DateTime weekEnd = weekStart.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return DateBounds(start: weekStart, end: weekEnd);
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
        return DateBounds(start: monthStart, end: monthEnd);
      case DashboardDateFilter.anio:
        final DateTime startOfYear = DateTime(now.year, 1, 1);
        final DateTime endOfNow = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        );
        return DateBounds(start: startOfYear, end: endOfNow);
      case DashboardDateFilter.rango:
        if (_customRange != null) {
          return DateBounds(
            start: _customRange!.start,
            end: _customRange!.end,
          );
        }
        return DateBounds(start: todayStart, end: todayEnd);
    }
  }

  DateBounds _resolveTrendVisualBounds() {
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
        return DateBounds(start: todayStart, end: todayEnd);
      case DashboardDateFilter.semana:
        final DateTime weekStart = todayStart.subtract(
          Duration(days: todayStart.weekday - DateTime.monday),
        );
        DateTime weekEnd = weekStart.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        if (todayStart.weekday == DateTime.sunday) {
          weekEnd = weekEnd.add(
            const Duration(days: 7),
          );
        }
        return DateBounds(start: weekStart, end: weekEnd);
      case DashboardDateFilter.mes:
        final DateTime monthStart = DateTime(now.year, now.month, 1);
        DateTime monthEnd = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
        );
        final int daysRemainingInMonth = monthEnd.day - todayStart.day;
        if (daysRemainingInMonth < 7) {
          monthEnd = monthEnd.add(const Duration(days: 7));
        }
        return DateBounds(start: monthStart, end: monthEnd);
      case DashboardDateFilter.anio:
        return DateBounds(start: DateTime(now.year, 1, 1), end: todayEnd);
      case DashboardDateFilter.rango:
        if (_customRange != null) {
          return DateBounds(
            start: _customRange!.start,
            end: _customRange!.end,
          );
        }
        return DateBounds(start: todayStart, end: todayEnd);
    }
  }

  List<T> _filterByRange<T>(
    List<T> source,
    DateBounds bounds,
    DateTime Function(T item) dateOf,
  ) {
    return source.where((T item) {
      final DateTime date = dateOf(item);
      return !date.isBefore(bounds.start) && !date.isAfter(bounds.end);
    }).toList();
  }

  NowSnapshot<_NowState> _buildNowSnapshot({
    required List<VisitItem> source,
    required DateTime now,
  }) {
    final List<VisitNowItem<_NowState>> items = <VisitNowItem<_NowState>>[];
    VisitItem? nextVisit;

    for (final VisitItem visit in source) {
      if (!_sameDay(visit.date, now)) continue;
      if (visit.status.toLowerCase() == 'realizada') continue;

      final DateTime end = visit.date.add(
        Duration(minutes: visit.durationMinutes),
      );

      if (now.isAfter(visit.date) && now.isBefore(end)) {
        items.add(
          VisitNowItem<_NowState>(visit: visit, state: _NowState.enCurso),
        );
        continue;
      }

      if (now.isBefore(visit.date)) {
        final int minutes = visit.date.difference(now).inMinutes;
        if (minutes <= 30) {
          items.add(
            VisitNowItem<_NowState>(visit: visit, state: _NowState.porIniciar),
          );
        }
        if (nextVisit == null || visit.date.isBefore(nextVisit.date)) {
          nextVisit = visit;
        }
        continue;
      }

      if (now.isAfter(end)) {
        items.add(
          VisitNowItem<_NowState>(visit: visit, state: _NowState.retrasada),
        );
      }
    }

    items.sort(
      (VisitNowItem<_NowState> a, VisitNowItem<_NowState> b) =>
          a.visit.date.compareTo(b.visit.date),
    );

    return NowSnapshot<_NowState>(items: items, nextVisit: nextVisit);
  }

  List<VisitItem> _buildUpcomingVisits({
    required List<VisitItem> source,
    required DateTime now,
  }) {
    final List<VisitItem> items = source.where((VisitItem item) {
      return item.status.toLowerCase() != 'realizada' && item.date.isAfter(now);
    }).toList()..sort((VisitItem a, VisitItem b) => a.date.compareTo(b.date));

    return items.take(5).toList();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<SmallMetric> _aggregateMetrics({
    required List<String> labels,
    required List<MetricEvent> source,
    required DateBounds bounds,
  }) {
    final List<MetricEvent> filtered = _filterByRange<MetricEvent>(
      source,
      bounds,
      (MetricEvent item) => item.date,
    );
    return labels.map((String label) {
      final int count = filtered
          .where((MetricEvent e) => e.label == label)
          .length;
      return SmallMetric(label: label, value: '$count');
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

  List<KpiItem> _buildKpis({
    required DateBounds bounds,
    required List<CensoPaciente> pacientes,
    required List<CandidateItem> candidatos,
    required List<VisitItem> visitas,
    required List<SimpleEventItem> noIngresos,
  }) {
    final List<CensoPaciente> enRango = pacientes.where((p) {
      final DateTime? ingreso = p.fechaIngreso;
      final DateTime? egreso = p.fechaEgreso;
      if (ingreso == null) return false;
      return !ingreso.isAfter(bounds.end) &&
          (egreso == null || !egreso.isBefore(bounds.start));
    }).toList();

    final int pacientesActuales = enRango.where((p) {
      return p.fechaEgreso == null || p.fechaEgreso!.isAfter(bounds.end);
    }).length;

    // Ingresos: pacientes con fechaIngreso dentro del rango
    final int ingresos = pacientes.where((p) {
      final DateTime? ingreso = p.fechaIngreso;
      return ingreso != null &&
          !ingreso.isBefore(bounds.start) &&
          !ingreso.isAfter(bounds.end);
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
          egreso != null &&
          !egreso.isBefore(bounds.start) &&
          !egreso.isAfter(bounds.end);
      return esReingresoValido;
    }).length;

    // Egresos: pacientes con fechaEgreso dentro del rango (incluye reingresos)
    final int egresos = pacientes.where((p) {
      final DateTime? egreso = p.fechaEgreso;
      return egreso != null &&
          !egreso.isBefore(bounds.start) &&
          !egreso.isAfter(bounds.end);
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

    // Movimiento PAD: ingresos + egresos + reingresos + no ingresos
    final int totalMovimientoPad =
        ingresos + egresos + reingresos + noIngresos.length;

    return <KpiItem>[
      KpiItem(
        label: PadUiLabels.kpiTotalMovement,
        value: '$totalMovimientoPad',
        valueColor: const Color(0xFF17726D),
      ),
      KpiItem(
        label: PadUiLabels.kpiCurrentPatients,
        value: '$pacientesActuales',
        valueColor: const Color(0xFF1E88E5),
      ),
      KpiItem(
        label: PadUiLabels.kpiDischarges,
        value: '$egresos',
        valueColor: const Color(0xFF43A047),
      ),
      KpiItem(
        label: PadUiLabels.kpiReadmissions,
        value: '$reingresos',
        valueColor: const Color(0xFF8E24AA),
      ),
      KpiItem(
        label: PadUiLabels.kpiAverageStayDays,
        value: promedioEstancia.toStringAsFixed(1),
        valueColor: const Color(0xFF3949AB),
      ),
      KpiItem(
        label: PadUiLabels.kpiNoAdmissions,
        value: '${noIngresos.length}',
        valueColor: const Color(0xFFFB8C00),
      ),
      KpiItem(
        label: PadUiLabels.casesPendingDefinition,
        value: '${candidatos.length}',
        valueColor: const Color(0xFFE53935),
      ),
      KpiItem(
        label: PadUiLabels.kpiTodayVisits,
        value: '${visitas.length}',
        valueColor: const Color(0xFF00897B),
      ),
    ];
  }

  String _rangeSummaryLabel(DateBounds bounds) {
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

  Widget _buildKpiSection(List<KpiItem> kpis) {
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
    required List<SmallMetric> metrics,
  }) {
    return SectionCard(
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

  Widget _buildCandidatesCard(List<CandidateItem> candidatos) {
    if (candidatos.isEmpty) {
      return SectionCard(
        title: PadUiLabels.casesPendingDefinition,
        child: _buildActionableEmptyState(
          title: 'No hay casos por definir para el periodo seleccionado.',
          ctaLabel: 'Crear nuevo caso',
          onTap: () => context.go('/pad/nuevo'),
        ),
      );
    }

    return SectionCard(
      title: PadUiLabels.casesPendingDefinition,
      child: Column(
        children: candidatos.asMap().entries.map((entry) {
          final int index = entry.key;
          final CandidateItem item = entry.value;
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
    required NowSnapshot<_NowState> snapshot,
  }) {
    return SectionCard(
      title: 'Ahora mismo',
      subtitle: 'Hora actual ${_formatTime(now)} · operación en curso',
      child: snapshot.items.isEmpty
          ? _buildNowEmptyState(snapshot.nextVisit)
          : Column(
              children: snapshot.items.asMap().entries.map((entry) {
                final int index = entry.key;
                final VisitNowItem<_NowState> item = entry.value;

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
                                MapLocationLink(
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
                              StatusPill(label: _nowStateLabel(item.state)),
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

  Widget _buildNowEmptyState(VisitItem? nextVisit) {
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

  void _openVisitInAgenda(VisitItem visit) {
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

  Widget _buildVisitsCard(List<VisitItem> visitas) {
    return SectionCard(
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
                final VisitItem item = entry.value;
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
                                MapLocationLink(
                                  label: item.location,
                                  onTap: () => _openLocationInMaps(
                                    location: item.location,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          StatusPill(label: item.status),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNoIngresosCard(List<SimpleEventItem> noIngresos) {
    if (noIngresos.isEmpty) {
      return SectionCard(
        title: PadUiLabels.recentNoAdmissions,
        child: _buildActionableEmptyState(
          title: 'No se registran no ingresos recientes.',
          ctaLabel: 'Revisar pacientes',
          onTap: () => context.go('/cases'),
        ),
      );
    }

    return SectionCard(
      title: PadUiLabels.recentNoAdmissions,
      child: Column(
        children: noIngresos.asMap().entries.map((entry) {
          final int index = entry.key;
          final SimpleEventItem item = entry.value;
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

  Widget _buildActivityCard(List<RecentActivityItem<_ActivityKind>> actividad) {
    if (actividad.isEmpty) {
      return SectionCard(
        title: PadUiLabels.recentActivity,
        child: _buildActionableEmptyState(
          title: 'Aún no se registra actividad reciente.',
          ctaLabel: 'Ir a pendientes',
          onTap: () => context.go('/pending'),
        ),
      );
    }

    final bool compact = actividad.length <= 1;

    return SectionCard(
      title: PadUiLabels.recentActivity,
      child: Column(
        children: actividad.asMap().entries.map((entry) {
          final int index = entry.key;
          final RecentActivityItem<_ActivityKind> item = entry.value;
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
    List<DailyPadStatPoint> dailyStats, {
    bool compactMode = false,
  }) {
    final List<MapEntry<String, DailyPadStatPoint>> chartEntries =
        _buildDailyBehaviorChartEntries(dailyStats);

    if (chartEntries.isEmpty) {
      return SectionCard(
        title: _dailyBehaviorTitle(),
        subtitle: _dailyBehaviorSubtitle(),
        child: _buildActionableEmptyState(
          title: 'No hay datos diarios para graficar en este rango.',
          ctaLabel: 'Ver mes actual',
          onTap: () => _onDateFilterSelected(DashboardDateFilter.mes),
        ),
      );
    }

    final bool sparse = compactMode || chartEntries.length <= 4;
    final DateBounds trendBounds = _resolveTrendVisualBounds();
    final bool yearlyScale = _selectedFilter == DashboardDateFilter.anio ||
        (_selectedFilter == DashboardDateFilter.rango &&
            trendBounds.end.difference(trendBounds.start).inDays.abs() + 1 > 45);
    final double chartHeight = sparse ? 190 : 250;
    final double pointWidth = yearlyScale ? 96 : 84;
    final double maxPixels = sparse ? 108 : 172;

    final int maxValue = chartEntries
        .map((entry) {
          final DailyPadStatPoint point = entry.value;
          return point.amanecen > point.egresan
              ? point.amanecen
              : point.egresan;
        })
        .fold<int>(0, (prev, next) => next > prev ? next : prev);

    return SectionCard(
      title: _dailyBehaviorTitle(),
      subtitle: _dailyBehaviorSubtitle(),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: _primary, width: 3),
          ),
        ),
        padding: const EdgeInsets.only(left: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: const <Widget>[
                LegendDot(
                  label: 'Censo inicial',
                  color: Color(0xFF17726D),
                ),
                LegendDot(
                  label: 'Egresos',
                  color: Color(0xFFB0BEC5),
                ),
              ],
            ),
            SizedBox(height: sparse ? 12 : 18),
            SizedBox(
              height: chartHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Wrap(
                  spacing: sparse ? 12 : 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: chartEntries.map((entry) {
                    final DailyPadStatPoint item = entry.value;
                    return SizedBox(
                      width: pointWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          SizedBox(
                            height: maxPixels,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Bar(
                                    value: item.amanecen,
                                    max: maxValue,
                                    color: const Color(0xFF17726D),
                                    compact: true,
                                    maxPixels: maxPixels,
                                  ),
                                  const SizedBox(width: 6),
                                  Bar(
                                    value: item.egresan,
                                    max: maxValue,
                                    color: const Color(0xFFB0BEC5),
                                    compact: true,
                                    maxPixels: maxPixels,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: sparse ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, DailyPadStatPoint>> _buildDailyBehaviorChartEntries(
    List<DailyPadStatPoint> dailyStats,
  ) {
    switch (_selectedFilter) {
      case DashboardDateFilter.hoy:
      case DashboardDateFilter.semana:
        return _buildDailyEntriesForWeek(dailyStats);
      case DashboardDateFilter.mes:
        return _buildWeeklyEntriesForMonth(dailyStats);
      case DashboardDateFilter.anio:
        return _buildMonthlyEntriesForYear(dailyStats);
      case DashboardDateFilter.rango:
        final DateBounds bounds = _resolveTrendVisualBounds();
        final int durationDays =
            bounds.end.difference(bounds.start).inDays.abs() + 1;
        return durationDays > 45
            ? _buildMonthlyEntriesForRange(dailyStats, bounds)
            : _buildWeeklyEntriesForRange(dailyStats, bounds);
    }
  }

  List<MapEntry<String, DailyPadStatPoint>> _buildDailyEntriesForWeek(
    List<DailyPadStatPoint> dailyStats,
  ) {
    final DateBounds bounds = _resolveTrendVisualBounds();
    final Map<String, DailyPadStatPoint> pointsByDay =
        <String, DailyPadStatPoint>{
          for (final DailyPadStatPoint point in dailyStats) _dateKey(point.date): point,
        };
    final List<MapEntry<String, DailyPadStatPoint>> entries =
        <MapEntry<String, DailyPadStatPoint>>[];

    for (
      DateTime day = DateTime(
        bounds.start.year,
        bounds.start.month,
        bounds.start.day,
      );
      !day.isAfter(bounds.end);
      day = day.add(const Duration(days: 1))
    ) {
      final DailyPadStatPoint point =
          pointsByDay[_dateKey(day)] ??
          DailyPadStatPoint(date: day, amanecen: 0, egresan: 0);
      entries.add(
        MapEntry<String, DailyPadStatPoint>(_weekdayLetter(day), point),
      );
    }

    return entries;
  }

  List<MapEntry<String, DailyPadStatPoint>> _buildWeeklyEntriesForMonth(
    List<DailyPadStatPoint> dailyStats,
  ) {
    final DateBounds bounds = _resolveTrendVisualBounds();
    final int totalWeeks = ((bounds.end.day - 1) ~/ 7) + 1;
    final List<MapEntry<String, DailyPadStatPoint>> entries =
        <MapEntry<String, DailyPadStatPoint>>[];

    for (int week = 1; week <= totalWeeks; week++) {
      final DateTime start = DateTime(
        bounds.start.year,
        bounds.start.month,
        ((week - 1) * 7) + 1,
      );
      final DateTime rawEnd = DateTime(
        bounds.start.year,
        bounds.start.month,
        week * 7,
        23,
        59,
        59,
      );
      final DateTime end = rawEnd.isAfter(bounds.end) ? bounds.end : rawEnd;
      entries.add(
        MapEntry<String, DailyPadStatPoint>(
          'S$week',
          _aggregateDailyStatsGroup(dailyStats, start: start, end: end),
        ),
      );
    }

    return entries;
  }

  List<MapEntry<String, DailyPadStatPoint>> _buildMonthlyEntriesForYear(
    List<DailyPadStatPoint> dailyStats,
  ) {
    final DateBounds bounds = _resolveTrendVisualBounds();
    final List<MapEntry<String, DailyPadStatPoint>> entries =
        <MapEntry<String, DailyPadStatPoint>>[];

    for (int month = 1; month <= 12; month++) {
      final DateTime start = DateTime(bounds.start.year, month, 1);
      if (start.isAfter(bounds.end)) break;
      final DateTime rawEnd = DateTime(
        bounds.start.year,
        month + 1,
        0,
        23,
        59,
        59,
      );
      final DateTime end = rawEnd.isAfter(bounds.end) ? bounds.end : rawEnd;
      entries.add(
        MapEntry<String, DailyPadStatPoint>(
          _monthLabel(month),
          _aggregateDailyStatsGroup(dailyStats, start: start, end: end),
        ),
      );
    }

    return entries;
  }

  List<MapEntry<String, DailyPadStatPoint>> _buildWeeklyEntriesForRange(
    List<DailyPadStatPoint> dailyStats,
    DateBounds bounds,
  ) {
    final DateTime startDate = DateTime(
      bounds.start.year,
      bounds.start.month,
      bounds.start.day,
    );
    final List<MapEntry<String, DailyPadStatPoint>> entries =
        <MapEntry<String, DailyPadStatPoint>>[];
    int weekIndex = 1;

    for (
      DateTime start = startDate;
      !start.isAfter(bounds.end);
      start = start.add(const Duration(days: 7)), weekIndex++
    ) {
      final DateTime rawEnd = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      final DateTime end = rawEnd.isAfter(bounds.end) ? bounds.end : rawEnd;
      entries.add(
        MapEntry<String, DailyPadStatPoint>(
          'S$weekIndex',
          _aggregateDailyStatsGroup(dailyStats, start: start, end: end),
        ),
      );
    }

    return entries;
  }

  List<MapEntry<String, DailyPadStatPoint>> _buildMonthlyEntriesForRange(
    List<DailyPadStatPoint> dailyStats,
    DateBounds bounds,
  ) {
    DateTime cursor = DateTime(bounds.start.year, bounds.start.month, 1);
    final List<MapEntry<String, DailyPadStatPoint>> entries =
        <MapEntry<String, DailyPadStatPoint>>[];

    while (!cursor.isAfter(bounds.end)) {
      final DateTime start = cursor.isBefore(bounds.start)
          ? bounds.start
          : cursor;
      final DateTime rawEnd = DateTime(
        cursor.year,
        cursor.month + 1,
        0,
        23,
        59,
        59,
      );
      final DateTime end = rawEnd.isAfter(bounds.end) ? bounds.end : rawEnd;
      entries.add(
        MapEntry<String, DailyPadStatPoint>(
          _monthLabel(cursor.month),
          _aggregateDailyStatsGroup(dailyStats, start: start, end: end),
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return entries;
  }

  DailyPadStatPoint _aggregateDailyStatsGroup(
    List<DailyPadStatPoint> dailyStats, {
    required DateTime start,
    required DateTime end,
  }) {
    final List<DailyPadStatPoint> points = dailyStats.where((point) {
      return !point.date.isBefore(start) && !point.date.isAfter(end);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    if (points.isEmpty) {
      return DailyPadStatPoint(date: start, amanecen: 0, egresan: 0);
    }

    final int egresan = points.fold<int>(
      0,
      (sum, point) => sum + point.egresan,
    );
    final DailyPadStatPoint lastPoint = points.last;
    return DailyPadStatPoint(
      date: lastPoint.date,
      amanecen: lastPoint.amanecen,
      egresan: egresan,
    );
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String _monthLabel(int month) {
    const List<String> labels = <String>[
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
    return labels[month - 1];
  }

  String _dailyBehaviorTitle() {
    switch (_selectedFilter) {
      case DashboardDateFilter.hoy:
        return 'Tendencia PAD de hoy';
      case DashboardDateFilter.semana:
        return 'Tendencia PAD semanal';
      case DashboardDateFilter.mes:
        return 'Tendencia PAD mensual';
      case DashboardDateFilter.anio:
        return 'Tendencia PAD anual';
      case DashboardDateFilter.rango:
        return 'Tendencia PAD personalizada';
    }
  }

  String _dailyBehaviorSubtitle() {
    switch (_selectedFilter) {
      case DashboardDateFilter.hoy:
        return 'Amanecen vs egresan por hora';
      case DashboardDateFilter.semana:
        return 'Amanecen vs egresan por día';
      case DashboardDateFilter.mes:
        return 'Amanecen vs egresan por semana';
      case DashboardDateFilter.anio:
        return 'Amanecen vs egresan por mes';
      case DashboardDateFilter.rango:
        return 'Amanecen vs egresan según rango seleccionado';
    }
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
                  ).pop(const RangeDialogResult(clear: true));
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
                          RangeDialogResult(
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
