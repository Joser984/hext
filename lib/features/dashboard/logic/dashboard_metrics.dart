import 'package:flutter/material.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/core/models/caso_paciente.dart';
import 'package:hext/features/dashboard/logic/dashboard_date_range.dart';
import 'package:hext/features/dashboard/models/dashboard_view_models.dart';

const List<String> causasReingresoValidas = <String>[
  'COMORBILIDADES DESCOMPENSADAS',
  'FACTORES SOCIALES O DE SOPORTE NO FAVORABLES',
  'NECESIDAD DE ESCALAMIENTO DEL NIVEL DE ATENCION POR EVOLUCION CLINICA',
  'PROGRESION DE LA PATOLOGIA DE BASE',
  'REQUERIMIENTO DE ATENCION INTRAHOSPITALARIA',
  'REACCION ADVERSA A MEDICAMENTO',
  'NO AVAL ADMINISTRATIVO',
];

bool allDashboardMetricsZero(List<SmallMetric> metrics) {
  for (final SmallMetric metric in metrics) {
    final int? value = int.tryParse(metric.value.trim());
    if ((value ?? 0) > 0) return false;
  }
  return true;
}

List<SmallMetric> aggregateDashboardMetrics({
  required List<String> labels,
  required List<MetricEvent> source,
  required DateBounds bounds,
}) {
  final List<MetricEvent> filtered = filterByRange<MetricEvent>(
    source,
    bounds,
    (MetricEvent item) => item.date,
  );
  return labels.map((String label) {
    final int count = filtered.where((MetricEvent e) => e.label == label).length;
    return SmallMetric(label: label, value: '$count');
  }).toList();
}

List<KpiItem> buildDashboardKpis({
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

  final int ingresos = pacientes.where((p) {
    final DateTime? ingreso = p.fechaIngreso;
    return ingreso != null &&
        !ingreso.isBefore(bounds.start) &&
        !ingreso.isAfter(bounds.end);
  }).length;

  final int reingresos = enRango.where((p) {
    final String? tipoEgreso = p.tipoEgreso?.trim();
    final String? causaReingreso = p.causaReingreso?.trim();
    final String? causaReingresoOtro = _getCausaReingresoOtro(p);
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

String? _getCausaReingresoOtro(dynamic p) {
  try {
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
