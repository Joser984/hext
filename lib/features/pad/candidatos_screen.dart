import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CandidatosScreen extends StatelessWidget {
  const CandidatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      return SafeArea(
        top: false,
        child: Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/pad/nuevo'),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo candidato'),
          ),
        ),
      );
  }
  }
}