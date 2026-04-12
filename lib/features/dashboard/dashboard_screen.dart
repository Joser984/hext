import 'package:flutter/material.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/shared/widgets/module_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum DashboardDateFilter { hoy, semana, mes, rango }

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardDateFilter _selectedFilter = DashboardDateFilter.hoy;

  static const Color _pageBg = Color(0xFFF5F6F8);
  static const Color _cardBg = Colors.white;
  static const Color _borderColor = Color(0xFFE2E6EA);
  static const Color _titleColor = Color(0xFF1F2937);
  static const Color _textColor = Color(0xFF4B5563);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF17726D);

  final List<_KpiItem> _kpis = const <_KpiItem>[
    _KpiItem(
      label: PadUiLabels.kpiCurrentPatients,
      value: '18',
      valueColor: Color(0xFF1E88E5),
    ),
    _KpiItem(
      label: PadUiLabels.casesPendingDefinition,
      value: '5',
      valueColor: Color(0xFFE53935),
    ),
    _KpiItem(
      label: PadUiLabels.kpiTodayVisits,
      value: '12',
      valueColor: Color(0xFF00897B),
    ),
    _KpiItem(
      label: PadUiLabels.kpiNoAdmissions,
      value: '3',
      valueColor: Color(0xFFFB8C00),
    ),
    _KpiItem(
      label: PadUiLabels.kpiDischarges,
      value: '7',
      valueColor: Color(0xFF43A047),
    ),
    _KpiItem(
      label: PadUiLabels.kpiReadmissions,
      value: '2',
      valueColor: Color(0xFF8E24AA),
    ),
    _KpiItem(
      label: PadUiLabels.kpiAverageStayDays,
      value: '6.4',
      valueColor: Color(0xFF3949AB),
    ),
  ];

  final List<_SmallMetric> _origenes = const <_SmallMetric>[
    _SmallMetric(label: PadUiLabels.captureOriginActiveSearch, value: '6'),
    _SmallMetric(label: PadUiLabels.captureOriginFromService, value: '3'),
  ];

  final List<_SmallMetric> _especialidades = const <_SmallMetric>[
    _SmallMetric(label: PadUiLabels.specialtyInternalMedicine, value: '8'),
    _SmallMetric(label: PadUiLabels.specialtySurgery, value: '4'),
    _SmallMetric(label: PadUiLabels.specialtyOrthopedics, value: '2'),
    _SmallMetric(label: PadUiLabels.specialtyOthers, value: '1'),
  ];

  // Demo-only operational samples: patient names/details stay local to screen.
  final List<_CandidateItem> _candidatos = const <_CandidateItem>[
    _CandidateItem(
      patientName: 'Juan Pérez',
      detail: 'Neumonía · 3 h sin decisión',
      actionLabel: PadUiLabels.openCaseAction,
    ),
    _CandidateItem(
      patientName: 'Ana Gómez',
      detail: 'Fractura · 5 h sin decisión',
      actionLabel: PadUiLabels.openCaseAction,
    ),
    _CandidateItem(
      patientName: 'Carlos Ruiz',
      detail: 'IAM · 1 h sin decisión',
      actionLabel: PadUiLabels.openCaseAction,
    ),
  ];

  final List<_VisitItem> _visitas = const <_VisitItem>[
    _VisitItem(
      date: '31 Mar',
      time: '09:00',
      patientName: 'Juan Pérez',
      modality: 'Domicilio',
      doctor: 'Dr. Díaz',
      status: 'Pendiente',
    ),
    _VisitItem(
      date: '31 Mar',
      time: '10:30',
      patientName: 'Ana Gómez',
      modality: 'Institución',
      doctor: 'Dra. Ríos',
      status: 'Realizada',
    ),
  ];

  final List<_SimpleEventItem> _noIngresos = const <_SimpleEventItem>[
    _SimpleEventItem(
      title: 'Luis Torres',
      subtitle: 'No cumple criterios · 28/03',
      trailing: 'Dr. Díaz',
    ),
    _SimpleEventItem(
      title: 'Marta Silva',
      subtitle: 'Rechazo familiar · 28/03',
      trailing: 'Dra. Ríos',
    ),
  ];

  final List<_RecentActivityItem> _actividad = const <_RecentActivityItem>[
    _RecentActivityItem(
      title: PadUiLabels.activityApprovedAdmission,
      subtitle: 'Juan Pérez',
      time: '08:45',
    ),
    _RecentActivityItem(
      title: PadUiLabels.activityNoAdmission,
      subtitle: 'Luis Torres',
      time: '08:30',
    ),
    _RecentActivityItem(
      title: PadUiLabels.caseReassessed,
      subtitle: 'Ana Gómez',
      time: '08:10',
    ),
  ];

  final List<_DailyPadStat> _dailyStats = const <_DailyPadStat>[
    _DailyPadStat(day: 'L', amanecen: 14, egresan: 3),
    _DailyPadStat(day: 'M', amanecen: 16, egresan: 4),
    _DailyPadStat(day: 'M', amanecen: 15, egresan: 2),
    _DailyPadStat(day: 'J', amanecen: 17, egresan: 5),
    _DailyPadStat(day: 'V', amanecen: 18, egresan: 4),
    _DailyPadStat(day: 'S', amanecen: 13, egresan: 2),
    _DailyPadStat(day: 'D', amanecen: 12, egresan: 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTopHeader(context),
              const SizedBox(height: 20),
              _buildKpiSection(),
              const SizedBox(height: 24),
              _ResponsiveTwoColumn(
                left: _buildSmallMetricsCard(
                  title: PadUiLabels.captureOriginSectionTitle,
                  metrics: _origenes,
                ),
                right: _buildSmallMetricsCard(
                  title: PadUiLabels.specialtiesSectionTitle,
                  metrics: _especialidades,
                ),
              ),
              const SizedBox(height: 24),
              _ResponsiveTwoColumn(
                left: _buildCandidatesCard(),
                right: _buildVisitsCard(),
              ),
              const SizedBox(height: 24),
              _ResponsiveTwoColumn(
                left: _buildNoIngresosCard(),
                right: _buildActivityCard(),
              ),
              const SizedBox(height: 24),
              _buildDailyBehaviorCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 420,
            child: ModuleHeader(
              title: PadUiLabels.dashboardTitle,
              subtitle: PadUiLabels.dashboardSubtitle,
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _buildDateFilters(),
            ],
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
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: _borderColor)
                    : Border.all(color: Colors.transparent),
              ),
              child: Text(
                _filterLabel(filter),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _titleColor : _mutedColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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

  Widget _buildKpiSection() {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: _kpis.map((item) {
        return SizedBox(
          width: 170,
          height: 112, // altura fija para todas
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

  Widget _buildCandidatesCard() {
    return _SectionCard(
      title: PadUiLabels.casesPendingDefinition,
      child: Column(
        children: _candidatos.asMap().entries.map((entry) {
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

  Widget _buildVisitsCard() {
    return _SectionCard(
      title: PadUiLabels.upcomingMedicalAssessments,
      child: Column(
        children: _visitas.asMap().entries.map((entry) {
          final int index = entry.key;
          final _VisitItem item = entry.value;
          return Column(
            children: <Widget>[
              if (index > 0) const Divider(height: 1, color: _borderColor),
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
                        border: Border.all(color: const Color(0xFFD6F0ED)),
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
                            '${item.date} · ${item.time}',
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
                            '${item.modality} · ${item.doctor}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textColor,
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

  Widget _buildNoIngresosCard() {
    return _SectionCard(
      title: PadUiLabels.recentNoAdmissions,
      child: Column(
        children: _noIngresos.asMap().entries.map((entry) {
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

  Widget _buildActivityCard() {
    return _SectionCard(
      title: PadUiLabels.recentActivity,
      child: Column(
        children: _actividad.asMap().entries.map((entry) {
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
                      item.time,
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

  Widget _buildDailyBehaviorCard() {
    final int maxValue = _dailyStats
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
              children: _dailyStats.map((item) {
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
                          item.day,
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

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: left),
            const SizedBox(width: 24),
            Expanded(child: right),
          ],
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
    final bool done = label.toLowerCase() == 'realizada';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFF1F8F6) : const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? const Color(0xFFD9ECE7) : const Color(0xFFF4DFC0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: done ? const Color(0xFF17726D) : const Color(0xFF9A6700),
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

  const _CandidateItem({
    required this.patientName,
    required this.detail,
    required this.actionLabel,
  });
}

class _VisitItem {
  final String date;
  final String time;
  final String patientName;
  final String modality;
  final String doctor;
  final String status;

  const _VisitItem({
    required this.date,
    required this.time,
    required this.patientName,
    required this.modality,
    required this.doctor,
    required this.status,
  });
}

class _SimpleEventItem {
  final String title;
  final String subtitle;
  final String trailing;

  const _SimpleEventItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}

class _RecentActivityItem {
  final String title;
  final String subtitle;
  final String time;

  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class _DailyPadStat {
  final String day;
  final int amanecen;
  final int egresan;

  const _DailyPadStat({
    required this.day,
    required this.amanecen,
    required this.egresan,
  });
}
