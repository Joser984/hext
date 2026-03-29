
class NuevoCandidatoPad {
  final String nombre;
  final String documento;
  final List<String> motivos;
  // Agrega aquí los demás campos necesarios

  NuevoCandidatoPad({
    required this.nombre,
    required this.documento,
    required this.motivos,
    // Otros campos
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'documento': documento,
      'motivos': motivos,
      // Otros campos
    };
  }
}
