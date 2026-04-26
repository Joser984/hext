import 'paciente_captacion_models.dart';

const String grupoRiesgoOtro = 'OTRO';
const String barrioOtro = 'Otro';

const List<ServicioQuePresenta> servicioQuePresentaOptions = <ServicioQuePresenta>[
  ServicioQuePresenta.urgencias,
  ServicioQuePresenta.hospitalizacionSanFernando,
  ServicioQuePresenta.hospitalizacionMariaAuxiliadora,
  ServicioQuePresenta.uci,
  ServicioQuePresenta.cirugia,
  ServicioQuePresenta.consultaExterna,
  ServicioQuePresenta.otro,
];

const List<OrigenPaciente> origenPacienteOptions = <OrigenPaciente>[
  OrigenPaciente.urgencias,
  OrigenPaciente.hospitalizacionSanFernando,
  OrigenPaciente.hospitalizacionMariaAuxiliadora,
  OrigenPaciente.uci,
  OrigenPaciente.cirugia,
  OrigenPaciente.consultaExterna,
  OrigenPaciente.otro,
];

const List<String> grupoRiesgoOptions = <String>[
  'ENF. INFECCIOSAS Y PARASITARIAS',
  'EMBARAZO, PARTO Y PUERPERIO',
  'ALCOHOL/DROGAS Y TRASTORNOS ORGANICOS MENTALES INDUCIDOS POR ALCOHOL/DROGAS',
  'ENF. O TRAST. MENTALES',
  'ENF. Y TRAST. DE LA PIEL, DEL TEJIDO SUBCUTANEO Y DE LA MAMA',
  'ENF. Y TRAST. DE LA SANGRE, DEL SISTEMA HEMATOPOYETICO Y DEL SISTEMA INMUNITARIO',
  'ENF. Y TRAST. DEL OIDO, NARIZ, BOCA Y GARGANTA',
  'ENF. Y TRAST. DEL OJO',
  'ENF. Y TRAST. DEL RINON Y VIAS URINARIAS',
  'ENF. Y TRAST. DEL SISTEMA CIRCULATORIO',
  'ENF. Y TRAST. DEL SISTEMA DIGESTIVO',
  'ENF. Y TRAST. DEL SISTEMA HEPATOBILIAR Y PANCREAS',
  'ENF. Y TRAST. DEL SISTEMA MUSCULOESQUELETICO Y TEJIDO CONECTIVO',
  'ENF. Y TRAST. DEL SISTEMA NERVIOSO',
  'ENF. Y TRAST. DEL SISTEMA REPRODUCTOR FEMENINO',
  'ENF. Y TRAST. DEL SISTEMA REPRODUCTOR MASCULINO',
  'ENF. Y TRAST. DEL SISTEMA RESPIRATORIO',
  'ENF. Y TRAST. ENDOCRINOS, NUTRICIONALES Y METABOLICOS',
  'ENF. Y TRAST. MIELOPROLIFERATIVOS Y NEOPLASIAS POCO DIFERENCIADAS',
  'FACTORES QUE INFLUYEN EN EL ESTADO DE SALUD Y OTROS CONTACTOS CON SERVICIOS DE SALUD',
  'HERIDAS, ENVENENAMIENTOS Y EFECTOS TOXICOS DE LAS DROGAS',
  'INFECCIONES POR EL VIH',
  'POLITRAUMATISMOS IMPORTANTES',
  'QUEMADURAS',
  'RECIEN NACIDOS Y CUADROS DEL PERIODO PERINATAL',
  grupoRiesgoOtro,
];

const List<String> causaReingresoOptions = <String>[
  'Comorbilidades descompensadas',
  'Factores sociales o de soporte no favorables',
  'Necesidad de escalamiento del nivel de atención por evolución clínica',
  'Progresión de la patología de base',
  'Requerimiento de atención intrahospitalaria',
  'Reacción adversa a medicamento',
  'No aval administrativo',
];
