// Servicio para guardar caso PAD en Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hext/features/agenda/data/agenda_repo.dart';
import 'package:hext/features/pad/services/pad_post_save_orchestrator.dart';

class PadFirestoreService {
  /// Actualiza un caso PAD en la colección censoPacientes por id.
  static Future<void> actualizarCensoPaciente(
    String id,
    Map<String, dynamic> data,
  ) async {
    final User user = _requireUser();
    final docRef = _censoPacientesRef.doc(id);
    final DocumentSnapshot<Map<String, dynamic>> existingDoc = await docRef.get();
    final Map<String, dynamic> existingData = existingDoc.data() ??
        const <String, dynamic>{};
    await docRef.update({
      ...data,
      'ubicacion': _buildCanonicalLocationMap(
        incoming: data,
        existing: existingData['ubicacion'] is Map
            ? Map<String, dynamic>.from(existingData['ubicacion'] as Map)
            : <String, dynamic>{},
      ),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });

    final bool cerrarAgenda =
        data['estadoPad'] == 'egresado' ||
        data['fechaEgreso'] != null ||
        data['tipoEgreso'] != null ||
        data['situacionAsistencialLabel'] == 'Egresado';

    if (cerrarAgenda) {
      await cerrarAgendaEventPorPaciente(id);
    }

    await _syncAgendaEventsForPatient(
      patientId: id,
      data: data,
      derivedSituacionAsistencialLabel:
          (data['situacionAsistencialLabel'] ?? '').toString().trim(),
    );

    // Conciliación operativa PAD (agenda y pendientes)
    await FirestoreAgendaRepo(
      firestore: _firestore,
    ).ensureAgendaContinuity(id);
    try {
      await PadPostSaveOrchestrator.reconcileAfterSave(
        patientId: id,
        data: data,
      );
    } catch (e) {
      debugPrint('[PadPostSaveOrchestrator] error post-guardado: $e');
    }

    debugPrint('[PadFirestoreService.actualizarCensoPaciente] docId = $id');
  }

  /// Obtiene un caso PAD desde la colección censoPacientes por id.
  static Future<Map<String, dynamic>?> obtenerCensoPaciente(String id) async {
    _requireUser();
    final doc = await _censoPacientesRef.doc(id).get();
    if (!doc.exists) return null;
    return <String, dynamic>{'id': doc.id, ...doc.data()!};
  }

  static CollectionReference<Map<String, dynamic>> get _candidatosRef =>
      _firestore.collection('candidatos');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _censoPacientesRef =>
      _firestore.collection('censoPacientes');

  static User _requireUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Usuario no autenticado',
      );
    }
    return user;
  }

  static Map<String, dynamic> _buildCanonicalLocationMap({
    required Map<String, dynamic> incoming,
    Map<String, dynamic> existing = const <String, dynamic>{},
  }) {
    final String barrio = _firstNonEmpty(<dynamic>[
      incoming['barrio'],
      existing['barrio'],
    ]);
    final String direccionAdministrativa = _firstNonEmpty(<dynamic>[
      incoming['direccionAdministrativa'],
      incoming['direccion'],
      existing['direccionAdministrativa'],
      existing['direccion'],
    ]);
    final String referenciaAdministrativa = _firstNonEmpty(<dynamic>[
      incoming['referenciaAdministrativa'],
      incoming['referenciaUbicacion'],
      incoming['referencia'],
      existing['referenciaAdministrativa'],
      existing['referencia'],
    ]);
    final List<Map<String, dynamic>> contactos = _normalizeLocationContacts(
      incoming['contactos'] is List ? incoming['contactos'] : existing['contactos'],
    );
    final String observacionesAcceso = _firstNonEmpty(<dynamic>[
      incoming['observacionesAcceso'],
      existing['observacionesAcceso'],
      incoming['observaciones'],
    ]);

    return <String, dynamic>{
      'barrio': barrio,
      'direccionAdministrativa': direccionAdministrativa,
      'referenciaAdministrativa': referenciaAdministrativa,
      'contactos': contactos,
      'observacionesAcceso': observacionesAcceso,
      'estadoUbicacion':
          (direccionAdministrativa.isNotEmpty && contactos.isNotEmpty)
              ? 'completa_administrativa'
              : 'pendiente_administrativa',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<Map<String, dynamic>> _normalizeLocationContacts(dynamic raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map(
          (Map contact) => <String, dynamic>{
            'nombre': (contact['nombre'] ?? '').toString().trim(),
            'telefono': (contact['telefono'] ?? '').toString().trim(),
            'parentesco': (contact['parentesco'] ?? '').toString().trim(),
            'esPrincipal': contact['esPrincipal'] == true,
          },
        )
        .where(
          (Map<String, dynamic> contact) =>
              (contact['nombre'] as String).isNotEmpty ||
              (contact['telefono'] as String).isNotEmpty ||
              (contact['parentesco'] as String).isNotEmpty,
        )
        .toList();
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final dynamic value in values) {
      final String text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static Future<String> guardarCandidato(Map<String, dynamic> data) async {
    debugPrint('[PadFirestoreService.guardarCandidato] inicio');
    try {
      final User user = _requireUser();
      debugPrint('[PadFirestoreService.guardarCandidato] uid = ${user.uid}');
      debugPrint(
        '[PadFirestoreService.guardarCandidato] email = ${user.email}',
      );
      debugPrint(
        '[PadFirestoreService.guardarCandidato] collection = censoPacientes',
      );

      final now = FieldValue.serverTimestamp();
      final String decision = (data['decision'] ?? '').toString().trim();
      final String decisionLabel = (data['resultadoPadLabel'] ?? '')
          .toString()
          .trim();
      final String estadoPad = (data['estadoPad'] ?? '').toString().trim();
      final String situacionAsistencial = (data['situacionAsistencial'] ?? '')
          .toString()
          .trim();
      final String situacionAsistencialDataLabel =
          (data['situacionAsistencialLabel'] ?? '').toString().trim();
      final bool ingresoAprobado =
          decision == 'ingresoAprobado' || decisionLabel == 'Ingreso aprobado';
      final String resultadoPadLabel = decisionLabel.isNotEmpty
          ? decisionLabel
          : (ingresoAprobado ? 'Ingreso aprobado' : decision);
      final String situacionAsistencialLabel =
          situacionAsistencialDataLabel.isNotEmpty
          ? situacionAsistencialDataLabel
          : (ingresoAprobado ? 'Activo en PAD' : 'En valoración');

      final dynamic fechaVisitaRaw = data['fechaVisita'];
      final DateTime? fechaVisita = _readAgendaDate(fechaVisitaRaw);
      final String horaVisita = (data['horaVisita'] ?? '').toString().trim();

      debugPrint(
        '[PadFirestoreService.guardarCandidato] payload decision=$decision estadoPad=$estadoPad situacionAsistencial=$situacionAsistencial situacionAsistencialLabel=$situacionAsistencialDataLabel fechaVisitaRaw=$fechaVisitaRaw (${fechaVisitaRaw.runtimeType}) fechaVisita=$fechaVisita horaVisita=$horaVisita',
      );

      final docRef = await _censoPacientesRef.add(<String, dynamic>{
        ...data,
        'ubicacion': _buildCanonicalLocationMap(incoming: data),

        // Campos canónicos para el censo
        'diagnosticos': data['diagnosticos'] ?? data['diagnostico'],
        'especialidadKey':
            data['especialidadKey'] ?? data['especialidadPrincipalTratante'],
        'especialidadLabel':
            data['especialidadLabel'] ?? data['especialidadPrincipalTratante'],
        'aseguradoraKey': data['aseguradoraKey'] ?? data['aseguradora'],
        'aseguradoraLabel': data['aseguradoraLabel'] ?? data['aseguradora'],
        'sexoKey': data['sexoKey'] ?? data['sexo'],
        'sexoLabel': data['sexoLabel'] ?? data['sexo'],
        'tipoAseguramientoKey':
            data['tipoAseguramientoKey'] ?? data['tipoAseguramiento'],
        'tipoAseguramientoLabel':
            data['tipoAseguramientoLabel'] ?? data['tipoAseguramiento'],
        'regimenAseguramientoKey':
            data['regimenAseguramientoKey'] ?? data['regimenAseguramiento'],
        'regimenAseguramientoLabel':
            data['regimenAseguramientoLabel'] ?? data['regimenAseguramiento'],
        'tipoCaptacionPadKey':
            data['tipoCaptacionPadKey'] ?? data['tipoCaptacionPad'],
        'tipoCaptacionPadLabel':
            data['tipoCaptacionPadLabel'] ?? data['tipoCaptacionPad'],
        'unidadFuncionalOrigenKey':
            data['unidadFuncionalOrigenKey'] ?? data['unidadFuncionalOrigen'],
        'unidadFuncionalOrigenLabel':
            data['unidadFuncionalOrigenLabel'] ?? data['unidadFuncionalOrigen'],
        'situacionAsistencialLabel': situacionAsistencialLabel,
        'situacionAsistencialKey': 'activo_en_pad',
        'resultadoPadKey': data['resultadoPadKey'] ?? data['decision'],
        'resultadoPadLabel': resultadoPadLabel,
        'fechaIngreso': now,

        // Compatibilidad con valores ya visibles en el documento
        'nombreCompleto': data['nombreCompleto'],
        'identificacion': data['identificacion'],
        'edad': data['edad'],
        'barrio': data['barrio'],
        'observaciones': data['observaciones'],

        // Auditoría
        'createdBy': user.uid,
        'createdAt': data['createdAt'] ?? now,
        'updatedAt': now,
      });

      debugPrint('[PadFirestoreService.guardarCandidato] escritura OK');
      debugPrint('[PadFirestoreService.guardarCandidato] docId = ${docRef.id}');

      await _syncAgendaEventsForPatient(
        patientId: docRef.id,
        data: data,
        derivedSituacionAsistencialLabel: situacionAsistencialLabel,
      );
      // Conciliación operativa PAD (agenda y pendientes)
      await FirestoreAgendaRepo(
        firestore: _firestore,
      ).ensureAgendaContinuity(docRef.id);
      try {
        await PadPostSaveOrchestrator.reconcileAfterSave(
          patientId: docRef.id,
          data: data,
        );
      } catch (e) {
        debugPrint('[PadPostSaveOrchestrator] error post-guardado: $e');
      }
      return docRef.id;
    } catch (e, st) {
      debugPrint('[PadFirestoreService.guardarCandidato] ERROR = $e');
      debugPrint('[PadFirestoreService.guardarCandidato] STACK = $st');
      rethrow;
    }
  }

  static Future<void> actualizarCandidato(
    String candidatoId,
    Map<String, dynamic> data,
  ) async {
    _requireUser();

    await _candidatosRef.doc(candidatoId).update(<String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> obtenerCandidato(
    String candidatoId,
  ) async {
    _requireUser();

    final DocumentSnapshot<Map<String, dynamic>> doc = await _candidatosRef
        .doc(candidatoId)
        .get();

    return doc.data();
  }

  /// Cierra todos los eventos de agenda activos para un paciente (isClosed=false)
  static Future<void> cerrarAgendaEventPorPaciente(String patientId) async {
    final query = await FirebaseFirestore.instance
        .collection('agenda_events')
        .where('patientId', isEqualTo: patientId)
        .where('isClosed', isEqualTo: false)
        .get();

    for (final doc in query.docs) {
      await doc.reference.update({
        'isClosed': true,
        'estadoAgenda': 'cerrada',
        'closedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static bool _isActivePadCase({
    required Map<String, dynamic> data,
    required String derivedSituacionAsistencialLabel,
  }) {
    final String decision = (data['decision'] ?? '').toString().trim();
    final String estadoPad = (data['estadoPad'] ?? '').toString().trim();
    final String situacionAsistencial = (data['situacionAsistencial'] ?? '')
        .toString()
        .trim();
    final String situacionAsistencialLabel =
        (data['situacionAsistencialLabel'] ?? '').toString().trim();

    bool matches(String value, Set<String> expected) =>
        expected.contains(value.trim().toLowerCase());

    final String resultadoPadLabel = (data['resultadoPadLabel'] ?? '')
        .toString()
        .trim();
    final String resultadoPadKey = (data['resultadoPadKey'] ?? '').toString().trim();

    return matches(decision, const <String>{'ingreso aprobado', 'ingresoaprobado'}) ||
        matches(resultadoPadLabel, const <String>{'ingreso aprobado'}) ||
        matches(resultadoPadKey, const <String>{'ingresoaprobado'}) ||
        matches(derivedSituacionAsistencialLabel, const <String>{
          'activo en pad',
        }) ||
        matches(situacionAsistencialLabel, const <String>{'activo en pad'}) ||
        matches(situacionAsistencial, const <String>{
          'activo en pad',
          'ingresado',
        }) ||
        matches(estadoPad, const <String>{
          'activo en pad',
          'ingresado',
          'aprobado_para_ingreso',
          'aprobado para ingreso',
        });
  }

  static DateTime? _readAgendaDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return DateTime(raw.year, raw.month, raw.day);
    }
    if (raw is Timestamp) {
      final DateTime date = raw.toDate();
      return DateTime(date.year, date.month, date.day);
    }
    if (raw is String) {
      final String value = raw.trim();
      if (value.isEmpty) return null;

      final DateTime? isoParsed = DateTime.tryParse(value);
      if (isoParsed != null) {
        return DateTime(isoParsed.year, isoParsed.month, isoParsed.day);
      }

      final RegExp ddMmYyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
      final Match? match = ddMmYyyy.firstMatch(value);
      if (match != null) {
        final int? day = int.tryParse(match.group(1)!);
        final int? month = int.tryParse(match.group(2)!);
        final int? year = int.tryParse(match.group(3)!);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  static Future<void> _syncAgendaEventsForPatient({
    required String patientId,
    required Map<String, dynamic> data,
    required String derivedSituacionAsistencialLabel,
  }) async {
    final bool isActivePadCase = _isActivePadCase(
      data: data,
      derivedSituacionAsistencialLabel: derivedSituacionAsistencialLabel,
    );
    final Map<String, dynamic> detalleMotivos =
        (data['detalleMotivos'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final List<_AgendaMotivoProgramable> motivosProgramables =
        _buildMotivosProgramables(data: data);

    debugPrint(
      '[PadFirestoreService._syncAgendaEventsForPatient] patientId=$patientId active=$isActivePadCase',
    );
    debugPrint(
      '[PadFirestoreService._syncAgendaEventsForPatient] detalleMotivos recibido=$detalleMotivos',
    );
    debugPrint(
      '[PadFirestoreService._syncAgendaEventsForPatient] motivos activos detectados=${motivosProgramables.map((m) => m.motivoKey).join(', ')}',
    );

    if (!isActivePadCase) {
      debugPrint(
        '[PadFirestoreService._syncAgendaEventsForPatient] agenda_event omitido: caso no activo en PAD',
      );
      return;
    }
    if (motivosProgramables.isEmpty) {
      debugPrint(
        '[PadFirestoreService._syncAgendaEventsForPatient] agenda_event omitido: no hay motivos activos con fecha y hora',
      );
      return;
    }

    try {
      final FirestoreAgendaRepo agendaRepo = FirestoreAgendaRepo(
        firestore: _firestore,
      );
      for (final _AgendaMotivoProgramable motivo in motivosProgramables) {
        final String fechaNormalizada =
            '${motivo.fecha.year.toString().padLeft(4, '0')}-'
            '${motivo.fecha.month.toString().padLeft(2, '0')}-'
            '${motivo.fecha.day.toString().padLeft(2, '0')}';
        debugPrint(
          '[PadFirestoreService._syncAgendaEventsForPatient] motivo=${motivo.motivoKey} motivoAgenda=${motivo.motivoAgenda} fechaVisita=${motivo.fecha} horaVisita=${motivo.hora} fechaNormalizada=$fechaNormalizada detalleMotivo=${motivo.detalleMotivo}',
        );
        final bool exists = await agendaRepo.agendaEventExists(
          patientId: patientId,
          fecha: motivo.fecha,
          hora: motivo.hora,
          sourceType: 'paciente_pad',
          motivoKey: motivo.motivoKey,
        );
        if (exists) {
          debugPrint(
            '[PadFirestoreService._syncAgendaEventsForPatient] agenda_event omitido por duplicado patientId=$patientId motivoKey=${motivo.motivoKey} fecha=${motivo.fecha} hora=${motivo.hora}',
          );
          continue;
        }

        debugPrint(
          '[PadFirestoreService._syncAgendaEventsForPatient] intentando crear agenda_event para motivo=${motivo.motivoKey}',
        );

        final String agendaEventId = await agendaRepo.createAgendaEvent(
          patientId: patientId,
          patientDisplay: (data['nombreCompleto'] ?? '').toString().toUpperCase(),
          identificacion: (data['identificacion'] ?? '').toString().trim(),
          fecha: motivo.fecha,
          hora: motivo.hora,
          dx: (data['diagnostico'] ?? '').toString().trim(),
          tratamiento: motivo.tratamiento,
          barrio: (data['barrio'] ?? '').toString().trim(),
          direccion: (data['direccion'] ?? '').toString().trim(),
          referencia:
              (data['referenciaUbicacion'] ?? data['referencia'] ?? '')
                  .toString()
                  .trim(),
          contacto: (data['contacto'] ?? '').toString().trim(),
          motivoAgenda: motivo.motivoAgenda,
          detalleMotivo: motivo.detalleMotivo,
          motivoKey: motivo.motivoKey,
          motivoLabel: motivo.motivoLabel,
          estadoMotivo: motivo.estadoMotivo,
          fechaProbableFinalizacion: motivo.fechaProbableFinalizacion,
          pacienteCuentaConInfusor: motivo.pacienteCuentaConInfusor,
          antibioticoCandidatoInfusor: motivo.antibioticoCandidatoInfusor,
          antibioticoDetectado: motivo.antibioticoDetectado,
          requiereCambioDiarioInfusor: motivo.requiereCambioDiarioInfusor,
          programacionSugerida: motivo.programacionSugerida,
          frecuenciaTratamiento: motivo.frecuenciaTratamiento,
          frecuenciaTratamientoLabel: motivo.frecuenciaTratamientoLabel,
          tipoActividadAgenda: motivo.tipoActividadAgenda,
          estadoAgenda: 'programada',
          sourceType: 'paciente_pad',
          isClosed: false,
        );
        debugPrint(
          '[PadFirestoreService._syncAgendaEventsForPatient] agenda_event creado id=$agendaEventId motivo=${motivo.motivoKey} patientId=$patientId',
        );
      }
    } catch (e, st) {
      debugPrint(
        '[PadFirestoreService._syncAgendaEventsForPatient] ERROR agenda_event = $e',
      );
      debugPrint(
        '[PadFirestoreService._syncAgendaEventsForPatient] STACK agenda_event = $st',
      );
    }
  }

  static List<_AgendaMotivoProgramable> _buildMotivosProgramables({
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> detalleMotivos =
        (data['detalleMotivos'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final List<_AgendaMotivoProgramable> motivos = <_AgendaMotivoProgramable>[];

    for (final MapEntry<String, dynamic> entry in detalleMotivos.entries) {
      final String motivoKey = entry.key.trim();
      final Map<String, dynamic> detalle =
          (entry.value as Map<String, dynamic>?) ?? <String, dynamic>{};
      final bool activo = detalle['activo'] != false;
      final bool disponibleParaAgenda = detalle['disponibleParaAgenda'] == true;
      final String motivoAgenda =
          (detalle['motivoAgenda'] ?? detalle['motivoLabel'] ?? '')
              .toString()
              .trim();
      final DateTime? fecha = _resolveFechaProgramable(
        motivoKey: motivoKey,
        detalle: detalle,
      );
      final String hora = _resolveHoraProgramable(
        motivoKey: motivoKey,
        detalle: detalle,
      );

      debugPrint(
        '[PadFirestoreService._buildMotivosProgramables] motivoKey=$motivoKey activo=$activo disponibleParaAgenda=$disponibleParaAgenda fechaVisita=$fecha horaVisita=$hora',
      );

      if (!activo || !disponibleParaAgenda) {
        debugPrint(
          '[PadFirestoreService._buildMotivosProgramables] motivo omitido por activo/disponible motivoKey=$motivoKey activo=$activo disponibleParaAgenda=$disponibleParaAgenda',
        );
        continue;
      }
      if (fecha == null || hora.isEmpty) {
        debugPrint(
          '[PadFirestoreService._buildMotivosProgramables] motivo omitido por fecha/hora incompletas motivo=$motivoKey fecha=$fecha hora=$hora',
        );
        continue;
      }

      final DateTime? fechaProbableFinalizacion =
          _readAgendaDate(detalle['fechaProbableFinalizacion']) ??
          (motivoKey == 'programacion_procedimiento' ? fecha : null);
      final Map<String, dynamic> detalleMotivo =
          (detalle['detalleMotivo'] as Map<String, dynamic>?) ??
          _buildFallbackDetalleMotivo(detalle);
      final String pacienteCuentaConInfusor = _readTrimmed(
        detalle['pacienteCuentaConInfusor'],
        fallback: detalleMotivo['pacienteCuentaConInfusor'],
      );
      final bool antibioticoCandidatoInfusor =
          detalle['antibioticoCandidatoInfusor'] == true ||
          detalleMotivo['antibioticoCandidatoInfusor'] == true;
      final String antibioticoDetectado = _readTrimmed(
        detalle['antibioticoDetectado'],
        fallback: detalleMotivo['antibioticoDetectado'],
      );
      final String programacionSugerida = _readTrimmed(
        detalle['programacionSugerida'],
        fallback: detalleMotivo['programacionSugerida'],
      );
      final String frecuenciaTratamiento = _readTrimmed(
        detalle['frecuenciaTratamiento'],
        fallback: detalleMotivo['frecuenciaTratamiento'],
      );
      final String frecuenciaTratamientoLabel = _readTrimmed(
        detalle['frecuenciaTratamientoLabel'],
        fallback: detalleMotivo['frecuenciaTratamientoLabel'],
      );
      final bool requiereCambioDiarioInfusor = _requiresCambioDiarioInfusor(
        motivoKey: motivoKey,
        pacienteCuentaConInfusor: pacienteCuentaConInfusor,
        antibioticoCandidatoInfusor: antibioticoCandidatoInfusor,
      );
      final String tipoActividadAgenda = _tipoActividadAgenda(
        motivoKey: motivoKey,
        pacienteCuentaConInfusor: pacienteCuentaConInfusor,
        antibioticoCandidatoInfusor: antibioticoCandidatoInfusor,
      );

      motivos.add(
        _AgendaMotivoProgramable(
          motivoKey: motivoKey,
          motivoLabel: _motivoLabelFromKey(motivoKey),
          motivoAgenda: motivoAgenda.isEmpty
              ? _motivoLabelFromKey(motivoKey)
              : motivoAgenda,
          fecha: fecha,
          hora: hora,
          tratamiento: _buildTratamientoAgenda(
            motivoKey: motivoKey,
            detalle: detalle,
          ),
          detalleMotivo: detalleMotivo,
          fechaProbableFinalizacion: fechaProbableFinalizacion,
          estadoMotivo: _deriveEstadoMotivo(
            activo: activo,
            fechaProbableFinalizacion: fechaProbableFinalizacion,
          ),
          pacienteCuentaConInfusor: pacienteCuentaConInfusor,
          antibioticoCandidatoInfusor: antibioticoCandidatoInfusor,
          antibioticoDetectado: antibioticoDetectado,
          requiereCambioDiarioInfusor: requiereCambioDiarioInfusor,
          programacionSugerida: programacionSugerida,
          frecuenciaTratamiento: frecuenciaTratamiento,
          frecuenciaTratamientoLabel: frecuenciaTratamientoLabel,
          tipoActividadAgenda: tipoActividadAgenda,
        ),
      );
    }

    return motivos;
  }

  static DateTime? _resolveFechaProgramable({
    required String motivoKey,
    required Map<String, dynamic> detalle,
  }) {
    final DateTime? fechaVisita = _readAgendaDate(detalle['fechaVisita']);
    if (fechaVisita != null) {
      return fechaVisita;
    }
    final DateTime? fechaSugerida = _readAgendaDate(detalle['fechaSugeridaVisita']);
    if (fechaSugerida != null) {
      return fechaSugerida;
    }
    switch (motivoKey) {
      case 'finalizar_tratamiento':
        return _readAgendaDate(detalle['fechaPrimeraVisita']);
      case 'clinica_heridas':
        return _readAgendaDate(detalle['fechaPrimeraVisita']) ??
            _readAgendaDate(detalle['fechaPrimeraCuracion']);
      case 'programacion_procedimiento':
        return _readAgendaDate(detalle['fechaProgramada']) ??
            _readAgendaDate(detalle['fechaProcedimiento']);
      default:
        return null;
    }
  }

  static String _resolveHoraProgramable({
    required String motivoKey,
    required Map<String, dynamic> detalle,
  }) {
    final String horaVisita = (detalle['horaVisita'] ?? '').toString().trim();
    if (horaVisita.isNotEmpty) {
      return horaVisita;
    }
    final String horaSugerida = (detalle['horaSugeridaVisita'] ?? '')
        .toString()
        .trim();
    if (horaSugerida.isNotEmpty) {
      return horaSugerida;
    }
    switch (motivoKey) {
      case 'finalizar_tratamiento':
        return (detalle['horaPrimeraVisita'] ?? '')
            .toString()
            .trim();
      case 'clinica_heridas':
        return (detalle['horaPrimeraVisita'] ??
                detalle['horaPrimeraCuracion'] ??
                '')
            .toString()
            .trim();
      case 'programacion_procedimiento':
        return (detalle['horaProgramada'] ?? detalle['horaProcedimiento'] ?? '')
            .toString()
            .trim();
      default:
        return '';
    }
  }

  static Map<String, dynamic> _buildFallbackDetalleMotivo(
    Map<String, dynamic> detalle,
  ) {
    return Map<String, dynamic>.from(detalle)
      ..remove('activo')
      ..remove('motivoKey')
      ..remove('motivoLabel')
      ..remove('motivoAgenda')
      ..remove('fechaVisita')
      ..remove('horaVisita')
      ..remove('sourceType')
      ..remove('estadoAgenda')
      ..remove('disponibleParaAgenda');
  }

  static String _motivoLabelFromKey(String motivoKey) {
    switch (motivoKey) {
      case 'finalizar_tratamiento':
        return 'Finalizar tratamiento';
      case 'clinica_heridas':
        return 'Clínica de heridas';
      case 'programacion_procedimiento':
        return 'Programación de procedimiento';
      default:
        return motivoKey;
    }
  }

  static String _buildTratamientoAgenda({
    required String motivoKey,
    required Map<String, dynamic> detalle,
  }) {
    switch (motivoKey) {
      case 'finalizar_tratamiento':
        return (detalle['tratamientoAFinalizar'] ??
                detalle['nombreTratamiento'] ??
                detalle['tratamientoPendiente'] ??
                '')
            .toString()
            .trim();
      case 'clinica_heridas':
        return (detalle['tipoHerida'] ?? '').toString().trim();
      case 'programacion_procedimiento':
        return (detalle['procedimientoRequerido'] ?? '').toString().trim();
      default:
        return '';
    }
  }

  static String _readTrimmed(dynamic value, {dynamic fallback}) {
    final String primary = (value ?? '').toString().trim();
    if (primary.isNotEmpty) {
      return primary;
    }
    return (fallback ?? '').toString().trim();
  }

  static bool _requiresCambioDiarioInfusor({
    required String motivoKey,
    required String? pacienteCuentaConInfusor,
    required bool antibioticoCandidatoInfusor,
  }) {
    return motivoKey == 'finalizar_tratamiento' &&
        antibioticoCandidatoInfusor &&
        (pacienteCuentaConInfusor ?? '').trim() == 'si';
  }

  static String _tipoActividadAgenda({
    required String motivoKey,
    required String? pacienteCuentaConInfusor,
    required bool antibioticoCandidatoInfusor,
  }) {
    if (motivoKey != 'finalizar_tratamiento' || !antibioticoCandidatoInfusor) {
      return '';
    }

    switch ((pacienteCuentaConInfusor ?? '').trim()) {
      case 'si':
        return 'Cambio de infusor / tratamiento';
      case 'no':
        return 'Administración de tratamiento';
      case 'por_confirmar':
        return 'Validar disponibilidad de infusor';
      default:
        return '';
    }
  }

  static String _deriveEstadoMotivo({
    required bool activo,
    required DateTime? fechaProbableFinalizacion,
  }) {
    if (!activo) {
      return 'finalizado';
    }
    if (fechaProbableFinalizacion == null) {
      return 'en_curso';
    }

    final DateTime today = DateTime.now();
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final DateTime normalizedFinal = DateTime(
      fechaProbableFinalizacion.year,
      fechaProbableFinalizacion.month,
      fechaProbableFinalizacion.day,
    );
    final int diasRestantes = normalizedFinal
        .difference(normalizedToday)
        .inDays;

    if (diasRestantes > 2) {
      return 'en_curso';
    }
    if (diasRestantes == 1 || diasRestantes == 2) {
      return 'proximo_a_finalizar';
    }
    return 'fecha_cumplida';
  }
}

class _AgendaMotivoProgramable {
  const _AgendaMotivoProgramable({
    required this.motivoKey,
    required this.motivoLabel,
    required this.motivoAgenda,
    required this.fecha,
    required this.hora,
    required this.tratamiento,
    required this.detalleMotivo,
    required this.fechaProbableFinalizacion,
    required this.estadoMotivo,
    required this.pacienteCuentaConInfusor,
    required this.antibioticoCandidatoInfusor,
    required this.antibioticoDetectado,
    required this.requiereCambioDiarioInfusor,
    required this.programacionSugerida,
    required this.frecuenciaTratamiento,
    required this.frecuenciaTratamientoLabel,
    required this.tipoActividadAgenda,
  });

  final String motivoKey;
  final String motivoLabel;
  final String motivoAgenda;
  final DateTime fecha;
  final String hora;
  final String tratamiento;
  final Map<String, dynamic> detalleMotivo;
  final DateTime? fechaProbableFinalizacion;
  final String estadoMotivo;
  final String pacienteCuentaConInfusor;
  final bool antibioticoCandidatoInfusor;
  final String antibioticoDetectado;
  final bool requiereCambioDiarioInfusor;
  final String programacionSugerida;
  final String frecuenciaTratamiento;
  final String frecuenciaTratamientoLabel;
  final String tipoActividadAgenda;
}
