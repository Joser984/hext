import 'package:flutter/material.dart';
import 'package:hext/features/dashboard/logic/dashboard_date_range.dart';
import 'package:hext/features/dashboard/logic/dashboard_historical_pattern.dart';
import 'package:hext/features/dashboard/logic/dashboard_real_trend.dart';
import 'package:hext/features/dashboard/models/dashboard_view_models.dart';

class OperationalForecastPoint {
  final DateTime date;
  final int weekday;
  final bool isForecast;
  final int projectedAdmissions;
  final int projectedCensus;
  final int projectedDischarges;
  final int projectedMovement;
  final PadHistoricalConfidenceLevel confidenceLevel;

  const OperationalForecastPoint({
    required this.date,
    required this.weekday,
    required this.isForecast,
    required this.projectedAdmissions,
    required this.projectedCensus,
    required this.projectedDischarges,
    required this.projectedMovement,
    required this.confidenceLevel,
  });

  DailyPadStatPoint toDailyPadStatPoint() {
    return DailyPadStatPoint(
      date: date,
      amanecen: projectedAdmissions,
      egresan: projectedDischarges,
      isForecast: isForecast,
    );
  }
}

DateTimeRange resolveOperationalForecastRange({
  required DashboardDateFilter filter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);

  switch (filter) {
    case DashboardDateFilter.hoy:
      final DateTime nextDay = today.add(const Duration(days: 1));
      return DateTimeRange(
        start: nextDay,
        end: DateTime(nextDay.year, nextDay.month, nextDay.day, 23, 59, 59),
      );
    case DashboardDateFilter.semana:
      final DateTime forecastStart = today.add(const Duration(days: 1));
      return DateTimeRange(
        start: forecastStart,
        end: forecastStart.add(
          const Duration(days: 1, hours: 23, minutes: 59, seconds: 59),
        ),
      );
    case DashboardDateFilter.mes:
      final DateTime nextMonthStart = DateTime(now.year, now.month + 1, 1);
      return DateTimeRange(
        start: nextMonthStart,
        end: DateTime(
          nextMonthStart.year,
          nextMonthStart.month + 1,
          0,
          23,
          59,
          59,
        ),
      );
    case DashboardDateFilter.anio:
      return DateTimeRange(
        start: DateTime(now.year + 1, 1, 1),
        end: DateTime(now.year + 1, 12, 31, 23, 59, 59),
      );
    case DashboardDateFilter.rango:
      final DateTimeRange visibleRange = normalizedDayRange(
        customRange ?? DateTimeRange(start: today, end: today),
      );
      final int durationDays =
          visibleRange.end.difference(visibleRange.start).inDays + 1;
      final DateTime forecastStart = DateTime(
        visibleRange.end.year,
        visibleRange.end.month,
        visibleRange.end.day,
      ).add(const Duration(days: 1));
      return DateTimeRange(
        start: forecastStart,
        end: forecastStart.add(
          Duration(
            days: durationDays - 1,
            hours: 23,
            minutes: 59,
            seconds: 59,
          ),
        ),
      );
  }
}

List<OperationalForecastPoint> buildOperationalForecastPoints({
  required List<DailyPadStatPoint> realTrend,
  required List<HistoricalPadPatternPoint> pattern,
  required DashboardDateFilter filter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateTimeRange forecastRange = resolveOperationalForecastRange(
    filter: filter,
    now: now,
    customRange: customRange,
  );

  return buildOperationalForecastPointsForRange(
    realTrend: realTrend,
    pattern: pattern,
    forecastRange: forecastRange,
    now: now,
  );
}

List<OperationalForecastPoint> buildNextSevenDayOperationalForecast({
  required List<DailyPadStatPoint> realTrend,
  required List<HistoricalPadPatternPoint> pattern,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);

  return buildOperationalForecastPointsForRange(
    realTrend: realTrend,
    pattern: pattern,
    forecastRange: DateTimeRange(
      start: today.add(const Duration(days: 1)),
      end: today.add(
        const Duration(days: 7, hours: 23, minutes: 59, seconds: 59),
      ),
    ),
    now: now,
  );
}

List<OperationalForecastPoint> buildOperationalForecastPointsForRange({
  required List<DailyPadStatPoint> realTrend,
  required List<HistoricalPadPatternPoint> pattern,
  required DateTimeRange forecastRange,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final Set<String> realDates = realTrend
      .where((DailyPadStatPoint point) => !point.isForecast)
      .map((DailyPadStatPoint point) => dateKey(point.date))
      .toSet();
  final List<OperationalForecastPoint> forecast =
      <OperationalForecastPoint>[];
  int rollingCensus = _resolveRollingCensusSeed(realTrend);

  for (
    DateTime day = _onlyDate(forecastRange.start);
    !day.isAfter(forecastRange.end);
    day = day.add(const Duration(days: 1))
  ) {
    if (!day.isAfter(today) || realDates.contains(dateKey(day))) {
      continue;
    }

    final HistoricalPadPatternPoint? basis = findHistoricalPatternForDate(
      pattern,
      day,
    );
    final PadHistoricalConfidenceLevel confidence =
        basis?.confidenceLevel ?? PadHistoricalConfidenceLevel.insuficiente;
    final int projectedAdmissions = _resolveProjectedAdmissions(
      basis: basis,
      confidence: confidence,
    );
    final int projectedDischarges = _resolveProjectedDischarges(
      basis: basis,
      confidence: confidence,
    );

    rollingCensus = (rollingCensus + projectedAdmissions - projectedDischarges)
        .clamp(0, 1 << 30);

    forecast.add(
      OperationalForecastPoint(
        date: day,
        weekday: day.weekday,
        isForecast: true,
        projectedAdmissions: projectedAdmissions,
        projectedCensus: rollingCensus,
        projectedDischarges: projectedDischarges,
        projectedMovement: projectedAdmissions + projectedDischarges,
        confidenceLevel: confidence,
      ),
    );
  }

  return forecast;
}

List<DailyPadStatPoint> mergeRealTrendWithForecast({
  required List<DailyPadStatPoint> realTrend,
  required List<OperationalForecastPoint> forecast,
}) {
  final List<DailyPadStatPoint> merged = <DailyPadStatPoint>[
    ...realTrend.where((DailyPadStatPoint point) => !point.isForecast),
    ...forecast.map((OperationalForecastPoint point) => point.toDailyPadStatPoint()),
  ];

  merged.sort((DailyPadStatPoint a, DailyPadStatPoint b) {
    return a.date.compareTo(b.date);
  });

  return merged;
}

int _resolveRollingCensusSeed(List<DailyPadStatPoint> realTrend) {
  if (realTrend.isEmpty) return 0;

  final List<DailyPadStatPoint> realOnly = realTrend
      .where((DailyPadStatPoint point) => !point.isForecast)
      .toList()
    ..sort((DailyPadStatPoint a, DailyPadStatPoint b) {
      return a.date.compareTo(b.date);
    });

  if (realOnly.isEmpty) return 0;
  return realOnly.last.amanecen;
}

int _resolveProjectedAdmissions({
  required HistoricalPadPatternPoint? basis,
  required PadHistoricalConfidenceLevel confidence,
}) {
  if (basis == null) return 0;

  switch (confidence) {
    case PadHistoricalConfidenceLevel.insuficiente:
      return 0;
    case PadHistoricalConfidenceLevel.preliminar:
      return (basis.averageAdmissions * 0.75).round();
    case PadHistoricalConfidenceLevel.patronInicial:
      return basis.averageAdmissions.round();
    case PadHistoricalConfidenceLevel.confiable:
      return basis.averageAdmissions.round();
  }
}

int _resolveProjectedDischarges({
  required HistoricalPadPatternPoint? basis,
  required PadHistoricalConfidenceLevel confidence,
}) {
  if (basis == null) return 0;

  switch (confidence) {
    case PadHistoricalConfidenceLevel.insuficiente:
      return 0;
    case PadHistoricalConfidenceLevel.preliminar:
      return (basis.averageDischarges * 0.75).round();
    case PadHistoricalConfidenceLevel.patronInicial:
      return basis.averageDischarges.round();
    case PadHistoricalConfidenceLevel.confiable:
      return basis.averageDischarges.round();
  }
}

DateTime _onlyDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
