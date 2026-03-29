import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_top_bar.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HextTopBar(title: 'Agenda'),
      body: Center(
        child: Text(
          'Agenda',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


