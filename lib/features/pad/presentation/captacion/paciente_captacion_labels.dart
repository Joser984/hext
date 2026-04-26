import 'paciente_captacion_models.dart';

String sexoPacienteLabel(SexoPaciente value) {
  switch (value) {
    case SexoPaciente.femenino:
      return 'Femenino';
    case SexoPaciente.masculino:
      return 'Masculino';
    case SexoPaciente.otro:
      return 'Otro';
  }
}

String tipoAseguramientoLabel(TipoAseguramiento value) {
  switch (value) {
    case TipoAseguramiento.eps:
      return 'EPS';
    case TipoAseguramiento.medicinaPrepagada:
      return 'Medicina prepagada';
    case TipoAseguramiento.poliza:
      return 'Póliza';
    case TipoAseguramiento.particular:
      return 'Particular';
    case TipoAseguramiento.otro:
      return 'Otro';
  }
}

String regimenAseguramientoLabel(RegimenAseguramiento value) {
  switch (value) {
    case RegimenAseguramiento.contributivo:
      return 'Contributivo';
    case RegimenAseguramiento.subsidiado:
      return 'Subsidiado';
    case RegimenAseguramiento.especial:
      return 'Especial';
    case RegimenAseguramiento.particular:
      return 'Particular';
    case RegimenAseguramiento.noAplica:
      return 'No aplica';
  }
}

String tipoCaptacionPadLabel(TipoCaptacionPad value) {
  switch (value) {
    case TipoCaptacionPad.busquedaActivaPad:
      return 'Búsqueda activa PAD';
    case TipoCaptacionPad.presentadoPorServicio:
      return 'Presentado por servicio';
  }
}

String servicioQuePresentaLabel(ServicioQuePresenta value) {
  switch (value) {
    case ServicioQuePresenta.urgencias:
      return 'Urgencias';
    case ServicioQuePresenta.hospitalizacionSanFernando:
      return 'Hospitalización San Fernando';
    case ServicioQuePresenta.hospitalizacionMariaAuxiliadora:
      return 'Hospitalización María Auxiliadora';
    case ServicioQuePresenta.hospitalizacion:
      return 'Hospitalización';
    case ServicioQuePresenta.uci:
      return 'UCI';
    case ServicioQuePresenta.cirugia:
      return 'Cirugía';
    case ServicioQuePresenta.consultaExterna:
      return 'Consulta externa';
    case ServicioQuePresenta.otro:
      return 'Otro';
  }
}

String origenPacienteLabel(OrigenPaciente value) {
  switch (value) {
    case OrigenPaciente.urgencias:
      return 'Urgencias';
    case OrigenPaciente.hospitalizacionSanFernando:
      return 'Hospitalización San Fernando';
    case OrigenPaciente.hospitalizacionMariaAuxiliadora:
      return 'Hospitalización María Auxiliadora';
    case OrigenPaciente.hospitalizacion:
      return 'Hospitalización';
    case OrigenPaciente.uci:
      return 'UCI';
    case OrigenPaciente.cirugia:
      return 'Cirugía';
    case OrigenPaciente.consultaExterna:
      return 'Consulta externa';
    case OrigenPaciente.otro:
      return 'Otro';
  }
}

String especialidadPrincipalTratanteLabel(
  EspecialidadPrincipalTratante value,
) {
  switch (value) {
    case EspecialidadPrincipalTratante.cardiologia:
      return 'Cardiología';
    case EspecialidadPrincipalTratante.cirugiaGeneral:
      return 'Cirugía general';
    case EspecialidadPrincipalTratante.cirugiaVascular:
      return 'Cirugía vascular';
    case EspecialidadPrincipalTratante.cuidadosPaliativos:
      return 'Cuidados paliativos';
    case EspecialidadPrincipalTratante.dermatologia:
      return 'Dermatología';
    case EspecialidadPrincipalTratante.endocrinologia:
      return 'Endocrinología';
    case EspecialidadPrincipalTratante.gastroenterologia:
      return 'Gastroenterología';
    case EspecialidadPrincipalTratante.geriatria:
      return 'Geriatría';
    case EspecialidadPrincipalTratante.ginecologia:
      return 'Ginecología';
    case EspecialidadPrincipalTratante.hematologia:
      return 'Hematología';
    case EspecialidadPrincipalTratante.infectologia:
      return 'Infectología';
    case EspecialidadPrincipalTratante.medicinaDelDolor:
      return 'Medicina del dolor';
    case EspecialidadPrincipalTratante.medicinaFamiliar:
      return 'Medicina familiar';
    case EspecialidadPrincipalTratante.medicinaFisicaRehabilitacion:
      return 'Medicina física y rehabilitación';
    case EspecialidadPrincipalTratante.medicinaInterna:
      return 'Medicina interna';
    case EspecialidadPrincipalTratante.nefrologia:
      return 'Nefrología';
    case EspecialidadPrincipalTratante.neurologia:
      return 'Neurología';
    case EspecialidadPrincipalTratante.neumologia:
      return 'Neumología';
    case EspecialidadPrincipalTratante.nutricionClinica:
      return 'Nutrición clínica';
    case EspecialidadPrincipalTratante.oftalmologia:
      return 'Oftalmología';
    case EspecialidadPrincipalTratante.oncologia:
      return 'Oncología';
    case EspecialidadPrincipalTratante.ortopediaTraumatologia:
      return 'Ortopedia y traumatología';
    case EspecialidadPrincipalTratante.otorrinolaringologia:
      return 'Otorrinolaringología';
    case EspecialidadPrincipalTratante.otra:
      return 'Otra';
    case EspecialidadPrincipalTratante.pediatria:
      return 'Pediatría';
    case EspecialidadPrincipalTratante.psiquiatria:
      return 'Psiquiatría';
    case EspecialidadPrincipalTratante.reumatologia:
      return 'Reumatología';
    case EspecialidadPrincipalTratante.urologia:
      return 'Urología';
  }
}

String decisionPadLabel(DecisionPad value) {
  switch (value) {
    case DecisionPad.ingresoAprobado:
      return 'Ingreso aprobado';
    case DecisionPad.ingresoNoAprobado:
      return 'Ingreso no aprobado';
    case DecisionPad.pendienteValoracion:
      return 'Pendiente valoración';
    case DecisionPad.requiereNuevaValoracion:
      return 'Requiere nueva valoración';
  }
}
