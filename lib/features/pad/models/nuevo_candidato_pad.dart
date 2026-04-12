class NuevoCandidatoPad {
  final String nombre;
  final String documento;
  final List<String> motivos;
  final String? motivoIngresoPrincipal;
  final List<String> motivosIngresoActivos;
  final Map<String, dynamic> detalleMotivos;

  NuevoCandidatoPad({
    required this.nombre,
    required this.documento,
    required this.motivos,
    this.motivoIngresoPrincipal,
    List<String>? motivosIngresoActivos,
    Map<String, dynamic>? detalleMotivos,
  }) : motivosIngresoActivos = motivosIngresoActivos ?? <String>[],
       detalleMotivos = detalleMotivos ?? <String, dynamic>{};

  factory NuevoCandidatoPad.fromMap(Map<String, dynamic> map) {
    final List<String> legacyMotivos =
        (map['motivos'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic item) => item.toString())
            .toList();

    final String? principal =
        map['motivoIngresoPrincipal'] as String? ??
        (legacyMotivos.isNotEmpty ? legacyMotivos.first : null);

    final List<String> activos =
        (map['motivosIngresoActivos'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic item) => item.toString())
            .toList();

    return NuevoCandidatoPad(
      nombre: map['nombre'] as String? ?? '',
      documento: map['documento'] as String? ?? '',
      motivos: legacyMotivos,
      motivoIngresoPrincipal: principal,
      motivosIngresoActivos: activos.isEmpty && principal != null
          ? <String>[principal]
          : activos,
      detalleMotivos:
          map['detalleMotivos'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'documento': documento,
      'motivoIngresoPrincipal': motivoIngresoPrincipal,
      'motivosIngresoActivos': motivosIngresoActivos,
      'detalleMotivos': detalleMotivos,
      'motivos': motivos,
    };
  }
}
