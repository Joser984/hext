import 'package:flutter/material.dart';

enum DashboardDateFilter { hoy, semana, mes, anio, rango }

class KpiItem {
  final String label;
  final String value;
  final Color valueColor;

  const KpiItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class SmallMetric {
  final String label;
  final String value;

  const SmallMetric({required this.label, required this.value});
}

class DailyPadStatPoint {
  final DateTime date;
  final int amanecen;
  final int egresan;
  final bool isForecast;

  const DailyPadStatPoint({
    required this.date,
    required this.amanecen,
    required this.egresan,
    this.isForecast = false,
  });
}

class TrendChartEntry {
  final String label;
  final DailyPadStatPoint point;
  final DateTime start;
  final DateTime end;

  const TrendChartEntry({
    required this.label,
    required this.point,
    required this.start,
    required this.end,
  });
}

class DateBounds {
  final DateTime start;
  final DateTime end;

  const DateBounds({required this.start, required this.end});
}

class CandidateItem {
  final String patientName;
  final String detail;
  final String actionLabel;
  final DateTime date;

  const CandidateItem({
    required this.patientName,
    required this.detail,
    required this.actionLabel,
    required this.date,
  });
}

class VisitItem {
  final DateTime date;
  final String patientName;
  final String? patientId;
  final String? visitId;
  final String? pendingId;
  final String modality;
  final String doctor;
  final String auxiliar;
  final String location;
  final String status;
  final int durationMinutes;

  const VisitItem({
    required this.date,
    required this.patientName,
    this.patientId,
    this.visitId,
    this.pendingId,
    required this.modality,
    required this.doctor,
    required this.auxiliar,
    required this.location,
    required this.status,
    this.durationMinutes = 60,
  });
}

enum ActivityKind { alta, reingreso }

enum NowState { enCurso, porIniciar, retrasada }

class VisitNowItem {
  final VisitItem visit;
  final NowState state;

  const VisitNowItem({required this.visit, required this.state});
}

class NowSnapshot {
  final List<VisitNowItem> items;
  final VisitItem? nextVisit;

  const NowSnapshot({required this.items, required this.nextVisit});
}

class SimpleEventItem {
  final String title;
  final String subtitle;
  final String trailing;
  final DateTime date;

  const SimpleEventItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.date,
  });
}

class RecentActivityItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final ActivityKind kind;

  const RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.kind,
  });
}

class MetricEvent {
  final String label;
  final DateTime date;

  const MetricEvent({required this.label, required this.date});
}

class RangeDialogResult {
  final DateTimeRange? range;
  final bool clear;

  const RangeDialogResult({this.range, this.clear = false});
}
