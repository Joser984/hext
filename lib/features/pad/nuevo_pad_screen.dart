import 'package:flutter/material.dart';
import 'package:hext/features/pad/services/pad_firestore_service.dart';
import 'package:hext/features/pad/widgets/paciente_captacion_form.dart';

class NuevoPadScreen extends StatelessWidget {
  const NuevoPadScreen({super.key, this.candidatoId});

  final String? candidatoId;

  @override
  Widget build(BuildContext context) {
    if (candidatoId == null || candidatoId!.trim().isEmpty) {
      return const SafeArea(top: false, child: PacienteCaptacionForm());
    }

    return SafeArea(
      top: false,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: PadFirestoreService.obtenerCandidato(candidatoId!),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No se pudo cargar el caso para edición.'),
            );
          }

          return PacienteCaptacionForm(
            candidatoId: candidatoId,
            initialData: snapshot.data,
          );
        },
      ),
    );
  }
}