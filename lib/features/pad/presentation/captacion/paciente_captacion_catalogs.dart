import 'paciente_captacion_models.dart';

const String grupoRiesgoOtro = 'Otro';
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
  'Enf. infecciosas y parasitarias',
  'Embarazo, parto y puerperio',
  'Alcohol/drogas y trastornos organicos mentales inducidos por alcohol/drogas',
  'Enf. o trast. mentales',
  'Enf. y trast. de la piel, del tejido subcutaneo y de la mama',
  'Enf. y trast. de la sangre, del sistema hematopoyetico y del sistema inmunitario',
  'Enf. y trast. del oido, nariz, boca y garganta',
  'Enf. y trast. del ojo',
  'Enf. y trast. del rinon y vias urinarias',
  'Enf. y trast. del sistema circulatorio',
  'Enf. y trast. del sistema digestivo',
  'Enf. y trast. del sistema hepatobiliar y pancreas',
  'Enf. y trast. del sistema musculoesqueletico y tejido conectivo',
  'Enf. y trast. del sistema nervioso',
  'Enf. y trast. del sistema reproductor femenino',
  'Enf. y trast. del sistema reproductor masculino',
  'Enf. y trast. del sistema respiratorio',
  'Enf. y trast. endocrinos, nutricionales y metabolicos',
  'Enf. y trast. mieloproliferativos y neoplasias poco diferenciadas',
  'Factores que influyen en el estado de salud y otros contactos con servicios de salud',
  'Heridas, envenenamientos y efectos toxicos de las drogas',
  'Infecciones por el VIH',
  'Politraumatismos importantes',
  'Quemaduras',
  'Recien nacidos y cuadros del periodo perinatal',
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
