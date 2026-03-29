import 'package:cloud_firestore/cloud_firestore.dart';

class CandidatoPad {
  final String id;
  final String identificacion;
  final String nombreCompleto;
  final int? edad;
  final String? sexo;
  final String? aseguradora;
  final String? direccion;
  final String? especialidad;
  final String? diagnosticos;
  final DateTime? fechaPresentacionPad;
  final String estadoPad; // presentado_pad, pendiente_valoracion, aprobado_para_ingreso, ingresado, no_ingresa, no_aprobado
  final String? resultadoPad; // ingresado, no_ingresa, no_aprobado
  final String? observaciones;
  final String? motivoNoIngreso;
  final String? motivoNoAprobacion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CandidatoPad({
    required this.id,
    required this.identificacion,
    required this.nombreCompleto,
    this.edad,
    this.sexo,
    this.aseguradora,
    this.direccion,
    this.especialidad,
    this.diagnosticos,
    this.fechaPresentacionPad,
    required this.estadoPad,
    this.resultadoPad,
    this.observaciones,
    this.motivoNoIngreso,
    this.motivoNoAprobacion,
    this.createdAt,
    this.updatedAt,
  });

  factory CandidatoPad.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CandidatoPad.fromMap(data, doc.id);
  }

  factory CandidatoPad.fromMap(Map<String, dynamic> map, String id) {
    return CandidatoPad(
      id: id,
      identificacion: (map['identificacion'] as String?)?.trim() ?? '',
      nombreCompleto: (map['nombreCompleto'] as String?)?.trim() ?? '',
      edad: _readInt(map['edad']),
      sexo: (map['sexo'] as String?)?.trim(),
      aseguradora: (map['aseguradora'] as String?)?.trim(),
      direccion: (map['direccion'] as String?)?.trim(),
      especialidad: (map['especialidad'] as String?)?.trim(),
      diagnosticos: (map['diagnosticos'] as String?)?.trim(),
      fechaPresentacionPad: _readDate(map['fechaPresentacionPad']),
      estadoPad: (map['estadoPad'] as String?)?.trim() ?? 'presentado_pad',
      resultadoPad: (map['resultadoPad'] as String?)?.trim(),
      observaciones: (map['observaciones'] as String?)?.trim(),
      motivoNoIngreso: (map['motivoNoIngreso'] as String?)?.trim(),
      motivoNoAprobacion: (map['motivoNoAprobacion'] as String?)?.trim(),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identificacion': identificacion,
      'nombreCompleto': nombreCompleto,
      'edad': edad,
      'sexo': sexo,
      'aseguradora': aseguradora,
      'direccion': direccion,
      'especialidad': especialidad,
      'diagnosticos': diagnosticos,
      'fechaPresentacionPad': _writeDate(fechaPresentacionPad),
      'estadoPad': estadoPad,
      'resultadoPad': resultadoPad,
      'observaciones': observaciones,
      'motivoNoIngreso': motivoNoIngreso,
      'motivoNoAprobacion': motivoNoAprobacion,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      final iso = DateTime.tryParse(text);
      if (iso != null) return iso;
      final parts = text.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Timestamp? _writeDate(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }
}
