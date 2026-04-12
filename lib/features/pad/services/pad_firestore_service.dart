// Servicio para guardar caso PAD en Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class PadFirestoreService {
  static Future<void> guardarCandidato(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('candidatosPad').add(
      <String, dynamic>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Future<void> actualizarCandidato(
    String id,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance.collection('candidatosPad').doc(id).set(
      <String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<Map<String, dynamic>?> obtenerCandidato(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('candidatosPad')
            .doc(id)
            .get();

    return snapshot.data();
  }
}
