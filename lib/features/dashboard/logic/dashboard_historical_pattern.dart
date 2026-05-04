import 'package:hext/core/models/caso_paciente.dart';

enum PadHistoricalConfidenceLevel {
  insuficiente,
  preliminar,
  patronInicial,
  confiable,
}

class HistoricalPadPatternPoint {
  final int weekday;
  final double averageAdmissions;
  final double averageDischarges;
  final double averageTotalMovement;
  final int observationCount;
  final PadHistoricalConfidenceLevel confidenceLevel;
  final int historicalDaysAnalyzed;

  const HistoricalPadPatternPoint({
    required this.weekday,
    required this.averageAdmissions,
    required this.averageDischarges,
    required this.averageTotalMovement,
    required this.observationCount,
    required this.confidenceLevel,
    required this.historicalDaysAnalyzed,
  });
}

List<HistoricalPadPatternPoint> buildHistoricalPadPattern({
  required List<CensoPaciente> pacientes,
  required DateTime now,
  int lookbackDays = 90,
}) {
  if (pacientes.isEmpty || lookbackDays <= 0) {
    return const <HistoricalPadPatternPoint>[];
  }

  final DateTime today = _onlyDate(now);
  final DateTime historyEnd = today.subtract(const Duration(days: 1));
  final DateTime? firstRelevantDate = _resolveFirstRelevantDate(pacientes);

  if (firstRelevantDate == null || firstRelevantDate.isAfter(historyEnd)) {
    return const <HistoricalPadPatternPoint>[];
  }

  final DateTime requestedStart = historyEnd.subtract(
    Duration(days: lookbackDays - 1),
  );
  final DateTime historyStart = requestedStart.isBefore(firstRelevantDate)
      ? firstRelevantDate
      : requestedStart;
  final int historicalDaysAnalyzed =
      historyEnd.difference(historyStart).inDays + 1;

  final Map<int, _HistoricalPadAccumulator> buckets =
      <int, _HistoricalPadAccumulator>{};

  for (
    DateTime day = historyStart;
    !day.isAfter(historyEnd);
    day = day.add(const Duration(days: 1))
  ) {
    final int admissions = _countAdmissionsForDay(pacientes, day);
    final int discharges = _countDischargesForDay(pacientes, day);
    final _HistoricalPadAccumulator bucket =
        buckets.putIfAbsent(day.weekday, _HistoricalPadAccumulator.new);

    bucket.add(
      admissions: admissions,
      discharges: discharges,
      totalMovement: admissions + discharges,
    );
  }

  final PadHistoricalConfidenceLevel confidenceLevel =
      resolveHistoricalConfidenceLevel(historicalDaysAnalyzed);

  return List<HistoricalPadPatternPoint>.generate(7, (int index) {
    final int weekday = index + 1;
    final _HistoricalPadAccumulator? bucket = buckets[weekday];

    if (bucket == null || bucket.observationCount == 0) {
      return HistoricalPadPatternPoint(
        weekday: weekday,
        averageAdmissions: 0,
        averageDischarges: 0,
        averageTotalMovement: 0,
        observationCount: 0,
        confidenceLevel: confidenceLevel,
        historicalDaysAnalyzed: historicalDaysAnalyzed,
      );
    }

    return HistoricalPadPatternPoint(
      weekday: weekday,
      averageAdmissions: bucket.totalAdmissions / bucket.observationCount,
      averageDischarges: bucket.totalDischarges / bucket.observationCount,
      averageTotalMovement: bucket.totalMovement / bucket.observationCount,
      observationCount: bucket.observationCount,
      confidenceLevel: confidenceLevel,
      historicalDaysAnalyzed: historicalDaysAnalyzed,
    );
  });
}

HistoricalPadPatternPoint? findHistoricalPatternForDate(
  List<HistoricalPadPatternPoint> pattern,
  DateTime date,
) {
  for (final HistoricalPadPatternPoint point in pattern) {
    if (point.weekday == date.weekday) {
      return point;
    }
  }
  return null;
}

PadHistoricalConfidenceLevel resolveHistoricalConfidenceLevel(
  int historicalDays,
) {
  if (historicalDays <= 14) {
    return PadHistoricalConfidenceLevel.insuficiente;
  }
  if (historicalDays <= 30) {
    return PadHistoricalConfidenceLevel.preliminar;
  }
  if (historicalDays <= 90) {
    return PadHistoricalConfidenceLevel.patronInicial;
  }
  return PadHistoricalConfidenceLevel.confiable;
}

DateTime? _resolveFirstRelevantDate(List<CensoPaciente> pacientes) {
  DateTime? earliest;

  for (final CensoPaciente paciente in pacientes) {
    final DateTime? ingreso = paciente.fechaIngreso == null
        ? null
        : _onlyDate(paciente.fechaIngreso!);
    final DateTime? egreso = paciente.fechaEgreso == null
        ? null
        : _onlyDate(paciente.fechaEgreso!);

    if (ingreso != null && (earliest == null || ingreso.isBefore(earliest))) {
      earliest = ingreso;
    }
    if (egreso != null && (earliest == null || egreso.isBefore(earliest))) {
      earliest = egreso;
    }
  }

  return earliest;
}

int _countAdmissionsForDay(List<CensoPaciente> pacientes, DateTime day) {
  return pacientes.where((CensoPaciente paciente) {
    final DateTime? ingreso = paciente.fechaIngreso;
    return ingreso != null && _isSameDay(ingreso, day);
  }).length;
}

int _countDischargesForDay(List<CensoPaciente> pacientes, DateTime day) {
  return pacientes.where((CensoPaciente paciente) {
    final DateTime? egreso = paciente.fechaEgreso;
    return egreso != null && _isSameDay(egreso, day);
  }).length;
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

DateTime _onlyDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

class _HistoricalPadAccumulator {
  int totalAdmissions = 0;
  int totalDischarges = 0;
  int totalMovement = 0;
  int observationCount = 0;

  void add({
    required int admissions,
    required int discharges,
    required int totalMovement,
  }) {
    totalAdmissions += admissions;
    totalDischarges += discharges;
    this.totalMovement += totalMovement;
    observationCount += 1;
  }
}
