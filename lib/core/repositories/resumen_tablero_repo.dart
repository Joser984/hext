import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resumen_tablero.dart';


class ResumenTableroRepo {
  ResumenTableroRepo({
    FirebaseFirestore? firestore,
        })  : _firestore = firestore ?? FirebaseFirestore.instance {
          // _censoRepo is removed to resolve unused field warning
        }

  final FirebaseFirestore _firestore;
        // final CensoPacienteRepo? _censoRepo; // Removed unused field

  DocumentReference<Map<String, dynamic>> get _resumenRef =>
      _firestore.collection('dashboard').doc('resumenTablero');

  Stream<ResumenTablero> watchResumenTablero() {
    return _resumenRef.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return const ResumenTablero(
          totalPacientesActuales: 0,
          totalAltas: 0,
          totalPendienteValoracion: 0,
        );
      }
      return ResumenTablero.fromFirestore(doc);
    });
  }

  Future<ResumenTablero> getResumenTablero() async {
    final doc = await _resumenRef.get();

    if (!doc.exists || doc.data() == null) {
      return const ResumenTablero(
        totalPacientesActuales: 0,
        totalAltas: 0,
        totalPendienteValoracion: 0,
      );
    }

    return ResumenTablero.fromFirestore(doc);
  }

  Future<void> saveResumenTablero(ResumenTablero resumen) async {
    final data = resumen.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _resumenRef.set(data, SetOptions(merge: true));
  }

  /// Recalcula el documento dashboard/resumenTablero
  /// desde la colección casosPacientes.
  ///
  /// Regla propuesta:
  /// - totalPacientesActuales = total documentos
  /// - totalAltas = situacionAsistencialKey == 'alta'
  /// - totalPendienteValoracion = pendienteValoracion == true
  ///
  /// Si más adelante decides excluir históricos o egresados,
  /// aquí es donde se cambia la lógica.
  Future<void> recomputeResumenTablero() async {
    final casosSnapshot = await _firestore.collection('casosPacientes').get();

    int totalPacientesActuales = 0;
    int totalAltas = 0;
    int totalPendienteValoracion = 0;

    for (final doc in casosSnapshot.docs) {
      final data = doc.data();

      totalPacientesActuales++;

      final situacion = (data['situacionAsistencialKey'] as String?)?.trim();
      final pendiente = data['pendienteValoracion'] == true;

      if (situacion == 'alta') {
        totalAltas++;
      }

      if (pendiente) {
        totalPendienteValoracion++;
      }
    }

    await _resumenRef.set(
      {
        'totalPacientesActuales': totalPacientesActuales,
        'totalAltas': totalAltas,
        'totalPendienteValoracion': totalPendienteValoracion,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
