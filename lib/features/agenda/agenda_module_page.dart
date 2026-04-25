import 'package:flutter/material.dart';
import 'package:hext/features/agenda/agenda_screen.dart';

class AgendaModulePage extends StatelessWidget {
  const AgendaModulePage({
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
    return AgendaScreen(
      initialSearch: initialSearch,
      initialVisitId: initialVisitId,
      initialPatientId: initialPatientId,
      initialPendingId: initialPendingId,
      sourceContext: sourceContext,
    );
  }
}
