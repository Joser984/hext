import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/shared/widgets/module_header.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum DashboardDateFilter { hoy, semana, mes, rango }

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardDateFilter _selectedFilter = DashboardDateFilter.hoy;
  DateTimeRange? _customRange;

  static const Color _pageBg = Color(0xFFF5F6F8);
  static const Color _cardBg = Colors.white;
  static const Color _borderColor = Color(0xFFE2E6EA);
  static const Color _titleColor = Color(0xFF1F2937);
  static const Color _textColor = Color(0xFF4B5563);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF17726D);

  late final List<_MetricEvent> _origenRecords;
  late final List<_MetricEvent> _especialidadRecords;
  late final List<_CandidateItem> _candidatos;
  late final List<_VisitItem> _visitas;
  late final List<_SimpleEventItem> _noIngresos;
  late final List<_RecentActivityItem> _actividad;
  late final List<_DailyPadStatPoint> _dailyStats;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _seedData();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _seedData() {
    DateTime at(int daysOffset, int hour, int minute) {
      final DateTime now = DateTime.now();
      final DateTime base = DateTime(now.year, now.month, now.day);
      return base.add(Duration(days: daysOffset, hours: hour, minutes: minute));
    }

    _origenRecords = <_MetricEvent>[
      _MetricEvent(
        label: PadUiLabels.captureOriginActiveSearch,
        date: at(0, 8, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginActiveSearch,
        date: at(0, 10, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginFromService,
        date: at(-1, 9, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginFromService,
        date: at(-3, 11, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginActiveSearch,
        date: at(-8, 8, 30),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginFromService,
        date: at(-12, 14, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginActiveSearch,
        date: at(-20, 15, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.captureOriginFromService,
        date: at(-26, 16, 0),
      ),
    ];

    _especialidadRecords = <_MetricEvent>[
      _MetricEvent(
        label: PadUiLabels.specialtyInternalMedicine,
        date: at(0, 8, 0),
      ),
      _MetricEvent(label: PadUiLabels.specialtySurgery, date: at(0, 9, 0)),
      _MetricEvent(
        label: PadUiLabels.specialtyOrthopedics,
        date: at(-1, 10, 0),
      ),
      _MetricEvent(label: PadUiLabels.specialtyOthers, date: at(-2, 11, 0)),
      _MetricEvent(
        label: PadUiLabels.specialtyInternalMedicine,
        date: at(-5, 9, 30),
      ),
      _MetricEvent(label: PadUiLabels.specialtySurgery, date: at(-10, 10, 45)),
      _MetricEvent(
        label: PadUiLabels.specialtyInternalMedicine,
        date: at(-15, 12, 0),
      ),
      _MetricEvent(
        label: PadUiLabels.specialtyOrthopedics,
        date: at(-22, 13, 0),
      ),
    ];

    _candidatos = <_CandidateItem>[
      _CandidateItem(
        patientName: 'Juan Pérez',
        detail: 'Neumonía · 3 h sin decisión',
        actionLabel: PadUiLabels.openCaseAction,
        date: at(0, 9, 15),
      ),
      _CandidateItem(
        patientName: 'Ana Gómez',
        detail: 'Fractura · 5 h sin decisión',
        actionLabel: PadUiLabels.openCaseAction,
        date: at(-2, 14, 30),
      ),
      _CandidateItem(
        patientName: 'Carlos Ruiz',
        detail: 'IAM · 1 h sin decisión',
        actionLabel: PadUiLabels.openCaseAction,
        date: at(-9, 11, 10),
      ),
    ];

    _visitas = <_VisitItem>[
      _VisitItem(
        date: at(0, 9, 0),
        patientName: 'Juan Pérez',
        modality: 'Domicilio',
        doctor: 'Dr. Díaz',
        auxiliar: 'Katerine Cabarcas',
        location: 'Barrio Boston',
        status: 'Pendiente',
        durationMinutes: 60,
      ),
      _VisitItem(
        date: at(0, 10, 30),
        patientName: 'Ana Gómez',
        modality: 'Institución',
        doctor: 'Dra. Ríos',
        auxiliar: 'Luis Castro',
        location: 'Clínica Cartagena',
        status: 'Realizada',
        durationMinutes: 45,
      ),
      _VisitItem(
        date: at(-4, 8, 45),
        patientName: 'Marta Silva',
        modality: 'Domicilio',
        doctor: 'Dr. Díaz',
        auxiliar: 'Nataly Vergara',
        location: 'La Campiña',
        status: 'Pendiente',
        durationMinutes: 60,
      ),
      _VisitItem(
        date: at(-16, 16, 10),
        patientName: 'Luis Torres',
        modality: 'Institución',
        doctor: 'Dra. Ríos',
        auxiliar: 'Edgar Mena',
        location: 'Hospital Universitario',
        status: 'Realizada',
        durationMinutes: 45,
      ),
    ];

    _noIngresos = <_SimpleEventItem>[
      _SimpleEventItem(
        title: 'Luis Torres',
        subtitle: 'No cumple criterios',
        trailing: 'Dr. Díaz',
        date: at(-1, 13, 20),
      ),
      _SimpleEventItem(
        title: 'Marta Silva',
        subtitle: 'Rechazo familiar',
        trailing: 'Dra. Ríos',
        date: at(-8, 9, 10),
      ),
    ];

    _actividad = <_RecentActivityItem>[
      _RecentActivityItem(
        title: PadUiLabels.activityApprovedAdmission,
        subtitle: 'Juan Pérez',
        date: at(0, 8, 45),
        kind: _ActivityKind.alta,
      ),
      _RecentActivityItem(
        title: PadUiLabels.activityNoAdmission,
        subtitle: 'Luis Torres',
        date: at(-2, 8, 30),
        kind: _ActivityKind.sinIngreso,
      ),
      _RecentActivityItem(
        title: PadUiLabels.caseReassessed,
        subtitle: 'Ana Gómez',
        date: at(-3, 8, 10),
        kind: _ActivityKind.reingreso,
      ),
      _RecentActivityItem(
        title: PadUiLabels.activityApprovedAdmission,
        subtitle: 'Carlos Ruiz',
        date: at(-14, 11, 0),
        kind: _ActivityKind.alta,
      ),
    ];

    _dailyStats = List<_DailyPadStatPoint>.generate(30, (int i) {
      final DateTime now = DateTime.now();
      final DateTime date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 29 - i));
      final int amanecen = 12 + (i % 7) + (i % 3);
      final int egresan = 1 + (i % 4);
      return _DailyPadStatPoint(
        date: date,
        amanecen: amanecen,
        egresan: egresan,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final _DateBounds bounds = _resolveDateBounds();
    final List<_CandidateItem> candidatos = _filterByRange<_CandidateItem>(
      _candidatos,
      bounds,
      (_CandidateItem item) => item.date,
    );
    final List<_VisitItem> visitas = _filterByRange<_VisitItem>(
      _visitas,
      bounds,
      (_VisitItem item) => item.date,
    );
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
    final List<_RecentActivityItem> actividad =
        _filterByRange<_RecentActivityItem>(
          _actividad,
          bounds,
          (_RecentActivityItem item) => item.date,
        );
    final List<_DailyPadStatPoint> dailyStats =
        _filterByRange<_DailyPadStatPoint>(
          _dailyStats,
          bounds,
          (_DailyPadStatPoint item) => item.date,
        );

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
      candidatos: candidatos,
      visitas: visitas,
      noIngresos: noIngresos,
      actividad: actividad,
      dailyStats: dailyStats,
    );

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
              const SizedBox(height: 24),
              _buildDailyBehaviorCard(dailyStats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, _DateBounds bounds) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 420,
            child: ModuleHeader(
              title: PadUiLabels.dashboardTitle,
              subtitle:
                  '${PadUiLabels.dashboardSubtitle} · ${_rangeSummaryLabel(bounds)}',
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[_buildDateFilters()],
          ),
        ],
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
    }).toList()..sort((_VisitItem a, _VisitItem b) => a.date.compareTo(b.date));

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
      final int count = filtered
          .where((_MetricEvent e) => e.label == label)
          .length;
      return _SmallMetric(label: label, value: '$count');
    }).toList();
  }

  List<_KpiItem> _buildKpis({
    required _DateBounds bounds,
    required List<_CandidateItem> candidatos,
    required List<_VisitItem> visitas,
    required List<_SimpleEventItem> noIngresos,
    required List<_RecentActivityItem> actividad,
    required List<_DailyPadStatPoint> dailyStats,
  }) {
    final int days = bounds.end.difference(bounds.start).inDays + 1;
    final int sumAmanecen = dailyStats.fold<int>(
      0,
      (int acc, _DailyPadStatPoint item) => acc + item.amanecen,
    );
    final double avgStay = days == 0 ? 0 : (sumAmanecen / days) / 2;
    final int altas = actividad
        .where((_RecentActivityItem a) => a.kind == _ActivityKind.alta)
        .length;
    final int reingresos = actividad
        .where((_RecentActivityItem a) => a.kind == _ActivityKind.reingreso)
        .length;

    return <_KpiItem>[
      _KpiItem(
        label: PadUiLabels.kpiCurrentPatients,
        value: '${sumAmanecen == 0 ? 0 : (sumAmanecen / days).round()}',
        valueColor: const Color(0xFF1E88E5),
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
      _KpiItem(
        label: PadUiLabels.kpiNoAdmissions,
        value: '${noIngresos.length}',
        valueColor: const Color(0xFFFB8C00),
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
        value: avgStay.toStringAsFixed(1),
        valueColor: const Color(0xFF3949AB),
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
                          _StatusPill(label: _nowStateLabel(item.state)),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Sin visitas en curso',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _mutedColor,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Sin visitas en curso',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Siguiente visita: ${_formatTime(nextVisit.date)} · ${nextVisit.patientName} · ${nextVisit.modality} · ${nextVisit.auxiliar}',
            style: const TextStyle(fontSize: 14, color: _textColor),
          ),
        ],
      ),
    );
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
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No hay próximas valoraciones en el periodo seleccionado.',
                style: TextStyle(
                  fontSize: 14,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
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

  Widget _buildDailyBehaviorCard(List<_DailyPadStatPoint> dailyStats) {
    final int maxValue = dailyStats
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
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((item) {
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

  const _Bar({required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final double height = max == 0 ? 0 : (value / max) * 150;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 12,
            color: _DashboardScreenState._mutedColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: height.clamp(8, 150),
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
  final String modality;
  final String doctor;
  final String auxiliar;
  final String location;
  final String status;
  final int durationMinutes;

  const _VisitItem({
    required this.date,
    required this.patientName,
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

enum _ActivityKind { alta, reingreso, sinIngreso }

enum _NowState { enCurso, porIniciar, retrasada }
