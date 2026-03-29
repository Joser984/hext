import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CandidatosScreen extends StatelessWidget {
  const CandidatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidatos PAD'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Aquí irá la lista de candidatos PAD'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/pad/nuevo'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo candidato'),
      ),
    );
  }
}