// Servicio para guardar candidato PAD en Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class PadFirestoreService {
  static Future<void> guardarCandidato(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('candidatosPad').add(data);
  }
}
