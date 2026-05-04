import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/shared/widgets/hext_loading_screen.dart';

class CandidatosScreen extends StatelessWidget {
  const CandidatosScreen({super.key});

  String _reasonLabelFromKey(String? key) {
    if (key == null || key.trim().isEmpty) return '-';
    for (final PadAdmissionReasonOption option in PadAdmissionReasonLabels.all) {
      if (option.key == key || option.label == key) {
        return option.label;
      }
    }
    return key;
  }

  List<String> _activeReasonLabels(Map<String, dynamic> data) {
    final List<String> fromNew =
        (data['motivosIngresoActivos'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic item) => _reasonLabelFromKey(item.toString()))
            .where((String item) => item.trim().isNotEmpty)
            .toList();
    if (fromNew.isNotEmpty) return fromNew;

    final List<String> fromLegacy =
        (data['motivos'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic item) => _reasonLabelFromKey(item.toString()))
            .where((String item) => item.trim().isNotEmpty)
            .toList();
    return fromLegacy;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.go('/pad/nuevo'),
                icon: const Icon(Icons.add),
                label: const Text(PadUiLabels.newCase),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('candidatosPad')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const HextLoadingScreen(
                    title: 'Cargando candidatos',
                    subtitle: 'Consultando casos PAD',
                    compact: true,
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudieron cargar los casos.'),
                  );
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                    snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                if (docs.isEmpty) {
                  return const Center(child: Text(PadUiLabels.noCases));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final QueryDocumentSnapshot<Map<String, dynamic>> doc =
                        docs[index];
                    final Map<String, dynamic> data = doc.data();
                    final String nombre =
                        (data['nombreCompleto'] as String?)?.trim().isNotEmpty ==
                            true
                        ? (data['nombreCompleto'] as String)
                        : 'Sin nombre';
                    final String identificacion =
                        (data['identificacion'] as String?) ?? '-';
                    final List<String> activos = _activeReasonLabels(data);
                    final String principal = _reasonLabelFromKey(
                      (data['motivoIngresoPrincipal'] as String?) ??
                          (activos.isNotEmpty ? activos.first : null),
                    );
                    final List<String> secundarios = activos
                        .where((String item) => item != principal)
                        .toList();

                    return Card(
                      child: ListTile(
                        title: Text(nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Identificación: $identificacion'),
                            Text('Principal: $principal'),
                            if (secundarios.isNotEmpty)
                              Text('Activos: ${secundarios.join(' · ')}'),
                          ],
                        ),
                        isThreeLine: secundarios.isNotEmpty,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/pad/editar/${doc.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
