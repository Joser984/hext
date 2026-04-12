import 'package:flutter/material.dart';
import 'package:hext/features/agenda/agenda_module_page.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({
    super.key,
    this.initialSearch,
  });

  final String? initialSearch;

  @override
  Widget build(BuildContext context) {
    return AgendaModulePage(initialSearch: initialSearch);
  }
}


