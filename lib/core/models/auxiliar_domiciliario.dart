class AuxiliarDomiciliario {
  final String id;
  final String nombreCompleto;
  final String cargo;
  final String modalidad;
  final DateTime? fechaIngreso;
  final bool activo;

  const AuxiliarDomiciliario({
    required this.id,
    required this.nombreCompleto,
    required this.cargo,
    required this.modalidad,
    this.fechaIngreso,
    required this.activo,
  });

  AuxiliarDomiciliario copyWith({
    String? id,
    String? nombreCompleto,
    String? cargo,
    String? modalidad,
    DateTime? fechaIngreso,
    bool? activo,
  }) {
    return AuxiliarDomiciliario(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      cargo: cargo ?? this.cargo,
      modalidad: modalidad ?? this.modalidad,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nombreCompleto': nombreCompleto,
      'cargo': cargo,
      'modalidad': modalidad,
      'fechaIngreso': fechaIngreso?.millisecondsSinceEpoch,
      'activo': activo,
    };
  }

  factory AuxiliarDomiciliario.fromMap(Map<String, dynamic> map) {
    return AuxiliarDomiciliario(
      id: map['id'] as String? ?? '',
      nombreCompleto: map['nombreCompleto'] as String? ?? '',
      cargo: map['cargo'] as String? ?? '',
      modalidad: map['modalidad'] as String? ?? '',
      fechaIngreso: map['fechaIngreso'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaIngreso'] as int)
          : null,
      activo: map['activo'] as bool? ?? true,
    );
  }
}
