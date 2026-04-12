import 'package:flutter/material.dart';
import 'package:hext/features/agenda/agenda_screen.dart';

class AgendaModulePage extends StatelessWidget {
  const AgendaModulePage({
    super.key,
    this.initialSearch,
  });

  final String? initialSearch;

  @override
  Widget build(BuildContext context) {
    return AgendaScreen(initialSearch: initialSearch);
  }
}
