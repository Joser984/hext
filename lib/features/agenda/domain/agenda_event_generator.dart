import 'agenda_models.dart';

/// Genera eventos de agenda a partir de pacientes activos y su pauta
List<AgendaEventDraft> generarEventosAgenda(List<AgendaPatientSource> pacientes) {
  final List<AgendaEventDraft> eventos = [];
  final now = DateTime.now();
  final hoy = DateTime(now.year, now.month, now.day);

  for (final paciente in pacientes) {
    if (!paciente.activo) continue;
    // Solo ejemplo: soporta q12h y q24h
    final frecuencias = _horasPorPauta(paciente.pauta);
    for (final hora in frecuencias) {
      final eventoHora = hoy.add(Duration(hours: hora));
      if (paciente.egreso != null && eventoHora.isAfter(paciente.egreso!)) continue;
      eventos.add(
        AgendaEventDraft(
          pacienteId: paciente.id,
          pacienteNombre: paciente.nombre,
          fechaHora: eventoHora,
          descripcion: 'Medicamento pautado',
        ),
      );
    }
  }
  return eventos;
}

/// Devuelve las horas del día para la pauta (ejemplo simple)
List<int> _horasPorPauta(String pauta) {
  switch (pauta) {
    case 'q12h':
      return [6, 18];
    case 'q24h':
      return [8];
    default:
      return [6, 18];
  }
}
