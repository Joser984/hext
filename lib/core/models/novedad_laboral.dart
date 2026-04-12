enum TipoNovedad {
  vacaciones,
  diaFamilia,
  compensatorioSufragio,
  juradoVotacion,
  incapacidad,
  permiso,
  licencia,
}

extension TipoNovedadX on TipoNovedad {
  String get label {
    switch (this) {
      case TipoNovedad.vacaciones:
        return 'Vacaciones';
      case TipoNovedad.diaFamilia:
        return 'Día de la familia';
      case TipoNovedad.compensatorioSufragio:
        return 'Comp. sufragio (½ día)';
      case TipoNovedad.juradoVotacion:
        return 'Jurado de votación';
      case TipoNovedad.incapacidad:
        return 'Incapacidad';
      case TipoNovedad.permiso:
        return 'Permiso';
      case TipoNovedad.licencia:
        return 'Licencia';
    }
  }

  /// Tipos que tienen un período de disfrute con fecha inicio y fin.
  bool get tienePeriodo {
    return this == TipoNovedad.vacaciones ||
        this == TipoNovedad.incapacidad ||
        this == TipoNovedad.permiso ||
        this == TipoNovedad.licencia;
  }

  /// Días límite legales desde la causación. null = no aplica límite automático.
  int? get diasLimiteDisfrute {
    switch (this) {
      case TipoNovedad.compensatorioSufragio:
        return 30; // Ley 403/1997: dentro del mes siguiente
      case TipoNovedad.juradoVotacion:
        return 45; // Ley 403/1997: dentro de los 45 días siguientes
      default:
        return null;
    }
  }
}

enum EstadoNovedad {
  pendiente,
  programado,
  disfrutado,
  vencido,
}

extension EstadoNovedadX on EstadoNovedad {
  String get label {
    switch (this) {
      case EstadoNovedad.pendiente:
        return 'Pendiente';
      case EstadoNovedad.programado:
        return 'Programado';
      case EstadoNovedad.disfrutado:
        return 'Disfrutado';
      case EstadoNovedad.vencido:
        return 'Vencido';
    }
  }
}

class NovedadLaboral {
  final String id;
  final String auxiliarId;
  final TipoNovedad tipo;
  final DateTime fechaCausacion;

  /// Fecha límite para disfrutar el beneficio (compensatorios y sufragio).
  final DateTime? fechaLimiteDisfrute;

  /// Inicio del período (vacaciones, incapacidad, permiso, licencia).
  final DateTime? fechaInicio;

  /// Fin del período.
  final DateTime? fechaFin;

  final EstadoNovedad estado;
  final String? observaciones;

  const NovedadLaboral({
    required this.id,
    required this.auxiliarId,
    required this.tipo,
    required this.fechaCausacion,
    this.fechaLimiteDisfrute,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
    this.observaciones,
  });

  NovedadLaboral copyWith({
    String? id,
    String? auxiliarId,
    TipoNovedad? tipo,
    DateTime? fechaCausacion,
    DateTime? fechaLimiteDisfrute,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    EstadoNovedad? estado,
    String? observaciones,
  }) {
    return NovedadLaboral(
      id: id ?? this.id,
      auxiliarId: auxiliarId ?? this.auxiliarId,
      tipo: tipo ?? this.tipo,
      fechaCausacion: fechaCausacion ?? this.fechaCausacion,
      fechaLimiteDisfrute: fechaLimiteDisfrute ?? this.fechaLimiteDisfrute,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
