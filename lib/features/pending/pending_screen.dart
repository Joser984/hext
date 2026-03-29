import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_top_bar.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HextTopBar(title: 'Pendientes'),
      body: Center(
        child: Text(
          'Pendientes',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


