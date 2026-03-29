import 'package:cloud_firestore/cloud_firestore.dart';

class ResumenTablero {
  final int totalPacientesActuales;
  final int totalAltas;
  final int totalPendienteValoracion;
  final DateTime? updatedAt;

  const ResumenTablero({
    required this.totalPacientesActuales,
    required this.totalAltas,
    required this.totalPendienteValoracion,
    this.updatedAt,
  });

  factory ResumenTablero.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ResumenTablero.fromMap(data);
  }

  factory ResumenTablero.fromMap(Map<String, dynamic> map) {
    return ResumenTablero(
      totalPacientesActuales: _readInt(map['totalPacientesActuales']) ?? 0,
      totalAltas: _readInt(map['totalAltas']) ?? 0,
      totalPendienteValoracion: _readInt(map['totalPendienteValoracion']) ?? 0,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPacientesActuales': totalPacientesActuales,
      'totalAltas': totalAltas,
      'totalPendienteValoracion': totalPendienteValoracion,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
