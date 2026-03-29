import 'package:flutter/material.dart';
import 'package:hext/features/pad/widgets/paciente_captacion_form.dart';

class NuevoPadScreen extends StatelessWidget {
  const NuevoPadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    return const SafeArea(
      top: false,
      child: PacienteCaptacionForm(),
    );
    );
  }
}