import 'package:flutter/material.dart';
import 'package:hext/features/agenda/agenda_module_page.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({
    super.key,
    this.initialSearch,
    this.initialVisitId,
    this.initialPatientId,
    this.initialPendingId,
    this.sourceContext,
  });

  final String? initialSearch;
  final String? initialVisitId;
  final String? initialPatientId;
  final String? initialPendingId;
  final String? sourceContext;

  @override
  Widget build(BuildContext context) {
    return AgendaModulePage(
      initialSearch: initialSearch,
      initialVisitId: initialVisitId,
      initialPatientId: initialPatientId,
      initialPendingId: initialPendingId,
      sourceContext: sourceContext,
    );
  }
}
