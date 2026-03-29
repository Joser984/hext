import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/caso_paciente.dart'; // El archivo sigue llamándose caso_paciente.dart, pero la clase es CensoPaciente

class CensoPacienteRepo {
  CensoPacienteRepo({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _censoRef =>
      _firestore.collection('censoPacientes');

  Stream<List<CensoPaciente>> watchCenso({
    String? situacionAsistencialKey,
    String? especialidadKey,
    String? aseguradoraKey,
    bool? pendienteValoracion,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _censoRef;

    if (situacionAsistencialKey != null && situacionAsistencialKey.trim().isNotEmpty) {
      query = query.where(
        'situacionAsistencialKey',
        isEqualTo: situacionAsistencialKey.trim(),
      );
    }

    if (especialidadKey != null && especialidadKey.trim().isNotEmpty) {
      query = query.where(
        'especialidadKey',
        isEqualTo: especialidadKey.trim(),
      );
    }

    if (aseguradoraKey != null && aseguradoraKey.trim().isNotEmpty) {
      query = query.where(
        'aseguradoraKey',
        isEqualTo: aseguradoraKey.trim(),
      );
    }

    if (pendienteValoracion != null) {
      query = query.where(
        'pendienteValoracion',
        isEqualTo: pendienteValoracion,
      );
    }

    query = query.orderBy('updatedAt', descending: true).limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => CensoPaciente.fromFirestore(doc))
          .toList(),
    );
  }

  Stream<CensoPaciente?> watchCensoById(String censoId) {
    return _censoRef.doc(censoId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CensoPaciente.fromFirestore(doc);
    });
  }

  Future<CensoPaciente?> getCensoById(String censoId) async {
    final doc = await _censoRef.doc(censoId).get();
    if (!doc.exists) return null;
    return CensoPaciente.fromFirestore(doc);
  }

  Future<String> createCenso(CensoPaciente censo) async {
    final docRef = censo.id.trim().isEmpty ? _censoRef.doc() : _censoRef.doc(censo.id);

    final data = censo.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..putIfAbsent('pendienteValoracion', () => false);

    await docRef.set(data, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> updateCenso(CensoPaciente censo) async {
    if (censo.id.trim().isEmpty) {
      throw ArgumentError('El id del censo es obligatorio para actualizar.');
    }

    final data = censo.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _censoRef.doc(censo.id).set(data, SetOptions(merge: true));
  }

  Future<void> patchCenso(
    String censoId,
    Map<String, dynamic> patch,
  ) async {
    if (censoId.trim().isEmpty) {
      throw ArgumentError('El id del censo es obligatorio.');
    }

    final cleanPatch = Map<String, dynamic>.from(patch)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _censoRef.doc(censoId).set(cleanPatch, SetOptions(merge: true));
  }

  Future<void> setPendienteValoracion(
    String censoId, {
    required bool value,
  }) async {
    await _censoRef.doc(censoId).set(
      {
        'pendienteValoracion': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteCenso(String censoId) async {
    if (censoId.trim().isEmpty) {
      throw ArgumentError('El id del censo es obligatorio para eliminar.');
    }
    await _censoRef.doc(censoId).delete();
  }

  Stream<List<CensoPaciente>> watchCensoReciente({int limit = 10}) {
    return _censoRef
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CensoPaciente.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<CensoPaciente>> watchAltas({int limit = 50}) {
    return watchCenso(
      situacionAsistencialKey: 'alta',
      limit: limit,
    );
  }

  Stream<List<CensoPaciente>> watchPendientesValoracion({int limit = 50}) {
    return watchCenso(
      pendienteValoracion: true,
      limit: limit,
    );
  }

  Future<int> countBySituacion(String situacionAsistencialKey) async {
    final snapshot = await _censoRef
        .where('situacionAsistencialKey', isEqualTo: situacionAsistencialKey)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<int> countPendienteValoracion() async {
    final snapshot = await _censoRef
        .where('pendienteValoracion', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
