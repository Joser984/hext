import 'package:flutter/material.dart';
import 'package:hext/core/models/caso_paciente.dart';
import 'package:hext/features/dashboard/logic/dashboard_date_range.dart';
import 'package:hext/features/dashboard/models/dashboard_view_models.dart';

List<DailyPadStatPoint> buildDailyStatsFromPacientes(
  List<CensoPaciente> pacientes,
  DateTimeRange range,
  {
  DateTime? now,
}) {
  final DateTime current = now ?? DateTime.now();
  final DateTime today = DateTime(current.year, current.month, current.day);

  DateTime onlyDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  final start = onlyDate(range.start);
  final end = onlyDate(range.end);

  final result = <DailyPadStatPoint>[];

  for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
    final bool futureDay = day.isAfter(today);
    final amanecen = futureDay
        ? 0
        : pacientes.where((p) {
            final ingreso = parseDateFlexible(p.fechaIngreso);
            if (ingreso == null) return false;
            final ingresoDay = onlyDate(ingreso);
            final egreso = parseDateFlexible(p.fechaEgreso);
            final egresoDay = egreso == null ? null : onlyDate(egreso);
            final yaIngreso = !ingresoDay.isAfter(day);
            final noHaEgresadoAntesDelDia =
                egresoDay == null || egresoDay.isAfter(day);
            return yaIngreso && noHaEgresadoAntesDelDia;
          }).length;

    final egresan = pacientes.where((p) {
      final egreso = parseDateFlexible(p.fechaEgreso);
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

DateTime? parseDateFlexible(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  if (value.runtimeType.toString() == 'Timestamp' && value.toDate != null) {
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }
  return null;
}

List<TrendChartEntry> buildDailyBehaviorChartEntries({
  required List<DailyPadStatPoint> dailyStats,
  required DashboardDateFilter selectedFilter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  switch (selectedFilter) {
    case DashboardDateFilter.hoy:
    case DashboardDateFilter.semana:
      return buildDailyEntriesForWeek(
        dailyStats: dailyStats,
        selectedFilter: selectedFilter,
        now: now,
        customRange: customRange,
      );
    case DashboardDateFilter.mes:
      return buildWeeklyEntriesForMonth(
        dailyStats: dailyStats,
        selectedFilter: selectedFilter,
        now: now,
        customRange: customRange,
      );
    case DashboardDateFilter.anio:
      return buildMonthlyEntriesForYear(
        dailyStats: dailyStats,
        selectedFilter: selectedFilter,
        now: now,
        customRange: customRange,
      );
    case DashboardDateFilter.rango:
      final DateBounds bounds = resolveTrendVisualBounds(
        filter: selectedFilter,
        now: now,
        customRange: customRange,
      );
      final int durationDays =
          bounds.end.difference(bounds.start).inDays.abs() + 1;
      return durationDays > 45
          ? buildMonthlyEntriesForRange(
              dailyStats: dailyStats,
              bounds: bounds,
              now: now,
            )
          : buildWeeklyEntriesForRange(
              dailyStats: dailyStats,
              bounds: bounds,
              now: now,
            );
  }
}

List<TrendChartEntry> buildDailyEntriesForWeek({
  required List<DailyPadStatPoint> dailyStats,
  required DashboardDateFilter selectedFilter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateBounds bounds = resolveTrendVisualBounds(
    filter: selectedFilter,
    now: now,
    customRange: customRange,
  );
  final Map<String, DailyPadStatPoint> pointsByDay =
      <String, DailyPadStatPoint>{
        for (final DailyPadStatPoint point in dailyStats)
          dateKey(point.date): point,
      };
  final List<TrendChartEntry> entries = <TrendChartEntry>[];

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
        pointsByDay[dateKey(day)] ??
        DailyPadStatPoint(date: day, amanecen: 0, egresan: 0);
    entries.add(
      TrendChartEntry(
        label: '${weekdayLetter(day)}\n${day.day}',
        point: point,
        start: day,
        end: DateTime(day.year, day.month, day.day, 23, 59, 59),
      ),
    );
  }

  return entries;
}

List<TrendChartEntry> buildWeeklyEntriesForMonth({
  required List<DailyPadStatPoint> dailyStats,
  required DashboardDateFilter selectedFilter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateBounds bounds = resolveTrendVisualBounds(
    filter: selectedFilter,
    now: now,
    customRange: customRange,
  );
  final int totalWeeks = ((bounds.end.day - 1) ~/ 7) + 1;
  final List<TrendChartEntry> entries = <TrendChartEntry>[];

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
      TrendChartEntry(
        label: 'S$week',
        point: aggregateDailyStatsGroup(
          dailyStats,
          start: start,
          end: end,
          now: now,
        ),
        start: start,
        end: end,
      ),
    );
  }

  return entries;
}

List<TrendChartEntry> buildMonthlyEntriesForYear({
  required List<DailyPadStatPoint> dailyStats,
  required DashboardDateFilter selectedFilter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateBounds bounds = resolveTrendVisualBounds(
    filter: selectedFilter,
    now: now,
    customRange: customRange,
  );
  final List<TrendChartEntry> entries = <TrendChartEntry>[];

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
      TrendChartEntry(
        label: monthLabel(month),
        point: aggregateDailyStatsGroup(
          dailyStats,
          start: start,
          end: end,
          now: now,
        ),
        start: start,
        end: end,
      ),
    );
  }

  return entries;
}

List<TrendChartEntry> buildWeeklyEntriesForRange({
  required List<DailyPadStatPoint> dailyStats,
  required DateBounds bounds,
  required DateTime now,
}) {
  final DateTime startDate = DateTime(
    bounds.start.year,
    bounds.start.month,
    bounds.start.day,
  );
  final List<TrendChartEntry> entries = <TrendChartEntry>[];
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
      TrendChartEntry(
        label: 'S$weekIndex',
        point: aggregateDailyStatsGroup(
          dailyStats,
          start: start,
          end: end,
          now: now,
        ),
        start: start,
        end: end,
      ),
    );
  }

  return entries;
}

List<TrendChartEntry> buildMonthlyEntriesForRange({
  required List<DailyPadStatPoint> dailyStats,
  required DateBounds bounds,
  required DateTime now,
}) {
  DateTime cursor = DateTime(bounds.start.year, bounds.start.month, 1);
  final List<TrendChartEntry> entries = <TrendChartEntry>[];

  while (!cursor.isAfter(bounds.end)) {
    final DateTime start = cursor.isBefore(bounds.start) ? bounds.start : cursor;
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
      TrendChartEntry(
        label: monthLabel(cursor.month),
        point: aggregateDailyStatsGroup(
          dailyStats,
          start: start,
          end: end,
          now: now,
        ),
        start: start,
        end: end,
      ),
    );
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }

  return entries;
}

DailyPadStatPoint aggregateDailyStatsGroup(
  List<DailyPadStatPoint> dailyStats, {
  required DateTime start,
  required DateTime end,
  DateTime? now,
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
  final DateTime current = now ?? DateTime.now();
  final DateTime today = DateTime(current.year, current.month, current.day);
  DailyPadStatPoint? lastRealPoint;
  for (final DailyPadStatPoint point in points) {
    if (!point.date.isAfter(today)) {
      lastRealPoint = point;
    }
  }
  final DailyPadStatPoint lastPoint = lastRealPoint ?? points.last;
  return DailyPadStatPoint(
    date: lastPoint.date,
    amanecen: lastRealPoint?.amanecen ?? lastPoint.amanecen,
    egresan: egresan,
    isForecast: lastRealPoint == null && lastPoint.isForecast,
  );
}

String dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

String weekdayLetter(DateTime date) {
  const List<String> letters = <String>['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  return letters[date.weekday - 1];
}

String monthLabel(int month) {
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
