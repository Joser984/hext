import 'package:flutter/material.dart';
import 'package:hext/features/pad/widgets/paciente_captacion_form.dart';

class NuevoPadScreen extends StatelessWidget {
  const NuevoPadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo candidato PAD'),
      ),
      body: const SafeArea(
        child: PacienteCaptacionForm(),
      ),
    );
  }
}