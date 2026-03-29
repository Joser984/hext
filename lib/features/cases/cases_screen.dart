import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_top_bar.dart';

class CensoScreen extends StatelessWidget {
  const CensoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HextTopBar(title: 'Censo'),
      body: Center(
        child: Text(
          'Censo',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


