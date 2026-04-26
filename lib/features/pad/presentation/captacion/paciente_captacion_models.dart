// Modelos y enums base para la captación PAD

enum SexoPaciente { femenino, masculino, otro }

enum TipoAseguramiento { eps, medicinaPrepagada, poliza, particular, otro }

enum RegimenAseguramiento {
  contributivo,
  subsidiado,
  especial,
  particular,
  noAplica,
}

enum TipoCaptacionPad { busquedaActivaPad, presentadoPorServicio }

enum ServicioQuePresenta {
  urgencias,
  hospitalizacionSanFernando,
  hospitalizacionMariaAuxiliadora,
  hospitalizacion,
  uci,
  cirugia,
  consultaExterna,
  otro,
}

enum OrigenPaciente {
  urgencias,
  hospitalizacionSanFernando,
  hospitalizacionMariaAuxiliadora,
  hospitalizacion,
  uci,
  cirugia,
  consultaExterna,
  otro,
}

enum EspecialidadPrincipalTratante {
  cardiologia,
  cirugiaGeneral,
  cirugiaVascular,
  cuidadosPaliativos,
  dermatologia,
  endocrinologia,
  gastroenterologia,
  geriatria,
  ginecologia,
  hematologia,
  infectologia,
  medicinaDelDolor,
  medicinaFamiliar,
  medicinaFisicaRehabilitacion,
  medicinaInterna,
  nefrologia,
  neurologia,
  neumologia,
  nutricionClinica,
  oftalmologia,
  oncologia,
  ortopediaTraumatologia,
  otorrinolaringologia,
  otra,
  pediatria,
  psiquiatria,
  reumatologia,
  urologia,
}

enum DecisionPad {
  ingresoAprobado,
  ingresoNoAprobado,
  pendienteValoracion,
  requiereNuevaValoracion,
}

enum MotivoDetalleEstado { enCurso, finalizado }

enum ProcedimientoEstado { pendiente, realizado }

class PacienteCaptacion {
  final String nombreCompleto;
  final String identificacion;
  final SexoPaciente sexo;
  final int edad;

  final TipoAseguramiento? tipoAseguramiento;
  final String aseguradora;
  final RegimenAseguramiento? regimenAseguramiento;

  final TipoCaptacionPad tipoCaptacionPad;
  final ServicioQuePresenta? servicioQuePresenta;

  final OrigenPaciente? origenPaciente;
  final EspecialidadPrincipalTratante? especialidadPrincipalTratante;
  final String diagnostico;
  final String grupoRelacionadoRiesgo;
  final Set<String> motivos;
  final String? motivoIngresoPrincipal;
  final List<String> motivosIngresoActivos;
  final Map<String, dynamic> detalleMotivos;

  final String unidadFuncionalOrigen;
  final DecisionPad? decision;
  final String observaciones;

  const PacienteCaptacion({
    required this.nombreCompleto,
    required this.identificacion,
    required this.sexo,
    required this.edad,
    required this.tipoAseguramiento,
    required this.aseguradora,
    required this.regimenAseguramiento,
    required this.tipoCaptacionPad,
    required this.servicioQuePresenta,
    required this.origenPaciente,
    required this.especialidadPrincipalTratante,
    required this.diagnostico,
    required this.grupoRelacionadoRiesgo,
    required this.motivos,
    required this.motivoIngresoPrincipal,
    required this.motivosIngresoActivos,
    required this.detalleMotivos,
    required this.unidadFuncionalOrigen,
    required this.decision,
    required this.observaciones,
  });
}
