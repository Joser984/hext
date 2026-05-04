import 'package:flutter/material.dart';
import 'package:hext/features/dashboard/models/dashboard_view_models.dart';

DateTimeRange normalizedDayRange(DateTimeRange range) {
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

DateBounds resolveDateBounds({
  required DashboardDateFilter filter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateTime todayStart = DateTime(now.year, now.month, now.day);
  final DateTime todayEnd = DateTime(
    now.year,
    now.month,
    now.day,
    23,
    59,
    59,
  );

  switch (filter) {
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
      return DateBounds(start: startOfYear, end: todayEnd);
    case DashboardDateFilter.rango:
      if (customRange != null) {
        return DateBounds(start: customRange.start, end: customRange.end);
      }
      return DateBounds(start: todayStart, end: todayEnd);
  }
}

DateBounds resolveTrendVisualBounds({
  required DashboardDateFilter filter,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  final DateTime todayStart = DateTime(now.year, now.month, now.day);
  final DateTime todayEnd = DateTime(
    now.year,
    now.month,
    now.day,
    23,
    59,
    59,
  );

  switch (filter) {
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
        weekEnd = weekEnd.add(const Duration(days: 7));
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
      if (customRange != null) {
        return DateBounds(start: customRange.start, end: customRange.end);
      }
      return DateBounds(start: todayStart, end: todayEnd);
  }
}

List<T> filterByRange<T>(
  List<T> source,
  DateBounds bounds,
  DateTime Function(T item) dateOf,
) {
  return source.where((T item) {
    final DateTime date = dateOf(item);
    return !date.isBefore(bounds.start) && !date.isAfter(bounds.end);
  }).toList();
}
