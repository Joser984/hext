import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/solicitud_pad.dart' as model;

class CandidatoPadRepo {
  final _collection = FirebaseFirestore.instance.collection('candidatosPad');

  Future<List<model.CandidatoPad>> getAll() async {
    final query = await _collection.orderBy('createdAt', descending: true).get();
    return query.docs.map((doc) => model.CandidatoPad.fromFirestore(doc)).toList();
  }

  Future<model.CandidatoPad?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return model.CandidatoPad.fromFirestore(doc);
  }

  Future<void> add(model.CandidatoPad candidato) async {
    final data = candidato.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.add(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
