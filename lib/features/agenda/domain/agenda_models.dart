/// Modelos mínimos de dominio para la agenda PAD
library;

/// Fuente de paciente para agenda (adaptador desde CensoPaciente)
class AgendaPatientSource {
  final String id;
  final String nombre;
  final bool activo;
  final String pauta; // Ej: 'q12h', 'q24h'
  final DateTime? egreso;

  AgendaPatientSource({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.pauta,
    this.egreso,
  });
}

/// Evento de agenda generado (antes de persistir)
class AgendaEventDraft {
  final String pacienteId;
  final String pacienteNombre;
  final DateTime fechaHora;
  final String descripcion;

  AgendaEventDraft({
    required this.pacienteId,
    required this.pacienteNombre,
    required this.fechaHora,
    required this.descripcion,
  });
}

/// Representa un auxiliar y su turno para un día
class AuxiliarTurno {
  final String auxiliarId;
  final String nombre;
  final String turno; // 'M', 'T', 'R', 'J'

  AuxiliarTurno({
    required this.auxiliarId,
    required this.nombre,
    required this.turno,
  });
}

/// Resultado de asignación de evento a auxiliar
class AssignmentResult {
  final AgendaEventDraft evento;
  final AuxiliarTurno? auxiliarAsignado;
  final String? motivoAlerta;

  AssignmentResult({
    required this.evento,
    this.auxiliarAsignado,
    this.motivoAlerta,
  });
}

/// Alerta de cobertura (nadie cubre la hora)
class CoverageAlert {
  final AgendaEventDraft evento;
  final List<AuxiliarTurno> elegibles;
  final String motivo;

  CoverageAlert({
    required this.evento,
    required this.elegibles,
    required this.motivo,
  });
}
