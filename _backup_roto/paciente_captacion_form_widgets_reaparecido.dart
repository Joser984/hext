import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/models/app_user.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:hext/features/pad/catalogs/aseguradoras_catalog.dart';
import 'package:hext/features/pad/summary/pad_summary_compact.dart';
import 'package:hext/features/pad/summary/pad_summary_domain_adapter.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_vm.dart';
import 'package:hext/features/pad/services/pad_firestore_service.dart';
import 'package:hext/features/pad/catalogs/barrios_catalog_service.dart';
import 'package:provider/provider.dart';

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

class PacienteCaptacionForm extends StatefulWidget {
  const PacienteCaptacionForm({super.key, this.candidatoId, this.initialData});

  final String? candidatoId;
  final Map<String, dynamic>? initialData;

  @override
  State<PacienteCaptacionForm> createState() => _PacienteCaptacionFormState();
}

class _PacienteCaptacionFormState extends State<PacienteCaptacionForm> {
    // --- Helpers aseguradora ---
    List<dynamic> get _aseguradoraOpciones {
      final String? tipoCatalogo = _catalogTipoFromAseguramiento(_tipoAseguramiento);
      return aseguradorasPorTipo(tipoCatalogo);
    }

    void _syncAseguradoraFromStoredValue() {
      final String rawValue = _aseguradoraController.text.trim();
      if (rawValue.isEmpty) {
        _aseguradoraCatalogKey = null;
        return;
      }
      final List<dynamic> options = _aseguradoraOpciones;
      for (final dynamic option in options) {
        final String value = option.value as String;
        final String label = option.label as String;
        if (rawValue == value || rawValue.toLowerCase() == label.toLowerCase()) {
          _aseguradoraCatalogKey = value;
          _aseguradoraController.text = label;
          return;
        }
      }
      _aseguradoraCatalogKey = null;
    }

    void _onTipoAseguramientoChanged(TipoAseguramiento? value) {
      _tipoAseguramiento = value;
      if (value == TipoAseguramiento.particular) {
        _aseguradoraCatalogKey = null;
        _aseguradoraController.text = 'Particular';
        return;
      }
      if (value == TipoAseguramiento.otro) {
        _aseguradoraCatalogKey = null;
        if (_aseguradoraController.text.trim().toLowerCase() == 'particular') {
          _aseguradoraController.clear();
        }
        return;
      }
      final List<dynamic> options = _aseguradoraOpciones;
      final bool hasSelected = options.any((dynamic option) => option.value == _aseguradoraCatalogKey);
      if (!hasSelected) {
        _aseguradoraCatalogKey = null;
        _aseguradoraController.clear();
      }
    }
  static const Color _brandPrimary = Color(0xFF17726D);
  static const Color _surfaceBase = Color(0xFFFFFFFF);
  static const Color _surfaceMuted = Color(0xFFF3F4F6);
  static const Color _borderSoft = Color(0xFFD9E2E7);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);


  // --- VISITA DOMICILIARIA ---
  bool _requiereVisita = false;
  DateTime? _fechaVisita;
  TimeOfDay? _horaVisita;

  static const List<ServicioQuePresenta> _servicioQuePresentaOptions =
      <ServicioQuePresenta>[
        ServicioQuePresenta.urgencias,
        ServicioQuePresenta.hospitalizacionSanFernando,
        ServicioQuePresenta.hospitalizacionMariaAuxiliadora,
        ServicioQuePresenta.uci,
        ServicioQuePresenta.cirugia,
        ServicioQuePresenta.consultaExterna,
        ServicioQuePresenta.otro,
      ];

  static const List<OrigenPaciente> _origenPacienteOptions = <OrigenPaciente>[
    OrigenPaciente.urgencias,
    OrigenPaciente.hospitalizacionSanFernando,
    OrigenPaciente.hospitalizacionMariaAuxiliadora,
    OrigenPaciente.uci,
    OrigenPaciente.cirugia,
    OrigenPaciente.consultaExterna,
    OrigenPaciente.otro,
  ];

  static const String _grupoRiesgoOtro = 'OTRO';
  static const String _barrioOtro = 'Otro';
  static const List<String> _barrioOptions = <String>[
    'Alameda La Victoria',
    'Albornoz',
    'Alcibia',
    'Alfredo V. Bonilla',
    'Alto Bosque',
    'Altos de San Isidro',
    'Amberes',
    'Antonio Jose de Sucre',
    'Arroz Barato',
    'Bellas Artes',
    'Bellavista',
    'Bicentenario',
    'Blas de Lezo',
    'Bocachica',
    'Bocagrande',
    'Bruselas',
    'Buenos Aires',
    'Caite',
    'Camaguey',
    'Campestre',
    'Canapote',
    'Carmen de Bolivar',
    'Castillogrande',
    'Ceballos',
    'Centro',
    'Cerros de Albornoz',
    'Chambacu',
    'Chapacuá',
    'Chipre',
    'Chiquinquira',
    'Ciudad Bicentenario',
    'Ciudadela 2000',
    'Ciudadela La Paz',
    'Colinas de Villa Barraza',
    'Conjunto Portal de La Cordialidad',
    'Crespo',
    'Daniel Lemaitre',
    'El Bosque',
    'El Campestre',
    'El Carmelo',
    'El Country',
    'El Educador',
    'El Espinal',
    'El Gallo',
    'El Golf',
    'El Limonar',
    'El Milagro',
    'El Nazareno',
    'El Paraiso',
    'El Poblado',
    'El Pozón',
    'El Prado',
    'El Recreo',
    'El Rodeo',
    'El Rubi',
    'El Socorro',
    'El Uvito',
    'Escallon Villa',
    'España',
    'Flor del Campo',
    'Fredonia',
    'Getsemani',
    'Henequen',
    'Jose Antonio Galan',
    'Juan XXIII',
    'La Boquilla',
    'La Campiña',
    'La Carolina',
    'La Castellana',
    'La Candelaria',
    'La Central',
    'La Concepcion',
    'La Consolata',
    'La Esperanza',
    'La Esmeralda I',
    'La Esmeralda II',
    'La Florida',
    'La Gloria',
    'La India',
    'La Magdalena',
    'La Maria',
    'La Matuna',
    'La Paz',
    'La Princesa',
    'La Providencia',
    'La Quinta',
    'Las Americas',
    'Las Brisas',
    'Las Delicias',
    'Las Gavias',
    'Las Gaviotas',
    'Las Palmeras',
    'Las Reinas',
    'Las Vegas',
    'Loma Fresca',
    'Los Alpes',
    'Los Almendros',
    'Los Calamares',
    'Los Caracoles',
    'Los Cerezos',
    'Los Comuneros',
    'Los Corales',
    'Los Ejecutivos',
    'Los Laureles',
    'Los Santanderes',
    'Manga',
    'Manzanillo del Mar',
    'Maria Auxiliadora',
    'Martinez Martelo',
    'Membrillal',
    'Mirador de La Bahia',
    'Mirador de San Jose',
    'Miramar',
    'Nelson Mandela',
    'Nueve de Abril',
    'Nuevo Bosque',
    'Nuevo Chile',
    'Nuevo Oriente',
    'Olaya Herrera',
    'Palmarito',
    'Paraiso II',
    'Paseo de Bolivar',
    'Pasacaballos',
    'Pedro Salazar',
    'Pie de La Popa',
    'Pie del Cerro',
    'Policarpa',
    'Portal de Alicante',
    'Portales de San Fernando',
    'Pozon Central',
    'Puerta de Hierro',
    'Puerto Rey',
    'Republica de Chile',
    'Republica del Caribe',
    'Rodeo',
    'San Antonio',
    'San Bernardo',
    'San Diego',
    'San Fernando',
    'San Francisco',
    'San Isidro',
    'San Jose de los Campanos',
    'San Jose Obrero',
    'San Pedro Martir',
    'San Pedro y Libertad',
    'San Vicente de Paul',
    'Santa Clara',
    'Santa Lucia',
    'Santa Maria',
    'Santa Monica',
    'Santa Rita',
    'Sector 11 de Noviembre',
    'Sector Rafael Nuñez',
    'Siete de Agosto',
    'Torices',
    'Turbaco Urbano',
    'Urbanizacion La India',
    'Urbanizacion San Buenaventura',
    'Urbanizacion Simon Bolivar',
    'Villa Barraza',
    'Villa Corelca',
    'Villa Estrella',
    'Villa Fanny',
    'Villa Hermosa',
    'Villa Rosita',
    'Villa Sandra',
    'Villa Zuldany',
    'Villagrande de Indias',
    'Vista Hermosa',
    'Zaragocilla',
    _barrioOtro,
  ];
  static const List<String> _grupoRiesgoOptions = <String>[
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
    _grupoRiesgoOtro,
  ];
  static const List<String> _causaReingresoOptions = <String>[
    'Comorbilidades descompensadas',
    'Factores sociales o de soporte no favorables',
    'Necesidad de escalamiento del nivel de atención por evolución clínica',
    'Progresión de la patología de base',
    'Requerimiento de atención intrahospitalaria',
    'Reacción adversa a medicamento',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _identificacionController =
      TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  final TextEditingController _aseguradoraController = TextEditingController();
  String? _aseguradoraCatalogKey;

  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _grupoRiesgoController = TextEditingController();
  String? _grupoRiesgoSeleccionado;
  final TextEditingController _especialidadBusquedaController =
      TextEditingController();
  final TextEditingController _especialidadManualController =
      TextEditingController();

  final TextEditingController _unidadFuncionalOrigenController =
      TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _barrioSearchController = TextEditingController();
  String? _barrioSeleccionado;
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _telefonoPrincipalController =
      TextEditingController();
  final TextEditingController _telefonoAlternoController =
      TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  SexoPaciente? _sexo;
  TipoAseguramiento? _tipoAseguramiento;
  RegimenAseguramiento? _regimenAseguramiento;

  TipoCaptacionPad? _tipoCaptacionPad;
  ServicioQuePresenta? _servicioQuePresenta;

  OrigenPaciente? _origenPaciente;
  bool _origenPacienteEditadoManualmente = false;
  OrigenPaciente? _ultimoOrigenAutocompletado;
  EspecialidadPrincipalTratante? _especialidadPrincipalTratante;
  DecisionPad? _decision;
  bool _esReingreso = false;
  String? _causaReingreso;

  String? _selectedAdmissionReason;
  final Set<String> _selectedAdmissionReasonKeys = <String>{};

  DateTime? _fechaProbableFinalizacionTratamiento;
  MotivoDetalleEstado _estadoFinalizacionTratamiento =
      MotivoDetalleEstado.enCurso;
  final TextEditingController _observacionesTratamientoController =
      TextEditingController();

  final TextEditingController _heridasCadaCuantosDiasController =
      TextEditingController();
  final TextEditingController _heridasSesionesPlaneadasController =
      TextEditingController();
  final TextEditingController _heridasSesionesRealizadasController =
      TextEditingController();
  DateTime? _fechaProbableFinalizacionHeridas;
  MotivoDetalleEstado _estadoClinicaHeridas = MotivoDetalleEstado.enCurso;

  final List<_ProcedimientoPendienteItem> _procedimientosPendientes =
      <_ProcedimientoPendienteItem>[];

  bool get _isEditing =>
      widget.candidatoId != null && widget.candidatoId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _hydrateFromData(widget.initialData!);
    }
  }

  void _hydrateFromData(Map<String, dynamic> data) {
          _aseguradoraController.text = (data['aseguradora'] as String?) ?? '';
          _tipoAseguramiento = _findEnumByLabel<TipoAseguramiento>(
            TipoAseguramiento.values,
            data['tipoAseguramiento'] as String?,
            _tipoAseguramientoLabel,
          );
          _regimenAseguramiento = _findEnumByLabel<RegimenAseguramiento>(
            RegimenAseguramiento.values,
            data['regimenAseguramiento'] as String?,
            _regimenAseguramientoLabel,
          );
          _syncAseguradoraFromStoredValue();
      debugPrint('hydrate keys => \\${data.keys.toList()}');
      debugPrint('barrio => \\${data['barrio']}');
      debugPrint('tipoAseguramiento => \\${data['tipoAseguramiento']}');
      debugPrint('regimenAseguramiento => \\${data['regimenAseguramiento']}');
      debugPrint('tipoCaptacionPad => \\${data['tipoCaptacionPad']}');
      debugPrint('especialidadPrincipalTratante => \\${data['especialidadPrincipalTratante']}');
      debugPrint('grupoRelacionadoRiesgo => \\${data['grupoRelacionadoRiesgo']}');
      debugPrint('origenPaciente => \\${data['origenPaciente']}');
    _nombreCompletoController.text =
        (data['nombreCompleto'] as String?) ??
        (data['nombre'] as String?) ??
        '';
    _identificacionController.text =
        (data['identificacion'] as String?) ??
        (data['documento'] as String?) ??
        '';

    final dynamic edadValue = data['edad'];
    if (edadValue != null) {
      _edadController.text = edadValue.toString();
    }

    _aseguradoraController.text = (data['aseguradora'] as String?) ?? '';
    _diagnosticoController.text = (data['diagnostico'] as String?) ?? '';
    _grupoRiesgoController.text =
        (data['grupoRelacionadoRiesgo'] as String?) ?? '';
    final String grupoRiesgo = _grupoRiesgoController.text.trim();
    if (grupoRiesgo.isEmpty) {
      _grupoRiesgoSeleccionado = null;
    } else if (_grupoRiesgoOptions.contains(grupoRiesgo)) {
      _grupoRiesgoSeleccionado = grupoRiesgo;
    } else {
      _grupoRiesgoSeleccionado = _grupoRiesgoOtro;
    }
    _unidadFuncionalOrigenController.text =
        (data['unidadFuncionalOrigen'] as String?) ?? '';
    _barrioController.text = (data['barrio'] as String?)?.trim() ?? '';
    final String barrio = _barrioController.text.trim();
    if (barrio.isEmpty) {
      _barrioSeleccionado = null;
    } else if (_barrioOptions.contains(barrio)) {
      _barrioSeleccionado = barrio;
    } else {
      _barrioSeleccionado = _barrioOtro;
    }
    _barrioSearchController.text = _barrioSeleccionado ?? '';
    _direccionController.text = (data['direccion'] as String?)?.trim() ?? '';
    _referenciaController.text =
        (data['referenciaUbicacion'] as String?)?.trim() ??
        (data['referencia'] as String?)?.trim() ??
        '';
    _telefonoPrincipalController.text =
        (data['telefonoPrincipal'] as String?)?.trim() ?? '';
    _telefonoAlternoController.text =
        (data['telefonoAlterno'] as String?)?.trim() ?? '';
    final String contactoRaw = (data['contacto'] as String?)?.trim() ?? '';
    if (contactoRaw.isNotEmpty &&
        _telefonoPrincipalController.text.isEmpty &&
        _telefonoAlternoController.text.isEmpty) {
      final List<String> telefonos = _splitContacto(contactoRaw);
      if (telefonos.isNotEmpty) {
        _telefonoPrincipalController.text = telefonos.first;
      }
      if (telefonos.length > 1) {
        _telefonoAlternoController.text = telefonos[1];
      }
    }
    _observacionesController.text = (data['observaciones'] as String?) ?? '';

    _sexo = _findEnumByLabel<SexoPaciente>(
      SexoPaciente.values,
      data['sexo'] as String?,
      _sexoPacienteLabel,
    );
    _tipoAseguramiento = _findEnumByLabel<TipoAseguramiento>(
      TipoAseguramiento.values,
      data['tipoAseguramiento'] as String?,
      _tipoAseguramientoLabel,
    );
    _syncAseguradoraFromStoredValue();
    _regimenAseguramiento = _findEnumByLabel<RegimenAseguramiento>(
      RegimenAseguramiento.values,
      data['regimenAseguramiento'] as String?,
      _regimenAseguramientoLabel,
    );
    _tipoCaptacionPad = _findEnumByLabel<TipoCaptacionPad>(
      TipoCaptacionPad.values,
      data['tipoCaptacionPad'] as String?,
      _tipoCaptacionPadLabel,
    );
    _servicioQuePresenta = _findEnumByLabel<ServicioQuePresenta>(
      ServicioQuePresenta.values,
      data['servicioQuePresenta'] as String?,
      _servicioQuePresentaLabel,
    );
    _origenPaciente = _findEnumByLabel<OrigenPaciente>(
      OrigenPaciente.values,
      data['origenPaciente'] as String?,
      _origenPacienteLabel,
    );
    _syncUnidadFuncionalOrigenDesdeOrigen();
    _ultimoOrigenAutocompletado = _origenFromServicio(_servicioQuePresenta);
    _origenPacienteEditadoManualmente = _origenPaciente != null;
    _especialidadPrincipalTratante =
        _findEnumByLabel<EspecialidadPrincipalTratante>(
          EspecialidadPrincipalTratante.values,
          data['especialidadPrincipalTratante'] as String?,
          _especialidadPrincipalTratanteLabel,
        );
    final String especialidadRaw =
        (data['especialidadPrincipalTratante'] as String?)?.trim() ?? '';
    if (_especialidadPrincipalTratante != null) {
      _especialidadBusquedaController.text =
          _especialidadPrincipalTratanteLabel(_especialidadPrincipalTratante!);
      _especialidadManualController.clear();
    } else if (especialidadRaw.isNotEmpty) {
      _especialidadPrincipalTratante = EspecialidadPrincipalTratante.otra;
      _especialidadBusquedaController.text =
          _especialidadPrincipalTratanteLabel(
            EspecialidadPrincipalTratante.otra,
          );
      _especialidadManualController.text = especialidadRaw;
    } else {
      _especialidadBusquedaController.clear();
      _especialidadManualController.clear();
    }
    _decision = _findEnumByLabel<DecisionPad>(
      DecisionPad.values,
      data['decision'] as String?,
      _decisionPadLabel,
    );
    // --- HIDRATACIÓN DE VISITA DOMICILIARIA ---
    _requiereVisita =
        (data['requiereVisita'] as bool?) == true ||
        data['requiereVisita']?.toString() == 'true';

    final dynamic fechaVisitaRaw = data['fechaVisita'];
    if (fechaVisitaRaw is DateTime) {
      _fechaVisita = DateTime(
        fechaVisitaRaw.year,
        fechaVisitaRaw.month,
        fechaVisitaRaw.day,
      );
    } else if (fechaVisitaRaw is String && fechaVisitaRaw.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(fechaVisitaRaw.trim());
      if (parsed != null) {
        _fechaVisita = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final String horaVisitaRaw =
        (data['horaVisita'] as String?)?.trim() ?? '';
    if (horaVisitaRaw.isNotEmpty) {
      final List<String> parts = horaVisitaRaw.split(':');
      if (parts.length >= 2) {
        final int? hour = int.tryParse(parts[0]);
        final int? minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          _horaVisita = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    final String? causaReingreso =
        (data['causaReingreso'] as String?)?.trim().isEmpty ?? true
        ? null
        : (data['causaReingreso'] as String).trim();
    _causaReingreso = causaReingreso;
    _esReingreso =
        ((data['esReingreso'] as bool?) ?? false) || causaReingreso != null;

    final List<dynamic> legacyMotivos =
        (data['motivos'] as List<dynamic>?) ?? <dynamic>[];
    final List<String> activosPersistidos =
        (data['motivosIngresoActivos'] as List<dynamic>?)
            ?.map(
              (dynamic item) => _normalizeAdmissionReasonKey(item.toString()),
            )
            .whereType<String>()
            .toList() ??
        <String>[];
    final String? principalKey =
        _normalizeAdmissionReasonKey(
          data['motivoIngresoPrincipal']?.toString(),
        ) ??
        (legacyMotivos.isNotEmpty
            ? _normalizeAdmissionReasonKey(legacyMotivos.first.toString())
            : null);

    _selectedAdmissionReasonKeys
      ..clear()
      ..addAll(activosPersistidos);
    if (_selectedAdmissionReasonKeys.isEmpty && principalKey != null) {
      _selectedAdmissionReasonKeys.add(principalKey);
    }

    final String? resolvedPrimaryKey =
        principalKey ??
        (_selectedAdmissionReasonKeys.isNotEmpty
            ? _selectedAdmissionReasonKeys.first
            : null);
    _selectedAdmissionReason = _admissionReasonLabelFromKey(resolvedPrimaryKey);

    final Map<String, dynamic> detalleMotivos =
        (data['detalleMotivos'] as Map<dynamic, dynamic>?)?.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, dynamic>(key.toString(), value),
        ) ??
        <String, dynamic>{};

    final Map<String, dynamic> detalleFinalizar =
        (detalleMotivos[PadAdmissionReasonLabels.finishTreatment.key]
                as Map<dynamic, dynamic>?)
            ?.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ) ??
        <String, dynamic>{};
    _fechaProbableFinalizacionTratamiento = _parseDate(
      detalleFinalizar['fechaProbableFinalizacion'],
    );
    _estadoFinalizacionTratamiento = _motivoEstadoFromKey(
      detalleFinalizar['estado']?.toString(),
    );
    _observacionesTratamientoController.text =
        (detalleFinalizar['observaciones'] as String?) ?? '';

    final Map<String, dynamic> detalleHeridas =
        (detalleMotivos[PadAdmissionReasonLabels.woundCare.key]
                as Map<dynamic, dynamic>?)
            ?.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ) ??
        <String, dynamic>{};
    _heridasCadaCuantosDiasController.text =
        (detalleHeridas['frecuenciaDias'] ?? '').toString();
    _heridasSesionesPlaneadasController.text =
        (detalleHeridas['sesionesPlaneadas'] ?? '').toString();
    _heridasSesionesRealizadasController.text =
        (detalleHeridas['sesionesRealizadas'] ?? '').toString();
    _fechaProbableFinalizacionHeridas = _parseDate(
      detalleHeridas['fechaProbableFinalizacion'],
    );
    _estadoClinicaHeridas = _motivoEstadoFromKey(
      detalleHeridas['estado']?.toString(),
    );

    _procedimientosPendientes.clear();
    final Map<String, dynamic> detalleProcedimiento =
        (detalleMotivos[PadAdmissionReasonLabels.pendingProcedure.key]
                as Map<dynamic, dynamic>?)
            ?.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ) ??
        <String, dynamic>{};
    final List<dynamic> procedimientos =
        (detalleProcedimiento['procedimientos'] as List<dynamic>?) ??
        <dynamic>[];

    for (final dynamic item in procedimientos) {
      if (item is! Map<dynamic, dynamic>) continue;
      final _ProcedimientoPendienteItem procedimiento =
          _ProcedimientoPendienteItem();
      procedimiento.nombreController.text = (item['nombre'] as String?) ?? '';
      procedimiento.observacionController.text =
          (item['observacion'] as String?) ?? '';
      procedimiento.fechaProbable = _parseDate(item['fechaProbable']);
      procedimiento.estado = _procedimientoEstadoFromKey(
        item['estado']?.toString(),
      );
      _procedimientosPendientes.add(procedimiento);
    }

    if (_selectedAdmissionReasonKeys.contains(
          PadAdmissionReasonLabels.pendingProcedure.key,
        ) &&
        _procedimientosPendientes.isEmpty) {
      _procedimientosPendientes.add(_ProcedimientoPendienteItem());
    }
  }

  String _normLabel(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  T? _findEnumByLabel<T>(
    Iterable<T> values,
    String? label,
    String Function(T) labelOf,
  ) {
    if (label == null || label.trim().isEmpty) return null;
    final target = _normLabel(label);
    for (final T value in values) {
      if (_normLabel(labelOf(value)) == target) {
        return value;
      }
    }
    return null;
  }

  String? _normalizeAdmissionReasonKey(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (option.key == rawValue || option.label == rawValue) {
        return option.key;
      }
    }
    return null;
  }

  String? _admissionReasonLabelFromKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (option.key == key) {
        return option.label;
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed == null) return null;
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  MotivoDetalleEstado _motivoEstadoFromKey(String? key) {
    return key == 'finalizado'
        ? MotivoDetalleEstado.finalizado
        : MotivoDetalleEstado.enCurso;
  }

  ProcedimientoEstado _procedimientoEstadoFromKey(String? key) {
    return key == 'realizado'
        ? ProcedimientoEstado.realizado
        : ProcedimientoEstado.pendiente;
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _identificacionController.dispose();
    _edadController.dispose();
    _aseguradoraController.dispose();
    _diagnosticoController.dispose();
    _grupoRiesgoController.dispose();
    _especialidadBusquedaController.dispose();
    _especialidadManualController.dispose();
    _unidadFuncionalOrigenController.dispose();
    _barrioController.dispose();
    _barrioSearchController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    _telefonoPrincipalController.dispose();
    _telefonoAlternoController.dispose();
    _observacionesController.dispose();
    _observacionesTratamientoController.dispose();
    _heridasCadaCuantosDiasController.dispose();
    _heridasSesionesPlaneadasController.dispose();
    _heridasSesionesRealizadasController.dispose();
    for (final _ProcedimientoPendienteItem p in _procedimientosPendientes) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedAdmissionReasonKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un motivo de ingreso.'),
        ),
      );
      return;
    }

    if (_selectedAdmissionReason != null) {
      final String? selectedPrimaryKey = _admissionReasonKeyFromLabel(
        _selectedAdmissionReason,
      );
      if (selectedPrimaryKey != null &&
          !_selectedAdmissionReasonKeys.contains(selectedPrimaryKey)) {
        _selectedAdmissionReasonKeys.add(selectedPrimaryKey);
      }
    }

    final String? motivoPrincipalKey = _admissionReasonKeyFromLabel(
      _selectedAdmissionReason,
    );
    final List<String> motivosActivos = _orderedSelectedReasonKeys();
    final String? resolvedPrincipalKey =
        motivoPrincipalKey ??
        (motivosActivos.isNotEmpty ? motivosActivos.first : null);
    final Map<String, dynamic> detalleMotivos = _buildDetalleMotivosForSave(
      motivosActivos,
    );

    // LOGS DE DEPURACIÓN DE VISITA
    debugPrint('requiereVisita=$_requiereVisita');
    debugPrint('fechaVisita=$_fechaVisita');
    debugPrint('horaVisita=$_horaVisita');

    final PacienteCaptacion paciente = PacienteCaptacion(
      nombreCompleto: _nombreCompletoController.text.trim(),
      identificacion: _identificacionController.text.trim(),
      sexo: _sexo!,
      edad: int.parse(_edadController.text.trim()),
      tipoAseguramiento: _tipoAseguramiento,
      aseguradora: _aseguradoraController.text.trim(),
      regimenAseguramiento: _regimenAseguramiento,
      tipoCaptacionPad: _tipoCaptacionPad!,
      servicioQuePresenta: _servicioQuePresenta,
      origenPaciente: _origenPaciente,
      especialidadPrincipalTratante: _especialidadPrincipalTratante,
      diagnostico: _diagnosticoController.text.trim(),
      grupoRelacionadoRiesgo: _grupoRiesgoController.text.trim(),
      motivos: motivosActivos.toSet(),
      motivoIngresoPrincipal: resolvedPrincipalKey,
      motivosIngresoActivos: motivosActivos,
      detalleMotivos: detalleMotivos,
      unidadFuncionalOrigen: _unidadFuncionalOrigenController.text.trim(),
      decision: _decision,
      observaciones: _observacionesController.text.trim(),
    );
    final String barrio = _barrioController.text.trim();
    final String direccion = _direccionController.text.trim();
    final String referenciaUbicacion = _referenciaController.text.trim();
    final String telefonoPrincipal = _telefonoPrincipalController.text.trim();
    final String telefonoAlterno = _telefonoAlternoController.text.trim();
    final String? especialidadCatalogo =
        _especialidadPrincipalTratante == null ||
            _especialidadPrincipalTratante == EspecialidadPrincipalTratante.otra
        ? null
        : _especialidadPrincipalTratanteLabel(_especialidadPrincipalTratante!);
    final String especialidadManual = _especialidadManualController.text.trim();
    final String? especialidadPersistida =
        _especialidadPrincipalTratante == EspecialidadPrincipalTratante.otra
        ? (especialidadManual.isEmpty ? null : especialidadManual)
        : especialidadCatalogo;

    final Map<String, dynamic> data = <String, dynamic>{
      'nombreCompleto': paciente.nombreCompleto,
      'identificacion': paciente.identificacion,
      'sexo': _sexoPacienteLabel(paciente.sexo),
      'edad': paciente.edad,
        'tipoAseguramiento': _tipoAseguramiento == null
          ? null
          : _tipoAseguramientoLabel(_tipoAseguramiento!),
        'aseguradora': _aseguradoraController.text.trim(),
        'regimenAseguramiento': _regimenAseguramiento == null
          ? null
          : _regimenAseguramientoLabel(_regimenAseguramiento!),
      'tipoCaptacionPad': _tipoCaptacionPadLabel(paciente.tipoCaptacionPad),
      'servicioQuePresenta': paciente.servicioQuePresenta == null
          ? null
          : _servicioQuePresentaLabel(paciente.servicioQuePresenta!),
      'origenPaciente': paciente.origenPaciente == null
          ? null
          : _origenPacienteLabel(paciente.origenPaciente!),
      'especialidadPrincipalTratante': especialidadPersistida,
      'especialidadCatalogo': especialidadCatalogo,
      'especialidadManual':
          _especialidadPrincipalTratante == EspecialidadPrincipalTratante.otra
          ? (especialidadManual.isEmpty ? null : especialidadManual)
          : null,
      'diagnostico': paciente.diagnostico,
      'grupoRelacionadoRiesgo': paciente.grupoRelacionadoRiesgo,
      'unidadFuncionalOrigen': paciente.unidadFuncionalOrigen,
      'barrio': barrio.isEmpty ? null : barrio,
      'direccion': direccion.isEmpty ? null : direccion,
      'referenciaUbicacion': referenciaUbicacion.isEmpty
          ? null
          : referenciaUbicacion,
      'telefonoPrincipal': telefonoPrincipal.isEmpty ? null : telefonoPrincipal,
      'telefonoAlterno': telefonoAlterno.isEmpty ? null : telefonoAlterno,
      'contacto': _composeContacto(
        telefonoPrincipal: telefonoPrincipal,
        telefonoAlterno: telefonoAlterno,
      ),
      'esReingreso': _isEditing ? _esReingreso : null,
      'causaReingreso': _isEditing && _esReingreso ? _causaReingreso : null,
      'decision': paciente.decision == null
          ? null
          : _decisionPadLabel(paciente.decision!),
      'observaciones': paciente.observaciones,
      // Nueva estructura persistida.
      'motivoIngresoPrincipal': paciente.motivoIngresoPrincipal,
      'motivosIngresoActivos': paciente.motivosIngresoActivos,
      'detalleMotivos': paciente.detalleMotivos,
      // Compatibilidad temporal.
      'motivos': paciente.motivos.toList(),
      // CAMPOS DE VISITA
        'requiereVisita': _requiereVisita,
        'fechaVisita': _fechaVisita,
        'horaVisita': _horaVisita == null
          ? null
          : '${_horaVisita!.hour.toString().padLeft(2, '0')}:${_horaVisita!.minute.toString().padLeft(2, '0')}',
    };

    debugPrint(
      "payload visita => [32m[1m[4m[7m${data['requiereVisita']} | ${data['fechaVisita']} | ${data['horaVisita']}[0m",
    );

    try {
      if (_isEditing) {
        await PadFirestoreService.actualizarCensoPaciente(
          widget.candidatoId!,
          data,
        );
      } else {
        await PadFirestoreService.guardarCandidato(data);
      }

      // Guardar barrio en catálogo global, sin bloquear el flujo si falla
      final barrioLimpio = barrio.trim();
      if (barrioLimpio.isNotEmpty) {
        try {
          await BarriosCatalogService.guardarBarrio(barrioLimpio);
        } catch (e) {
          debugPrint('No se pudo guardar el barrio en catálogo: $e');
        }
      }

      if (!mounted) return;

      final shouldGoToCases = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text(PadUiLabels.caseSaved),
          content: SingleChildScrollView(
            child: Text(
              'Nombre: ${paciente.nombreCompleto}\n'
              'Identificación: ${paciente.identificacion}\n'
              'Sexo: ${_sexoPacienteLabel(paciente.sexo)}\n'
              'Edad: ${paciente.edad}\n'
              'Tipo captación PAD: ${_tipoCaptacionPadLabel(paciente.tipoCaptacionPad)}\n'
              'Servicio que presenta: ${paciente.servicioQuePresenta != null ? _servicioQuePresentaLabel(paciente.servicioQuePresenta!) : '-'}\n'
              'Origen: ${paciente.origenPaciente != null ? _origenPacienteLabel(paciente.origenPaciente!) : '-'}\n'
              'Especialidad: ${especialidadPersistida ?? '-'}\n'
              'Barrio: ${barrio.isNotEmpty ? barrio : '-'}\n'
              'Diagnóstico: ${paciente.diagnostico}\n'
              'Grupo de riesgo: ${paciente.grupoRelacionadoRiesgo}\n'
              'Motivo principal: ${paciente.motivoIngresoPrincipal ?? '-'}\n'
              'Motivos activos: ${paciente.motivosIngresoActivos.isEmpty ? '-' : paciente.motivosIngresoActivos.join(', ')}\n'
              'Detalle del motivo: ${_motivoDetalleSummary()}\n'
              'Decisión: ${paciente.decision != null ? _decisionPadLabel(paciente.decision!) : '-'}\n'
              'Reingreso: ${_isEditing ? (_esReingreso ? 'Sí' : 'No') : '-'}\n'
              'Causa del reingreso: ${_isEditing && _esReingreso ? (_causaReingreso ?? '-') : '-'}',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );

      if (shouldGoToCases == true && context.mounted) {
        context.go('/cases');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(PadUiLabels.saveCaseError)));
      return;
    }
  }

  Future<void> _registrarDecision() async {
    final decision = _decision == null ? '' : _decisionPadLabel(_decision!).trim();

    if (decision.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una decisión antes de continuar.')),
      );
      return;
    }

    if (decision == 'Ingreso aprobado') {
      await _guardar();
      return;
    }

    // Para otras decisiones, aquí puedes guardar solo la decisión o ejecutar otro flujo si aplica.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Decisión registrada: $decision')),
    );
  }

  void _cancelarEdicion() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/cases');
  }

  List<String> _splitContacto(String raw) {
    final String normalized = raw.replaceAll('·', '+');
    return normalized
        .split(RegExp(r'\s*(?:\+|-|/)\s*'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
  }

  String? _composeContacto({
    required String telefonoPrincipal,
    required String telefonoAlterno,
  }) {
    if (telefonoPrincipal.isEmpty && telefonoAlterno.isEmpty) return null;
    if (telefonoPrincipal.isNotEmpty && telefonoAlterno.isNotEmpty) {
      return '$telefonoPrincipal + $telefonoAlterno';
    }
    return telefonoPrincipal.isNotEmpty ? telefonoPrincipal : telefonoAlterno;
  }

  String? _catalogTipoFromAseguramiento(TipoAseguramiento? tipo) {
    switch (tipo) {
      case TipoAseguramiento.eps:
        return 'eps';
      case TipoAseguramiento.medicinaPrepagada:
        return 'prepagada';
      case TipoAseguramiento.poliza:
        return 'poliza';
      case TipoAseguramiento.particular:
      case TipoAseguramiento.otro:
      case null:
        return null;
    }
  }

  List<dynamic> get _aseguradoraOpciones {
    final String? tipoCatalogo = _catalogTipoFromAseguramiento(
      _tipoAseguramiento,
    );
    return aseguradorasPorTipo(tipoCatalogo);
  }

  void _syncAseguradoraFromStoredValue() {
    final String rawValue = _aseguradoraController.text.trim();
    if (rawValue.isEmpty) {
      _aseguradoraCatalogKey = null;
      return;
    }

    final List<dynamic> options = _aseguradoraOpciones;
    for (final dynamic option in options) {
      final String value = option.value as String;
      final String label = option.label as String;
      if (rawValue == value || rawValue.toLowerCase() == label.toLowerCase()) {
        _aseguradoraCatalogKey = value;
        _aseguradoraController.text = label;
        return;
      }
    }

    _aseguradoraCatalogKey = null;
  }

  void _onTipoAseguramientoChanged(TipoAseguramiento? value) {
    _tipoAseguramiento = value;

    if (value == TipoAseguramiento.particular) {
      _aseguradoraCatalogKey = null;
      _aseguradoraController.text = 'Particular';
      return;
    }

    if (value == TipoAseguramiento.otro) {
      _aseguradoraCatalogKey = null;
      if (_aseguradoraController.text.trim().toLowerCase() == 'particular') {
        _aseguradoraController.clear();
      }
      return;
    }

    final List<dynamic> options = _aseguradoraOpciones;
    final bool hasSelected = options.any(
      (dynamic option) => option.value == _aseguradoraCatalogKey,
    );

    if (!hasSelected) {
      _aseguradoraCatalogKey = null;
      _aseguradoraController.clear();
    }
  }

  List<T> _sortedByLabel<T>(
    Iterable<T> values,
    String Function(T value) labelOf,
  ) {
    final List<T> sorted = values.toList();
    bool isOtherLabel(String label) {
      final String normalized = label.trim().toLowerCase();
      return normalized.startsWith('otro') || normalized.startsWith('otra');
    }

    sorted.sort((T a, T b) {
      final String labelA = labelOf(a);
      final String labelB = labelOf(b);
      final bool isOtherA = isOtherLabel(labelA);
      final bool isOtherB = isOtherLabel(labelB);

      if (isOtherA && !isOtherB) return 1;
      if (!isOtherA && isOtherB) return -1;
      return labelA.toLowerCase().compareTo(labelB.toLowerCase());
    });
    return sorted;
  }

  EspecialidadPrincipalTratante? _especialidadFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    for (final EspecialidadPrincipalTratante value
        in EspecialidadPrincipalTratante.values) {
      if (_especialidadPrincipalTratanteLabel(value).toLowerCase() ==
          label.trim().toLowerCase()) {
        return value;
      }
    }
    return null;
  }

  InputDecoration _inputDecoration(String label, {bool fixedHeight = true}) {
    return InputDecoration(
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: true,
      filled: true,
      fillColor: _surfaceBase,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: fixedHeight
          ? const BoxConstraints(minHeight: 40, maxHeight: 40)
          : null,
      hintStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.15,
        color: _textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _brandPrimary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
    );
  }

  Future<void> _pickDate(
    ValueChanged<DateTime> onPicked, {
    DateTime? initialDate,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) {
      onPicked(DateTime(selected.year, selected.month, selected.day));
    }
  }

  int get _heridasSesionesPendientes {
    final int planeadas =
        int.tryParse(_heridasSesionesPlaneadasController.text) ?? 0;
    final int realizadas =
        int.tryParse(_heridasSesionesRealizadasController.text) ?? 0;
    final int pendiente = planeadas - realizadas;
    return pendiente < 0 ? 0 : pendiente;
  }

  DateTime? get _proximaSesionHeridas {
    final int frecuenciaDias =
        int.tryParse(_heridasCadaCuantosDiasController.text) ?? 0;
    if (frecuenciaDias <= 0 || _heridasSesionesPendientes <= 0) {
      return null;
    }

    final DateTime hoy = DateTime.now();
    final DateTime base = DateTime(hoy.year, hoy.month, hoy.day);
    return base.add(Duration(days: frecuenciaDias));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateOrDash(DateTime? date) {
    if (date == null) return '--';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  OrigenPaciente? _origenFromServicio(ServicioQuePresenta? servicio) {
    switch (servicio) {
      case ServicioQuePresenta.urgencias:
        return OrigenPaciente.urgencias;
      case ServicioQuePresenta.hospitalizacionSanFernando:
        return OrigenPaciente.hospitalizacionSanFernando;
      case ServicioQuePresenta.hospitalizacionMariaAuxiliadora:
        return OrigenPaciente.hospitalizacionMariaAuxiliadora;
      case ServicioQuePresenta.hospitalizacion:
        return OrigenPaciente.hospitalizacion;
      case ServicioQuePresenta.uci:
        return OrigenPaciente.uci;
      case ServicioQuePresenta.cirugia:
        return OrigenPaciente.cirugia;
      case ServicioQuePresenta.consultaExterna:
        return OrigenPaciente.consultaExterna;
      case ServicioQuePresenta.otro:
        return OrigenPaciente.otro;
      case null:
        return null;
    }
  }

  void _autocompletarOrigenDesdeServicioSiAplica() {
    if (_tipoCaptacionPad != TipoCaptacionPad.presentadoPorServicio) return;

    final OrigenPaciente? origenSugerido = _origenFromServicio(
      _servicioQuePresenta,
    );
    if (origenSugerido == null) return;

    final bool origenSinValor = _origenPaciente == null;
    final bool origenNoEditado = !_origenPacienteEditadoManualmente;
    final bool origenEsUltimoAutocompletado =
        _ultimoOrigenAutocompletado != null &&
        _origenPaciente == _ultimoOrigenAutocompletado;

    if (origenSinValor || origenNoEditado || origenEsUltimoAutocompletado) {
      _origenPaciente = origenSugerido;
      _syncUnidadFuncionalOrigenDesdeOrigen();
      _ultimoOrigenAutocompletado = origenSugerido;
      _origenPacienteEditadoManualmente = false;
    }
  }

  void _syncUnidadFuncionalOrigenDesdeOrigen() {
    _unidadFuncionalOrigenController.text = _origenPaciente == null
        ? ''
        : _origenPacienteLabel(_origenPaciente!);
  }

  String? _dateIso(DateTime? date) {
    if (date == null) return null;
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }

  String? _admissionReasonKeyFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (option.label == label) {
        return option.key;
      }
    }
    return null;
  }

  String _motivoEstadoKey(MotivoDetalleEstado estado) {
    return estado == MotivoDetalleEstado.finalizado ? 'finalizado' : 'en_curso';
  }

  String _procedimientoEstadoKey(ProcedimientoEstado estado) {
    return estado == ProcedimientoEstado.realizado ? 'realizado' : 'pendiente';
  }

  Map<String, dynamic> _buildDetalleMotivosForSave(List<String> activeKeys) {
    final Map<String, dynamic> detalles = <String, dynamic>{};

    if (activeKeys.contains(PadAdmissionReasonLabels.finishTreatment.key)) {
      detalles[PadAdmissionReasonLabels.finishTreatment.key] =
          <String, dynamic>{
            'activo': true,
            'estado': _motivoEstadoKey(_estadoFinalizacionTratamiento),
            'fechaProbableFinalizacion': _dateIso(
              _fechaProbableFinalizacionTratamiento,
            ),
            'observaciones': _observacionesTratamientoController.text.trim(),
          };
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.woundCare.key)) {
      final int frecuenciaDias =
          int.tryParse(_heridasCadaCuantosDiasController.text) ?? 0;
      final int sesionesPlaneadas =
          int.tryParse(_heridasSesionesPlaneadasController.text) ?? 0;
      final int sesionesRealizadas =
          int.tryParse(_heridasSesionesRealizadasController.text) ?? 0;

      detalles[PadAdmissionReasonLabels.woundCare.key] = <String, dynamic>{
        'activo': true,
        'estado': _motivoEstadoKey(_estadoClinicaHeridas),
        'frecuenciaDias': frecuenciaDias,
        'sesionesPlaneadas': sesionesPlaneadas,
        'sesionesRealizadas': sesionesRealizadas,
        'sesionesPendientes': _heridasSesionesPendientes,
        'fechaProbableFinalizacion': _dateIso(
          _fechaProbableFinalizacionHeridas,
        ),
      };
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.pendingProcedure.key)) {
      detalles[PadAdmissionReasonLabels.pendingProcedure.key] =
          <String, dynamic>{
            'activo': true,
            'estado':
                _procedimientosPendientes.any(
                  (p) => p.estado == ProcedimientoEstado.pendiente,
                )
                ? 'en_curso'
                : 'finalizado',
            'procedimientos': _procedimientosPendientes
                .where(
                  (p) =>
                      p.nombreController.text.trim().isNotEmpty ||
                      p.observacionController.text.trim().isNotEmpty ||
                      p.fechaProbable != null,
                )
                .map(
                  (p) => <String, dynamic>{
                    'nombre': p.nombreController.text.trim(),
                    'fechaProbable': _dateIso(p.fechaProbable),
                    'estado': _procedimientoEstadoKey(p.estado),
                    'observacion': p.observacionController.text.trim(),
                  },
                )
                .toList(),
          };
    }

    return detalles;
  }

  List<String> _orderedSelectedReasonKeys() {
    final List<String> ordered = <String>[];
    for (final PadAdmissionReasonOption option
        in PadAdmissionReasonLabels.all) {
      if (_selectedAdmissionReasonKeys.contains(option.key)) {
        ordered.add(option.key);
      }
    }
    return ordered;
  }

  String _motivoDetalleSummary() {
    final List<String> activeKeys = _orderedSelectedReasonKeys();
    if (activeKeys.isEmpty) {
      return '-';
    }

    final List<String> chunks = <String>[];

    if (activeKeys.contains(PadAdmissionReasonLabels.finishTreatment.key)) {
      final String estado =
          _estadoFinalizacionTratamiento == MotivoDetalleEstado.finalizado
          ? 'Finalizado'
          : 'En curso';
      chunks.add(
        'Finalizar tratamiento: ${_formatDateOrDash(_fechaProbableFinalizacionTratamiento)} · $estado',
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.woundCare.key)) {
      final int planeadas =
          int.tryParse(_heridasSesionesPlaneadasController.text) ?? 0;
      final int realizadas =
          int.tryParse(_heridasSesionesRealizadasController.text) ?? 0;
      final int frecuenciaDias =
          int.tryParse(_heridasCadaCuantosDiasController.text) ?? 0;
      chunks.add(
        'Clínica de heridas: ${frecuenciaDias > 0 ? 'cada $frecuenciaDias días' : '--'} · Sesiones: $realizadas/$planeadas · Pendientes: $_heridasSesionesPendientes',
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.pendingProcedure.key)) {
      final int pendientes = _procedimientosPendientes
          .where((p) => p.estado == ProcedimientoEstado.pendiente)
          .length;
      final int realizados = _procedimientosPendientes
          .where((p) => p.estado == ProcedimientoEstado.realizado)
          .length;
      chunks.add(
        'Procedimiento pendiente: Pendientes $pendientes · Realizados $realizados',
      );
    }

    return chunks.join(' | ');
  }

  PadCaseData _buildPadCaseDataPreview() {
    final List<String> activeReasonLabels = _orderedSelectedReasonKeys()
        .map((String key) => _admissionReasonLabelFromKey(key) ?? key)
        .toList();

    final String detailSummary = _motivoDetalleSummary();

    String? situacion;
    if (_decision == DecisionPad.ingresoAprobado) {
      situacion = PadCareSituationLabels.hospitalExtension;
    } else if (_decision == DecisionPad.pendienteValoracion ||
        _decision == DecisionPad.requiereNuevaValoracion) {
      situacion = 'En valoracion';
    } else if (_decision == DecisionPad.ingresoNoAprobado) {
      situacion = 'No ingreso';
    }
    if (_isEditing && _esReingreso) {
      situacion = PadCareSituationLabels.readmission;
    }

    final PadCaseRecord record = PadCaseRecord(
      motivoIngresoPrincipal: _selectedAdmissionReason,
      motivosIngresoActivos: activeReasonLabels,
      detalleClinicoResumido: detailSummary == '-' ? null : detailSummary,
      observaciones: _observacionesController.text.trim(),
      situacionAsistencial: situacion,
      estadoPad: _decision == null ? null : _decisionPadLabel(_decision!),
      barrio: _barrioController.text.trim(),
    );

    return PadSummaryDomainAdapter.toPadCaseData(record);
  }

  bool _isSummaryEffectivelyEmpty(PadSummaryCompactVm summary) {
    return summary.principalLabel.trim().toLowerCase() ==
            'sin motivo principal' &&
        summary.activeReasonLabels.isEmpty &&
        summary.shortDetail.trim().toLowerCase() ==
            'sin detalle clinico resumido' &&
        summary.generalStatusLabel.trim().toLowerCase() ==
            'estado no clasificado';
  }

  bool get _canApproveForAdmission {
    final bool hasBasics =
        _nombreCompletoController.text.trim().isNotEmpty &&
        _identificacionController.text.trim().isNotEmpty &&
        _sexo != null &&
        int.tryParse(_edadController.text.trim()) != null;

    final bool hasClinicalCore =
        _diagnosticoController.text.trim().isNotEmpty &&
        _grupoRiesgoSeleccionado != null &&
        _selectedAdmissionReasonKeys.isNotEmpty;

    final bool hasApprovalDecision = _decision == DecisionPad.ingresoAprobado;
    return hasBasics && hasClinicalCore && hasApprovalDecision;
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(value),
              style: TextStyle(
                fontSize: 14,
                color: value == null ? const Color(0xFF7A869A) : _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivoDetalleSection() {
    final List<String> activeKeys = _orderedSelectedReasonKeys();
    if (activeKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> sections = <Widget>[];

    if (activeKeys.contains(PadAdmissionReasonLabels.finishTreatment.key)) {
      sections.add(
        _SectionCard(
          title: PadAdmissionReasonLabels.finishTreatment.label,
          child: _buildDetalleFinalizarTratamiento(),
        ),
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.woundCare.key)) {
      sections.add(
        _SectionCard(
          title: PadAdmissionReasonLabels.woundCare.label,
          child: _buildDetalleClinicaHeridas(),
        ),
      );
    }

    if (activeKeys.contains(PadAdmissionReasonLabels.pendingProcedure.key)) {
      sections.add(
        _SectionCard(
          title: PadAdmissionReasonLabels.pendingProcedure.label,
          child: _buildDetalleProcedimientosPendientes(),
        ),
      );
    }

    return Column(children: <Widget>[const SizedBox(height: 12), ...sections]);
  }

  Widget _buildAdmissionReasonField() {
    return InputDecorator(
      decoration: _inputDecoration(
        PadUiLabels.admissionReasonField,
        fixedHeight: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PadAdmissionReasonLabels.all.map((
              PadAdmissionReasonOption option,
            ) {
              final bool selected = _selectedAdmissionReasonKeys.contains(
                option.key,
              );

              return FilterChip(
                label: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                    color: _textPrimary,
                  ),
                ),
                selected: selected,
                onSelected: (_) => _toggleAdmissionReason(option),
                showCheckmark: false,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                side: BorderSide(color: selected ? _brandPrimary : _borderSoft),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: _surfaceBase,
                selectedColor: const Color(0xFFE8F3F1),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedAdmissionReason,
            decoration: _inputDecoration('Motivo principal'),
            items: _orderedSelectedReasonKeys()
                .map(
                  (String key) => DropdownMenuItem<String>(
                    value: _admissionReasonLabelFromKey(key),
                    child: Text(_admissionReasonLabelFromKey(key) ?? key),
                  ),
                )
                .toList(),
            onChanged: _selectedAdmissionReasonKeys.isEmpty
                ? null
                : (String? value) {
                    setState(() {
                      _selectedAdmissionReason = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  void _toggleAdmissionReason(PadAdmissionReasonOption option) {
    setState(() {
      if (_selectedAdmissionReasonKeys.contains(option.key)) {
        _selectedAdmissionReasonKeys.remove(option.key);
        if (_selectedAdmissionReason == option.label) {
          final String? nextPrimary = _selectedAdmissionReasonKeys.isNotEmpty
              ? _admissionReasonLabelFromKey(_orderedSelectedReasonKeys().first)
              : null;
          _selectedAdmissionReason = nextPrimary;
        }
        return;
      }

      _selectedAdmissionReasonKeys.add(option.key);
      _selectedAdmissionReason ??= option.label;
      if (option.key == PadAdmissionReasonLabels.pendingProcedure.key &&
          _procedimientosPendientes.isEmpty) {
        _procedimientosPendientes.add(_ProcedimientoPendienteItem());
      }
    });
  }

  Widget _buildDetalleFinalizarTratamiento() {
    return _AdaptiveFieldsRow(
      children: <_FieldItem>[
        _FieldItem(
          flex: 18,
          child: _buildDatePickerField(
            label: 'Fecha probable de finalización',
            value: _fechaProbableFinalizacionTratamiento,
            onTap: () => _pickDate((DateTime date) {
              setState(() => _fechaProbableFinalizacionTratamiento = date);
            }, initialDate: _fechaProbableFinalizacionTratamiento),
          ),
        ),
        _FieldItem(
          flex: 14,
          child: DropdownButtonFormField<MotivoDetalleEstado>(
            initialValue: _estadoFinalizacionTratamiento,
            decoration: _inputDecoration('Estado del motivo'),
            items: const <DropdownMenuItem<MotivoDetalleEstado>>[
              DropdownMenuItem(
                value: MotivoDetalleEstado.enCurso,
                child: Text('En curso'),
              ),
              DropdownMenuItem(
                value: MotivoDetalleEstado.finalizado,
                child: Text('Finalizado'),
              ),
            ],
            onChanged: (MotivoDetalleEstado? value) {
              if (value == null) return;
              setState(() => _estadoFinalizacionTratamiento = value);
            },
          ),
        ),
        _FieldItem(
          flex: 24,
          child: TextFormField(
            controller: _observacionesTratamientoController,
            decoration: _inputDecoration('Observaciones del tratamiento'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleClinicaHeridas() {
    return Column(
      children: <Widget>[
        _AdaptiveFieldsRow(
          children: <_FieldItem>[
            _FieldItem(
              flex: 12,
              child: TextFormField(
                controller: _heridasCadaCuantosDiasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Frecuencia de sesiones'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FieldItem(
              flex: 12,
              child: TextFormField(
                controller: _heridasSesionesPlaneadasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Sesiones planeadas'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FieldItem(
              flex: 12,
              child: TextFormField(
                controller: _heridasSesionesRealizadasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Sesiones realizadas'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FieldItem(
              flex: 12,
              child: InputDecorator(
                decoration: _inputDecoration('Sesiones pendientes'),
                child: Text(
                  '$_heridasSesionesPendientes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AdaptiveFieldsRow(
          children: <_FieldItem>[
            _FieldItem(
              flex: 12,
              child: InputDecorator(
                decoration: _inputDecoration('Próxima sesión'),
                child: Text(
                  _formatDateOrDash(_proximaSesionHeridas),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
            _FieldItem(
              flex: 18,
              child: _buildDatePickerField(
                label: 'Fecha probable de finalización',
                value: _fechaProbableFinalizacionHeridas,
                onTap: () => _pickDate((DateTime date) {
                  setState(() => _fechaProbableFinalizacionHeridas = date);
                }, initialDate: _fechaProbableFinalizacionHeridas),
              ),
            ),
            _FieldItem(
              flex: 14,
              child: DropdownButtonFormField<MotivoDetalleEstado>(
                initialValue: _estadoClinicaHeridas,
                decoration: _inputDecoration('Estado del motivo'),
                items: const <DropdownMenuItem<MotivoDetalleEstado>>[
                  DropdownMenuItem(
                    value: MotivoDetalleEstado.enCurso,
                    child: Text('En curso'),
                  ),
                  DropdownMenuItem(
                    value: MotivoDetalleEstado.finalizado,
                    child: Text('Finalizado'),
                  ),
                ],
                onChanged: (MotivoDetalleEstado? value) {
                  if (value == null) return;
                  setState(() => _estadoClinicaHeridas = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetalleProcedimientosPendientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ..._procedimientosPendientes.asMap().entries.map((
          MapEntry<int, _ProcedimientoPendienteItem> entry,
        ) {
          final int index = entry.key;
          final _ProcedimientoPendienteItem item = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _procedimientosPendientes.length - 1 ? 10 : 12,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSoft),
              ),
              child: Column(
                children: <Widget>[
                  _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 24,
                        child: TextFormField(
                          controller: item.nombreController,
                          decoration: _inputDecoration(
                            'Nombre del procedimiento',
                          ),
                        ),
                      ),
                      _FieldItem(
                        flex: 18,
                        child: _buildDatePickerField(
                          label: 'Fecha probable',
                          value: item.fechaProbable,
                          onTap: () => _pickDate((DateTime date) {
                            setState(() => item.fechaProbable = date);
                          }, initialDate: item.fechaProbable),
                        ),
                      ),
                      _FieldItem(
                        flex: 14,
                        child: DropdownButtonFormField<ProcedimientoEstado>(
                          initialValue: item.estado,
                          decoration: _inputDecoration('Estado'),
                          items: const <DropdownMenuItem<ProcedimientoEstado>>[
                            DropdownMenuItem(
                              value: ProcedimientoEstado.pendiente,
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: ProcedimientoEstado.realizado,
                              child: Text('Realizado'),
                            ),
                          ],
                          onChanged: (ProcedimientoEstado? value) {
                            if (value == null) return;
                            setState(() => item.estado = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AdaptiveFieldsRow(
                    children: <_FieldItem>[
                      _FieldItem(
                        flex: 30,
                        child: TextFormField(
                          controller: item.observacionController,
                          decoration: _inputDecoration('Observación'),
                        ),
                      ),
                      _FieldItem(
                        flex: 10,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Agregar procedimiento',
                                onPressed: () {
                                  setState(() {
                                    _procedimientosPendientes.add(
                                      _ProcedimientoPendienteItem(),
                                    );
                                  });
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: _brandPrimary,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar procedimiento',
                                onPressed: () {
                                  setState(() {
                                    if (_procedimientosPendientes.length == 1) {
                                      item.nombreController.clear();
                                      item.observacionController.clear();
                                      item.fechaProbable = null;
                                      item.estado =
                                          ProcedimientoEstado.pendiente;
                                      return;
                                    }

                                    final _ProcedimientoPendienteItem removed =
                                        _procedimientosPendientes.removeAt(
                                          index,
                                        );
                                    removed.dispose();
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? appUser = context.watch<AuthNotifier?>()?.appUser;
    final summary = mapPadSummary(_buildPadCaseDataPreview());
    final bool summaryEmpty = _isSummaryEffectivelyEmpty(summary);
    final bool desktop = MediaQuery.sizeOf(context).width >= 1024;
    final double scrollTopOffset = desktop ? 10 : 8;
    final String nombre = _nombreCompletoController.text.trim();
    final String identificacion = _identificacionController.text.trim();
    final bool hasPatientContext =
        nombre.isNotEmpty || identificacion.isNotEmpty;
    final bool showLocationContactSection =
        _isEditing && (appUser?.isAuxiliarAdministrativa ?? false);

    return ColoredBox(
      color: _surfaceMuted,
      child: Column(
        children: <Widget>[
          // --- HEADER DE MÓDULO Y CHIP DE ESTADO ---
          Padding(
            padding: EdgeInsets.fromLTRB(14, scrollTopOffset, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo candidato PAD',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(),
                ),
                // ...otros widgets de encabezado...
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAseguramientoSection(),
          // ...resto del formulario...
        ],
      ),
    );
                          Widget _buildAseguramientoSection() {
                            return _SectionCard(
                              title: 'Aseguramiento',
                              child: Column(
                                children: <Widget>[
                                  DropdownButtonFormField<TipoAseguramiento>(
                                    initialValue: _tipoAseguramiento,
                                    decoration: _inputDecoration('Tipo de aseguramiento'),
                                    items: _sortedByLabel<TipoAseguramiento>(
                                      TipoAseguramiento.values,
                                      _tipoAseguramientoLabel,
                                    ).map((TipoAseguramiento value) {
                                      return DropdownMenuItem<TipoAseguramiento>(
                                        value: value,
                                        child: Text(_tipoAseguramientoLabel(value)),
                                      );
                                    }).toList(),
                                    onChanged: (TipoAseguramiento? value) {
                                      setState(() => _onTipoAseguramientoChanged(value));
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAseguradoraField(),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<RegimenAseguramiento>(
                                    initialValue: _regimenAseguramiento,
                                    decoration: _inputDecoration('Régimen'),
                                    items: _sortedByLabel<RegimenAseguramiento>(
                                      RegimenAseguramiento.values,
                                      _regimenAseguramientoLabel,
                                    ).map((RegimenAseguramiento value) {
                                      return DropdownMenuItem<RegimenAseguramiento>(
                                        value: value,
                                        child: Text(_regimenAseguramientoLabel(value)),
                                      );
                                    }).toList(),
                                    onChanged: (RegimenAseguramiento? value) {
                                      setState(() => _regimenAseguramiento = value);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }

                          Widget _buildAseguradoraField() {
                            if (_tipoAseguramiento == TipoAseguramiento.particular) {
                              return TextFormField(
                                controller: _aseguradoraController,
                                readOnly: true,
                                decoration: _inputDecoration('Aseguradora'),
                              );
                            }
                            if (_tipoAseguramiento == TipoAseguramiento.otro) {
                              return TextFormField(
                                controller: _aseguradoraController,
                                decoration: _inputDecoration('Especificar entidad'),
                              );
                            }
                            final List<dynamic> options = _aseguradoraOpciones;
                            if (options.isNotEmpty) {
                              return DropdownButtonFormField<String>(
                                initialValue: options.any((dynamic option) => option.value == _aseguradoraCatalogKey)
                                    ? _aseguradoraCatalogKey
                                    : null,
                                decoration: _inputDecoration('Aseguradora'),
                                items: options.map((dynamic option) {
                                  return DropdownMenuItem<String>(
                                    value: option.value as String,
                                    child: Text(option.label as String),
                                  );
                                }).toList(),
                                onChanged: (String? selectedKey) {
                                  setState(() {
                                    _aseguradoraCatalogKey = selectedKey;
                                    if (selectedKey == null) {
                                      _aseguradoraController.clear();
                                      return;
                                    }
                                    final dynamic match = options.firstWhere((dynamic option) => option.value == selectedKey);
                                    _aseguradoraController.text = match.label as String;
                                  });
                                },
                              );
                            }
                            return TextFormField(
                              controller: _aseguradoraController,
                              enabled: false,
                              decoration: _inputDecoration('Aseguradora'),
                            );
                          }
                        // --- UBICACIÓN Y CONTACTO ---
                        if (showLocationContactSection) ...<Widget>[
                          // Archivo legacy movido a backup por duplicidad. Ver ruta presentation/captacion para la versión activa.
                        ],
                        const SizedBox(height: 16),

                        // --- PROGRAMACIÓN DE VISITA ---
                        _SectionCard(
                          title: 'Programación de visita',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SwitchListTile(
                                title: const Text('¿Requiere visita domiciliaria?'),
                                value: _requiereVisita,
                                onChanged: (bool value) {
                                  setState(() {
                                    _requiereVisita = value;
                                    if (!value) {
                                      _fechaVisita = null;
                                      _horaVisita = null;
                                    }
                                  });
                                },
                              ),
                              if (_requiereVisita) ...[
                                const SizedBox(height: 10),
                                _buildDatePickerField(
                                  label: 'Fecha de visita',
                                  value: _fechaVisita,
                                  onTap: () async {
                                    await _pickDate(
                                      (DateTime picked) {
                                        setState(() => _fechaVisita = picked);
                                      },
                                      initialDate: _fechaVisita,
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: _horaVisita ?? TimeOfDay.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => _horaVisita = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: _inputDecoration('Hora de visita'),
                                    child: Text(
                                      _horaVisita != null
                                          ? _horaVisita!.format(context)
                                          : 'Seleccionar hora',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // --- DECISIÓN DE INGRESO ---
                        _SectionCard(
                          title: 'Decisión de ingreso',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 20,
                                    child: DropdownButtonFormField<DecisionPad>(
                                      initialValue: _decision,
                                      decoration: _inputDecoration('Resultado de la valoración'),
                                      items: _sortedByLabel<DecisionPad>(
                                          DecisionPad.values,
                                          _decisionPadLabel,
                                        )
                                        .map(
                                          (DecisionPad value) =>
                                              DropdownMenuItem<DecisionPad>(
                                                value: value,
                                                child: Text(
                                                  _decisionPadLabel(value),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                      onChanged: (DecisionPad? value) {
                                        setState(() => _decision = value);
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _observacionesController,
                                      decoration: _inputDecoration('Observaciones'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // Microcopy según selección
                              if (_decision != null) ...[
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    switch (_decision) {
                                      case DecisionPad.ingresoAprobado:
                                        return const Text(
                                          'El paciente cumple criterios y se aprueba su ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF17726D)),
                                        );
                                      case DecisionPad.ingresoNoAprobado:
                                        return const Text(
                                          'El paciente no cumple criterios para ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFFB42318)),
                                        );
                                      case DecisionPad.pendienteValoracion:
                                        return const Text(
                                          'La decisión queda pendiente. Se requiere información adicional o seguimiento.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      case DecisionPad.requiereNuevaValoracion:
                                        return const Text(
                                          'Se requiere revalorar el caso antes de tomar una decisión definitiva.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              ],
                              if (_isEditing) ...<Widget>[
                                const SizedBox(height: 14),
                                _AdaptiveFieldsRow(
                                  children: <_FieldItem>[
                                    _FieldItem(
                                      flex: 20,
                                      child: DropdownButtonFormField<bool>(
                                        initialValue: _esReingreso,
                                        decoration: _inputDecoration(
                                          '¿Es reingreso?',
                                        ),
                                        items: const <DropdownMenuItem<bool>>[
                                          DropdownMenuItem<bool>(
                                            value: false,
                                            child: Text('No'),
                                          ),
                                          DropdownMenuItem<bool>(
                                            value: true,
                                            child: Text('Sí'),
                                          ),
                                        ],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _esReingreso = value ?? false;
                                            if (!_esReingreso) {
                                              _causaReingreso = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    if (_esReingreso)
                                      _FieldItem(
                                        flex: 40,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _causaReingreso,
                                          decoration: _inputDecoration(
                                            'Causa del reingreso',
                                          ),
                                          items: _causaReingresoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() => _causaReingreso = value);
                                          },
                                          validator: (String? value) {
                                            if (_isEditing &&
                                                _esReingreso &&
                                                (value == null ||
                                                    value.trim().isEmpty)) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Contexto clínico',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        Autocomplete<EspecialidadPrincipalTratante>(
                                          optionsBuilder:
                                              (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            final List<
                                              EspecialidadPrincipalTratante
                                            >
                                            options =
                                                _sortedByLabel<
                                                  EspecialidadPrincipalTratante
                                                >(
                                                  EspecialidadPrincipalTratante
                                                      .values,
                                                  _especialidadPrincipalTratanteLabel,
                                                );
                                            if (query.isEmpty) {
                                              return options;
                                            }
                                            return options.where(
                                              (
                                                EspecialidadPrincipalTratante
                                                value,
                                              ) =>
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  ).toLowerCase().contains(query),
                                            );
                                          },
                                          displayStringForOption:
                                              _especialidadPrincipalTratanteLabel,
                                          onSelected:
                                              (EspecialidadPrincipalTratante value) {
                                                setState(() {
                                                  _especialidadPrincipalTratante =
                                                      value;
                                                  _especialidadBusquedaController
                                                      .text =
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  );
                                                  if (value !=
                                                      EspecialidadPrincipalTratante
                                                          .otra) {
                                                    _especialidadManualController
                                                        .clear();
                                                  }
                                                });
                                              },
                                          fieldViewBuilder:
                                              (
                                                BuildContext context,
                                                TextEditingController
                                                textEditingController,
                                                FocusNode focusNode,
                                                VoidCallback onFieldSubmitted,
                                              ) {
                                                if (textEditingController.text !=
                                                    _especialidadBusquedaController
                                                        .text) {
                                                  textEditingController.text =
                                                      _especialidadBusquedaController
                                                          .text;
                                                }
                                                return TextFormField(
                                                  controller: textEditingController,
                                                  focusNode: focusNode,
                                                  decoration: _inputDecoration(
                                                    'Especialidad',
                                                  ),
                                                  onChanged: (String value) {
                                                    _especialidadBusquedaController
                                                        .text = value;
                                                    final EspecialidadPrincipalTratante?
                                                    match = _especialidadFromLabel(
                                                      value,
                                                    );
                                                    setState(() {
                                                      _especialidadPrincipalTratante =
                                                          match;
                                                      if (match !=
                                                          EspecialidadPrincipalTratante
                                                              .otra) {
                                                        _especialidadManualController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                  validator: (String? value) {
                                                    if (_especialidadPrincipalTratante ==
                                                        null) {
                                                      return 'Seleccione una especialidad';
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            ),
                                            if (_especialidadPrincipalTratante ==
                                                EspecialidadPrincipalTratante
                                                    .otra) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _especialidadManualController,
                                                decoration: _inputDecoration(
                                                  'Especifique la especialidad',
                                                ),
                                                validator: (String? value) {
                                                  if (_especialidadPrincipalTratante ==
                                                          EspecialidadPrincipalTratante
                                                              .otra &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 34,
                                        child: TextFormField(
                                          controller: _diagnosticoController,
                                          decoration: _inputDecoration('Diagnóstico'),
                                          validator: (String? value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 18,
                                        child: Column(
                                          children: <Widget>[
                                            DropdownButtonFormField<String>(
                                              initialValue: _grupoRiesgoSeleccionado,
                                              isExpanded: true,
                                              decoration: _inputDecoration(
                                                'Grupo relacionado de riesgo (GRD)',
                                              ),
                                              items: _grupoRiesgoOptions
                                                  .map(
                                                    (String value) =>
                                                        DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(
                                                            value.toLowerCase(),
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _grupoRiesgoSeleccionado = value;
                                                  if (value == null) {
                                                    _grupoRiesgoController.clear();
                                                    return;
                                                  }
                                                  if (value != _grupoRiesgoOtro) {
                                                    _grupoRiesgoController.text = value;
                                                  } else if (_grupoRiesgoOptions.contains(
                                                    _grupoRiesgoController.text.trim(),
                                                  )) {
                                                    _grupoRiesgoController.clear();
                                                  }
                                                });
                                              },
                                              validator: (String? value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Campo obligatorio';
                                                }
                                                if (value == _grupoRiesgoOtro &&
                                                    _grupoRiesgoController.text
                                                        .trim()
                                                        .isEmpty) {
                                                  return 'Especifique el grupo';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (_grupoRiesgoSeleccionado ==
                                                _grupoRiesgoOtro) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _grupoRiesgoController,
                                                decoration: _inputDecoration(
                                                  'Especifique grupo de riesgo',
                                                ),
                                                validator: (String? value) {
                                                  if (_grupoRiesgoSeleccionado ==
                                                          _grupoRiesgoOtro &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _FieldItem(
                                    flex: 56,
                                    child: DropdownButtonFormField<OrigenPaciente>(
                                      initialValue: _origenPaciente,
                                      decoration: _inputDecoration(
                                        'Origen del paciente',
                                      ),
                                      items:
                                          _sortedByLabel<OrigenPaciente>(
                                                _origenPacienteOptions,
                                                _origenPacienteLabel,
                                              )
                                              .map(
                                                (OrigenPaciente value) =>
                                                    DropdownMenuItem<OrigenPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _origenPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (OrigenPaciente? value) {
                                        setState(() {
                                          _origenPaciente = value;
                                          _syncUnidadFuncionalOrigenDesdeOrigen();
                                          _origenPacienteEditadoManualmente = true;
                                        });
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _diagnosticoController,
                                      decoration: _inputDecoration('Diagnóstico'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        DropdownButtonFormField<String>(
                                          initialValue: _grupoRiesgoSeleccionado,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            'Grupo relacionado de riesgo (GRD)',
                                          ),
                                          items: _grupoRiesgoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(
                                                        value.toLowerCase(),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              _grupoRiesgoSeleccionado = value;
                                              if (value == null) {
                                                _grupoRiesgoController.clear();
                                                return;
                                              }
                                              if (value != _grupoRiesgoOtro) {
                                                _grupoRiesgoController.text = value;
                                              } else if (_grupoRiesgoOptions.contains(
                                                _grupoRiesgoController.text.trim(),
                                              )) {
                                                _grupoRiesgoController.clear();
                                              }
                                            });
                                          },
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            if (value == _grupoRiesgoOtro &&
                                                _grupoRiesgoController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return 'Especifique el grupo';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (_grupoRiesgoSeleccionado ==
                                            _grupoRiesgoOtro) ...<Widget>[
                                          const SizedBox(height: 10),
                                          TextFormField(
                                            controller: _grupoRiesgoController,
                                            decoration: _inputDecoration(
                                              'Especifique grupo de riesgo',
                                            ),
                                            validator: (String? value) {
                                              if (_grupoRiesgoSeleccionado ==
                                                      _grupoRiesgoOtro &&
                                                  (value == null ||
                                                      value.trim().isEmpty)) {
                                                return 'Campo obligatorio';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 20,
                                    child: DropdownButtonFormField<DecisionPad>(
                                      initialValue: _decision,
                                      decoration: _inputDecoration('Resultado de la valoración'),
                                      items: _sortedByLabel<DecisionPad>(
                                          DecisionPad.values,
                                          _decisionPadLabel,
                                        )
                                        .map(
                                          (DecisionPad value) =>
                                              DropdownMenuItem<DecisionPad>(
                                                value: value,
                                                child: Text(
                                                  _decisionPadLabel(value),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                      onChanged: (DecisionPad? value) {
                                        setState(() => _decision = value);
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _observacionesController,
                                      decoration: _inputDecoration('Observaciones'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // Microcopy según selección
                              if (_decision != null) ...[
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    switch (_decision) {
                                      case DecisionPad.ingresoAprobado:
                                        return const Text(
                                          'El paciente cumple criterios y se aprueba su ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF17726D)),
                                        );
                                      case DecisionPad.ingresoNoAprobado:
                                        return const Text(
                                          'El paciente no cumple criterios para ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFFB42318)),
                                        );
                                      case DecisionPad.pendienteValoracion:
                                        return const Text(
                                          'La decisión queda pendiente. Se requiere información adicional o seguimiento.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      case DecisionPad.requiereNuevaValoracion:
                                        return const Text(
                                          'Se requiere revalorar el caso antes de tomar una decisión definitiva.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              ],
                              if (_isEditing) ...<Widget>[
                                const SizedBox(height: 14),
                                _AdaptiveFieldsRow(
                                  children: <_FieldItem>[
                                    _FieldItem(
                                      flex: 20,
                                      child: DropdownButtonFormField<bool>(
                                        initialValue: _esReingreso,
                                        decoration: _inputDecoration(
                                          '¿Es reingreso?',
                                        ),
                                        items: const <DropdownMenuItem<bool>>[
                                          DropdownMenuItem<bool>(
                                            value: false,
                                            child: Text('No'),
                                          ),
                                          DropdownMenuItem<bool>(
                                            value: true,
                                            child: Text('Sí'),
                                          ),
                                        ],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _esReingreso = value ?? false;
                                            if (!_esReingreso) {
                                              _causaReingreso = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    if (_esReingreso)
                                      _FieldItem(
                                        flex: 40,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _causaReingreso,
                                          decoration: _inputDecoration(
                                            'Causa del reingreso',
                                          ),
                                          items: _causaReingresoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() => _causaReingreso = value);
                                          },
                                          validator: (String? value) {
                                            if (_isEditing &&
                                                _esReingreso &&
                                                (value == null ||
                                                    value.trim().isEmpty)) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Datos básicos',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: TextFormField(
                                      controller: _nombreCompletoController,
                                      decoration: _inputDecoration('Nombre completo'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 20,
                                    child: TextFormField(
                                      controller: _identificacionController,
                                      decoration: _inputDecoration('Identificación'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 14,
                                    child: Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            if (query.isEmpty) return _barrioOptions;
                                            return _barrioOptions.where(
                                              (String b) =>
                                                  b.toLowerCase().contains(query),
                                            );
                                          },
                                      displayStringForOption: (String value) => value,
                                      onSelected: (String value) {
                                        setState(() {
                                          _barrioSeleccionado = value;
                                          _barrioSearchController.text = value;
                                          if (value != _barrioOtro) {
                                            _barrioController.text = value;
                                          } else if (_barrioOptions.contains(
                                            _barrioController.text.trim(),
                                          )) {
                                            _barrioController.clear();
                                          }
                                        });
                                      },
                                      fieldViewBuilder:
                                          (
                                            BuildContext ctx,
                                            TextEditingController autoCtrl,
                                            FocusNode focusNode,
                                            VoidCallback onFieldSubmitted,
                                          ) {
                                            if (autoCtrl.text !=
                                                _barrioSearchController.text) {
                                              autoCtrl.text =
                                                  _barrioSearchController.text;
                                            }
                                            return TextFormField(
                                              controller: autoCtrl,
                                              focusNode: focusNode,
                                              decoration: _inputDecoration('Barrio'),
                                              onChanged: (String value) {
                                                _barrioSearchController.text = value;
                                                setState(() {
                                                  if (_barrioOptions.contains(
                                                    value,
                                                  ) &&
                                                    value != _barrioOtro) {
                                                    _barrioSeleccionado = value;
                                                    _barrioController.text = value;
                                                  } else {
                                                    _barrioSeleccionado = null;
                                                  }
                                                });
                                              },
                                            );
                                          },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 8,
                                    child: DropdownButtonFormField<SexoPaciente>(
                                      initialValue: _sexo,
                                      decoration: _inputDecoration('Sexo'),
                                      items:
                                          _sortedByLabel<SexoPaciente>(
                                                SexoPaciente.values,
                                                _sexoPacienteLabel,
                                              )
                                              .map(
                                                (SexoPaciente value) =>
                                                    DropdownMenuItem<SexoPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _sexoPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (SexoPaciente? value) {
                                        setState(() => _sexo = value);
                                      },
                                      validator: (SexoPaciente? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _edadController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _inputDecoration('Edad'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        final int? edad = int.tryParse(value.trim());
                                        if (edad == null) {
                                          return 'Edad inválida';
                                        }
                                        if (edad < 0 || edad > 120) {
                                          return 'Edad inválida';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_barrioSeleccionado == _barrioOtro) ...<Widget>[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _barrioController,
                                  decoration: _inputDecoration('Especifique barrio'),
                                  validator: (String? value) {
                                    if (_barrioSeleccionado == _barrioOtro &&
                                        (value == null || value.trim().isEmpty)) {
                                      return 'Campo obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Aseguramiento',
                          child: _AdaptiveFieldsRow(
                            children: <_FieldItem>[
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<TipoAseguramiento>(
                                  initialValue: _tipoAseguramiento,
                                  decoration: _inputDecoration('Tipo'),
                                  items:
                                      _sortedByLabel<TipoAseguramiento>(
                                            TipoAseguramiento.values,
                                            _tipoAseguramientoLabel,
                                          )
                                          .map(
                                            (TipoAseguramiento value) =>
                                                DropdownMenuItem<TipoAseguramiento>(
                                                  value: value,
                                                  child: Text(
                                                    _tipoAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (TipoAseguramiento? value) {
                                    setState(
                                      () => _onTipoAseguramientoChanged(value),
                                    );
                                  },
                                ),
                              ),
                              _FieldItem(
                                flex: 36,
                                child: () {
                                  if (_tipoAseguramiento ==
                                      TipoAseguramiento.particular) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      readOnly: true,
                                      decoration: _inputDecoration('Aseguradora'),
                                    );
                                  }

                                  if (_tipoAseguramiento == TipoAseguramiento.otro) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      decoration: _inputDecoration(
                                        'Especificar entidad',
                                      ),
                                    );
                                  }

                                  final List<dynamic> options = _aseguradoraOpciones;
                                  if (options.isNotEmpty) {
                                    return DropdownButtonFormField<String>(
                                      initialValue:
                                          options.any(
                                            (dynamic option) =>
                                                option.value ==
                                                _aseguradoraCatalogKey,
                                          )
                                          ? _aseguradoraCatalogKey
                                          : null,
                                      decoration: _inputDecoration('Aseguradora'),
                                      items: options
                                          .map(
                                            (dynamic option) =>
                                                DropdownMenuItem<String>(
                                                  value: option.value as String,
                                                  child: Text(option.label as String),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (String? selectedKey) {
                                        setState(() {
                                          _aseguradoraCatalogKey = selectedKey;
                                          if (selectedKey == null) {
                                            _aseguradoraController.clear();
                                            return;
                                          }
                                          final dynamic match = options.firstWhere(
                                            (dynamic option) =>
                                                option.value == selectedKey,
                                          );
                                          _aseguradoraController.text =
                                              match.label as String;
                                        });
                                      },
                                    );
                                  }

                                  return TextFormField(
                                    controller: _aseguradoraController,
                                    enabled: false,
                                    decoration: _inputDecoration('Aseguradora'),
                                  );
                                }(),
                              ),
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<RegimenAseguramiento>(
                                  initialValue: _regimenAseguramiento,
                                  decoration: _inputDecoration('Régimen'),
                                  items:
                                      _sortedByLabel<RegimenAseguramiento>(
                                            RegimenAseguramiento.values,
                                            _regimenAseguramientoLabel,
                                          )
                                          .map(
                                            (RegimenAseguramiento value) =>
                                                DropdownMenuItem<
                                                  RegimenAseguramiento
                                                >(
                                                  value: value,
                                                  child: Text(
                                                    _regimenAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (RegimenAseguramiento? value) {
                                    setState(() => _regimenAseguramiento = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Captación PAD',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: DropdownButtonFormField<TipoCaptacionPad>(
                                      initialValue: _tipoCaptacionPad,
                                      decoration: _inputDecoration(
                                        'Tipo de captación PAD',
                                      ),
                                      items:
                                          _sortedByLabel<TipoCaptacionPad>(
                                                TipoCaptacionPad.values,
                                                _tipoCaptacionPadLabel,
                                              )
                                              .map(
                                                (TipoCaptacionPad value) =>
                                                    DropdownMenuItem<
                                                      TipoCaptacionPad
                                                    >(
                                                      value: value,
                                                      child: Text(
                                                        _tipoCaptacionPadLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (TipoCaptacionPad? value) {
                                        setState(() {
                                          _tipoCaptacionPad = value;
                                          if (value !=
                                              TipoCaptacionPad
                                                  .presentadoPorServicio) {
                                            _servicioQuePresenta = null;
                                            _ultimoOrigenAutocompletado = null;
                                          } else {
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          }
                                        });
                                      },
                                      validator: (TipoCaptacionPad? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_tipoCaptacionPad ==
                                      TipoCaptacionPad.presentadoPorServicio)
                                    _FieldItem(
                                      flex: 24,
                                      child: DropdownButtonFormField<ServicioQuePresenta>(
                                        key: const ValueKey('servicio_que_presenta'),
                                        initialValue: _servicioQuePresenta,
                                        decoration: _inputDecoration(
                                          'Servicio que presenta',
                                        ),
                                        items:
                                            _sortedByLabel<ServicioQuePresenta>(
                                                  _servicioQuePresentaOptions,
                                                  _servicioQuePresentaLabel,
                                                )
                                                .map(
                                                  (ServicioQuePresenta value) =>
                                                      DropdownMenuItem<
                                                        ServicioQuePresenta
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          _servicioQuePresentaLabel(
                                                            value,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                        onChanged: (ServicioQuePresenta? value) {
                                          setState(() {
                                            _servicioQuePresenta = value;
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          });
                                        },
                                        validator: (ServicioQuePresenta? value) {
                                          if (_tipoCaptacionPad ==
                                                  TipoCaptacionPad
                                                      .presentadoPorServicio &&
                                              value == null) {
                                            return 'Campo obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Contexto clínico',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        Autocomplete<EspecialidadPrincipalTratante>(
                                          optionsBuilder:
                                              (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            final List<
                                              EspecialidadPrincipalTratante
                                            >
                                            options =
                                                _sortedByLabel<
                                                  EspecialidadPrincipalTratante
                                                >(
                                                  EspecialidadPrincipalTratante
                                                      .values,
                                                  _especialidadPrincipalTratanteLabel,
                                                );
                                            if (query.isEmpty) {
                                              return options;
                                            }
                                            return options.where(
                                              (
                                                EspecialidadPrincipalTratante
                                                value,
                                              ) =>
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  ).toLowerCase().contains(query),
                                            );
                                          },
                                          displayStringForOption:
                                              _especialidadPrincipalTratanteLabel,
                                          onSelected:
                                              (EspecialidadPrincipalTratante value) {
                                                setState(() {
                                                  _especialidadPrincipalTratante =
                                                      value;
                                                  _especialidadBusquedaController
                                                      .text =
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  );
                                                  if (value !=
                                                      EspecialidadPrincipalTratante
                                                          .otra) {
                                                    _especialidadManualController
                                                        .clear();
                                                  }
                                                });
                                              },
                                          fieldViewBuilder:
                                              (
                                                BuildContext context,
                                                TextEditingController
                                                textEditingController,
                                                FocusNode focusNode,
                                                VoidCallback onFieldSubmitted,
                                              ) {
                                                if (textEditingController.text !=
                                                    _especialidadBusquedaController
                                                        .text) {
                                                  textEditingController.text =
                                                      _especialidadBusquedaController
                                                          .text;
                                                }
                                                return TextFormField(
                                                  controller: textEditingController,
                                                  focusNode: focusNode,
                                                  decoration: _inputDecoration(
                                                    'Especialidad',
                                                  ),
                                                  onChanged: (String value) {
                                                    _especialidadBusquedaController
                                                        .text = value;
                                                    final EspecialidadPrincipalTratante?
                                                    match = _especialidadFromLabel(
                                                      value,
                                                    );
                                                    setState(() {
                                                      _especialidadPrincipalTratante =
                                                          match;
                                                      if (match !=
                                                          EspecialidadPrincipalTratante
                                                              .otra) {
                                                        _especialidadManualController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                  validator: (String? value) {
                                                    if (_especialidadPrincipalTratante ==
                                                        null) {
                                                      return 'Seleccione una especialidad';
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            ),
                                            if (_especialidadPrincipalTratante ==
                                                EspecialidadPrincipalTratante
                                                    .otra) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _especialidadManualController,
                                                decoration: _inputDecoration(
                                                  'Especifique la especialidad',
                                                ),
                                                validator: (String? value) {
                                                  if (_especialidadPrincipalTratante ==
                                                          EspecialidadPrincipalTratante
                                                              .otra &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 34,
                                        child: TextFormField(
                                          controller: _diagnosticoController,
                                          decoration: _inputDecoration('Diagnóstico'),
                                          validator: (String? value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 18,
                                        child: Column(
                                          children: <Widget>[
                                            DropdownButtonFormField<String>(
                                              initialValue: _grupoRiesgoSeleccionado,
                                              isExpanded: true,
                                              decoration: _inputDecoration(
                                                'Grupo relacionado de riesgo (GRD)',
                                              ),
                                              items: _grupoRiesgoOptions
                                                  .map(
                                                    (String value) =>
                                                        DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(
                                                            value.toLowerCase(),
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _grupoRiesgoSeleccionado = value;
                                                  if (value == null) {
                                                    _grupoRiesgoController.clear();
                                                    return;
                                                  }
                                                  if (value != _grupoRiesgoOtro) {
                                                    _grupoRiesgoController.text = value;
                                                  } else if (_grupoRiesgoOptions.contains(
                                                    _grupoRiesgoController.text.trim(),
                                                  )) {
                                                    _grupoRiesgoController.clear();
                                                  }
                                                });
                                              },
                                              validator: (String? value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Campo obligatorio';
                                                }
                                                if (value == _grupoRiesgoOtro &&
                                                    _grupoRiesgoController.text
                                                        .trim()
                                                        .isEmpty) {
                                                  return 'Especifique el grupo';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (_grupoRiesgoSeleccionado ==
                                                _grupoRiesgoOtro) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _grupoRiesgoController,
                                                decoration: _inputDecoration(
                                                  'Especifique grupo de riesgo',
                                                ),
                                                validator: (String? value) {
                                                  if (_grupoRiesgoSeleccionado ==
                                                          _grupoRiesgoOtro &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _FieldItem(
                                    flex: 56,
                                    child: DropdownButtonFormField<OrigenPaciente>(
                                      initialValue: _origenPaciente,
                                      decoration: _inputDecoration(
                                        'Origen del paciente',
                                      ),
                                      items:
                                          _sortedByLabel<OrigenPaciente>(
                                                _origenPacienteOptions,
                                                _origenPacienteLabel,
                                              )
                                              .map(
                                                (OrigenPaciente value) =>
                                                    DropdownMenuItem<OrigenPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _origenPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (OrigenPaciente? value) {
                                        setState(() {
                                          _origenPaciente = value;
                                          _syncUnidadFuncionalOrigenDesdeOrigen();
                                          _origenPacienteEditadoManualmente = true;
                                        });
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _diagnosticoController,
                                      decoration: _inputDecoration('Diagnóstico'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        DropdownButtonFormField<String>(
                                          initialValue: _grupoRiesgoSeleccionado,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            'Grupo relacionado de riesgo (GRD)',
                                          ),
                                          items: _grupoRiesgoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(
                                                        value.toLowerCase(),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              _grupoRiesgoSeleccionado = value;
                                              if (value == null) {
                                                _grupoRiesgoController.clear();
                                                return;
                                              }
                                              if (value != _grupoRiesgoOtro) {
                                                _grupoRiesgoController.text = value;
                                              } else if (_grupoRiesgoOptions.contains(
                                                _grupoRiesgoController.text.trim(),
                                              )) {
                                                _grupoRiesgoController.clear();
                                              }
                                            });
                                          },
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            if (value == _grupoRiesgoOtro &&
                                                _grupoRiesgoController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return 'Especifique el grupo';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (_grupoRiesgoSeleccionado ==
                                            _grupoRiesgoOtro) ...<Widget>[
                                          const SizedBox(height: 10),
                                          TextFormField(
                                            controller: _grupoRiesgoController,
                                            decoration: _inputDecoration(
                                              'Especifique grupo de riesgo',
                                            ),
                                            validator: (String? value) {
                                              if (_grupoRiesgoSeleccionado ==
                                                      _grupoRiesgoOtro &&
                                                  (value == null ||
                                                      value.trim().isEmpty)) {
                                                return 'Campo obligatorio';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 20,
                                    child: DropdownButtonFormField<DecisionPad>(
                                      initialValue: _decision,
                                      decoration: _inputDecoration('Resultado de la valoración'),
                                      items: _sortedByLabel<DecisionPad>(
                                          DecisionPad.values,
                                          _decisionPadLabel,
                                        )
                                        .map(
                                          (DecisionPad value) =>
                                              DropdownMenuItem<DecisionPad>(
                                                value: value,
                                                child: Text(
                                                  _decisionPadLabel(value),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                      onChanged: (DecisionPad? value) {
                                        setState(() => _decision = value);
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _observacionesController,
                                      decoration: _inputDecoration('Observaciones'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // Microcopy según selección
                              if (_decision != null) ...[
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    switch (_decision) {
                                      case DecisionPad.ingresoAprobado:
                                        return const Text(
                                          'El paciente cumple criterios y se aprueba su ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF17726D)),
                                        );
                                      case DecisionPad.ingresoNoAprobado:
                                        return const Text(
                                          'El paciente no cumple criterios para ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFFB42318)),
                                        );
                                      case DecisionPad.pendienteValoracion:
                                        return const Text(
                                          'La decisión queda pendiente. Se requiere información adicional o seguimiento.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      case DecisionPad.requiereNuevaValoracion:
                                        return const Text(
                                          'Se requiere revalorar el caso antes de tomar una decisión definitiva.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              ],
                              if (_isEditing) ...<Widget>[
                                const SizedBox(height: 14),
                                _AdaptiveFieldsRow(
                                  children: <_FieldItem>[
                                    _FieldItem(
                                      flex: 20,
                                      child: DropdownButtonFormField<bool>(
                                        initialValue: _esReingreso,
                                        decoration: _inputDecoration(
                                          '¿Es reingreso?',
                                        ),
                                        items: const <DropdownMenuItem<bool>>[
                                          DropdownMenuItem<bool>(
                                            value: false,
                                            child: Text('No'),
                                          ),
                                          DropdownMenuItem<bool>(
                                            value: true,
                                            child: Text('Sí'),
                                          ),
                                        ],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _esReingreso = value ?? false;
                                            if (!_esReingreso) {
                                              _causaReingreso = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    if (_esReingreso)
                                      _FieldItem(
                                        flex: 40,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _causaReingreso,
                                          decoration: _inputDecoration(
                                            'Causa del reingreso',
                                          ),
                                          items: _causaReingresoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() => _causaReingreso = value);
                                          },
                                          validator: (String? value) {
                                            if (_isEditing &&
                                                _esReingreso &&
                                                (value == null ||
                                                    value.trim().isEmpty)) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Datos básicos',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: TextFormField(
                                      controller: _nombreCompletoController,
                                      decoration: _inputDecoration('Nombre completo'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 20,
                                    child: TextFormField(
                                      controller: _identificacionController,
                                      decoration: _inputDecoration('Identificación'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 14,
                                    child: Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            if (query.isEmpty) return _barrioOptions;
                                            return _barrioOptions.where(
                                              (String b) =>
                                                  b.toLowerCase().contains(query),
                                            );
                                          },
                                      displayStringForOption: (String value) => value,
                                      onSelected: (String value) {
                                        setState(() {
                                          _barrioSeleccionado = value;
                                          _barrioSearchController.text = value;
                                          if (value != _barrioOtro) {
                                            _barrioController.text = value;
                                          } else if (_barrioOptions.contains(
                                            _barrioController.text.trim(),
                                          )) {
                                            _barrioController.clear();
                                          }
                                        });
                                      },
                                      fieldViewBuilder:
                                          (
                                            BuildContext ctx,
                                            TextEditingController autoCtrl,
                                            FocusNode focusNode,
                                            VoidCallback onFieldSubmitted,
                                          ) {
                                            if (autoCtrl.text !=
                                                _barrioSearchController.text) {
                                              autoCtrl.text =
                                                  _barrioSearchController.text;
                                            }
                                            return TextFormField(
                                              controller: autoCtrl,
                                              focusNode: focusNode,
                                              decoration: _inputDecoration('Barrio'),
                                              onChanged: (String value) {
                                                _barrioSearchController.text = value;
                                                setState(() {
                                                  if (_barrioOptions.contains(
                                                    value,
                                                  ) &&
                                                    value != _barrioOtro) {
                                                    _barrioSeleccionado = value;
                                                    _barrioController.text = value;
                                                  } else {
                                                    _barrioSeleccionado = null;
                                                  }
                                                });
                                              },
                                            );
                                          },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 8,
                                    child: DropdownButtonFormField<SexoPaciente>(
                                      initialValue: _sexo,
                                      decoration: _inputDecoration('Sexo'),
                                      items:
                                          _sortedByLabel<SexoPaciente>(
                                                SexoPaciente.values,
                                                _sexoPacienteLabel,
                                              )
                                              .map(
                                                (SexoPaciente value) =>
                                                    DropdownMenuItem<SexoPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _sexoPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (SexoPaciente? value) {
                                        setState(() => _sexo = value);
                                      },
                                      validator: (SexoPaciente? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _edadController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _inputDecoration('Edad'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        final int? edad = int.tryParse(value.trim());
                                        if (edad == null) {
                                          return 'Edad inválida';
                                        }
                                        if (edad < 0 || edad > 120) {
                                          return 'Edad inválida';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_barrioSeleccionado == _barrioOtro) ...<Widget>[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _barrioController,
                                  decoration: _inputDecoration('Especifique barrio'),
                                  validator: (String? value) {
                                    if (_barrioSeleccionado == _barrioOtro &&
                                        (value == null || value.trim().isEmpty)) {
                                      return 'Campo obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Aseguramiento',
                          child: _AdaptiveFieldsRow(
                            children: <_FieldItem>[
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<TipoAseguramiento>(
                                  initialValue: _tipoAseguramiento,
                                  decoration: _inputDecoration('Tipo'),
                                  items:
                                      _sortedByLabel<TipoAseguramiento>(
                                            TipoAseguramiento.values,
                                            _tipoAseguramientoLabel,
                                          )
                                          .map(
                                            (TipoAseguramiento value) =>
                                                DropdownMenuItem<TipoAseguramiento>(
                                                  value: value,
                                                  child: Text(
                                                    _tipoAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (TipoAseguramiento? value) {
                                    setState(
                                      () => _onTipoAseguramientoChanged(value),
                                    );
                                  },
                                ),
                              ),
                              _FieldItem(
                                flex: 36,
                                child: () {
                                  if (_tipoAseguramiento ==
                                      TipoAseguramiento.particular) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      readOnly: true,
                                      decoration: _inputDecoration('Aseguradora'),
                                    );
                                  }

                                  if (_tipoAseguramiento == TipoAseguramiento.otro) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      decoration: _inputDecoration(
                                        'Especificar entidad',
                                      ),
                                    );
                                  }

                                  final List<dynamic> options = _aseguradoraOpciones;
                                  if (options.isNotEmpty) {
                                    return DropdownButtonFormField<String>(
                                      initialValue:
                                          options.any(
                                            (dynamic option) =>
                                                option.value ==
                                                _aseguradoraCatalogKey,
                                          )
                                          ? _aseguradoraCatalogKey
                                          : null,
                                      decoration: _inputDecoration('Aseguradora'),
                                      items: options
                                          .map(
                                            (dynamic option) =>
                                                DropdownMenuItem<String>(
                                                  value: option.value as String,
                                                  child: Text(option.label as String),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (String? selectedKey) {
                                        setState(() {
                                          _aseguradoraCatalogKey = selectedKey;
                                          if (selectedKey == null) {
                                            _aseguradoraController.clear();
                                            return;
                                          }
                                          final dynamic match = options.firstWhere(
                                            (dynamic option) =>
                                                option.value == selectedKey,
                                          );
                                          _aseguradoraController.text =
                                              match.label as String;
                                        });
                                      },
                                    );
                                  }

                                  return TextFormField(
                                    controller: _aseguradoraController,
                                    enabled: false,
                                    decoration: _inputDecoration('Aseguradora'),
                                  );
                                }(),
                              ),
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<RegimenAseguramiento>(
                                  initialValue: _regimenAseguramiento,
                                  decoration: _inputDecoration('Régimen'),
                                  items:
                                      _sortedByLabel<RegimenAseguramiento>(
                                            RegimenAseguramiento.values,
                                            _regimenAseguramientoLabel,
                                          )
                                          .map(
                                            (RegimenAseguramiento value) =>
                                                DropdownMenuItem<
                                                  RegimenAseguramiento
                                                >(
                                                  value: value,
                                                  child: Text(
                                                    _regimenAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (RegimenAseguramiento? value) {
                                    setState(() => _regimenAseguramiento = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Captación PAD',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: DropdownButtonFormField<TipoCaptacionPad>(
                                      initialValue: _tipoCaptacionPad,
                                      decoration: _inputDecoration(
                                        'Tipo de captación PAD',
                                      ),
                                      items:
                                          _sortedByLabel<TipoCaptacionPad>(
                                                TipoCaptacionPad.values,
                                                _tipoCaptacionPadLabel,
                                              )
                                              .map(
                                                (TipoCaptacionPad value) =>
                                                    DropdownMenuItem<
                                                      TipoCaptacionPad
                                                    >(
                                                      value: value,
                                                      child: Text(
                                                        _tipoCaptacionPadLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (TipoCaptacionPad? value) {
                                        setState(() {
                                          _tipoCaptacionPad = value;
                                          if (value !=
                                              TipoCaptacionPad
                                                  .presentadoPorServicio) {
                                            _servicioQuePresenta = null;
                                            _ultimoOrigenAutocompletado = null;
                                          } else {
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          }
                                        });
                                      },
                                      validator: (TipoCaptacionPad? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_tipoCaptacionPad ==
                                      TipoCaptacionPad.presentadoPorServicio)
                                    _FieldItem(
                                      flex: 24,
                                      child: DropdownButtonFormField<ServicioQuePresenta>(
                                        key: const ValueKey('servicio_que_presenta'),
                                        initialValue: _servicioQuePresenta,
                                        decoration: _inputDecoration(
                                          'Servicio que presenta',
                                        ),
                                        items:
                                            _sortedByLabel<ServicioQuePresenta>(
                                                  _servicioQuePresentaOptions,
                                                  _servicioQuePresentaLabel,
                                                )
                                                .map(
                                                  (ServicioQuePresenta value) =>
                                                      DropdownMenuItem<
                                                        ServicioQuePresenta
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          _servicioQuePresentaLabel(
                                                            value,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                        onChanged: (ServicioQuePresenta? value) {
                                          setState(() {
                                            _servicioQuePresenta = value;
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          });
                                        },
                                        validator: (ServicioQuePresenta? value) {
                                          if (_tipoCaptacionPad ==
                                                  TipoCaptacionPad
                                                      .presentadoPorServicio &&
                                              value == null) {
                                            return 'Campo obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Contexto clínico',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        Autocomplete<EspecialidadPrincipalTratante>(
                                          optionsBuilder:
                                              (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            final List<
                                              EspecialidadPrincipalTratante
                                            >
                                            options =
                                                _sortedByLabel<
                                                  EspecialidadPrincipalTratante
                                                >(
                                                  EspecialidadPrincipalTratante
                                                      .values,
                                                  _especialidadPrincipalTratanteLabel,
                                                );
                                            if (query.isEmpty) {
                                              return options;
                                            }
                                            return options.where(
                                              (
                                                EspecialidadPrincipalTratante
                                                value,
                                              ) =>
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  ).toLowerCase().contains(query),
                                            );
                                          },
                                          displayStringForOption:
                                              _especialidadPrincipalTratanteLabel,
                                          onSelected:
                                              (EspecialidadPrincipalTratante value) {
                                                setState(() {
                                                  _especialidadPrincipalTratante =
                                                      value;
                                                  _especialidadBusquedaController
                                                      .text =
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  );
                                                  if (value !=
                                                      EspecialidadPrincipalTratante
                                                          .otra) {
                                                    _especialidadManualController
                                                        .clear();
                                                  }
                                                });
                                              },
                                          fieldViewBuilder:
                                              (
                                                BuildContext context,
                                                TextEditingController
                                                textEditingController,
                                                FocusNode focusNode,
                                                VoidCallback onFieldSubmitted,
                                              ) {
                                                if (textEditingController.text !=
                                                    _especialidadBusquedaController
                                                        .text) {
                                                  textEditingController.text =
                                                      _especialidadBusquedaController
                                                          .text;
                                                }
                                                return TextFormField(
                                                  controller: textEditingController,
                                                  focusNode: focusNode,
                                                  decoration: _inputDecoration(
                                                    'Especialidad',
                                                  ),
                                                  onChanged: (String value) {
                                                    _especialidadBusquedaController
                                                        .text = value;
                                                    final EspecialidadPrincipalTratante?
                                                    match = _especialidadFromLabel(
                                                      value,
                                                    );
                                                    setState(() {
                                                      _especialidadPrincipalTratante =
                                                          match;
                                                      if (match !=
                                                          EspecialidadPrincipalTratante
                                                              .otra) {
                                                        _especialidadManualController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                  validator: (String? value) {
                                                    if (_especialidadPrincipalTratante ==
                                                        null) {
                                                      return 'Seleccione una especialidad';
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            ),
                                            if (_especialidadPrincipalTratante ==
                                                EspecialidadPrincipalTratante
                                                    .otra) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _especialidadManualController,
                                                decoration: _inputDecoration(
                                                  'Especifique la especialidad',
                                                ),
                                                validator: (String? value) {
                                                  if (_especialidadPrincipalTratante ==
                                                          EspecialidadPrincipalTratante
                                                              .otra &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 34,
                                        child: TextFormField(
                                          controller: _diagnosticoController,
                                          decoration: _inputDecoration('Diagnóstico'),
                                          validator: (String? value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 18,
                                        child: Column(
                                          children: <Widget>[
                                            DropdownButtonFormField<String>(
                                              initialValue: _grupoRiesgoSeleccionado,
                                              isExpanded: true,
                                              decoration: _inputDecoration(
                                                'Grupo relacionado de riesgo (GRD)',
                                              ),
                                              items: _grupoRiesgoOptions
                                                  .map(
                                                    (String value) =>
                                                        DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(
                                                            value.toLowerCase(),
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _grupoRiesgoSeleccionado = value;
                                                  if (value == null) {
                                                    _grupoRiesgoController.clear();
                                                    return;
                                                  }
                                                  if (value != _grupoRiesgoOtro) {
                                                    _grupoRiesgoController.text = value;
                                                  } else if (_grupoRiesgoOptions.contains(
                                                    _grupoRiesgoController.text.trim(),
                                                  )) {
                                                    _grupoRiesgoController.clear();
                                                  }
                                                });
                                              },
                                              validator: (String? value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Campo obligatorio';
                                                }
                                                if (value == _grupoRiesgoOtro &&
                                                    _grupoRiesgoController.text
                                                        .trim()
                                                        .isEmpty) {
                                                  return 'Especifique el grupo';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (_grupoRiesgoSeleccionado ==
                                                _grupoRiesgoOtro) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _grupoRiesgoController,
                                                decoration: _inputDecoration(
                                                  'Especifique grupo de riesgo',
                                                ),
                                                validator: (String? value) {
                                                  if (_grupoRiesgoSeleccionado ==
                                                          _grupoRiesgoOtro &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _FieldItem(
                                    flex: 56,
                                    child: DropdownButtonFormField<OrigenPaciente>(
                                      initialValue: _origenPaciente,
                                      decoration: _inputDecoration(
                                        'Origen del paciente',
                                      ),
                                      items:
                                          _sortedByLabel<OrigenPaciente>(
                                                _origenPacienteOptions,
                                                _origenPacienteLabel,
                                              )
                                              .map(
                                                (OrigenPaciente value) =>
                                                    DropdownMenuItem<OrigenPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _origenPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (OrigenPaciente? value) {
                                        setState(() {
                                          _origenPaciente = value;
                                          _syncUnidadFuncionalOrigenDesdeOrigen();
                                          _origenPacienteEditadoManualmente = true;
                                        });
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _diagnosticoController,
                                      decoration: _inputDecoration('Diagnóstico'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        DropdownButtonFormField<String>(
                                          initialValue: _grupoRiesgoSeleccionado,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            'Grupo relacionado de riesgo (GRD)',
                                          ),
                                          items: _grupoRiesgoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(
                                                        value.toLowerCase(),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              _grupoRiesgoSeleccionado = value;
                                              if (value == null) {
                                                _grupoRiesgoController.clear();
                                                return;
                                              }
                                              if (value != _grupoRiesgoOtro) {
                                                _grupoRiesgoController.text = value;
                                              } else if (_grupoRiesgoOptions.contains(
                                                _grupoRiesgoController.text.trim(),
                                              )) {
                                                _grupoRiesgoController.clear();
                                              }
                                            });
                                          },
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            if (value == _grupoRiesgoOtro &&
                                                _grupoRiesgoController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return 'Especifique el grupo';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (_grupoRiesgoSeleccionado ==
                                            _grupoRiesgoOtro) ...<Widget>[
                                          const SizedBox(height: 10),
                                          TextFormField(
                                            controller: _grupoRiesgoController,
                                            decoration: _inputDecoration(
                                              'Especifique grupo de riesgo',
                                            ),
                                            validator: (String? value) {
                                              if (_grupoRiesgoSeleccionado ==
                                                      _grupoRiesgoOtro &&
                                                  (value == null ||
                                                      value.trim().isEmpty)) {
                                                return 'Campo obligatorio';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 20,
                                    child: DropdownButtonFormField<DecisionPad>(
                                      initialValue: _decision,
                                      decoration: _inputDecoration('Resultado de la valoración'),
                                      items: _sortedByLabel<DecisionPad>(
                                          DecisionPad.values,
                                          _decisionPadLabel,
                                        )
                                        .map(
                                          (DecisionPad value) =>
                                              DropdownMenuItem<DecisionPad>(
                                                value: value,
                                                child: Text(
                                                  _decisionPadLabel(value),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                      onChanged: (DecisionPad? value) {
                                        setState(() => _decision = value);
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _observacionesController,
                                      decoration: _inputDecoration('Observaciones'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // Microcopy según selección
                              if (_decision != null) ...[
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    switch (_decision) {
                                      case DecisionPad.ingresoAprobado:
                                        return const Text(
                                          'El paciente cumple criterios y se aprueba su ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF17726D)),
                                        );
                                      case DecisionPad.ingresoNoAprobado:
                                        return const Text(
                                          'El paciente no cumple criterios para ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFFB42318)),
                                        );
                                      case DecisionPad.pendienteValoracion:
                                        return const Text(
                                          'La decisión queda pendiente. Se requiere información adicional o seguimiento.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      case DecisionPad.requiereNuevaValoracion:
                                        return const Text(
                                          'Se requiere revalorar el caso antes de tomar una decisión definitiva.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              ],
                              if (_isEditing) ...<Widget>[
                                const SizedBox(height: 14),
                                _AdaptiveFieldsRow(
                                  children: <_FieldItem>[
                                    _FieldItem(
                                      flex: 20,
                                      child: DropdownButtonFormField<bool>(
                                        initialValue: _esReingreso,
                                        decoration: _inputDecoration(
                                          '¿Es reingreso?',
                                        ),
                                        items: const <DropdownMenuItem<bool>>[
                                          DropdownMenuItem<bool>(
                                            value: false,
                                            child: Text('No'),
                                          ),
                                          DropdownMenuItem<bool>(
                                            value: true,
                                            child: Text('Sí'),
                                          ),
                                        ],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _esReingreso = value ?? false;
                                            if (!_esReingreso) {
                                              _causaReingreso = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    if (_esReingreso)
                                      _FieldItem(
                                        flex: 40,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _causaReingreso,
                                          decoration: _inputDecoration(
                                            'Causa del reingreso',
                                          ),
                                          items: _causaReingresoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() => _causaReingreso = value);
                                          },
                                          validator: (String? value) {
                                            if (_isEditing &&
                                                _esReingreso &&
                                                (value == null ||
                                                    value.trim().isEmpty)) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Datos básicos',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: TextFormField(
                                      controller: _nombreCompletoController,
                                      decoration: _inputDecoration('Nombre completo'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 20,
                                    child: TextFormField(
                                      controller: _identificacionController,
                                      decoration: _inputDecoration('Identificación'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 14,
                                    child: Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            if (query.isEmpty) return _barrioOptions;
                                            return _barrioOptions.where(
                                              (String b) =>
                                                  b.toLowerCase().contains(query),
                                            );
                                          },
                                      displayStringForOption: (String value) => value,
                                      onSelected: (String value) {
                                        setState(() {
                                          _barrioSeleccionado = value;
                                          _barrioSearchController.text = value;
                                          if (value != _barrioOtro) {
                                            _barrioController.text = value;
                                          } else if (_barrioOptions.contains(
                                            _barrioController.text.trim(),
                                          )) {
                                            _barrioController.clear();
                                          }
                                        });
                                      },
                                      fieldViewBuilder:
                                          (
                                            BuildContext ctx,
                                            TextEditingController autoCtrl,
                                            FocusNode focusNode,
                                            VoidCallback onFieldSubmitted,
                                          ) {
                                            if (autoCtrl.text !=
                                                _barrioSearchController.text) {
                                              autoCtrl.text =
                                                  _barrioSearchController.text;
                                            }
                                            return TextFormField(
                                              controller: autoCtrl,
                                              focusNode: focusNode,
                                              decoration: _inputDecoration('Barrio'),
                                              onChanged: (String value) {
                                                _barrioSearchController.text = value;
                                                setState(() {
                                                  if (_barrioOptions.contains(
                                                    value,
                                                  ) &&
                                                    value != _barrioOtro) {
                                                    _barrioSeleccionado = value;
                                                    _barrioController.text = value;
                                                  } else {
                                                    _barrioSeleccionado = null;
                                                  }
                                                });
                                              },
                                            );
                                          },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 8,
                                    child: DropdownButtonFormField<SexoPaciente>(
                                      initialValue: _sexo,
                                      decoration: _inputDecoration('Sexo'),
                                      items:
                                          _sortedByLabel<SexoPaciente>(
                                                SexoPaciente.values,
                                                _sexoPacienteLabel,
                                              )
                                              .map(
                                                (SexoPaciente value) =>
                                                    DropdownMenuItem<SexoPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _sexoPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (SexoPaciente? value) {
                                        setState(() => _sexo = value);
                                      },
                                      validator: (SexoPaciente? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _edadController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _inputDecoration('Edad'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        final int? edad = int.tryParse(value.trim());
                                        if (edad == null) {
                                          return 'Edad inválida';
                                        }
                                        if (edad < 0 || edad > 120) {
                                          return 'Edad inválida';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_barrioSeleccionado == _barrioOtro) ...<Widget>[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _barrioController,
                                  decoration: _inputDecoration('Especifique barrio'),
                                  validator: (String? value) {
                                    if (_barrioSeleccionado == _barrioOtro &&
                                        (value == null || value.trim().isEmpty)) {
                                      return 'Campo obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Aseguramiento',
                          child: _AdaptiveFieldsRow(
                            children: <_FieldItem>[
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<TipoAseguramiento>(
                                  initialValue: _tipoAseguramiento,
                                  decoration: _inputDecoration('Tipo'),
                                  items:
                                      _sortedByLabel<TipoAseguramiento>(
                                            TipoAseguramiento.values,
                                            _tipoAseguramientoLabel,
                                          )
                                          .map(
                                            (TipoAseguramiento value) =>
                                                DropdownMenuItem<TipoAseguramiento>(
                                                  value: value,
                                                  child: Text(
                                                    _tipoAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (TipoAseguramiento? value) {
                                    setState(
                                      () => _onTipoAseguramientoChanged(value),
                                    );
                                  },
                                ),
                              ),
                              _FieldItem(
                                flex: 36,
                                child: () {
                                  if (_tipoAseguramiento ==
                                      TipoAseguramiento.particular) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      readOnly: true,
                                      decoration: _inputDecoration('Aseguradora'),
                                    );
                                  }

                                  if (_tipoAseguramiento == TipoAseguramiento.otro) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      decoration: _inputDecoration(
                                        'Especificar entidad',
                                      ),
                                    );
                                  }

                                  final List<dynamic> options = _aseguradoraOpciones;
                                  if (options.isNotEmpty) {
                                    return DropdownButtonFormField<String>(
                                      initialValue:
                                          options.any(
                                            (dynamic option) =>
                                                option.value ==
                                                _aseguradoraCatalogKey,
                                          )
                                          ? _aseguradoraCatalogKey
                                          : null,
                                      decoration: _inputDecoration('Aseguradora'),
                                      items: options
                                          .map(
                                            (dynamic option) =>
                                                DropdownMenuItem<String>(
                                                  value: option.value as String,
                                                  child: Text(option.label as String),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (String? selectedKey) {
                                        setState(() {
                                          _aseguradoraCatalogKey = selectedKey;
                                          if (selectedKey == null) {
                                            _aseguradoraController.clear();
                                            return;
                                          }
                                          final dynamic match = options.firstWhere(
                                            (dynamic option) =>
                                                option.value == selectedKey,
                                          );
                                          _aseguradoraController.text =
                                              match.label as String;
                                        });
                                      },
                                    );
                                  }

                                  return TextFormField(
                                    controller: _aseguradoraController,
                                    enabled: false,
                                    decoration: _inputDecoration('Aseguradora'),
                                  );
                                }(),
                              ),
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<RegimenAseguramiento>(
                                  initialValue: _regimenAseguramiento,
                                  decoration: _inputDecoration('Régimen'),
                                  items:
                                      _sortedByLabel<RegimenAseguramiento>(
                                            RegimenAseguramiento.values,
                                            _regimenAseguramientoLabel,
                                          )
                                          .map(
                                            (RegimenAseguramiento value) =>
                                                DropdownMenuItem<
                                                  RegimenAseguramiento
                                                >(
                                                  value: value,
                                                  child: Text(
                                                    _regimenAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (RegimenAseguramiento? value) {
                                    setState(() => _regimenAseguramiento = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Captación PAD',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: DropdownButtonFormField<TipoCaptacionPad>(
                                      initialValue: _tipoCaptacionPad,
                                      decoration: _inputDecoration(
                                        'Tipo de captación PAD',
                                      ),
                                      items:
                                          _sortedByLabel<TipoCaptacionPad>(
                                                TipoCaptacionPad.values,
                                                _tipoCaptacionPadLabel,
                                              )
                                              .map(
                                                (TipoCaptacionPad value) =>
                                                    DropdownMenuItem<
                                                      TipoCaptacionPad
                                                    >(
                                                      value: value,
                                                      child: Text(
                                                        _tipoCaptacionPadLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (TipoCaptacionPad? value) {
                                        setState(() {
                                          _tipoCaptacionPad = value;
                                          if (value !=
                                              TipoCaptacionPad
                                                  .presentadoPorServicio) {
                                            _servicioQuePresenta = null;
                                            _ultimoOrigenAutocompletado = null;
                                          } else {
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          }
                                        });
                                      },
                                      validator: (TipoCaptacionPad? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_tipoCaptacionPad ==
                                      TipoCaptacionPad.presentadoPorServicio)
                                    _FieldItem(
                                      flex: 24,
                                      child: DropdownButtonFormField<ServicioQuePresenta>(
                                        key: const ValueKey('servicio_que_presenta'),
                                        initialValue: _servicioQuePresenta,
                                        decoration: _inputDecoration(
                                          'Servicio que presenta',
                                        ),
                                        items:
                                            _sortedByLabel<ServicioQuePresenta>(
                                                  _servicioQuePresentaOptions,
                                                  _servicioQuePresentaLabel,
                                                )
                                                .map(
                                                  (ServicioQuePresenta value) =>
                                                      DropdownMenuItem<
                                                        ServicioQuePresenta
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          _servicioQuePresentaLabel(
                                                            value,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                        onChanged: (ServicioQuePresenta? value) {
                                          setState(() {
                                            _servicioQuePresenta = value;
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          });
                                        },
                                        validator: (ServicioQuePresenta? value) {
                                          if (_tipoCaptacionPad ==
                                                  TipoCaptacionPad
                                                      .presentadoPorServicio &&
                                              value == null) {
                                            return 'Campo obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Contexto clínico',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        Autocomplete<EspecialidadPrincipalTratante>(
                                          optionsBuilder:
                                              (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            final List<
                                              EspecialidadPrincipalTratante
                                            >
                                            options =
                                                _sortedByLabel<
                                                  EspecialidadPrincipalTratante
                                                >(
                                                  EspecialidadPrincipalTratante
                                                      .values,
                                                  _especialidadPrincipalTratanteLabel,
                                                );
                                            if (query.isEmpty) {
                                              return options;
                                            }
                                            return options.where(
                                              (
                                                EspecialidadPrincipalTratante
                                                value,
                                              ) =>
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  ).toLowerCase().contains(query),
                                            );
                                          },
                                          displayStringForOption:
                                              _especialidadPrincipalTratanteLabel,
                                          onSelected:
                                              (EspecialidadPrincipalTratante value) {
                                                setState(() {
                                                  _especialidadPrincipalTratante =
                                                      value;
                                                  _especialidadBusquedaController
                                                      .text =
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  );
                                                  if (value !=
                                                      EspecialidadPrincipalTratante
                                                          .otra) {
                                                    _especialidadManualController
                                                        .clear();
                                                  }
                                                });
                                              },
                                          fieldViewBuilder:
                                              (
                                                BuildContext context,
                                                TextEditingController
                                                textEditingController,
                                                FocusNode focusNode,
                                                VoidCallback onFieldSubmitted,
                                              ) {
                                                if (textEditingController.text !=
                                                    _especialidadBusquedaController
                                                        .text) {
                                                  textEditingController.text =
                                                      _especialidadBusquedaController
                                                          .text;
                                                }
                                                return TextFormField(
                                                  controller: textEditingController,
                                                  focusNode: focusNode,
                                                  decoration: _inputDecoration(
                                                    'Especialidad',
                                                  ),
                                                  onChanged: (String value) {
                                                    _especialidadBusquedaController
                                                        .text = value;
                                                    final EspecialidadPrincipalTratante?
                                                    match = _especialidadFromLabel(
                                                      value,
                                                    );
                                                    setState(() {
                                                      _especialidadPrincipalTratante =
                                                          match;
                                                      if (match !=
                                                          EspecialidadPrincipalTratante
                                                              .otra) {
                                                        _especialidadManualController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                  validator: (String? value) {
                                                    if (_especialidadPrincipalTratante ==
                                                        null) {
                                                      return 'Seleccione una especialidad';
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            ),
                                            if (_especialidadPrincipalTratante ==
                                                EspecialidadPrincipalTratante
                                                    .otra) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _especialidadManualController,
                                                decoration: _inputDecoration(
                                                  'Especifique la especialidad',
                                                ),
                                                validator: (String? value) {
                                                  if (_especialidadPrincipalTratante ==
                                                          EspecialidadPrincipalTratante
                                                              .otra &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 34,
                                        child: TextFormField(
                                          controller: _diagnosticoController,
                                          decoration: _inputDecoration('Diagnóstico'),
                                          validator: (String? value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 18,
                                        child: Column(
                                          children: <Widget>[
                                            DropdownButtonFormField<String>(
                                              initialValue: _grupoRiesgoSeleccionado,
                                              isExpanded: true,
                                              decoration: _inputDecoration(
                                                'Grupo relacionado de riesgo (GRD)',
                                              ),
                                              items: _grupoRiesgoOptions
                                                  .map(
                                                    (String value) =>
                                                        DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(
                                                            value.toLowerCase(),
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _grupoRiesgoSeleccionado = value;
                                                  if (value == null) {
                                                    _grupoRiesgoController.clear();
                                                    return;
                                                  }
                                                  if (value != _grupoRiesgoOtro) {
                                                    _grupoRiesgoController.text = value;
                                                  } else if (_grupoRiesgoOptions.contains(
                                                    _grupoRiesgoController.text.trim(),
                                                  )) {
                                                    _grupoRiesgoController.clear();
                                                  }
                                                });
                                              },
                                              validator: (String? value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Campo obligatorio';
                                                }
                                                if (value == _grupoRiesgoOtro &&
                                                    _grupoRiesgoController.text
                                                        .trim()
                                                        .isEmpty) {
                                                  return 'Especifique el grupo';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (_grupoRiesgoSeleccionado ==
                                                _grupoRiesgoOtro) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _grupoRiesgoController,
                                                decoration: _inputDecoration(
                                                  'Especifique grupo de riesgo',
                                                ),
                                                validator: (String? value) {
                                                  if (_grupoRiesgoSeleccionado ==
                                                          _grupoRiesgoOtro &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _FieldItem(
                                    flex: 56,
                                    child: DropdownButtonFormField<OrigenPaciente>(
                                      initialValue: _origenPaciente,
                                      decoration: _inputDecoration(
                                        'Origen del paciente',
                                      ),
                                      items:
                                          _sortedByLabel<OrigenPaciente>(
                                                _origenPacienteOptions,
                                                _origenPacienteLabel,
                                              )
                                              .map(
                                                (OrigenPaciente value) =>
                                                    DropdownMenuItem<OrigenPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _origenPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (OrigenPaciente? value) {
                                        setState(() {
                                          _origenPaciente = value;
                                          _syncUnidadFuncionalOrigenDesdeOrigen();
                                          _origenPacienteEditadoManualmente = true;
                                        });
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _diagnosticoController,
                                      decoration: _inputDecoration('Diagnóstico'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        DropdownButtonFormField<String>(
                                          initialValue: _grupoRiesgoSeleccionado,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            'Grupo relacionado de riesgo (GRD)',
                                          ),
                                          items: _grupoRiesgoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(
                                                        value.toLowerCase(),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              _grupoRiesgoSeleccionado = value;
                                              if (value == null) {
                                                _grupoRiesgoController.clear();
                                                return;
                                              }
                                              if (value != _grupoRiesgoOtro) {
                                                _grupoRiesgoController.text = value;
                                              } else if (_grupoRiesgoOptions.contains(
                                                _grupoRiesgoController.text.trim(),
                                              )) {
                                                _grupoRiesgoController.clear();
                                              }
                                            });
                                          },
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            if (value == _grupoRiesgoOtro &&
                                                _grupoRiesgoController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return 'Especifique el grupo';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (_grupoRiesgoSeleccionado ==
                                            _grupoRiesgoOtro) ...<Widget>[
                                          const SizedBox(height: 10),
                                          TextFormField(
                                            controller: _grupoRiesgoController,
                                            decoration: _inputDecoration(
                                              'Especifique grupo de riesgo',
                                            ),
                                            validator: (String? value) {
                                              if (_grupoRiesgoSeleccionado ==
                                                      _grupoRiesgoOtro &&
                                                  (value == null ||
                                                      value.trim().isEmpty)) {
                                                return 'Campo obligatorio';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 20,
                                    child: DropdownButtonFormField<DecisionPad>(
                                      initialValue: _decision,
                                      decoration: _inputDecoration('Resultado de la valoración'),
                                      items: _sortedByLabel<DecisionPad>(
                                          DecisionPad.values,
                                          _decisionPadLabel,
                                        )
                                        .map(
                                          (DecisionPad value) =>
                                              DropdownMenuItem<DecisionPad>(
                                                value: value,
                                                child: Text(
                                                  _decisionPadLabel(value),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                      onChanged: (DecisionPad? value) {
                                        setState(() => _decision = value);
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _observacionesController,
                                      decoration: _inputDecoration('Observaciones'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // Microcopy según selección
                              if (_decision != null) ...[
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    switch (_decision) {
                                      case DecisionPad.ingresoAprobado:
                                        return const Text(
                                          'El paciente cumple criterios y se aprueba su ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF17726D)),
                                        );
                                      case DecisionPad.ingresoNoAprobado:
                                        return const Text(
                                          'El paciente no cumple criterios para ingreso al PAD.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFFB42318)),
                                        );
                                      case DecisionPad.pendienteValoracion:
                                        return const Text(
                                          'La decisión queda pendiente. Se requiere información adicional o seguimiento.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      case DecisionPad.requiereNuevaValoracion:
                                        return const Text(
                                          'Se requiere revalorar el caso antes de tomar una decisión definitiva.',
                                          style: TextStyle(fontSize: 13.5, color: Color(0xFF946200)),
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              ],
                              if (_isEditing) ...<Widget>[
                                const SizedBox(height: 14),
                                _AdaptiveFieldsRow(
                                  children: <_FieldItem>[
                                    _FieldItem(
                                      flex: 20,
                                      child: DropdownButtonFormField<bool>(
                                        initialValue: _esReingreso,
                                        decoration: _inputDecoration(
                                          '¿Es reingreso?',
                                        ),
                                        items: const <DropdownMenuItem<bool>>[
                                          DropdownMenuItem<bool>(
                                            value: false,
                                            child: Text('No'),
                                          ),
                                          DropdownMenuItem<bool>(
                                            value: true,
                                            child: Text('Sí'),
                                          ),
                                        ],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _esReingreso = value ?? false;
                                            if (!_esReingreso) {
                                              _causaReingreso = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    if (_esReingreso)
                                      _FieldItem(
                                        flex: 40,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _causaReingreso,
                                          decoration: _inputDecoration(
                                            'Causa del reingreso',
                                          ),
                                          items: _causaReingresoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() => _causaReingreso = value);
                                          },
                                          validator: (String? value) {
                                            if (_isEditing &&
                                                _esReingreso &&
                                                (value == null ||
                                                    value.trim().isEmpty)) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Datos básicos',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: TextFormField(
                                      controller: _nombreCompletoController,
                                      decoration: _inputDecoration('Nombre completo'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 20,
                                    child: TextFormField(
                                      controller: _identificacionController,
                                      decoration: _inputDecoration('Identificación'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 14,
                                    child: Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            if (query.isEmpty) return _barrioOptions;
                                            return _barrioOptions.where(
                                              (String b) =>
                                                  b.toLowerCase().contains(query),
                                            );
                                          },
                                      displayStringForOption: (String value) => value,
                                      onSelected: (String value) {
                                        setState(() {
                                          _barrioSeleccionado = value;
                                          _barrioSearchController.text = value;
                                          if (value != _barrioOtro) {
                                            _barrioController.text = value;
                                          } else if (_barrioOptions.contains(
                                            _barrioController.text.trim(),
                                          )) {
                                            _barrioController.clear();
                                          }
                                        });
                                      },
                                      fieldViewBuilder:
                                          (
                                            BuildContext ctx,
                                            TextEditingController autoCtrl,
                                            FocusNode focusNode,
                                            VoidCallback onFieldSubmitted,
                                          ) {
                                            if (autoCtrl.text !=
                                                _barrioSearchController.text) {
                                              autoCtrl.text =
                                                  _barrioSearchController.text;
                                            }
                                            return TextFormField(
                                              controller: autoCtrl,
                                              focusNode: focusNode,
                                              decoration: _inputDecoration('Barrio'),
                                              onChanged: (String value) {
                                                _barrioSearchController.text = value;
                                                setState(() {
                                                  if (_barrioOptions.contains(
                                                    value,
                                                  ) &&
                                                    value != _barrioOtro) {
                                                    _barrioSeleccionado = value;
                                                    _barrioController.text = value;
                                                  } else {
                                                    _barrioSeleccionado = null;
                                                  }
                                                });
                                              },
                                            );
                                          },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 8,
                                    child: DropdownButtonFormField<SexoPaciente>(
                                      initialValue: _sexo,
                                      decoration: _inputDecoration('Sexo'),
                                      items:
                                          _sortedByLabel<SexoPaciente>(
                                                SexoPaciente.values,
                                                _sexoPacienteLabel,
                                              )
                                              .map(
                                                (SexoPaciente value) =>
                                                    DropdownMenuItem<SexoPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _sexoPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (SexoPaciente? value) {
                                        setState(() => _sexo = value);
                                      },
                                      validator: (SexoPaciente? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _edadController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _inputDecoration('Edad'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        final int? edad = int.tryParse(value.trim());
                                        if (edad == null) {
                                          return 'Edad inválida';
                                        }
                                        if (edad < 0 || edad > 120) {
                                          return 'Edad inválida';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_barrioSeleccionado == _barrioOtro) ...<Widget>[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _barrioController,
                                  decoration: _inputDecoration('Especifique barrio'),
                                  validator: (String? value) {
                                    if (_barrioSeleccionado == _barrioOtro &&
                                        (value == null || value.trim().isEmpty)) {
                                      return 'Campo obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Aseguramiento',
                          child: _AdaptiveFieldsRow(
                            children: <_FieldItem>[
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<TipoAseguramiento>(
                                  initialValue: _tipoAseguramiento,
                                  decoration: _inputDecoration('Tipo'),
                                  items:
                                      _sortedByLabel<TipoAseguramiento>(
                                            TipoAseguramiento.values,
                                            _tipoAseguramientoLabel,
                                          )
                                          .map(
                                            (TipoAseguramiento value) =>
                                                DropdownMenuItem<TipoAseguramiento>(
                                                  value: value,
                                                  child: Text(
                                                    _tipoAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (TipoAseguramiento? value) {
                                    setState(
                                      () => _onTipoAseguramientoChanged(value),
                                    );
                                  },
                                ),
                              ),
                              _FieldItem(
                                flex: 36,
                                child: () {
                                  if (_tipoAseguramiento ==
                                      TipoAseguramiento.particular) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      readOnly: true,
                                      decoration: _inputDecoration('Aseguradora'),
                                    );
                                  }

                                  if (_tipoAseguramiento == TipoAseguramiento.otro) {
                                    return TextFormField(
                                      controller: _aseguradoraController,
                                      decoration: _inputDecoration(
                                        'Especificar entidad',
                                      ),
                                    );
                                  }

                                  final List<dynamic> options = _aseguradoraOpciones;
                                  if (options.isNotEmpty) {
                                    return DropdownButtonFormField<String>(
                                      initialValue:
                                          options.any(
                                            (dynamic option) =>
                                                option.value ==
                                                _aseguradoraCatalogKey,
                                          )
                                          ? _aseguradoraCatalogKey
                                          : null,
                                      decoration: _inputDecoration('Aseguradora'),
                                      items: options
                                          .map(
                                            (dynamic option) =>
                                                DropdownMenuItem<String>(
                                                  value: option.value as String,
                                                  child: Text(option.label as String),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (String? selectedKey) {
                                        setState(() {
                                          _aseguradoraCatalogKey = selectedKey;
                                          if (selectedKey == null) {
                                            _aseguradoraController.clear();
                                            return;
                                          }
                                          final dynamic match = options.firstWhere(
                                            (dynamic option) =>
                                                option.value == selectedKey,
                                          );
                                          _aseguradoraController.text =
                                              match.label as String;
                                        });
                                      },
                                    );
                                  }

                                  return TextFormField(
                                    controller: _aseguradoraController,
                                    enabled: false,
                                    decoration: _inputDecoration('Aseguradora'),
                                  );
                                }(),
                              ),
                              _FieldItem(
                                flex: 16,
                                child: DropdownButtonFormField<RegimenAseguramiento>(
                                  initialValue: _regimenAseguramiento,
                                  decoration: _inputDecoration('Régimen'),
                                  items:
                                      _sortedByLabel<RegimenAseguramiento>(
                                            RegimenAseguramiento.values,
                                            _regimenAseguramientoLabel,
                                          )
                                          .map(
                                            (RegimenAseguramiento value) =>
                                                DropdownMenuItem<
                                                  RegimenAseguramiento
                                                >(
                                                  value: value,
                                                  child: Text(
                                                    _regimenAseguramientoLabel(value),
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (RegimenAseguramiento? value) {
                                    setState(() => _regimenAseguramiento = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Captación PAD',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 24,
                                    child: DropdownButtonFormField<TipoCaptacionPad>(
                                      initialValue: _tipoCaptacionPad,
                                      decoration: _inputDecoration(
                                        'Tipo de captación PAD',
                                      ),
                                      items:
                                          _sortedByLabel<TipoCaptacionPad>(
                                                TipoCaptacionPad.values,
                                                _tipoCaptacionPadLabel,
                                              )
                                              .map(
                                                (TipoCaptacionPad value) =>
                                                    DropdownMenuItem<
                                                      TipoCaptacionPad
                                                    >(
                                                      value: value,
                                                      child: Text(
                                                        _tipoCaptacionPadLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (TipoCaptacionPad? value) {
                                        setState(() {
                                          _tipoCaptacionPad = value;
                                          if (value !=
                                              TipoCaptacionPad
                                                  .presentadoPorServicio) {
                                            _servicioQuePresenta = null;
                                            _ultimoOrigenAutocompletado = null;
                                          } else {
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          }
                                        });
                                      },
                                      validator: (TipoCaptacionPad? value) {
                                        if (value == null) return 'Campo obligatorio';
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_tipoCaptacionPad ==
                                      TipoCaptacionPad.presentadoPorServicio)
                                    _FieldItem(
                                      flex: 24,
                                      child: DropdownButtonFormField<ServicioQuePresenta>(
                                        key: const ValueKey('servicio_que_presenta'),
                                        initialValue: _servicioQuePresenta,
                                        decoration: _inputDecoration(
                                          'Servicio que presenta',
                                        ),
                                        items:
                                            _sortedByLabel<ServicioQuePresenta>(
                                                  _servicioQuePresentaOptions,
                                                  _servicioQuePresentaLabel,
                                                )
                                                .map(
                                                  (ServicioQuePresenta value) =>
                                                      DropdownMenuItem<
                                                        ServicioQuePresenta
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          _servicioQuePresentaLabel(
                                                            value,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                        onChanged: (ServicioQuePresenta? value) {
                                          setState(() {
                                            _servicioQuePresenta = value;
                                            _autocompletarOrigenDesdeServicioSiAplica();
                                          });
                                        },
                                        validator: (ServicioQuePresenta? value) {
                                          if (_tipoCaptacionPad ==
                                                  TipoCaptacionPad
                                                      .presentadoPorServicio &&
                                              value == null) {
                                            return 'Campo obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Contexto clínico',
                          child: Column(
                            children: <Widget>[
                              _AdaptiveFieldsRow(
                                children: <_FieldItem>[
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        Autocomplete<EspecialidadPrincipalTratante>(
                                          optionsBuilder:
                                              (TextEditingValue textEditingValue) {
                                            final String query = textEditingValue
                                                .text
                                                .trim()
                                                .toLowerCase();
                                            final List<
                                              EspecialidadPrincipalTratante
                                            >
                                            options =
                                                _sortedByLabel<
                                                  EspecialidadPrincipalTratante
                                                >(
                                                  EspecialidadPrincipalTratante
                                                      .values,
                                                  _especialidadPrincipalTratanteLabel,
                                                );
                                            if (query.isEmpty) {
                                              return options;
                                            }
                                            return options.where(
                                              (
                                                EspecialidadPrincipalTratante
                                                value,
                                              ) =>
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  ).toLowerCase().contains(query),
                                            );
                                          },
                                          displayStringForOption:
                                              _especialidadPrincipalTratanteLabel,
                                          onSelected:
                                              (EspecialidadPrincipalTratante value) {
                                                setState(() {
                                                  _especialidadPrincipalTratante =
                                                      value;
                                                  _especialidadBusquedaController
                                                      .text =
                                                  _especialidadPrincipalTratanteLabel(
                                                    value,
                                                  );
                                                  if (value !=
                                                      EspecialidadPrincipalTratante
                                                          .otra) {
                                                    _especialidadManualController
                                                        .clear();
                                                  }
                                                });
                                              },
                                          fieldViewBuilder:
                                              (
                                                BuildContext context,
                                                TextEditingController
                                                textEditingController,
                                                FocusNode focusNode,
                                                VoidCallback onFieldSubmitted,
                                              ) {
                                                if (textEditingController.text !=
                                                    _especialidadBusquedaController
                                                        .text) {
                                                  textEditingController.text =
                                                      _especialidadBusquedaController
                                                          .text;
                                                }
                                                return TextFormField(
                                                  controller: textEditingController,
                                                  focusNode: focusNode,
                                                  decoration: _inputDecoration(
                                                    'Especialidad',
                                                  ),
                                                  onChanged: (String value) {
                                                    _especialidadBusquedaController
                                                        .text = value;
                                                    final EspecialidadPrincipalTratante?
                                                    match = _especialidadFromLabel(
                                                      value,
                                                    );
                                                    setState(() {
                                                      _especialidadPrincipalTratante =
                                                          match;
                                                      if (match !=
                                                          EspecialidadPrincipalTratante
                                                              .otra) {
                                                        _especialidadManualController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                  validator: (String? value) {
                                                    if (_especialidadPrincipalTratante ==
                                                        null) {
                                                      return 'Seleccione una especialidad';
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            ),
                                            if (_especialidadPrincipalTratante ==
                                                EspecialidadPrincipalTratante
                                                    .otra) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _especialidadManualController,
                                                decoration: _inputDecoration(
                                                  'Especifique la especialidad',
                                                ),
                                                validator: (String? value) {
                                                  if (_especialidadPrincipalTratante ==
                                                          EspecialidadPrincipalTratante
                                                              .otra &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 34,
                                        child: TextFormField(
                                          controller: _diagnosticoController,
                                          decoration: _inputDecoration('Diagnóstico'),
                                          validator: (String? value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      _FieldItem(
                                        flex: 18,
                                        child: Column(
                                          children: <Widget>[
                                            DropdownButtonFormField<String>(
                                              initialValue: _grupoRiesgoSeleccionado,
                                              isExpanded: true,
                                              decoration: _inputDecoration(
                                                'Grupo relacionado de riesgo (GRD)',
                                              ),
                                              items: _grupoRiesgoOptions
                                                  .map(
                                                    (String value) =>
                                                        DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(
                                                            value.toLowerCase(),
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _grupoRiesgoSeleccionado = value;
                                                  if (value == null) {
                                                    _grupoRiesgoController.clear();
                                                    return;
                                                  }
                                                  if (value != _grupoRiesgoOtro) {
                                                    _grupoRiesgoController.text = value;
                                                  } else if (_grupoRiesgoOptions.contains(
                                                    _grupoRiesgoController.text.trim(),
                                                  )) {
                                                    _grupoRiesgoController.clear();
                                                  }
                                                });
                                              },
                                              validator: (String? value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Campo obligatorio';
                                                }
                                                if (value == _grupoRiesgoOtro &&
                                                    _grupoRiesgoController.text
                                                        .trim()
                                                        .isEmpty) {
                                                  return 'Especifique el grupo';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (_grupoRiesgoSeleccionado ==
                                                _grupoRiesgoOtro) ...<Widget>[
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: _grupoRiesgoController,
                                                decoration: _inputDecoration(
                                                  'Especifique grupo de riesgo',
                                                ),
                                                validator: (String? value) {
                                                  if (_grupoRiesgoSeleccionado ==
                                                          _grupoRiesgoOtro &&
                                                      (value == null ||
                                                          value.trim().isEmpty)) {
                                                    return 'Campo obligatorio';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _FieldItem(
                                    flex: 56,
                                    child: DropdownButtonFormField<OrigenPaciente>(
                                      initialValue: _origenPaciente,
                                      decoration: _inputDecoration(
                                        'Origen del paciente',
                                      ),
                                      items:
                                          _sortedByLabel<OrigenPaciente>(
                                                _origenPacienteOptions,
                                                _origenPacienteLabel,
                                              )
                                              .map(
                                                (OrigenPaciente value) =>
                                                    DropdownMenuItem<OrigenPaciente>(
                                                      value: value,
                                                      child: Text(
                                                        _origenPacienteLabel(value),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (OrigenPaciente? value) {
                                        setState(() {
                                          _origenPaciente = value;
                                          _syncUnidadFuncionalOrigenDesdeOrigen();
                                          _origenPacienteEditadoManualmente = true;
                                        });
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 40,
                                    child: TextFormField(
                                      controller: _diagnosticoController,
                                      decoration: _inputDecoration('Diagnóstico'),
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _FieldItem(
                                    flex: 18,
                                    child: Column(
                                      children: <Widget>[
                                        DropdownButtonFormField<String>(
                                          initialValue: _grupoRiesgoSeleccionado,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            'Grupo relacionado de riesgo (GRD)',
                                          ),
                                          items: _grupoRiesgoOptions
                                              .map(
                                                (String value) =>
                                                    DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(
                                                        value.toLowerCase(),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            setState(() {
                                              _grupoRiesgoSeleccionado = value;
                                              if (value == null) {
                                                _grupoRiesgoController.clear();
                                                return;
                                              }
                                              if (value != _grupoRiesgoOtro) {
                                                _grupoRiesgoController.text = value;
                                              } else if (_grupoRiesgoOptions.contains(
                                                _grupoRiesgoController.text.trim(),
                                              )) {
                                                _grupoRiesgoController.clear();
                                              }
                                            });
                                          },
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Campo obligatorio';
                                            }
                                            if (value == _grupoRiesgoOtro &&
                                                _grupoR