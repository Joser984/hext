import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/core/repositories/ops_firestore_repo.dart';
import 'package:hext/core/repositories/caso_paciente_repo.dart';
import 'package:hext/core/models/caso_paciente.dart';
import 'package:hext/features/dashboard/logic/dashboard_date_range.dart';
import 'package:hext/features/dashboard/logic/dashboard_operational_forecast.dart';
import 'package:hext/features/dashboard/logic/dashboard_historical_pattern.dart';
import 'package:hext/features/dashboard/logic/dashboard_metrics.dart';
import 'package:hext/features/dashboard/logic/dashboard_real_trend.dart';
import 'package:hext/features/dashboard/models/dashboard_view_models.dart';
import 'package:hext/shared/widgets/hext_page_shell.dart';
import 'package:hext/features/dashboard/widgets/dashboard_common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardDateFilter _selectedFilter = DashboardDateFilter.semana;
  DateTimeRange? _customRange;
  final OpsFirestoreRepo _opsRepo = OpsFirestoreRepo();
  final GlobalKey _trendCardKey = GlobalKey();
  bool _rangeSelectorOpen = false;

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
  List<RecentActivityItem> _actividad = <RecentActivityItem>[];
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
    final DateTime now = DateTime.now();
    final DateBounds selectedBounds = resolveDateBounds(
      filter: _selectedFilter,
      now: now,
      customRange: _customRange,
    );
    final DateBounds trendBounds = resolveTrendVisualBounds(
      filter: _selectedFilter,
      now: now,
      customRange: _customRange,
    );
    final DateTimeRange selectedRange = DateTimeRange(
      start: selectedBounds.start,
      end: selectedBounds.end,
    );
    final DateTimeRange trendRange = DateTimeRange(
      start: trendBounds.start,
      end: trendBounds.end,
    );
    _dailyStats = buildDailyStatsFromPacientes(
      _pacientes,
      selectedRange,
      now: now,
    );
    _trendDailyStats = buildDailyStatsFromPacientes(
      _pacientes,
      trendRange,
      now: now,
    );
  }

  void _scrollToTrendCardIfNeeded() {
    if (_selectedFilter == DashboardDateFilter.hoy) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? trendContext = _trendCardKey.currentContext;
      if (trendContext == null) return;
      Scrollable.ensureVisible(
        trendContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
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
                (OpsVisitRecord r) => RecentActivityItem(
                  title: r.status.toLowerCase() == 'realizada'
                      ? PadUiLabels.activityApprovedAdmission
                      : PadUiLabels.caseReassessed,
                  subtitle: r.patientName,
                  date: r.date,
                  kind: r.status.toLowerCase() == 'realizada'
                      ? ActivityKind.alta
                      : ActivityKind.reingreso,
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
  @override
  Widget build(BuildContext context) {
    final DateBounds bounds = resolveDateBounds(
      filter: _selectedFilter,
      now: DateTime.now(),
      customRange: _customRange,
    );

    final List<CandidateItem> candidatos = filterByRange<CandidateItem>(
      _candidatos,
      bounds,
      (CandidateItem item) => item.date,
    );
    final List<VisitItem> visitas = filterByRange<VisitItem>(
      _visitas,
      bounds,
      (VisitItem item) => item.date,
    );
    final DateTime now = DateTime.now();
    final NowSnapshot nowSnapshot = _buildNowSnapshot(
      source: _visitas,
      now: now,
    );
    final List<VisitItem> proximas = _buildUpcomingVisits(
      source: visitas,
      now: now,
    );
    final List<SimpleEventItem> noIngresos = filterByRange<SimpleEventItem>(
      _noIngresos,
      bounds,
      (SimpleEventItem item) => item.date,
    );
    final List<RecentActivityItem> actividad =
        filterByRange<RecentActivityItem>(
          _actividad,
          bounds,
          (RecentActivityItem item) => item.date,
        );
    final List<DailyPadStatPoint> dailyStats =
        filterByRange<DailyPadStatPoint>(
          _dailyStats,
          bounds,
          (DailyPadStatPoint item) => item.date,
        );

    final List<SmallMetric> origenes = aggregateDashboardMetrics(
      labels: <String>[
        PadUiLabels.captureOriginActiveSearch,
        PadUiLabels.captureOriginFromService,
      ],
      source: _origenRecords,
      bounds: bounds,
    );
    final List<SmallMetric> especialidades = aggregateDashboardMetrics(
      labels: <String>[
        PadUiLabels.specialtyInternalMedicine,
        PadUiLabels.specialtySurgery,
        PadUiLabels.specialtyOrthopedics,
        PadUiLabels.specialtyOthers,
      ],
      source: _especialidadRecords,
      bounds: bounds,
    );
    final List<KpiItem> kpis = buildDashboardKpis(
      bounds: bounds,
      pacientes: _pacientes,
      candidatos: candidatos,
      visitas: visitas,
      noIngresos: noIngresos,
    );
    final bool secondaryMetricsAllZero =
        allDashboardMetricsZero(origenes) &&
        allDashboardMetricsZero(especialidades);
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

    return HextPageShell(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildTopHeader(context, bounds),
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
            KeyedSubtree(
              key: _trendCardKey,
              child: _buildDailyBehaviorCard(
                _trendDailyStats,
                compactMode: lowDensityMode || nonZeroDailyPoints <= 2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, DateBounds bounds) {
    return HextPageHeader(
      title: PadUiLabels.dashboardTitle,
      subtitle:
          '${PadUiLabels.dashboardSubtitle} · ${_rangeSummaryLabel(bounds)}',
      trailing: _buildDateFilters(),
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
      if (_rangeSelectorOpen) return;
      _rangeSelectorOpen = true;
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

      final RangeDialogResult? result;
      try {
        result = await _openRangeSelector(
          now: now,
          initial: initial,
        );
      } finally {
        _rangeSelectorOpen = false;
      }
      if (!mounted || result == null) return;
      final RangeDialogResult rangeResult = result;

      if (rangeResult.clear) {
        setState(() {
          _customRange = null;
          _selectedFilter = DashboardDateFilter.hoy;
          _refreshDailyStats();
        });
        _scrollToTrendCardIfNeeded();
        return;
      }

      if (rangeResult.range == null) return;

      setState(() {
        _selectedFilter = DashboardDateFilter.rango;
        _customRange = normalizedDayRange(rangeResult.range!);
        _refreshDailyStats();
      });
      _scrollToTrendCardIfNeeded();
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
      _scrollToTrendCardIfNeeded();
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _refreshDailyStats();
    });
    _scrollToTrendCardIfNeeded();
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

  NowSnapshot _buildNowSnapshot({
    required List<VisitItem> source,
    required DateTime now,
  }) {
    final List<VisitNowItem> items = <VisitNowItem>[];
    VisitItem? nextVisit;

    for (final VisitItem visit in source) {
      if (!_sameDay(visit.date, now)) continue;
      if (visit.status.toLowerCase() == 'realizada') continue;

      final DateTime end = visit.date.add(
        Duration(minutes: visit.durationMinutes),
      );

      if (now.isAfter(visit.date) && now.isBefore(end)) {
        items.add(
          VisitNowItem(visit: visit, state: NowState.enCurso),
        );
        continue;
      }

      if (now.isBefore(visit.date)) {
        final int minutes = visit.date.difference(now).inMinutes;
        if (minutes <= 30) {
          items.add(
            VisitNowItem(visit: visit, state: NowState.porIniciar),
          );
        }
        if (nextVisit == null || visit.date.isBefore(nextVisit.date)) {
          nextVisit = visit;
        }
        continue;
      }

      if (now.isAfter(end)) {
        items.add(
          VisitNowItem(visit: visit, state: NowState.retrasada),
        );
      }
    }

    items.sort(
      (VisitNowItem a, VisitNowItem b) =>
          a.visit.date.compareTo(b.visit.date),
    );

    return NowSnapshot(items: items, nextVisit: nextVisit);
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
          child: SurfaceCard(
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
    required NowSnapshot snapshot,
  }) {
    return SectionCard(
      title: 'Ahora mismo',
      subtitle: 'Hora actual ${_formatTime(now)} · operación en curso',
      child: snapshot.items.isEmpty
          ? _buildNowEmptyState(snapshot.nextVisit)
          : Column(
              children: snapshot.items.asMap().entries.map((entry) {
                final int index = entry.key;
                final VisitNowItem item = entry.value;

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

  String _nowStateLabel(NowState state) {
    switch (state) {
      case NowState.enCurso:
        return 'En curso';
      case NowState.porIniciar:
        return 'Por iniciar';
      case NowState.retrasada:
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

  Widget _buildActivityCard(List<RecentActivityItem> actividad) {
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
          final RecentActivityItem item = entry.value;
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
    final DateTime now = DateTime.now();
    final List<HistoricalPadPatternPoint> historicalPattern =
        buildHistoricalPadPattern(
          pacientes: _pacientes,
          now: now,
        );
    final List<OperationalForecastPoint> forecastPoints =
        buildOperationalForecastPoints(
          realTrend: dailyStats,
          pattern: historicalPattern,
          filter: _selectedFilter,
          now: now,
          customRange: _customRange,
        );
    final List<DailyPadStatPoint> chartSource = mergeRealTrendWithForecast(
      realTrend: dailyStats,
      forecast: forecastPoints,
    );
    final List<TrendChartEntry> rawChartEntries =
        buildDailyBehaviorChartEntries(
          dailyStats: chartSource,
          selectedFilter: _selectedFilter,
          now: now,
          customRange: _customRange,
        );
    final List<TrendChartEntry> chartEntries = _selectedFilter ==
            DashboardDateFilter.semana
        ? _trimWeeklyTrendEntries(
            rawChartEntries,
            now: now,
            forecastHorizonDays: 2,
          )
        : rawChartEntries;

    if (chartEntries.isEmpty) {
      return SectionCard(
        title: _dailyBehaviorTitle(),
        subtitle: _dailyBehaviorForecastSubtitle(),
        child: _buildActionableEmptyState(
          title: 'No hay datos diarios para graficar en este rango.',
          ctaLabel: 'Ver mes actual',
          onTap: () => _onDateFilterSelected(DashboardDateFilter.mes),
        ),
      );
    }

    final bool sparse = compactMode || chartEntries.length <= 4;
    final DateBounds trendBounds = resolveTrendVisualBounds(
      filter: _selectedFilter,
      now: now,
      customRange: _customRange,
    );
    final bool yearlyScale = _selectedFilter == DashboardDateFilter.anio ||
        (_selectedFilter == DashboardDateFilter.rango &&
            trendBounds.end.difference(trendBounds.start).inDays.abs() + 1 > 45);
    final double chartHeight = sparse ? 228 : 296;
    final double pointWidth = yearlyScale ? 96 : 84;
    final double maxPixels = sparse ? 150 : 214;
    final double barAreaHeight = maxPixels + (sparse ? 26 : 30);
    final bool hasForecastSeries = chartSource.any(
      (DailyPadStatPoint point) => point.isForecast,
    );
    final _TrendStatusSummary trendStatus = _buildTrendStatusSummary(
      chartEntries,
      now,
    );

    final int maxValue = chartEntries
        .map((entry) {
          final DailyPadStatPoint point = entry.point;
          return point.amanecen > point.egresan
              ? point.amanecen
              : point.egresan;
        })
        .fold<int>(0, (prev, next) => next > prev ? next : prev);

    return SectionCard(
      title: _dailyBehaviorTitle(),
      subtitle: _dailyBehaviorForecastSubtitle(),
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
            _buildTrendStatusBanner(trendStatus),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _buildTrendFilterSelector(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: <Widget>[
                const LegendDot(
                  label: 'Pacientes activos',
                  color: Color(0xFF17726D),
                ),
                const LegendDot(
                  label: 'Egresos',
                  color: Color(0xFFB0BEC5),
                ),
                if (hasForecastSeries)
                  const LegendDot(
                    label: 'Posibles ingresos',
                    color: Color(0xFF7EA7F8),
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
                    final DailyPadStatPoint item = entry.point;
                    final bool highlightCurrentPeriod =
                        !now.isBefore(entry.start) && !now.isAfter(entry.end);
                    return SizedBox(
                      width: pointWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          SizedBox(
                            height: barAreaHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  if (!item.isForecast) ...<Widget>[
                                    Bar(
                                      value: item.amanecen,
                                      max: maxValue,
                                      color: const Color(0xFF17726D),
                                      compact: true,
                                      maxPixels: maxPixels,
                                      showValue: true,
                                      valueColor: _titleColor,
                                      semanticLabel: 'Censo inicial',
                                    ),
                                    const SizedBox(width: 6),
                                    Bar(
                                      value: item.egresan,
                                      max: maxValue,
                                      color: const Color(0xFFB0BEC5),
                                      compact: true,
                                      maxPixels: maxPixels,
                                      showValue: true,
                                      valueColor: _mutedColor,
                                      semanticLabel: 'Egresos',
                                    ),
                                  ],
                                  if (item.isForecast) ...<Widget>[
                                    Bar(
                                      value: item.amanecen,
                                      max: maxValue,
                                      color: const Color(0xFF7EA7F8),
                                      compact: true,
                                      maxPixels: maxPixels,
                                      showValue: true,
                                      valueColor: const Color(0xFF4D74C9),
                                      semanticLabel: 'Posibles ingresos',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: highlightCurrentPeriod
                                ? BoxDecoration(
                                    color: const Color(0xFFEAF3FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFD5E8FF),
                                    ),
                                  )
                                : null,
                            child: Text(
                              entry.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: sparse ? 11 : 12,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                color: highlightCurrentPeriod
                                    ? const Color(0xFF1E88E5)
                                    : _mutedColor,
                              ),
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

  Widget _buildTrendFilterSelector() {
    const List<DashboardDateFilter> filters = <DashboardDateFilter>[
      DashboardDateFilter.semana,
      DashboardDateFilter.mes,
      DashboardDateFilter.anio,
      DashboardDateFilter.rango,
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: filters.map((DashboardDateFilter filter) {
        final bool selected = _selectedFilter == filter;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onDateFilterSelected(filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F3F1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? _primary : _borderColor,
              ),
            ),
            child: Text(
              _filterLabel(filter),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? _primary : _mutedColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _dailyBehaviorTitle() {
    switch (_selectedFilter) {
      case DashboardDateFilter.hoy:
        return 'Tendencia PAD';
      case DashboardDateFilter.semana:
        return 'Tendencia PAD';
      case DashboardDateFilter.mes:
        return 'Tendencia PAD';
      case DashboardDateFilter.anio:
        return 'Tendencia PAD';
      case DashboardDateFilter.rango:
        return 'Tendencia PAD';
    }
  }

  String _dailyBehaviorForecastSubtitle() =>
      'Actividad real y posibles ingresos según patrón histórico';

  List<TrendChartEntry> _trimWeeklyTrendEntries(
    List<TrendChartEntry> entries, {
    required DateTime now,
    required int forecastHorizonDays,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime cutoff = today.add(Duration(days: forecastHorizonDays));

    return entries.where((TrendChartEntry entry) {
      final DateTime start = DateTime(
        entry.start.year,
        entry.start.month,
        entry.start.day,
      );
      return !start.isAfter(cutoff);
    }).toList();
  }

  Widget _buildTrendStatusBanner(_TrendStatusSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: summary.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: summary.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            summary.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: summary.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.primaryTitle,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: summary.textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            summary.primaryMessage,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.25,
              color: summary.textColor,
            ),
          ),
          if (summary.secondaryTitle != null &&
              summary.secondaryMessage != null)
            ...<Widget>[
              const SizedBox(height: 10),
              Text(
                summary.secondaryTitle!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: summary.textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                summary.secondaryMessage!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: summary.textColor,
                ),
              ),
            ],
          if (summary.tertiaryTitle != null && summary.tertiaryMessage != null)
            ...<Widget>[
              const SizedBox(height: 10),
              Text(
                summary.tertiaryTitle!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: summary.textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                summary.tertiaryMessage!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: summary.textColor,
                ),
              ),
            ],
        ],
      ),
    );
  }

  _TrendStatusSummary _buildTrendStatusSummary(
    List<TrendChartEntry> chartEntries,
    DateTime now,
  ) {
    const int simultaneousGoal = 20;
    final bool hasForecastPoints = chartEntries.any(
      (TrendChartEntry entry) => entry.point.isForecast,
    );
    final int currentSimultaneousCensus = _countCurrentSimultaneousCensus(now);
    final int missingForGoal = simultaneousGoal - currentSimultaneousCensus;
    final String censusMessage =
        'Censo simultáneo: $currentSimultaneousCensus de $simultaneousGoal pacientes en extensión hospitalaria.';
    final String objectiveMessage = currentSimultaneousCensus >= simultaneousGoal
        ? 'Objetivo operativo cumplido.'
        : 'Faltan $missingForGoal para alcanzar el objetivo operativo.';

    final DateBounds currentBounds = resolveDateBounds(
      filter: _selectedFilter,
      now: now,
      customRange: _customRange,
    );
    final DateBounds previousBounds = _resolvePreviousPeriodBounds(
      filter: _selectedFilter,
      bounds: currentBounds,
    );
    final int currentMovement = _countVisibleRealMovement(chartEntries);
    final int previousMovement = _countVisibleRealMovement(
      _buildComparableChartEntries(previousBounds),
    );
    final bool hasComparableBase = _hasComparablePeriodData(previousBounds);
    final String comparisonLabel = _comparisonPeriodLabel();
    final String movementStatus;
    if (!hasComparableBase) {
      movementStatus =
          'Sin base comparativa suficiente para el período anterior.';
    } else if (currentMovement > previousMovement) {
      movementStatus = 'Movimiento superior al período anterior.';
    } else if (currentMovement == previousMovement) {
      movementStatus = 'Movimiento igual al período anterior.';
    } else {
      movementStatus = 'Movimiento por debajo del período anterior.';
    }

    return _TrendStatusSummary(
      label: 'Lectura operativa',
      primaryTitle: 'Meta operativa',
      primaryMessage: '$censusMessage $objectiveMessage',
      secondaryTitle: 'Movimiento real del período',
      secondaryMessage: hasComparableBase
          ? 'Movimiento real: $currentMovement. $comparisonLabel: $previousMovement. $movementStatus'
          : 'Movimiento real: $currentMovement. $movementStatus',
      tertiaryTitle: hasForecastPoints ? 'Anticipación' : null,
      tertiaryMessage: hasForecastPoints
          ? 'Posibles ingresos próximos 2 días según patrón histórico.'
          : null,
      backgroundColor: const Color(0xFFF6F7F8),
      borderColor: const Color(0xFFE3E7EB),
      textColor: _textColor,
    );
  }

  DateBounds _resolvePreviousPeriodBounds({
    required DashboardDateFilter filter,
    required DateBounds bounds,
  }) {
    switch (filter) {
      case DashboardDateFilter.hoy:
        final DateTime previousDay = bounds.start.subtract(
          const Duration(days: 1),
        );
        return DateBounds(
          start: DateTime(
            previousDay.year,
            previousDay.month,
            previousDay.day,
          ),
          end: DateTime(
            previousDay.year,
            previousDay.month,
            previousDay.day,
            23,
            59,
            59,
          ),
        );
      case DashboardDateFilter.semana:
        final DateTime previousWeekStart = bounds.start.subtract(
          const Duration(days: 7),
        );
        return DateBounds(
          start: previousWeekStart,
          end: previousWeekStart.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          ),
        );
      case DashboardDateFilter.mes:
        final DateTime previousMonthStart = DateTime(
          bounds.start.year,
          bounds.start.month - 1,
          1,
        );
        return DateBounds(
          start: previousMonthStart,
          end: DateTime(
            previousMonthStart.year,
            previousMonthStart.month + 1,
            0,
            23,
            59,
            59,
          ),
        );
      case DashboardDateFilter.anio:
        return DateBounds(
          start: DateTime(bounds.start.year - 1, 1, 1),
          end: DateTime(bounds.start.year - 1, 12, 31, 23, 59, 59),
        );
      case DashboardDateFilter.rango:
        final int durationDays =
            bounds.end.difference(bounds.start).inDays.abs() + 1;
        final DateTime previousEnd = DateTime(
          bounds.start.year,
          bounds.start.month,
          bounds.start.day,
          23,
          59,
          59,
        ).subtract(const Duration(days: 1));
        final DateTime previousStart = DateTime(
          previousEnd.year,
          previousEnd.month,
          previousEnd.day,
        ).subtract(Duration(days: durationDays - 1));
        return DateBounds(start: previousStart, end: previousEnd);
    }
  }

  int _countVisibleRealMovement(List<TrendChartEntry> entries) {
    return entries.where((TrendChartEntry entry) => !entry.point.isForecast).fold(
      0,
      (int sum, TrendChartEntry entry) =>
          sum + entry.point.amanecen + entry.point.egresan,
    );
  }

  List<TrendChartEntry> _buildComparableChartEntries(DateBounds bounds) {
    final DateTime referenceNow = DateTime(
      bounds.end.year,
      bounds.end.month,
      bounds.end.day,
    );
    final DateTimeRange range = DateTimeRange(
      start: bounds.start,
      end: bounds.end,
    );
    final List<DailyPadStatPoint> stats = buildDailyStatsFromPacientes(
      _pacientes,
      range,
      now: referenceNow,
    );

    return buildDailyBehaviorChartEntries(
      dailyStats: stats,
      selectedFilter: _selectedFilter,
      now: referenceNow,
      customRange: _selectedFilter == DashboardDateFilter.rango ? range : null,
    );
  }

  bool _hasComparablePeriodData(DateBounds bounds) {
    return _pacientes.any((CensoPaciente paciente) {
      final DateTime? ingreso = paciente.fechaIngreso;
      final DateTime? egreso = paciente.fechaEgreso;
      final bool hasMovementInBounds =
          (ingreso != null &&
              !ingreso.isBefore(bounds.start) &&
              !ingreso.isAfter(bounds.end)) ||
          (egreso != null &&
              !egreso.isBefore(bounds.start) &&
              !egreso.isAfter(bounds.end));
      if (hasMovementInBounds) return true;
      if (ingreso == null) return false;

      return !ingreso.isAfter(bounds.end) &&
          (egreso == null || !egreso.isBefore(bounds.start));
    });
  }

  int _countCurrentSimultaneousCensus(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);

    return _pacientes.where((CensoPaciente paciente) {
      final DateTime? ingreso = paciente.fechaIngreso;
      if (ingreso == null) return false;
      final bool admitted = !DateTime(
        ingreso.year,
        ingreso.month,
        ingreso.day,
      ).isAfter(today);

      final DateTime? egreso = paciente.fechaEgreso;
      final bool active = egreso == null ||
          DateTime(egreso.year, egreso.month, egreso.day).isAfter(today);

      return admitted && active;
    }).length;
  }

  String _comparisonPeriodLabel() {
    switch (_selectedFilter) {
      case DashboardDateFilter.hoy:
        return 'Día anterior';
      case DashboardDateFilter.semana:
        return 'Semana anterior';
      case DashboardDateFilter.mes:
        return 'Mes anterior';
      case DashboardDateFilter.anio:
        return 'Año anterior';
      case DashboardDateFilter.rango:
        return 'Rango anterior equivalente';
    }
  }

  Widget _buildActionableEmptyState({
    required String title,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }
}

class _TrendStatusSummary {
  final String label;
  final String primaryTitle;
  final String primaryMessage;
  final String? secondaryTitle;
  final String? secondaryMessage;
  final String? tertiaryTitle;
  final String? tertiaryMessage;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _TrendStatusSummary({
    required this.label,
    this.primaryTitle = 'Meta operativa',
    required this.primaryMessage,
    this.secondaryTitle,
    this.secondaryMessage,
    this.tertiaryTitle,
    this.tertiaryMessage,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
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

