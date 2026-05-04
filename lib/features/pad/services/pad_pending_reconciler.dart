import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hext/features/agenda/data/agenda_repo.dart';

class PadPendingReconciler {
  PadPendingReconciler({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _pendingRef =>
      _firestore.collection('pendingItems');

  CollectionReference<Map<String, dynamic>> get _agendaRef =>
      _firestore.collection('agenda_events');

  Future<void> reconcile({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    final String paciente = _readTrimmed(<dynamic>[
      data['nombreCompleto'],
      data['patientDisplay'],
    ]);
    final bool isActivePadCase = _isActivePadCase(data);
    final Map<String, dynamic> detalleMotivos = data['detalleMotivos'] is Map
        ? Map<String, dynamic>.from(data['detalleMotivos'] as Map)
        : <String, dynamic>{};
    final Map<String, _PendingDraft> desired = <String, _PendingDraft>{};

    if (isActivePadCase) {
      _collectProcedurePendings(
        patientId: patientId,
        paciente: paciente,
        detalleMotivos: detalleMotivos,
        desired: desired,
      );
      _collectTreatmentPendings(
        patientId: patientId,
        paciente: paciente,
        detalleMotivos: detalleMotivos,
        desired: desired,
      );
      _collectCriticalDataPendings(
        patientId: patientId,
        paciente: paciente,
        data: data,
        desired: desired,
      );

      final List<AgendaEventRecord> agendaEvents = await _fetchAgendaEvents(
        patientId,
      );
      _collectAgendaPendings(
        patientId: patientId,
        fallbackPaciente: paciente,
        events: agendaEvents,
        desired: desired,
      );
    }

    await _reconcileManagedPendings(
      patientId: patientId,
      desired: desired.values.toList(),
    );
  }

  void _collectProcedurePendings({
    required String patientId,
    required String paciente,
    required Map<String, dynamic> detalleMotivos,
    required Map<String, _PendingDraft> desired,
  }) {
    final Map<String, dynamic> procedimiento = _asMap(
      detalleMotivos['programacion_procedimiento'],
    );
    if (procedimiento['activo'] != true) {
      return;
    }

    final Map<String, dynamic> detalle = _asMap(procedimiento['detalleMotivo']);
    final String nombreProcedimiento = _readTrimmed(<dynamic>[
      procedimiento['nombreProcedimiento'],
      procedimiento['procedimientoRequerido'],
      procedimiento['procedimientoProgramado'],
      detalle['nombreProcedimiento'],
      detalle['procedimientoRequerido'],
      detalle['procedimientoProgramado'],
    ]);
    final DateTime? fechaProgramada = _readDate(<dynamic>[
      procedimiento['fechaProgramada'],
      procedimiento['fechaProcedimiento'],
      detalle['fechaProgramada'],
      detalle['fechaProcedimiento'],
    ]);
    final String horaProgramada = _readTrimmed(<dynamic>[
      procedimiento['horaProgramada'],
      procedimiento['horaProcedimiento'],
      detalle['horaProgramada'],
      detalle['horaProcedimiento'],
    ]);
    final String requiereAnestesiologia = _readTrimmed(<dynamic>[
      procedimiento['requiereAnestesiologia'],
      detalle['requiereAnestesiologia'],
    ]).toLowerCase();
    final String anestesiologiaRealizada = _readTrimmed(<dynamic>[
      procedimiento['anestesiologiaRealizada'],
      detalle['anestesiologiaRealizada'],
    ]).toLowerCase();
    final DateTime? fechaValoracionAnestesiologia = _readDate(<dynamic>[
      procedimiento['fechaValoracionAnestesiologia'],
      detalle['fechaValoracionAnestesiologia'],
    ]);

    final String detalleProcedimiento = nombreProcedimiento.isEmpty
        ? 'Procedimiento quirurgico activo.'
        : 'Procedimiento quirurgico: $nombreProcedimiento.';
    final String route = '/pad/editar/$patientId';

    if (fechaProgramada == null || horaProgramada.isEmpty) {
      final String id = _patientPendingId(patientId, 'procedimiento-programacion');
      desired[id] = _PendingDraft(
        id: id,
        tipo: 'Procedimiento quirurgico',
        paciente: paciente,
        detalle:
            '$detalleProcedimiento Procedimiento quirurgico sin programacion completa.',
        dueAt: DateTime.now(),
        rutaContexto: route,
        contextoLabel: 'Paciente PAD',
        patientId: patientId,
        motivoKey: 'programacion_procedimiento',
      );
    }

    if (requiereAnestesiologia == 'por_confirmar') {
      final String id = _patientPendingId(
        patientId,
        'anestesiologia-confirmacion',
      );
      desired[id] = _PendingDraft(
        id: id,
        tipo: 'Procedimiento quirurgico',
        paciente: paciente,
        detalle:
            '$detalleProcedimiento Confirmar necesidad de valoracion por anestesiologia.',
        dueAt: fechaProgramada ?? DateTime.now(),
        rutaContexto: route,
        contextoLabel: 'Paciente PAD',
        patientId: patientId,
        motivoKey: 'programacion_procedimiento',
      );
    }

    if (requiereAnestesiologia == 'si' && anestesiologiaRealizada != 'si') {
      final String id = _patientPendingId(
        patientId,
        'anestesiologia-pendiente',
      );
      desired[id] = _PendingDraft(
        id: id,
        tipo: 'Procedimiento quirurgico',
        paciente: paciente,
        detalle:
            '$detalleProcedimiento Valoracion por anestesiologia pendiente.',
        dueAt:
            fechaValoracionAnestesiologia ??
            fechaProgramada ??
            DateTime.now(),
        rutaContexto: route,
        contextoLabel: 'Paciente PAD',
        patientId: patientId,
        motivoKey: 'programacion_procedimiento',
      );
    }
  }

  void _collectTreatmentPendings({
    required String patientId,
    required String paciente,
    required Map<String, dynamic> detalleMotivos,
    required Map<String, _PendingDraft> desired,
  }) {
    final Map<String, dynamic> tratamiento = _asMap(
      detalleMotivos['finalizar_tratamiento'],
    );
    if (tratamiento.isEmpty || tratamiento['activo'] != true) {
      return;
    }

    final DateTime? fechaProbableFinalizacion = _readDate(<dynamic>[
      tratamiento['fechaProbableFinalizacion'],
      _asMap(tratamiento['detalleMotivo'])['fechaProbableFinalizacion'],
    ]);
    if (fechaProbableFinalizacion == null) {
      return;
    }

    final DateTime today = _normalizedDate(DateTime.now());
    final int diasRestantes = _normalizedDate(
      fechaProbableFinalizacion,
    ).difference(today).inDays;
    if (diasRestantes < 1 || diasRestantes > 2) {
      return;
    }

    final String nombreTratamiento = _readTrimmed(<dynamic>[
      tratamiento['tratamientoAFinalizar'],
      tratamiento['nombreTratamiento'],
      tratamiento['tratamientoPendiente'],
      _asMap(tratamiento['detalleMotivo'])['tratamientoAFinalizar'],
      _asMap(tratamiento['detalleMotivo'])['nombreTratamiento'],
      _asMap(tratamiento['detalleMotivo'])['tratamientoPendiente'],
    ]);
    final String detalleTratamiento = nombreTratamiento.isEmpty
        ? 'Tratamiento activo.'
        : 'Tratamiento: $nombreTratamiento.';
    final String id = _patientPendingId(patientId, 'tratamiento-proximo-fin');
    desired[id] = _PendingDraft(
      id: id,
      tipo: 'Finalizar tratamiento',
      paciente: paciente,
      detalle:
          '$detalleTratamiento Tratamiento proximo a finalizar. Revisar continuidad.',
      dueAt: fechaProbableFinalizacion,
      rutaContexto: '/schedule',
      contextoLabel: 'Agenda',
      patientId: patientId,
      motivoKey: 'finalizar_tratamiento',
    );
  }

  void _collectCriticalDataPendings({
    required String patientId,
    required String paciente,
    required Map<String, dynamic> data,
    required Map<String, _PendingDraft> desired,
  }) {
    final List<String> faltantes = <String>[];
    _appendMissingLabel(
      faltantes,
      label: 'Identificacion',
      candidates: <dynamic>[data['identificacion']],
    );
    _appendMissingLabel(
      faltantes,
      label: 'Aseguradora',
      candidates: <dynamic>[data['aseguradoraLabel'], data['aseguradora']],
    );
    _appendMissingLabel(
      faltantes,
      label: 'Especialidad tratante',
      candidates: <dynamic>[
        data['especialidadLabel'],
        data['especialidadPrincipalTratante'],
      ],
    );
    _appendMissingLabel(
      faltantes,
      label: 'Diagnostico',
      candidates: <dynamic>[data['diagnostico'], data['diagnosticos']],
    );

    if (faltantes.isEmpty) {
      return;
    }

    final String id = _patientPendingId(patientId, 'datos-criticos');
    desired[id] = _PendingDraft(
      id: id,
      tipo: 'Datos clinicos',
      paciente: paciente,
      detalle:
          'Datos criticos incompletos: ${faltantes.join(', ')}.',
      dueAt: DateTime.now(),
      rutaContexto: '/pad/editar/$patientId',
      contextoLabel: 'Paciente PAD',
      patientId: patientId,
      motivoKey: 'datos_criticos',
    );
  }

  Future<List<AgendaEventRecord>> _fetchAgendaEvents(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _agendaRef
        .where('patientId', isEqualTo: patientId)
        .get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return AgendaEventRecord.fromFirestore(doc);
        })
        .toList();
  }

  void _collectAgendaPendings({
    required String patientId,
    required String fallbackPaciente,
    required List<AgendaEventRecord> events,
    required Map<String, _PendingDraft> desired,
  }) {
    final Set<String> agendaKeys = <String>{};
    for (final AgendaEventRecord event in events) {
      if (!_isOpenAgendaEvent(event)) {
        continue;
      }

      final String paciente = event.patientDisplay.trim().isEmpty
          ? fallbackPaciente
          : event.patientDisplay.trim();
      final DateTime? when = _combineDateAndTime(event.fecha, event.hora);
      final String eventLabel = _agendaEventLabel(event);
      final String agendaKey =
          '$patientId|${_normalizedDate(event.fecha).toIso8601String()}|${event.motivoKey.trim()}';
      if (!agendaKeys.add(agendaKey)) {
        continue;
      }

      if (when != null && when.isBefore(DateTime.now())) {
        final String id = _eventPendingId(event.id, 'vencida-sin-cierre');
        desired[id] = _PendingDraft(
          id: id,
          tipo: 'Agenda operativa',
          paciente: paciente,
          detalle: '$eventLabel Visita vencida sin cierre.',
          dueAt: when,
          rutaContexto: '/schedule',
          contextoLabel: 'Agenda',
          patientId: patientId,
          visitId: event.id,
          motivoKey: event.motivoKey,
        );
      }

      final bool sinResponsable =
          (event.responsableNombre ?? '').trim().isEmpty &&
          (event.responsableId ?? '').trim().isEmpty;
      if (event.estadoAgenda.trim().toLowerCase() == 'programada' &&
          sinResponsable &&
          (when == null || !when.isBefore(DateTime.now()))) {
        final String id = _eventPendingId(event.id, 'sin-responsable');
        desired[id] = _PendingDraft(
          id: id,
          tipo: 'Agenda operativa',
          paciente: paciente,
          detalle: '$eventLabel Visita sin responsable asignado.',
          dueAt: when ?? event.fecha,
          rutaContexto: '/schedule',
          contextoLabel: 'Agenda',
          patientId: patientId,
          visitId: event.id,
          motivoKey: event.motivoKey,
        );
      }
    }
  }

  Future<void> _reconcileManagedPendings({
    required String patientId,
    required List<_PendingDraft> desired,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _pendingRef
        .where('patientId', isEqualTo: patientId)
        .get();
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> existing =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      if (_isManagedPendingDoc(doc)) {
        existing[doc.id] = doc;
      }
    }

    final Set<String> desiredIds = desired.map((_PendingDraft d) => d.id).toSet();
    for (final _PendingDraft draft in desired) {
      await _upsertPending(draft);
    }
    for (final MapEntry<String, QueryDocumentSnapshot<Map<String, dynamic>>> entry
        in existing.entries) {
      if (!desiredIds.contains(entry.key)) {
        await _resolvePending(
          id: entry.key,
          detail: entry.value.data()['detalle']?.toString(),
          reason: 'condition_cleared',
        );
      }
    }
  }

  bool _isManagedPendingDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    if ((data['managedBy'] ?? '').toString().trim() == 'pad_pending_reconciler') {
      return true;
    }
    return doc.id.startsWith('pad-');
  }

  Future<void> _upsertPending(_PendingDraft draft) {
    return _pendingRef.doc(draft.id).set(<String, dynamic>{
      'tipo': draft.tipo,
      'paciente': draft.paciente,
      'detalle': draft.detalle,
      'dueAt': Timestamp.fromDate(draft.dueAt),
      'rutaContexto': draft.rutaContexto,
      'contextoLabel': draft.contextoLabel,
      'patientId': draft.patientId,
      'visitId': draft.visitId,
      'pendingId': draft.id,
      'status': 'pendiente',
      'responsable': 'Sin asignar',
      'motivoKey': draft.motivoKey,
      'sourceType': 'paciente_pad',
      'managedBy': 'pad_pending_reconciler',
      'isClosed': false,
      'closedAt': null,
      'resolvedAt': null,
      'resolutionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _resolvePending({
    required String id,
    String? detail,
    required String reason,
  }) async {
    try {
      await _pendingRef.doc(id).set(<String, dynamic>{
        'status': 'resuelto',
        'isClosed': true,
        'closedAt': FieldValue.serverTimestamp(),
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolutionReason': reason,
        if (detail != null && detail.trim().isNotEmpty) 'detalle': detail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Mantener flujo operativo aunque una regla de Firestore bloquee el cierre.
    }
  }

  String _patientPendingId(String patientId, String suffix) {
    return 'pad-patient-$patientId-$suffix';
  }

  String _eventPendingId(String eventId, String suffix) {
    return 'pad-event-$eventId-$suffix';
  }

  String _agendaEventLabel(AgendaEventRecord event) {
    final String tratamiento = event.tratamiento.trim();
    if (tratamiento.isEmpty) {
      return 'Visita programada.';
    }
    return 'Visita programada para $tratamiento.';
  }

  bool _isOpenAgendaEvent(AgendaEventRecord event) {
    if (event.isClosed) {
      return false;
    }
    const Set<String> closedStates = <String>{
      'cerrada',
      'cancelada',
      'finalizada',
    };
    return !closedStates.contains(event.estadoAgenda.trim().toLowerCase());
  }

  DateTime? _combineDateAndTime(DateTime fecha, String hora) {
    final List<String> parts = hora.trim().split(':');
    if (parts.length < 2) {
      return DateTime(fecha.year, fecha.month, fecha.day);
    }
    final int? hh = int.tryParse(parts[0]);
    final int? mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) {
      return DateTime(fecha.year, fecha.month, fecha.day);
    }
    return DateTime(fecha.year, fecha.month, fecha.day, hh, mm);
  }

  void _appendMissingLabel(
    List<String> target, {
    required String label,
    required List<dynamic> candidates,
  }) {
    if (_readTrimmed(candidates).isEmpty) {
      target.add(label);
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _readTrimmed(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      final String value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  DateTime? _readDate(List<dynamic> candidates) {
    for (final dynamic candidate in candidates) {
      if (candidate is Timestamp) {
        final DateTime value = candidate.toDate();
        return DateTime(value.year, value.month, value.day);
      }
      if (candidate is DateTime) {
        return DateTime(candidate.year, candidate.month, candidate.day);
      }
      final String value = (candidate ?? '').toString().trim();
      if (value.isEmpty) {
        continue;
      }
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
      final List<String> parts = value.split('/');
      if (parts.length == 3) {
        final int? day = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        final int? year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isActivePadCase(Map<String, dynamic> data) {
    bool matches(String value, Set<String> expected) =>
        expected.contains(value.trim().toLowerCase());

    final String decision = (data['decision'] ?? '').toString();
    final String estadoPad = (data['estadoPad'] ?? '').toString();
    final String situacionAsistencial = (data['situacionAsistencial'] ?? '')
        .toString();
    final String situacionAsistencialLabel =
        (data['situacionAsistencialLabel'] ?? '').toString();
    final String resultadoPadLabel = (data['resultadoPadLabel'] ?? '').toString();
    final String resultadoPadKey = (data['resultadoPadKey'] ?? '').toString();

    return matches(decision, const <String>{'ingreso aprobado', 'ingresoaprobado'}) ||
        matches(resultadoPadLabel, const <String>{'ingreso aprobado'}) ||
        matches(resultadoPadKey, const <String>{'ingresoaprobado'}) ||
        matches(situacionAsistencialLabel, const <String>{'activo en pad'}) ||
        matches(situacionAsistencial, const <String>{'activo en pad', 'ingresado'}) ||
        matches(estadoPad, const <String>{
          'activo en pad',
          'ingresado',
          'aprobado_para_ingreso',
          'aprobado para ingreso',
        });
  }
}

class _PendingDraft {
  const _PendingDraft({
    required this.id,
    required this.tipo,
    required this.paciente,
    required this.detalle,
    required this.dueAt,
    required this.rutaContexto,
    required this.contextoLabel,
    required this.patientId,
    required this.motivoKey,
    this.visitId,
  });

  final String id;
  final String tipo;
  final String paciente;
  final String detalle;
  final DateTime dueAt;
  final String rutaContexto;
  final String contextoLabel;
  final String patientId;
  final String motivoKey;
  final String? visitId;
}
