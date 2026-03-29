import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nuevo_candidato_pad.dart';

class NuevoCandidatoPadService {
  final FirebaseFirestore _firestore;
  NuevoCandidatoPadService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> guardarNuevoCandidato(NuevoCandidatoPad candidato) async {
    await _firestore.collection('candidatosPad').add({
      ...candidato.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
