/// Contrato de claves y labels para motivos PAD.
class PadMotivoKeys {
  static const finalizarTratamiento = 'finalizar_tratamiento';
  static const clinicaHeridas = 'clinica_heridas';
  static const programacionProcedimiento = 'programacion_procedimiento';
}

String padMotivoLabel(String key) {
  switch (key) {
    case PadMotivoKeys.finalizarTratamiento:
      return 'Finalizar tratamiento';
    case PadMotivoKeys.clinicaHeridas:
      return 'Clínica de heridas';
    case PadMotivoKeys.programacionProcedimiento:
      return 'Programación de procedimiento';
    default:
      return key;
  }
}

/// Helper para leer detalleMotivos de un motivo dado.
Map<String, dynamic> getDetalleMotivo(
  Map<String, dynamic>? detalleMotivos,
  String motivoKey,
) {
  if (detalleMotivos == null) return <String, dynamic>{};
  final value = detalleMotivos[motivoKey];
  if (value is Map<String, dynamic>) return value;
  return <String, dynamic>{};
}
