import 'package:flutter/material.dart';
import 'package:hext/features/pad/services/pad_firestore_service.dart'
    as pad_service;
import 'package:hext/features/pad/presentation/captacion/paciente_captacion_form.dart'
    as pad_form;
import 'package:hext/shared/widgets/hext_loading_screen.dart';

class NuevoPadScreen extends StatelessWidget {
  const NuevoPadScreen({
    super.key,
    this.candidatoId,
    this.initialData,
  });

  final String? candidatoId;
  final Map<String, dynamic>? initialData;

  @override
  Widget build(BuildContext context) {
    final String? id = candidatoId?.trim();

    if (initialData != null) {
      return SafeArea(
        top: false,
        child: pad_form.PacienteCaptacionForm(
          candidatoId: id,
          initialData: initialData,
        ),
      );
    }

    if (id == null || id.isEmpty) {
      return const SafeArea(
        top: false,
        child: pad_form.PacienteCaptacionForm(),
      );
    }

    return SafeArea(
      top: false,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: pad_service.PadFirestoreService.obtenerCensoPaciente(id),
        builder: (
          BuildContext context,
          AsyncSnapshot<Map<String, dynamic>?> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const HextLoadingScreen(
              title: 'Cargando caso',
              subtitle: 'Preparando formulario PAD',
              compact: true,
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el caso para edición.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No se encontró el caso para edición.'),
            );
          }

          return pad_form.PacienteCaptacionForm(
            candidatoId: id,
            initialData: snapshot.data,
          );
        },
      ),
    );
  }
}