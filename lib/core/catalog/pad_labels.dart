class PadUiLabels {
  const PadUiLabels._();

  static const String dashboardTitle = 'Dashboard PAD';
  static const String newCaseTitle = 'Nuevo caso PAD';
  static const String editCaseTitle = 'Editar caso PAD';
  static const String casesModuleTitle = 'Casos PAD';

  static const String casesPendingDefinition = 'Casos por definir';
  static const String caseReassessed = 'Caso revalorado';

  static const String newCase = 'Nuevo caso';
  static const String saveCase = 'Guardar caso';
  static const String saveChanges = 'Guardar cambios';
  static const String cancel = 'Cancelar';

  static const String caseSaved = 'Caso guardado';
  static const String caseApprovedForAdmission = 'Caso aprobado para ingreso';

  static const String noCases = 'No hay casos';
  static const String createFirstCase = 'Crea tu primer caso';
  static const String selectCase = 'Selecciona un caso';
  static const String saveCaseError = 'No se pudo guardar el caso';

  static const String admissionReasonField = 'Motivo de ingreso';

  static const String clearFilters = 'Limpiar filtros';
  static const String filterAll = 'Todos';

  static const String casesPageTitle = 'Seguimiento asistencial';
  static const String casesPageSubtitle =
      'Consulta y seguimiento operativo de pacientes del programa.';
  static const String casesFiltersHeader = 'Filtros y acciones';
  static const String casesFiltersSubtitle =
      'Organiza el censo con una vista clara y operativa.';
  static const String casesSearchLabel = 'Buscar';
  static const String casesSearchHint = 'Buscar paciente, identificación...';
  static const String careSituationLabel = 'Situación asistencial';
  static const String processStatusLabel = 'Estado PAD';
  static const String functionalUnitLabel = 'Unidad funcional';

  static const List<String> casesFunctionalUnitOptions = <String>[
    filterAll,
    'Medicina interna',
    'Cirugía general',
    'Urgencias',
    'Hospitalización',
  ];

  static const String casesSectionTitle = 'Pacientes';
  static const String recordsSuffix = 'registros';
  static const String tableHeaderPatient = 'PACIENTE';
  static const String tableHeaderDiagnosis = 'DIAGNÓSTICO';
  static const String tableHeaderSpecialty = 'ESPECIALIDAD';
  static const String tableHeaderDates = 'FECHAS';
  static const String tableHeaderFunctionalUnit = 'UNIDAD FUNCIONAL';
  static const String tableHeaderNeighborhood = 'BARRIO';
  static const String tableHeaderObservations = 'OBSERVACIONES';
  static const String noResultsTitle = 'No hay casos';
  static const String noResultsSubtitle =
      'Ajusta los filtros o crea un caso para comenzar.';
  static const String noResultsWithFilters =
      'No hay resultados con los filtros actuales.';

  static const String admissionDateLabel = 'Ingreso';
  static const String dischargeDateLabel = 'Egreso';
  static const String stayDaysLabel = 'Días';
  static const String specialtyLabel = 'Especialidad';
  static const String neighborhoodLabel = 'Barrio';
  static const String diagnosisLabel = 'Diagnóstico';
  static const String observationsLabel = 'Observaciones';

  static const String captureOriginActiveSearch = 'Búsqueda activa del PAD';
  static const String captureOriginFromService = 'Presentado por el servicio';
  static const String specialtyInternalMedicine = 'Medicina interna';
  static const String specialtySurgery = 'Cirugía';
  static const String specialtyOrthopedics = 'Ortopedia';
  static const String specialtyOthers = 'Otros';
  static const String activityApprovedAdmission = 'Ingreso aprobado';
  static const String activityNoAdmission = 'No ingreso';
  static const String legendMorningCensus = 'Amanecen';
  static const String legendDischarges = 'Egresan';

  static const String dashboardSubtitle =
      'Vista general operativa del programa.';
  static const String kpiCurrentPatients = 'Pacientes actuales';
  static const String kpiTodayVisits = 'Visitas de hoy';
  static const String kpiNoAdmissions = 'No ingresos';
  static const String kpiDischarges = 'Altas';
  static const String kpiReadmissions = 'Reingresos';
  static const String kpiAverageStayDays = 'Días prom. estancia';

  static const String captureOriginSectionTitle = 'Origen de captación';
  static const String specialtiesSectionTitle = 'Especialidades';
  static const String openCaseAction = 'Abrir';
  static const String upcomingMedicalAssessments =
      'Próximas valoraciones médicas';
  static const String recentNoAdmissions = 'No ingresos recientes';
  static const String recentActivity = 'Actividad reciente';
  static const String dailyPadBehavior = 'Comportamiento diario PAD';
  static const String dailyPadBehaviorSubtitle = 'Amanecen vs egresan';
}

class PadProcessStatusLabels {
  const PadProcessStatusLabels._();

  static const String captured = 'Captado';
  static const String underAssessment = 'En valoracion';
  static const String defined = 'Definido';
  static const String admissionApproved = 'Ingreso aprobado';
  static const String admissionNotApproved = 'Ingreso no aprobado';
  static const String closed = 'Cerrado';

  static const List<String> all = <String>[
    captured,
    underAssessment,
    defined,
    admissionApproved,
    admissionNotApproved,
    closed,
  ];
}

class PadCareSituationLabels {
  const PadCareSituationLabels._();

  static const String hospitalExtension = 'Extensión hospitalaria';
  static const String discharge = 'Alta';
  static const String readmission = 'Reingreso';
  static const String institutionalized = 'En institución';
  static const String noProgramAdmission = 'Sin ingreso al programa';

  static const List<String> all = <String>[
    hospitalExtension,
    discharge,
    readmission,
    institutionalized,
    noProgramAdmission,
  ];
}

class PadAdmissionReasonOption {
  const PadAdmissionReasonOption({
    required this.key,
    required this.label,
    this.internalDescription,
  });

  final String key;
  final String label;
  final String? internalDescription;
}

class PadAdmissionReasonLabels {
  const PadAdmissionReasonLabels._();

  static const PadAdmissionReasonOption finishTreatment =
      PadAdmissionReasonOption(
        key: 'finalizar_tratamiento',
        label: 'Finalizar tratamiento',
      );

  static const PadAdmissionReasonOption woundCare = PadAdmissionReasonOption(
    key: 'clinica_heridas',
    label: 'Clínica de heridas',
  );

  static const PadAdmissionReasonOption pendingProcedure =
      PadAdmissionReasonOption(
        key: 'procedimiento_pendiente',
        label: 'Procedimiento pendiente',
        internalDescription:
            'Incluye procedimientos quirúrgicos o diagnósticos pendientes',
      );

  static const List<PadAdmissionReasonOption> all = <PadAdmissionReasonOption>[
    finishTreatment,
    woundCare,
    pendingProcedure,
  ];

  static const List<String> allLabels = <String>[
    'Finalizar tratamiento',
    'Clínica de heridas',
    'Procedimiento pendiente',
  ];
}
