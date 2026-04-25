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
  final String? barrio;

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

  // Campos agregados para cierre / egreso
  final String? motivoPrincipal;
  final String? motivoPrincipalLabel;
  final List<String>? motivosActivos;
  final List<String>? motivos;
  final String? detalleClinicoResumido;
  final String? resumenClinico;
  final String? detalleClinico;
  final String? resolucionPad;
  final String? estadoCaso;
  final String? tipoEgreso;
  final String? observacionEgreso;
  final DateTime? fechaEgresoTs;
  final String? actualizadoPor;
  final DateTime? actualizadoEn;
  final String? destinoTraslado;

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
    this.barrio,
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
    this.motivoPrincipal,
    this.motivoPrincipalLabel,
    this.motivosActivos,
    this.motivos,
    this.detalleClinicoResumido,
    this.resumenClinico,
    this.detalleClinico,
    this.resolucionPad,
    this.estadoCaso,
    this.tipoEgreso,
    this.observacionEgreso,
    this.fechaEgresoTs,
    this.actualizadoPor,
    this.actualizadoEn,
    this.destinoTraslado,
  });

  int? get diasEstanciaCalculados {
    if (fechaIngreso == null) return null;
    final DateTime hasta = fechaEgreso ?? DateTime.now();
    final DateTime ingreso = DateTime(
      fechaIngreso!.year,
      fechaIngreso!.month,
      fechaIngreso!.day,
    );
    final DateTime fin = DateTime(hasta.year, hasta.month, hasta.day);
    final int diff = fin.difference(ingreso).inDays;
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
    String? barrio,
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
    String? motivoPrincipal,
    String? motivoPrincipalLabel,
    List<String>? motivosActivos,
    List<String>? motivos,
    String? detalleClinicoResumido,
    String? resumenClinico,
    String? detalleClinico,
    String? resolucionPad,
    String? estadoCaso,
    String? tipoEgreso,
    String? observacionEgreso,
    DateTime? fechaEgresoTs,
    String? actualizadoPor,
    DateTime? actualizadoEn,
    String? destinoTraslado,
  }) {
    return CensoPaciente(
      id: id ?? this.id,
      situacionAsistencialKey:
          situacionAsistencialKey ?? this.situacionAsistencialKey,
      situacionAsistencialLabel:
          situacionAsistencialLabel ?? this.situacionAsistencialLabel,
      resultadoPadKey: resultadoPadKey ?? this.resultadoPadKey,
      resultadoPadLabel: resultadoPadLabel ?? this.resultadoPadLabel,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaEgreso: fechaEgreso ?? this.fechaEgreso,
      diasEstancia: diasEstancia ?? this.diasEstancia,
      unidadFuncionalOrigenKey:
          unidadFuncionalOrigenKey ?? this.unidadFuncionalOrigenKey,
      unidadFuncionalOrigenLabel:
          unidadFuncionalOrigenLabel ?? this.unidadFuncionalOrigenLabel,
      identificacion: identificacion ?? this.identificacion,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      edad: edad ?? this.edad,
      sexoKey: sexoKey ?? this.sexoKey,
      sexoLabel: sexoLabel ?? this.sexoLabel,
      aseguradoraKey: aseguradoraKey ?? this.aseguradoraKey,
      aseguradoraLabel: aseguradoraLabel ?? this.aseguradoraLabel,
      direccion: direccion ?? this.direccion,
      barrio: barrio ?? this.barrio,
      especialidadKey: especialidadKey ?? this.especialidadKey,
      especialidadLabel: especialidadLabel ?? this.especialidadLabel,
      diagnosticos: diagnosticos ?? this.diagnosticos,
      resolucionAsistencialCaso:
          resolucionAsistencialCaso ?? this.resolucionAsistencialCaso,
      grd: grd ?? this.grd,
      causaReingreso: causaReingreso ?? this.causaReingreso,
      fechaSolicitudProcedimientoQx:
          fechaSolicitudProcedimientoQx ??
          this.fechaSolicitudProcedimientoQx,
      fechaRealizacionProcedimientoQx:
          fechaRealizacionProcedimientoQx ??
          this.fechaRealizacionProcedimientoQx,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendienteValoracion: pendienteValoracion ?? this.pendienteValoracion,
      motivoPrincipal: motivoPrincipal ?? this.motivoPrincipal,
      motivoPrincipalLabel: motivoPrincipalLabel ?? this.motivoPrincipalLabel,
      motivosActivos: motivosActivos ?? this.motivosActivos,
      motivos: motivos ?? this.motivos,
      detalleClinicoResumido:
          detalleClinicoResumido ?? this.detalleClinicoResumido,
      resumenClinico: resumenClinico ?? this.resumenClinico,
      detalleClinico: detalleClinico ?? this.detalleClinico,
      resolucionPad: resolucionPad ?? this.resolucionPad,
      estadoCaso: estadoCaso ?? this.estadoCaso,
      tipoEgreso: tipoEgreso ?? this.tipoEgreso,
      observacionEgreso: observacionEgreso ?? this.observacionEgreso,
      fechaEgresoTs: fechaEgresoTs ?? this.fechaEgresoTs,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      destinoTraslado: destinoTraslado ?? this.destinoTraslado,
    );
  }

  factory CensoPaciente.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return CensoPaciente.fromMap(data, doc.id);
  }

  factory CensoPaciente.fromMap(Map<String, dynamic> map, String id) {
    return CensoPaciente(
      id: id,
      situacionAsistencialKey:
          (map['situacionAsistencialKey'] as String?)?.trim() ?? '',
      situacionAsistencialLabel:
          (map['situacionAsistencialLabel'] as String?)?.trim() ?? '',
      resultadoPadKey: (map['resultadoPadKey'] as String?)?.trim(),
      resultadoPadLabel: (map['resultadoPadLabel'] as String?)?.trim(),
      fechaIngreso: _readDate(map['fechaIngreso']),
      fechaEgreso: _readDate(map['fechaEgreso']),
      diasEstancia: _readInt(map['diasEstancia']),
      unidadFuncionalOrigenKey:
          (map['unidadFuncionalOrigenKey'] as String?)?.trim(),
      unidadFuncionalOrigenLabel:
          (map['unidadFuncionalOrigenLabel'] as String?)?.trim(),
      identificacion: (map['identificacion'] as String?)?.trim() ?? '',
      nombreCompleto: (map['nombreCompleto'] as String?)?.trim() ?? '',
      edad: _readInt(map['edad']),
      sexoKey: (map['sexoKey'] as String?)?.trim(),
      sexoLabel: (map['sexoLabel'] as String?)?.trim(),
      aseguradoraKey: (map['aseguradoraKey'] as String?)?.trim(),
      aseguradoraLabel: (map['aseguradoraLabel'] as String?)?.trim(),
      direccion: (map['direccion'] as String?)?.trim(),
      barrio: (map['barrio'] as String?)?.trim(),
      especialidadKey: (map['especialidadKey'] as String?)?.trim(),
      especialidadLabel: (map['especialidadLabel'] as String?)?.trim(),
      diagnosticos: (map['diagnosticos'] as String?)?.trim(),
      resolucionAsistencialCaso:
          (map['resolucionAsistencialCaso'] as String?)?.trim(),
      grd: (map['grd'] as String?)?.trim(),
      causaReingreso: (map['causaReingreso'] as String?)?.trim(),
      fechaSolicitudProcedimientoQx:
          _readDate(map['fechaSolicitudProcedimientoQx']),
      fechaRealizacionProcedimientoQx:
          _readDate(map['fechaRealizacionProcedimientoQx']),
      observaciones: (map['observaciones'] as String?)?.trim(),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      pendienteValoracion: map['pendienteValoracion'] == true,

      // Campos agregados
      motivoPrincipal: (map['motivoPrincipal'] as String?)?.trim(),
      motivoPrincipalLabel: (map['motivoPrincipalLabel'] as String?)?.trim(),
      motivosActivos: _readStringList(map['motivosActivos']),
      motivos: _readStringList(map['motivos']),
      detalleClinicoResumido:
          (map['detalleClinicoResumido'] as String?)?.trim(),
      resumenClinico: (map['resumenClinico'] as String?)?.trim(),
      detalleClinico: (map['detalleClinico'] as String?)?.trim(),
      resolucionPad: (map['resolucionPad'] as String?)?.trim(),
      estadoCaso: (map['estadoCaso'] as String?)?.trim(),
      tipoEgreso: (map['tipoEgreso'] as String?)?.trim(),
      observacionEgreso:
          (map['observacionEgreso'] as String?)?.trim() ??
          (map['observacionCierre'] as String?)?.trim(),
      fechaEgresoTs: _readDate(map['fechaEgresoTs']),
      actualizadoPor: (map['actualizadoPor'] as String?)?.trim(),
      actualizadoEn:
          _readDate(map['actualizadoEn']) ?? _readDate(map['updatedAt']),
      destinoTraslado: (map['destinoTraslado'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
      'barrio': barrio,
      'especialidadKey': especialidadKey,
      'especialidadLabel': especialidadLabel,
      'diagnosticos': diagnosticos,
      'resolucionAsistencialCaso': resolucionAsistencialCaso,
      'grd': grd,
      'causaReingreso': causaReingreso,
      'fechaSolicitudProcedimientoQx':
          _writeDate(fechaSolicitudProcedimientoQx),
      'fechaRealizacionProcedimientoQx':
          _writeDate(fechaRealizacionProcedimientoQx),
      'observaciones': observaciones,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
      'pendienteValoracion': pendienteValoracion,

      // Campos agregados
      'motivoPrincipal': motivoPrincipal,
      'motivoPrincipalLabel': motivoPrincipalLabel,
      'motivosActivos': motivosActivos,
      'motivos': motivos,
      'detalleClinicoResumido': detalleClinicoResumido,
      'resumenClinico': resumenClinico,
      'detalleClinico': detalleClinico,
      'resolucionPad': resolucionPad,
      'estadoCaso': estadoCaso,
      'tipoEgreso': tipoEgreso,
      'observacionEgreso': observacionEgreso,
      'fechaEgresoTs': _writeDate(fechaEgresoTs),
      'actualizadoPor': actualizadoPor,
      'actualizadoEn': _writeDate(actualizadoEn),
      'destinoTraslado': destinoTraslado,
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final String text = value.trim();
      if (text.isEmpty) return null;

      final DateTime? iso = DateTime.tryParse(text);
      if (iso != null) return iso;

      final List<String> parts = text.split('/');
      if (parts.length == 3) {
        final int? day = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        final int? year = int.tryParse(parts[2]);
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

  static List<String>? _readStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final List<String> items = value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      return items.isEmpty ? null : items;
    }
    return null;
  }

  static Timestamp? _writeDate(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }
}