import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AgendaEventRecord {
  final String id;
  final String patientId;
  final String patientDisplay;
  final DateTime fecha;
  final String hora;
  final String dx;
  final String tratamiento;
  final String barrio;
  final String direccion;
  final String referencia;
  final String contacto;
  final String estadoAgenda;
  final String sourceType;
  final String motivoKey;
  final String motivoLabel;
  final Map<String, dynamic> detalleMotivo;
  final String estadoMotivo;
  final DateTime? fechaProbableFinalizacion;
  final bool isClosed;
  final String? responsableId;
  final String? responsableNombre;
  final String? pacienteCuentaConInfusor;
  final bool antibioticoCandidatoInfusor;
  final String? antibioticoDetectado;
  final bool requiereCambioDiarioInfusor;
  final String? programacionSugerida;
  final String? frecuenciaTratamiento;
  final String? frecuenciaTratamientoLabel;
  final String? tipoActividadAgenda;
  final String? cancelReason;
  final double? verifiedLat;
  final double? verifiedLng;

  const AgendaEventRecord({
    required this.id,
    required this.patientId,
    required this.patientDisplay,
    required this.fecha,
    required this.hora,
    required this.dx,
    required this.tratamiento,
    required this.barrio,
    required this.direccion,
    required this.referencia,
    required this.contacto,
    required this.estadoAgenda,
    required this.sourceType,
    required this.motivoKey,
    required this.motivoLabel,
    required this.detalleMotivo,
    required this.estadoMotivo,
    this.fechaProbableFinalizacion,
    required this.isClosed,
    this.responsableId,
    this.responsableNombre,
    this.pacienteCuentaConInfusor,
    required this.antibioticoCandidatoInfusor,
    this.antibioticoDetectado,
    required this.requiereCambioDiarioInfusor,
    this.programacionSugerida,
    this.frecuenciaTratamiento,
    this.frecuenciaTratamientoLabel,
    this.tipoActividadAgenda,
    this.cancelReason,
    this.verifiedLat,
    this.verifiedLng,
  });

  factory AgendaEventRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final dynamic fechaRaw = data['fecha'];
    final Timestamp? fechaTs = fechaRaw is Timestamp ? fechaRaw : null;
    final DateTime fecha =
        fechaTs?.toDate() ??
        FirestoreAgendaRepo._readDateFromUnknown(fechaRaw) ??
        DateTime.now();
    final dynamic fechaProbableFinalizacionRaw =
        data['fechaProbableFinalizacion'];
    final Map<String, dynamic> detalleMotivo = data['detalleMotivo'] is Map
        ? Map<String, dynamic>.from(data['detalleMotivo'] as Map)
        : <String, dynamic>{};

    return AgendaEventRecord(
      id: doc.id,
      patientId: (data['patientId'] ?? '').toString(),
      patientDisplay: (data['patientDisplay'] ?? '').toString(),
      fecha: fecha,
      hora: (data['hora'] ?? '').toString(),
      dx: (data['dx'] ?? '').toString(),
      tratamiento: (data['tratamiento'] ?? '').toString(),
      barrio: (data['barrio'] ?? '').toString(),
      direccion: (data['direccion'] ?? '').toString(),
      referencia: (data['referencia'] ?? '').toString(),
      contacto: (data['contacto'] ?? '').toString(),
      estadoAgenda: (data['estadoAgenda'] ?? 'programada').toString(),
      sourceType: (data['sourceType'] ?? 'manual').toString(),
      motivoKey: (data['motivoKey'] ?? '').toString(),
      motivoLabel: (data['motivoLabel'] ?? '').toString(),
      detalleMotivo: detalleMotivo,
      estadoMotivo: (data['estadoMotivo'] ?? 'en_curso').toString(),
      fechaProbableFinalizacion:
          fechaProbableFinalizacionRaw is Timestamp
              ? fechaProbableFinalizacionRaw.toDate()
              : fechaProbableFinalizacionRaw is DateTime
              ? fechaProbableFinalizacionRaw
              : null,
      isClosed: data['isClosed'] == true,
      responsableId: data['responsableId']?.toString(),
      responsableNombre: data['responsableNombre']?.toString(),
      pacienteCuentaConInfusor: data['pacienteCuentaConInfusor']?.toString(),
      antibioticoCandidatoInfusor: data['antibioticoCandidatoInfusor'] == true,
      antibioticoDetectado: data['antibioticoDetectado']?.toString(),
      requiereCambioDiarioInfusor: data['requiereCambioDiarioInfusor'] == true,
      programacionSugerida: data['programacionSugerida']?.toString(),
      frecuenciaTratamiento: data['frecuenciaTratamiento']?.toString(),
      frecuenciaTratamientoLabel: data['frecuenciaTratamientoLabel']?.toString(),
      tipoActividadAgenda: data['tipoActividadAgenda']?.toString(),
      cancelReason: data['cancelReason']?.toString(),
      verifiedLat: FirestoreAgendaRepo._readCoordinate(data['verifiedLat']),
      verifiedLng: FirestoreAgendaRepo._readCoordinate(data['verifiedLng']),
    );
  }

  AgendaEventRecord copyWith({
    String? id,
    String? patientId,
    String? patientDisplay,
    DateTime? fecha,
    String? hora,
    String? dx,
    String? tratamiento,
    String? barrio,
    String? direccion,
    String? referencia,
    String? contacto,
    String? estadoAgenda,
    String? sourceType,
    String? motivoKey,
    String? motivoLabel,
    Map<String, dynamic>? detalleMotivo,
    String? estadoMotivo,
    DateTime? fechaProbableFinalizacion,
    bool? isClosed,
    String? responsableId,
    String? responsableNombre,
    String? pacienteCuentaConInfusor,
    bool? antibioticoCandidatoInfusor,
    String? antibioticoDetectado,
    bool? requiereCambioDiarioInfusor,
    String? programacionSugerida,
    String? frecuenciaTratamiento,
    String? frecuenciaTratamientoLabel,
    String? tipoActividadAgenda,
    String? cancelReason,
    double? verifiedLat,
    double? verifiedLng,
  }) {
    return AgendaEventRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientDisplay: patientDisplay ?? this.patientDisplay,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      dx: dx ?? this.dx,
      tratamiento: tratamiento ?? this.tratamiento,
      barrio: barrio ?? this.barrio,
      direccion: direccion ?? this.direccion,
      referencia: referencia ?? this.referencia,
      contacto: contacto ?? this.contacto,
      estadoAgenda: estadoAgenda ?? this.estadoAgenda,
      sourceType: sourceType ?? this.sourceType,
      motivoKey: motivoKey ?? this.motivoKey,
      motivoLabel: motivoLabel ?? this.motivoLabel,
      detalleMotivo: detalleMotivo ?? this.detalleMotivo,
      estadoMotivo: estadoMotivo ?? this.estadoMotivo,
      fechaProbableFinalizacion:
          fechaProbableFinalizacion ?? this.fechaProbableFinalizacion,
      isClosed: isClosed ?? this.isClosed,
      responsableId: responsableId ?? this.responsableId,
      responsableNombre: responsableNombre ?? this.responsableNombre,
      pacienteCuentaConInfusor:
          pacienteCuentaConInfusor ?? this.pacienteCuentaConInfusor,
      antibioticoCandidatoInfusor:
          antibioticoCandidatoInfusor ?? this.antibioticoCandidatoInfusor,
      antibioticoDetectado: antibioticoDetectado ?? this.antibioticoDetectado,
      requiereCambioDiarioInfusor:
          requiereCambioDiarioInfusor ?? this.requiereCambioDiarioInfusor,
      programacionSugerida: programacionSugerida ?? this.programacionSugerida,
      frecuenciaTratamiento:
          frecuenciaTratamiento ?? this.frecuenciaTratamiento,
      frecuenciaTratamientoLabel:
          frecuenciaTratamientoLabel ?? this.frecuenciaTratamientoLabel,
      tipoActividadAgenda: tipoActividadAgenda ?? this.tipoActividadAgenda,
      cancelReason: cancelReason ?? this.cancelReason,
      verifiedLat: verifiedLat ?? this.verifiedLat,
      verifiedLng: verifiedLng ?? this.verifiedLng,
    );
  }
}

abstract class AgendaRepo {
  Stream<List<AgendaEventRecord>> watchAgendaEvents();
}

class FirestoreAgendaRepo implements AgendaRepo {
  final FirebaseFirestore _firestore;
  static const bool _debugAgendaRepoLogs = false;

  FirestoreAgendaRepo({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static bool _isRenderableAgendaEvent(AgendaEventRecord event) {
    if (event.sourceType == 'virtual') {
      return false;
    }
    if (event.estadoAgenda.trim().toLowerCase() == 'cancelada' &&
        (event.cancelReason ?? '').trim().toLowerCase() ==
            'normalizacion_infusor') {
      return false;
    }
    return true;
  }

  @override
  Stream<List<AgendaEventRecord>> watchAgendaEvents() {
    return _firestore
        .collection('agenda_events')
        .orderBy('fecha')
        .snapshots()
        .asyncMap((snapshot) async {
          final List<AgendaEventRecord> events =
              await _applyPatientLocationOverrides(
                snapshot.docs
                    .map((doc) => AgendaEventRecord.fromFirestore(doc))
                    .toList(),
              );

          final List<AgendaEventRecord> all = events
              .where(_isRenderableAgendaEvent)
              .toList();
          all.sort((a, b) => a.fecha.compareTo(b.fecha));
          final String preview = all
              .take(3)
              .map(
                (event) =>
                    '${event.patientId}|${event.patientDisplay}|${event.fecha.toIso8601String()}|${event.hora}|${event.estadoAgenda}|${event.sourceType}',
              )
              .join(' ; ');
          if (_debugAgendaRepoLogs) {
            debugPrint(
              '[FirestoreAgendaRepo.watchAgendaEvents] docs=${all.length}${preview.isEmpty ? '' : ' preview=$preview'}',
            );
          }
          return all;
        });
  }

  static DateTime? _readDateFromUnknown(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) {
      final String value = raw.trim();
      if (value.isEmpty) return null;
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
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

  /// Crea un evento de agenda a partir de los datos mínimos requeridos.
  Future<String> createAgendaEvent({
    required String patientId,
    required String patientDisplay,
    required String identificacion,
    required DateTime fecha,
    required String hora,
    required String dx,
    required String tratamiento,
    required String barrio,
    required String direccion,
    required String referencia,
    required String contacto,
    String motivoAgenda = '',
    Map<String, dynamic>? detalleMotivo,
    String motivoKey = '',
    String motivoLabel = '',
    String estadoMotivo = 'en_curso',
    DateTime? fechaProbableFinalizacion,
    String estadoAgenda = 'programada',
    String sourceType = 'manual',
    bool isClosed = false,
    String? responsableId,
    String? responsableNombre,
    String? pacienteCuentaConInfusor,
    bool antibioticoCandidatoInfusor = false,
    String? antibioticoDetectado,
    bool requiereCambioDiarioInfusor = false,
    String? programacionSugerida,
    String? frecuenciaTratamiento,
    String? frecuenciaTratamientoLabel,
    String? tipoActividadAgenda,
  }) async {
    final DateTime normalizedDate = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );
    final String fechaYmd =
        '${normalizedDate.year.toString().padLeft(4, '0')}-'
        '${normalizedDate.month.toString().padLeft(2, '0')}-'
        '${normalizedDate.day.toString().padLeft(2, '0')}';
    debugPrint(
      'AGENDA CREATE -> $fechaYmd $hora | patientId=$patientId sourceType=$sourceType motivoKey=$motivoKey estadoAgenda=$estadoAgenda',
    );
    final DocumentReference<Map<String, dynamic>> docRef = await _firestore
        .collection('agenda_events')
        .add({
      'patientId': patientId,
      'patientDisplay': patientDisplay,
      'identificacion': identificacion,
      'fecha': Timestamp.fromDate(normalizedDate),
      'fechaYmd': fechaYmd,
      'hora': hora,
      'dx': dx,
      'tratamiento': tratamiento,
      'barrio': barrio,
      'direccion': direccion,
      'referencia': referencia,
      'contacto': contacto,
      'motivoAgenda': motivoAgenda.isEmpty ? motivoLabel : motivoAgenda,
      'detalleMotivo': detalleMotivo ?? <String, dynamic>{},
      'motivoKey': motivoKey,
      'motivoLabel': motivoLabel,
      'estadoMotivo': estadoMotivo,
      'fechaProbableFinalizacion': fechaProbableFinalizacion == null
          ? null
          : Timestamp.fromDate(
              DateTime(
                fechaProbableFinalizacion.year,
                fechaProbableFinalizacion.month,
                fechaProbableFinalizacion.day,
              ),
            ),
      'estadoAgenda': estadoAgenda,
      'sourceType': sourceType,
      'isClosed': isClosed,
      'responsableId': responsableId,
      'responsableNombre': responsableNombre,
      'pacienteCuentaConInfusor': pacienteCuentaConInfusor,
      'antibioticoCandidatoInfusor': antibioticoCandidatoInfusor,
      'antibioticoDetectado': antibioticoDetectado,
      'requiereCambioDiarioInfusor': requiereCambioDiarioInfusor,
      'programacionSugerida': programacionSugerida,
      'frecuenciaTratamiento': frecuenciaTratamiento,
      'frecuenciaTratamientoLabel': frecuenciaTratamientoLabel,
      'tipoActividadAgenda': tipoActividadAgenda,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<bool> agendaEventExists({
    required String patientId,
    required DateTime fecha,
    required String hora,
    required String sourceType,
    String? motivoKey,
    String? motivoAgenda,
  }) async {
    final DateTime normalizedDate = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('agenda_events')
        .where('patientId', isEqualTo: patientId)
        .get();

    final bool exists = snapshot.docs.any((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      if ((data['sourceType'] ?? '').toString().trim() != sourceType) {
        return false;
      }
      final String estadoAgenda =
          (data['estadoAgenda'] ?? '').toString().trim().toLowerCase();
      if (estadoAgenda == 'cancelada') {
        return false;
      }
      final DateTime? storedDate = _readDateFromUnknown(data['fecha']);
      if (storedDate == null || _dateKey(storedDate) != _dateKey(normalizedDate)) {
        return false;
      }
      final String storedHour = (data['hora'] ?? '').toString().trim();
      if (storedHour != hora.trim()) {
        return false;
      }
      if (motivoAgenda != null && motivoAgenda.trim().isNotEmpty) {
        return (data['motivoAgenda'] ?? '').toString().trim() ==
            motivoAgenda.trim();
      }
      if (motivoKey != null && motivoKey.trim().isNotEmpty) {
        return (data['motivoKey'] ?? '').toString().trim() == motivoKey.trim();
      }
      return true;
    });

    debugPrint(
      '[FirestoreAgendaRepo.agendaEventExists] patientId=$patientId fecha=$normalizedDate hora=$hora sourceType=$sourceType motivoKey=${motivoKey ?? ''} motivoAgenda=${motivoAgenda ?? ''} exists=$exists',
    );

    return exists;
  }

  Future<bool> agendaEventExistsForContinuity({
    required String patientId,
    required DateTime fecha,
    required String sourceType,
    required String motivoKey,
    required bool ignoreHour,
    String? hora,
  }) async {
    final DateTime normalizedDate = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('agenda_events')
        .where('patientId', isEqualTo: patientId)
        .get();
    return snapshot.docs.any((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      final String estadoAgenda =
          (data['estadoAgenda'] ?? '').toString().trim().toLowerCase();
      if (estadoAgenda == 'cancelada') {
        return false;
      }
      if ((data['sourceType'] ?? '').toString().trim() != sourceType) {
        return false;
      }
      if ((data['motivoKey'] ?? '').toString().trim() != motivoKey) {
        return false;
      }
      final DateTime? storedDate = _readDateFromUnknown(data['fecha']);
      if (storedDate == null || _dateKey(storedDate) != _dateKey(normalizedDate)) {
        return false;
      }
      if (ignoreHour) {
        return true;
      }
      final String storedHour = (data['hora'] ?? '').toString().trim();
      return hora != null && hora.trim().isNotEmpty && storedHour == hora.trim();
    });
  }

  Future<Map<String, dynamic>> fetchPatientLocation(String patientId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('censoPacientes')
        .doc(patientId)
        .get();
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final Map<String, dynamic> rawUbicacion = data['ubicacion'] is Map
        ? Map<String, dynamic>.from(data['ubicacion'] as Map)
        : <String, dynamic>{};
    if (_debugAgendaRepoLogs) {
      debugPrint(
        'READ_LOCATION patientId=$patientId ubicacion=$rawUbicacion',
      );
    }
    return _normalizedLocationMap(data);
  }

  Future<void> updatePatientLocation({
    required String patientId,
    required Map<String, dynamic> ubicacion,
    String? eventId,
    String updatedByRole = 'auxiliar_enfermeria',
  }) async {
    final String barrio = (ubicacion['barrio'] ?? '').toString().trim();
    final String direccionAdministrativa =
        (ubicacion['direccionAdministrativa'] ?? '').toString().trim();
    final String referenciaAdministrativa =
        (ubicacion['referenciaAdministrativa'] ?? '').toString().trim();
    final List<Map<String, dynamic>> contactos = _normalizeLocationContacts(
      ubicacion['contactos'],
    );
    final Map<String, dynamic> payload = <String, dynamic>{
      'ubicacion.barrio': barrio,
      'ubicacion.direccionAdministrativa': direccionAdministrativa,
      'ubicacion.referenciaAdministrativa': referenciaAdministrativa,
      'ubicacion.contactos': contactos,
      'ubicacion.observacionesAcceso': (ubicacion['observacionesAcceso'] ?? '')
          .toString()
          .trim(),
      'ubicacion.estadoUbicacion': 'completa_administrativa',
      'ubicacion.updatedByRole': updatedByRole,
      'ubicacion.updatedAt': FieldValue.serverTimestamp(),
    };
    debugPrint(
      'SAVE_LOCATION patientId=$patientId payload=$payload',
    );

    await _firestore.collection('censoPacientes').doc(patientId).update(payload);
    final String trimmedEventId = (eventId ?? '').trim();
    if (trimmedEventId.isNotEmpty) {
      await _firestore
          .collection('agenda_events')
          .doc(trimmedEventId)
          .update(<String, dynamic>{
            'barrio': barrio,
            'direccion': direccionAdministrativa,
            'referencia': referenciaAdministrativa,
            'contacto': _locationContactsSummary(contactos),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }
    debugPrint(
      '[FirestoreAgendaRepo.updatePatientLocation] saved patientId=$patientId',
    );
  }

  Future<void> updatePatientSiteVerification({
    required String patientId,
    required Map<String, dynamic> verification,
    String? eventId,
    String updatedBy = 'auxiliar_enfermeria',
  }) async {
    final bool confirmada = verification['confirmada'] == true;
    final double? lat = _readCoordinate(verification['lat']);
    final double? lng = _readCoordinate(verification['lng']);
    final String direccionReal =
        (verification['direccionReal'] ?? '').toString().trim();
    final String direccionGeocodificada =
      (verification['direccionGeocodificada'] ?? '').toString().trim();
    final String referenciaReal =
        (verification['referenciaReal'] ?? '').toString().trim();
    final String contactoEfectivo =
        (verification['contactoEfectivo'] ?? '').toString().trim();
    final String observacion =
        (verification['observacion'] ?? '').toString().trim();
    final String estadoUbicacion = lat != null && lng != null
        ? 'verificada_en_sitio'
        : 'requiere_correccion';

    final Map<String, dynamic> payload = <String, dynamic>{
      'ubicacion.verificacionEnSitio.confirmada':
        lat != null && lng != null ? true : confirmada,
      'ubicacion.verificacionEnSitio.lat': lat,
      'ubicacion.verificacionEnSitio.lng': lng,
      'ubicacion.verificacionEnSitio.direccionReal': direccionReal,
      'ubicacion.verificacionEnSitio.direccionGeocodificada':
        direccionGeocodificada,
      'ubicacion.verificacionEnSitio.referenciaReal': referenciaReal,
      'ubicacion.verificacionEnSitio.contactoEfectivo': contactoEfectivo,
      'ubicacion.verificacionEnSitio.observacion': observacion,
      'ubicacion.verificacionEnSitio.updatedAt': FieldValue.serverTimestamp(),
      'ubicacion.verificacionEnSitio.updatedBy': updatedBy,
      'ubicacion.estadoUbicacion': estadoUbicacion,
      'ubicacion.updatedAt': FieldValue.serverTimestamp(),
    };

    debugPrint(
      'SAVE_SITE_VERIFICATION patientId=$patientId payload=$payload',
    );

    await _firestore.collection('censoPacientes').doc(patientId).update(payload);
    final String trimmedEventId = (eventId ?? '').trim();
    if (trimmedEventId.isNotEmpty) {
      await _firestore
          .collection('agenda_events')
          .doc(trimmedEventId)
          .update(<String, dynamic>{
            'ubicacionVerificada': lat != null && lng != null ? true : confirmada,
            'ubicacionVerificadaAt': FieldValue.serverTimestamp(),
            'ubicacionVerificadaPor': updatedBy,
            'verifiedLat': lat,
            'verifiedLng': lng,
            if (direccionReal.isNotEmpty) 'direccion': direccionReal,
            if (referenciaReal.isNotEmpty) 'referencia': referenciaReal,
            if (contactoEfectivo.isNotEmpty) 'contacto': contactoEfectivo,
          });
    }
    debugPrint(
      '[FirestoreAgendaRepo.updatePatientSiteVerification] saved patientId=$patientId',
    );
  }

  Future<void> ensureAgendaContinuity(String patientId) async {
    final DocumentSnapshot<Map<String, dynamic>> patientSnap =
        await _firestore.collection('censoPacientes').doc(patientId).get();
    if (!patientSnap.exists) return;

    final Map<String, dynamic> patientData =
        patientSnap.data() ?? <String, dynamic>{};
    final String estadoPad = (patientData['estadoPad'] ?? '').toString().trim();
    final bool activePad = _isContinuityActivePatient(patientData);
    if (!activePad) {
      debugPrint(
        '[FirestoreAgendaRepo.ensureAgendaContinuity] omitido patientId=$patientId estadoPad=$estadoPad activoPad=$activePad',
      );
      return;
    }

    final Map<String, dynamic> tratamiento = _resolveTratamientoContinuity(
      patientData,
    );
    final bool tratamientoActivo = tratamiento['activo'] == true;
    if (!tratamientoActivo) {
      debugPrint(
        '[FirestoreAgendaRepo.ensureAgendaContinuity] omitido patientId=$patientId finalizar_tratamiento_activo=$tratamientoActivo',
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? inicio = _readDateFromUnknown(
      tratamiento['fechaPrimeraVisita'] ?? tratamiento['fechaSugeridaVisita'],
    );
    final DateTime? fin = _readDateFromUnknown(
      tratamiento['fechaProbableFinalizacion'],
    );
    if (fin == null) {
      debugPrint(
        '[FirestoreAgendaRepo.ensureAgendaContinuity] omitido patientId=$patientId fechaProbableFinalizacion=null',
      );
      return;
    }

    final DateTime normalizedStart = inicio == null
        ? today
        : DateTime(inicio.year, inicio.month, inicio.day);
    final DateTime normalizedEnd = DateTime(fin.year, fin.month, fin.day);
    if (today.isAfter(normalizedEnd)) {
      debugPrint(
        '[FirestoreAgendaRepo.ensureAgendaContinuity] omitido patientId=$patientId fecha_fin_vencida=${_dateKey(normalizedEnd)}',
      );
      return;
    }

    final bool hasInfusor = _hasInfusorSafe(
      tratamiento['pacienteCuentaConInfusor'],
    );
    final List<String> horas = hasInfusor
        ? <String>[
            _firstProjectedHour(
                  tratamiento['horaPrimeraVisita'] ??
                      tratamiento['horaSugeridaVisita'],
                ) ??
                '08:00',
          ]
        : _projectedHoursFromTreatment(tratamiento);
    if (horas.isEmpty) {
      debugPrint(
        '[FirestoreAgendaRepo.ensureAgendaContinuity] omitido patientId=$patientId horas_calculadas_vacias',
      );
      return;
    }

    if (hasInfusor) {
      await _normalizeInfusorDailyEvents(
        patientId: patientId,
        from: today,
        to: normalizedEnd,
        preferredHour: horas.first,
      );
    }

    final String patientDisplay = ((patientData['nombreCompleto'] ??
                patientData['nombrePaciente'] ??
                patientData['nombre']) ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    final String identificacion =
        (patientData['identificacion'] ?? '').toString().trim();
    final String dx = ((patientData['diagnosticos'] ??
                patientData['diagnostico']) ??
            '')
        .toString()
        .trim();
    final String tratamientoLabel =
      ((tratamiento['tratamientoPrincipal'] ??
            tratamiento['tratamientoAFinalizar'] ??
                    tratamiento['nombreTratamiento'] ??
                    tratamiento['tratamientoPendiente']) ??
                '')
            .toString()
            .trim();
    final String barrio = (patientData['barrio'] ?? '').toString().trim();
    final String direccion = (patientData['direccion'] ?? '').toString().trim();
    final String referencia =
        ((patientData['referenciaUbicacion'] ?? patientData['referencia']) ?? '')
            .toString()
            .trim();
    final String contacto = (patientData['contacto'] ?? '').toString().trim();
    final String frecuenciaTratamiento =
        (tratamiento['frecuenciaTratamiento'] ?? tratamiento['frecuencia'] ?? '')
            .toString()
            .trim();
    final String frecuenciaTratamientoLabel =
        (tratamiento['frecuenciaTratamientoLabel'] ?? '')
            .toString()
            .trim();
    final bool advertenciaQ6h = _isQ6hFrequency(tratamiento);

    debugPrint(
      '[FirestoreAgendaRepo.ensureAgendaContinuity] patientId=$patientId estadoPad=$estadoPad activo=$tratamientoActivo fechaPrimeraVisita=${inicio == null ? 'null' : _dateKey(inicio)} fechaProbableFinalizacion=${_dateKey(normalizedEnd)} infusor=${_normalizeInfusorValue(tratamiento['pacienteCuentaConInfusor'])} horas=${horas.join(',')}',
    );

    for (
      DateTime day = normalizedStart.isBefore(today) ? today : normalizedStart;
      !day.isAfter(normalizedEnd);
      day = day.add(const Duration(days: 1))
    ) {
      debugPrint(
        '[FirestoreAgendaRepo.ensureAgendaContinuity] evaluando patientId=$patientId fecha=${_dateKey(day)}',
      );
      for (final String hora in horas) {
        final bool exists = await agendaEventExistsForContinuity(
          patientId: patientId,
          fecha: day,
          sourceType: 'paciente_pad',
          motivoKey: 'finalizar_tratamiento',
          ignoreHour: hasInfusor,
          hora: hora,
        );
        if (exists) {
          debugPrint(
            '[FirestoreAgendaRepo.ensureAgendaContinuity] omitido_duplicado patientId=$patientId fecha=${_dateKey(day)} hora=$hora',
          );
          continue;
        }

        await createAgendaEvent(
          patientId: patientId,
          patientDisplay: patientDisplay,
          identificacion: identificacion,
          fecha: day,
          hora: hora,
          dx: dx,
          tratamiento: tratamientoLabel,
          barrio: barrio,
          direccion: direccion,
          referencia: referencia,
          contacto: contacto,
          motivoAgenda: hasInfusor
              ? 'Cambio diario de infusor'
              : 'Finalizar tratamiento',
          detalleMotivo: tratamiento,
          motivoKey: 'finalizar_tratamiento',
          motivoLabel: 'Finalizar tratamiento',
          estadoMotivo: _deriveProjectedEstadoMotivo(
            fechaProbableFinalizacion: normalizedEnd,
          ),
          fechaProbableFinalizacion: normalizedEnd,
          pacienteCuentaConInfusor: hasInfusor ? 'si' : 'no',
          antibioticoCandidatoInfusor: hasInfusor,
          requiereCambioDiarioInfusor: hasInfusor,
          programacionSugerida:
              hasInfusor ? 'cambio_diario_infusor' : 'segun_frecuencia',
          frecuenciaTratamiento: frecuenciaTratamiento,
          frecuenciaTratamientoLabel: frecuenciaTratamientoLabel,
          tipoActividadAgenda: hasInfusor
              ? 'Cambio diario de infusor'
              : 'Administracion de tratamiento',
          estadoAgenda: 'programada',
          sourceType: 'paciente_pad',
        );

        debugPrint(
          '[FirestoreAgendaRepo.ensureAgendaContinuity] creado patientId=$patientId fecha=${_dateKey(day)} hora=$hora',
        );

        if (advertenciaQ6h) {
          debugPrint(
            '[FirestoreAgendaRepo.ensureAgendaContinuity] advertencia q6h patientId=$patientId fecha=${_dateKey(day)} hora=$hora',
          );
        }
      }
    }
  }

  Future<void> cerrarEventosFuturosPorMotivo({
    required String patientId,
    required String motivoKey,
    required DateTime desde,
  }) async {
    final DateTime normalizedDesde = DateTime(
      desde.year,
      desde.month,
      desde.day,
    );
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('agenda_events')
        .where('patientId', isEqualTo: patientId)
        .where('motivoKey', isEqualTo: motivoKey)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedDesde))
        .get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      final String estadoAgenda = (data['estadoAgenda'] ?? '').toString().trim();
      if (estadoAgenda == 'cancelada' || estadoAgenda == 'finalizada') {
        continue;
      }

      await doc.reference.update(<String, dynamic>{
        'estadoAgenda': 'cancelada',
        'cancelReason': 'motivo_finalizado',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String? _firstProjectedHour(dynamic raw) {
    if (raw == null) return null;
    final String value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static List<String> _projectedHoursFromTreatment(
    Map<String, dynamic> tratamiento,
  ) {
    final dynamic raw = tratamiento['horasProgramadas'];
    if (raw is List) {
      final List<String> horas = raw
          .map((dynamic value) => value.toString().trim())
          .where((String value) => value.isNotEmpty)
          .toList();
      if (horas.isNotEmpty) {
        return horas;
      }
    }

    final String frequency =
        (tratamiento['frecuenciaTratamiento'] ?? tratamiento['frecuencia'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    if (frequency.contains('q6') || frequency.contains('cada 6')) {
      return <String>['06:00', '12:00', '18:00', '22:00'];
    }
    if (frequency.contains('q8') || frequency.contains('cada 8')) {
      return <String>['06:00', '14:00', '22:00'];
    }
    if (frequency.contains('q12') || frequency.contains('cada 12')) {
      return <String>['06:00', '18:00'];
    }
    return <String>[
      _firstProjectedHour(
            tratamiento['horaPrimeraVisita'] ??
                tratamiento['horaSugeridaVisita'],
          ) ??
          '08:00',
    ];
  }

  static bool _isQ6hFrequency(Map<String, dynamic> tratamiento) {
    final String frequency =
        (tratamiento['frecuenciaTratamiento'] ?? tratamiento['frecuencia'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return frequency.contains('q6') || frequency.contains('cada 6');
  }

  static String _deriveProjectedEstadoMotivo({
    required DateTime fechaProbableFinalizacion,
  }) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diasRestantes = fechaProbableFinalizacion.difference(today).inDays;
    if (diasRestantes > 2) {
      return 'en_curso';
    }
    if (diasRestantes == 1 || diasRestantes == 2) {
      return 'proximo_a_finalizar';
    }
    return 'fecha_cumplida';
  }

  Future<void> _normalizeInfusorDailyEvents({
    required String patientId,
    required DateTime from,
    required DateTime to,
    String? preferredHour,
  }) async {
    if (from.isAfter(to)) {
      return;
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('agenda_events')
        .where('patientId', isEqualTo: patientId)
        .get();

    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      if ((data['motivoKey'] ?? '').toString().trim() != 'finalizar_tratamiento') {
        continue;
      }
      if ((data['sourceType'] ?? '').toString().trim() != 'paciente_pad') {
        continue;
      }
      final String estadoAgenda = (data['estadoAgenda'] ?? '').toString().trim();
      if (estadoAgenda == 'cancelada' || estadoAgenda == 'finalizada') {
        continue;
      }
      final DateTime? fecha = _readDateFromUnknown(data['fecha']);
      if (fecha == null) {
        continue;
      }
      if (fecha.isBefore(from) || fecha.isAfter(to)) {
        continue;
      }
      byDay.putIfAbsent(_dateKey(fecha), () => <QueryDocumentSnapshot<Map<String, dynamic>>>[]).add(doc);
    }

    for (final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs in byDay.values) {
      if (docs.length <= 1) {
        continue;
      }
      docs.sort((a, b) {
        final String horaA = (a.data()['hora'] ?? '').toString();
        final String horaB = (b.data()['hora'] ?? '').toString();
        final String preferred = (preferredHour ?? '').trim();
        if (preferred.isNotEmpty) {
          if (horaA == preferred && horaB != preferred) {
            return -1;
          }
          if (horaB == preferred && horaA != preferred) {
            return 1;
          }
        }
        return horaA.compareTo(horaB);
      });
      for (final QueryDocumentSnapshot<Map<String, dynamic>> duplicate
          in docs.skip(1)) {
        await duplicate.reference.update(<String, dynamic>{
          'estadoAgenda': 'cancelada',
          'cancelReason': 'normalizacion_infusor',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          '[FirestoreAgendaRepo._normalizeInfusorDailyEvents] cancelado patientId=$patientId fecha=${_dateKey(_readDateFromUnknown(duplicate.data()['fecha']) ?? from)} hora=${(duplicate.data()['hora'] ?? '').toString().trim()} keep=${preferredHour ?? ''}',
        );
      }
    }
  }

  Future<List<AgendaEventRecord>> _applyPatientLocationOverrides(
    List<AgendaEventRecord> events,
  ) async {
    if (events.isEmpty) {
      return events;
    }
    final List<String> patientIds = events
        .map((event) => event.patientId.trim())
        .where((patientId) => patientId.isNotEmpty)
        .toSet()
        .toList();
    if (patientIds.isEmpty) {
      return events;
    }

    final Map<String, Map<String, dynamic>> locationByPatient =
        <String, Map<String, dynamic>>{};
    await Future.wait(
      patientIds.map((patientId) async {
        final Map<String, dynamic> location = await fetchPatientLocation(
          patientId,
        );
        locationByPatient[patientId] = location;
      }),
    );

    return events.map((event) {
      final Map<String, dynamic>? location =
          locationByPatient[event.patientId.trim()];
      if (location == null || location.isEmpty) {
        return event;
      }
      final String direccion = (location['direccion'] ?? '').toString().trim();
      final String barrio = (location['barrio'] ?? '').toString().trim();
      final String referencia = (location['referencia'] ?? '')
          .toString()
          .trim();
      final String contacto = (location['contacto'] ?? '').toString().trim();
      final double? verifiedLat = _readCoordinate(location['lat']);
      final double? verifiedLng = _readCoordinate(location['lng']);
      return event.copyWith(
        direccion: direccion.isNotEmpty ? direccion : event.direccion,
        barrio: barrio.isNotEmpty ? barrio : event.barrio,
        referencia: referencia.isNotEmpty ? referencia : event.referencia,
        contacto: contacto.isNotEmpty ? contacto : event.contacto,
        verifiedLat: verifiedLat,
        verifiedLng: verifiedLng,
      );
    }).toList();
  }

  static Map<String, dynamic> _normalizedLocationMap(
    Map<String, dynamic> patientData,
  ) {
    final Map<String, dynamic> ubicacion = patientData['ubicacion'] is Map
        ? Map<String, dynamic>.from(patientData['ubicacion'] as Map)
        : <String, dynamic>{};
    final String barrio =
        (ubicacion['barrio'] ?? patientData['barrio'] ?? '')
            .toString()
            .trim();
    final String direccionAdministrativa =
        (ubicacion['direccionAdministrativa'] ??
          patientData['direccionAdministrativa'] ??
                ubicacion['direccion'] ??
                patientData['direccion'] ??
                '')
            .toString()
            .trim();
    final String referenciaAdministrativa =
        (ubicacion['referenciaAdministrativa'] ??
          patientData['referenciaAdministrativa'] ??
                ubicacion['referencia'] ??
                patientData['referenciaUbicacion'] ??
                patientData['referencia'] ??
                '')
            .toString()
            .trim();
    final List<Map<String, dynamic>> contactos = _normalizeLocationContacts(
      ubicacion['contactos'],
    );
    final Map<String, dynamic> verificacionEnSitio = _normalizeSiteVerification(
      ubicacion['verificacionEnSitio'],
    );
    final double? lat = _readCoordinate(verificacionEnSitio['lat']);
    final double? lng = _readCoordinate(verificacionEnSitio['lng']);
    final String direccionReal = (verificacionEnSitio['direccionReal'] ?? '')
        .toString()
        .trim();
    final String direccionGeocodificada =
      (verificacionEnSitio['direccionGeocodificada'] ?? '')
        .toString()
        .trim();
    final String referenciaReal = (verificacionEnSitio['referenciaReal'] ?? '')
        .toString()
        .trim();
    final bool hasCoordinates = lat != null && lng != null;
    final bool confirmada =
      verificacionEnSitio['confirmada'] == true || hasCoordinates;
    final bool hasRealAddress = direccionReal.isNotEmpty;
    final bool hasAdminAddress = direccionAdministrativa.isNotEmpty;
    final String direccionVisible = hasCoordinates
      ? 'Ubicación verificada'
      : confirmada && hasRealAddress
        ? direccionReal
        : direccionAdministrativa;
    final String referenciaVisible =
      hasCoordinates
        ? (direccionGeocodificada.isNotEmpty
          ? direccionGeocodificada
          : referenciaReal)
        : confirmada && hasRealAddress
        ? referenciaReal
            : referenciaAdministrativa;
    if (barrio.isNotEmpty && !hasRealAddress && !hasAdminAddress) {
      if (_debugAgendaRepoLogs) {
        debugPrint(
          '[FirestoreAgendaRepo.fetchPatientLocation] barrio_sin_direccion barrio=$barrio ubicacion=$ubicacion',
        );
      }
    }
    return <String, dynamic>{
      'barrio': barrio,
      'direccionAdministrativa': direccionAdministrativa,
      'referenciaAdministrativa': referenciaAdministrativa,
      'contactos': contactos,
      'observacionesAcceso': (ubicacion['observacionesAcceso'] ?? '')
          .toString()
          .trim(),
      'verificacionEnSitio': verificacionEnSitio,
      'estadoUbicacion': _resolveLocationStatus(
        rawStatus: ubicacion['estadoUbicacion'],
        direccionAdministrativa: direccionAdministrativa,
        contactos: contactos,
        confirmadaEnSitio: confirmada,
      ),
      'lat': lat,
      'lng': lng,
      'hasVerifiedCoordinates': hasCoordinates,
      'direccion': direccionVisible,
      'referencia': referenciaVisible,
      'contacto': _locationContactsSummary(contactos),
    };
  }

  static List<Map<String, dynamic>> _normalizeLocationContacts(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    final List<Map<String, dynamic>> contacts = raw
        .whereType<Map>()
        .map(
          (entry) => <String, dynamic>{
            'nombre': (entry['nombre'] ?? '').toString().trim(),
            'telefono': (entry['telefono'] ?? '').toString().trim(),
            'parentesco': (entry['parentesco'] ?? '').toString().trim(),
            'esPrincipal': entry['esPrincipal'] == true,
          },
        )
        .where((entry) {
          return (entry['nombre'] ?? '').toString().isNotEmpty ||
              (entry['telefono'] ?? '').toString().isNotEmpty ||
              (entry['parentesco'] ?? '').toString().isNotEmpty;
        })
        .toList();
    if (contacts.isEmpty) {
      return contacts;
    }
    final int principalIndex = contacts.indexWhere(
      (entry) => entry['esPrincipal'] == true,
    );
    final int selectedIndex = principalIndex >= 0 ? principalIndex : 0;
    return contacts.asMap().entries.map((entry) {
      return <String, dynamic>{
        ...entry.value,
        'esPrincipal': entry.key == selectedIndex,
      };
    }).toList();
  }

  static Map<String, dynamic> _normalizeSiteVerification(dynamic raw) {
    final Map<String, dynamic> data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return <String, dynamic>{
      'confirmada': data['confirmada'] == true,
      'lat': _readCoordinate(data['lat']),
      'lng': _readCoordinate(data['lng']),
      'direccionReal': (data['direccionReal'] ?? '').toString().trim(),
      'direccionGeocodificada':
          (data['direccionGeocodificada'] ?? '').toString().trim(),
      'referenciaReal': (data['referenciaReal'] ?? '').toString().trim(),
      'contactoEfectivo': (data['contactoEfectivo'] ?? '').toString().trim(),
      'observacion': (data['observacion'] ?? '').toString().trim(),
      'updatedBy': (data['updatedBy'] ?? '').toString().trim(),
      'updatedAt': data['updatedAt'],
    };
  }

  static double? _readCoordinate(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw == null) {
      return null;
    }
    return double.tryParse(raw.toString().trim());
  }

  static String _resolveLocationStatus({
    required dynamic rawStatus,
    required String direccionAdministrativa,
    required List<Map<String, dynamic>> contactos,
    required bool confirmadaEnSitio,
  }) {
    final String status = (rawStatus ?? '').toString().trim();
    if (status.isNotEmpty) {
      return status;
    }
    if (confirmadaEnSitio) {
      return 'verificada_en_sitio';
    }
    final bool hasOperativeContact = contactos.any((contact) {
      final String nombre = (contact['nombre'] ?? '').toString().trim();
      final String telefono = (contact['telefono'] ?? '').toString().trim();
      final String parentesco = (contact['parentesco'] ?? '').toString().trim();
      return nombre.isNotEmpty && telefono.isNotEmpty && parentesco.isNotEmpty;
    });
    if (direccionAdministrativa.isNotEmpty && hasOperativeContact) {
      return 'completa_administrativa';
    }
    return 'pendiente_administrativa';
  }

  static String _locationContactsSummary(dynamic raw) {
    final List<Map<String, dynamic>> contacts = _normalizeLocationContacts(raw);
    if (contacts.isEmpty) {
      return '';
    }
    final List<Map<String, dynamic>> ordered = List<Map<String, dynamic>>.from(
      contacts,
    )..sort((a, b) {
        final bool aPrincipal = a['esPrincipal'] == true;
        final bool bPrincipal = b['esPrincipal'] == true;
        if (aPrincipal == bPrincipal) {
          return 0;
        }
        return aPrincipal ? -1 : 1;
      });
    return ordered.map((contact) {
      final String nombre = (contact['nombre'] ?? '').toString().trim();
      final String telefono = (contact['telefono'] ?? '').toString().trim();
      final String parentesco = (contact['parentesco'] ?? '')
          .toString()
          .trim();
      final List<String> parts = <String>[];
      if (nombre.isNotEmpty) {
        parts.add(nombre);
      }
      if (parentesco.isNotEmpty) {
        parts.add(parentesco);
      }
      if (telefono.isNotEmpty) {
        parts.add(telefono);
      }
      return parts.join(' · ');
    }).join(' | ');
  }

  static Map<String, dynamic> _resolveTratamientoContinuity(
    Map<String, dynamic> patientData,
  ) {
    final Map<String, dynamic> detalleMotivos = patientData['detalleMotivos'] is Map
        ? Map<String, dynamic>.from(patientData['detalleMotivos'] as Map)
        : <String, dynamic>{};
    final dynamic snake = detalleMotivos['finalizar_tratamiento'];
    if (snake is Map) {
      return Map<String, dynamic>.from(snake);
    }
    final dynamic camel = detalleMotivos['finalizarTratamiento'];
    if (camel is Map) {
      return Map<String, dynamic>.from(camel);
    }
    final dynamic rootSnake = patientData['finalizar_tratamiento'];
    if (rootSnake is Map) {
      return Map<String, dynamic>.from(rootSnake);
    }
    return <String, dynamic>{};
  }

  static bool _isContinuityActivePatient(Map<String, dynamic> data) {
    final String estadoPad = (data['estadoPad'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String situacionAsistencialLabel =
        (data['situacionAsistencialLabel'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return data['activoPad'] == true ||
        estadoPad == 'activo en pad' ||
        estadoPad == 'activo' ||
        situacionAsistencialLabel == 'activo en pad';
  }

  static bool _hasInfusorSafe(dynamic value) {
    final String normalized = '${value ?? ''}'.toLowerCase().trim();
    return normalized == 'si' ||
        normalized == 'sí' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'sÃ­' ||
        normalized == 'sÃƒÂ­';
  }

  static String _normalizeInfusorValue(dynamic value) {
    final String normalized = '${value ?? ''}'.toLowerCase().trim();
    if (normalized == 'sí' || normalized == 'sÃ­') {
      return 'sÃ­';
    }
    return normalized;
  }

}
