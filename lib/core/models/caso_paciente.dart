import 'package:cloud_firestore/cloud_firestore.dart';

class CensoPaciente {
  final String id;
  final String situacionAsistencialKey;
  final String situacionAsistencialLabel;
  final String? resultadoPadKey;
  final String? resultadoPadLabel;
  final DateTime? fechaIngreso;
  final DateTime? fechaEgreso;
  final int? diasEstancia;
  final String? unidadFuncionalOrigenKey;
  final String? unidadFuncionalOrigenLabel;
  final String identificacion;
  final String nombreCompleto;
  final int? edad;
  final String? sexoKey;
  final String? sexoLabel;
  final String? aseguradoraKey;
  final String? aseguradoraLabel;
  final String? direccion;
  final String? especialidadKey;
  final String? especialidadLabel;
  final String? diagnosticos;
  final String? resolucionAsistencialCaso;
  final String? grd;
  final String? causaReingreso;
  final DateTime? fechaSolicitudProcedimientoQx;
  final DateTime? fechaRealizacionProcedimientoQx;
  final String? observaciones;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool pendienteValoracion;

  const CensoPaciente({
    required this.id,
    required this.situacionAsistencialKey,
    required this.situacionAsistencialLabel,
    this.resultadoPadKey,
    this.resultadoPadLabel,
    this.fechaIngreso,
    this.fechaEgreso,
    this.diasEstancia,
    this.unidadFuncionalOrigenKey,
    this.unidadFuncionalOrigenLabel,
    required this.identificacion,
    required this.nombreCompleto,
    this.edad,
    this.sexoKey,
    this.sexoLabel,
    this.aseguradoraKey,
    this.aseguradoraLabel,
    this.direccion,
    this.especialidadKey,
    this.especialidadLabel,
    this.diagnosticos,
    this.resolucionAsistencialCaso,
    this.grd,
    this.causaReingreso,
    this.fechaSolicitudProcedimientoQx,
    this.fechaRealizacionProcedimientoQx,
    this.observaciones,
    this.createdAt,
    this.updatedAt,
    this.pendienteValoracion = false,
  });
  // ...existing code...

  int? get diasEstanciaCalculados {
    if (fechaIngreso == null) return null;
    final hasta = fechaEgreso ?? DateTime.now();
    final ingreso = DateTime(fechaIngreso!.year, fechaIngreso!.month, fechaIngreso!.day);
    final fin = DateTime(hasta.year, hasta.month, hasta.day);
    final diff = fin.difference(ingreso).inDays;
    if (diff < 0) return null;
    return diff;
  }

  CensoPaciente copyWith({
    String? id,
    String? situacionAsistencialKey,
    String? situacionAsistencialLabel,
    String? resultadoPadKey,
    String? resultadoPadLabel,
    DateTime? fechaIngreso,
    DateTime? fechaEgreso,
    int? diasEstancia,
    String? unidadFuncionalOrigenKey,
    String? unidadFuncionalOrigenLabel,
    String? identificacion,
    String? nombreCompleto,
    int? edad,
    String? sexoKey,
    String? sexoLabel,
    String? aseguradoraKey,
    String? aseguradoraLabel,
    String? direccion,
    String? especialidadKey,
    String? especialidadLabel,
    String? diagnosticos,
    String? resolucionAsistencialCaso,
    String? grd,
    String? causaReingreso,
    DateTime? fechaSolicitudProcedimientoQx,
    DateTime? fechaRealizacionProcedimientoQx,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendienteValoracion,
  }) {
    return CensoPaciente(
      id: id ?? this.id,
      situacionAsistencialKey: situacionAsistencialKey ?? this.situacionAsistencialKey,
      situacionAsistencialLabel: situacionAsistencialLabel ?? this.situacionAsistencialLabel,
      resultadoPadKey: resultadoPadKey ?? this.resultadoPadKey,
      resultadoPadLabel: resultadoPadLabel ?? this.resultadoPadLabel,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaEgreso: fechaEgreso ?? this.fechaEgreso,
      diasEstancia: diasEstancia ?? this.diasEstancia,
      unidadFuncionalOrigenKey: unidadFuncionalOrigenKey ?? this.unidadFuncionalOrigenKey,
      unidadFuncionalOrigenLabel: unidadFuncionalOrigenLabel ?? this.unidadFuncionalOrigenLabel,
      identificacion: identificacion ?? this.identificacion,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      edad: edad ?? this.edad,
      sexoKey: sexoKey ?? this.sexoKey,
      sexoLabel: sexoLabel ?? this.sexoLabel,
      aseguradoraKey: aseguradoraKey ?? this.aseguradoraKey,
      aseguradoraLabel: aseguradoraLabel ?? this.aseguradoraLabel,
      direccion: direccion ?? this.direccion,
      especialidadKey: especialidadKey ?? this.especialidadKey,
      especialidadLabel: especialidadLabel ?? this.especialidadLabel,
      diagnosticos: diagnosticos ?? this.diagnosticos,
      resolucionAsistencialCaso: resolucionAsistencialCaso ?? this.resolucionAsistencialCaso,
      grd: grd ?? this.grd,
      causaReingreso: causaReingreso ?? this.causaReingreso,
      fechaSolicitudProcedimientoQx: fechaSolicitudProcedimientoQx ?? this.fechaSolicitudProcedimientoQx,
      fechaRealizacionProcedimientoQx: fechaRealizacionProcedimientoQx ?? this.fechaRealizacionProcedimientoQx,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendienteValoracion: pendienteValoracion ?? this.pendienteValoracion,
    );
  }
  // ...existing code...

  factory CensoPaciente.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CensoPaciente.fromMap(data, doc.id);
  }

  factory CensoPaciente.fromMap(Map<String, dynamic> map, String id) {
    return CensoPaciente(
      id: id,
      situacionAsistencialKey: (map['situacionAsistencialKey'] as String?)?.trim() ?? '',
      situacionAsistencialLabel: (map['situacionAsistencialLabel'] as String?)?.trim() ?? '',
      resultadoPadKey: (map['resultadoPadKey'] as String?)?.trim(),
      resultadoPadLabel: (map['resultadoPadLabel'] as String?)?.trim(),
      fechaIngreso: _readDate(map['fechaIngreso']),
      fechaEgreso: _readDate(map['fechaEgreso']),
      diasEstancia: _readInt(map['diasEstancia']),
      unidadFuncionalOrigenKey: (map['unidadFuncionalOrigenKey'] as String?)?.trim(),
      unidadFuncionalOrigenLabel: (map['unidadFuncionalOrigenLabel'] as String?)?.trim(),
      identificacion: (map['identificacion'] as String?)?.trim() ?? '',
      nombreCompleto: (map['nombreCompleto'] as String?)?.trim() ?? '',
      edad: _readInt(map['edad']),
      sexoKey: (map['sexoKey'] as String?)?.trim(),
      sexoLabel: (map['sexoLabel'] as String?)?.trim(),
      aseguradoraKey: (map['aseguradoraKey'] as String?)?.trim(),
      aseguradoraLabel: (map['aseguradoraLabel'] as String?)?.trim(),
      direccion: (map['direccion'] as String?)?.trim(),
      especialidadKey: (map['especialidadKey'] as String?)?.trim(),
      especialidadLabel: (map['especialidadLabel'] as String?)?.trim(),
      diagnosticos: (map['diagnosticos'] as String?)?.trim(),
      resolucionAsistencialCaso: (map['resolucionAsistencialCaso'] as String?)?.trim(),
      grd: (map['grd'] as String?)?.trim(),
      causaReingreso: (map['causaReingreso'] as String?)?.trim(),
      fechaSolicitudProcedimientoQx: _readDate(map['fechaSolicitudProcedimientoQx']),
      fechaRealizacionProcedimientoQx: _readDate(map['fechaRealizacionProcedimientoQx']),
      observaciones: (map['observaciones'] as String?)?.trim(),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      pendienteValoracion: map['pendienteValoracion'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'situacionAsistencialKey': situacionAsistencialKey,
      'situacionAsistencialLabel': situacionAsistencialLabel,
      'resultadoPadKey': resultadoPadKey,
      'resultadoPadLabel': resultadoPadLabel,
      'fechaIngreso': _writeDate(fechaIngreso),
      'fechaEgreso': _writeDate(fechaEgreso),
      'diasEstancia': diasEstancia,
      'unidadFuncionalOrigenKey': unidadFuncionalOrigenKey,
      'unidadFuncionalOrigenLabel': unidadFuncionalOrigenLabel,
      'identificacion': identificacion,
      'nombreCompleto': nombreCompleto,
      'edad': edad,
      'sexoKey': sexoKey,
      'sexoLabel': sexoLabel,
      'aseguradoraKey': aseguradoraKey,
      'aseguradoraLabel': aseguradoraLabel,
      'direccion': direccion,
      'especialidadKey': especialidadKey,
      'especialidadLabel': especialidadLabel,
      'diagnosticos': diagnosticos,
      'resolucionAsistencialCaso': resolucionAsistencialCaso,
      'grd': grd,
      'causaReingreso': causaReingreso,
      'fechaSolicitudProcedimientoQx': _writeDate(fechaSolicitudProcedimientoQx),
      'fechaRealizacionProcedimientoQx': _writeDate(fechaRealizacionProcedimientoQx),
      'observaciones': observaciones,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
      'pendienteValoracion': pendienteValoracion,
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
