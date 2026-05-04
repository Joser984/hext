import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hext/features/schedule/models/scheduled_shift.dart';

const String kImportedScheduleAssetPath =
    'assets/data/horarios/horario_hext_import_2026_04_20_2026_08_02.json';

class ImportedScheduleMonthData {
  const ImportedScheduleMonthData({
    required this.month,
    required this.auxiliarNames,
    required this.entriesByAuxiliar,
  });

  final DateTime month;
  final List<String> auxiliarNames;
  final Map<String, Map<DateTime, ScheduledShift>> entriesByAuxiliar;
}

class ImportedScheduleDataset {
  const ImportedScheduleDataset({
    required this.entries,
    required this.auxiliarNames,
  });

  final List<ScheduledShift> entries;
  final List<String> auxiliarNames;

  static Future<ImportedScheduleDataset?> loadDefault() async {
    try {
      final String raw = await rootBundle.loadString(kImportedScheduleAssetPath);
      return ImportedScheduleDataset.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  factory ImportedScheduleDataset.fromJsonString(String raw) {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<ScheduledShift> entries = decoded
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) => ScheduledShift.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    return ImportedScheduleDataset.fromEntries(entries);
  }

  factory ImportedScheduleDataset.fromEntries(List<ScheduledShift> entries) {
    final List<ScheduledShift> sortedEntries = List<ScheduledShift>.from(entries)
      ..sort((ScheduledShift a, ScheduledShift b) {
        final int dateCompare = a.fecha.compareTo(b.fecha);
        if (dateCompare != 0) return dateCompare;
        return a.auxiliarNombre.toLowerCase().compareTo(
          b.auxiliarNombre.toLowerCase(),
        );
      });

    final List<String> auxiliarNames = <String>[];
    for (final ScheduledShift entry in sortedEntries) {
      if (!auxiliarNames.contains(entry.auxiliarNombre)) {
        auxiliarNames.add(entry.auxiliarNombre);
      }
    }

    return ImportedScheduleDataset(
      entries: sortedEntries,
      auxiliarNames: auxiliarNames,
    );
  }

  ImportedScheduleMonthData? monthFor(DateTime month) {
    final DateTime normalizedMonth = DateTime(month.year, month.month, 1);
    final List<ScheduledShift> monthEntries = entries.where((ScheduledShift entry) {
      return entry.fecha.year == normalizedMonth.year &&
          entry.fecha.month == normalizedMonth.month;
    }).toList();

    if (monthEntries.isEmpty) {
      return null;
    }

    final Map<String, Map<DateTime, ScheduledShift>> byAuxiliar =
        <String, Map<DateTime, ScheduledShift>>{};

    for (final String auxiliarName in auxiliarNames) {
      byAuxiliar[auxiliarName] = <DateTime, ScheduledShift>{};
    }

    for (final ScheduledShift entry in monthEntries) {
      byAuxiliar.putIfAbsent(
        entry.auxiliarNombre,
        () => <DateTime, ScheduledShift>{},
      )[entry.fecha] = entry;
    }

    return ImportedScheduleMonthData(
      month: normalizedMonth,
      auxiliarNames: auxiliarNames,
      entriesByAuxiliar: byAuxiliar,
    );
  }

  ImportedScheduleMonthData? windowFor({
    required DateTime anchorDate,
    required List<DateTime> visibleDays,
  }) {
    if (visibleDays.isEmpty) return null;
    final Set<DateTime> allowedDates = visibleDays
        .map((DateTime day) => DateTime(day.year, day.month, day.day))
        .toSet();
    final List<ScheduledShift> windowEntries = entries.where((
      ScheduledShift entry,
    ) {
      return allowedDates.contains(entry.fecha);
    }).toList();

    if (windowEntries.isEmpty) {
      return null;
    }

    final Map<String, Map<DateTime, ScheduledShift>> byAuxiliar =
        <String, Map<DateTime, ScheduledShift>>{};

    for (final String auxiliarName in auxiliarNames) {
      byAuxiliar[auxiliarName] = <DateTime, ScheduledShift>{};
    }

    for (final ScheduledShift entry in windowEntries) {
      byAuxiliar.putIfAbsent(
        entry.auxiliarNombre,
        () => <DateTime, ScheduledShift>{},
      )[entry.fecha] = entry;
    }

    return ImportedScheduleMonthData(
      month: DateTime(anchorDate.year, anchorDate.month, 1),
      auxiliarNames: auxiliarNames,
      entriesByAuxiliar: byAuxiliar,
    );
  }
}
