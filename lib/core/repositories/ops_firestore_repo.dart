
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class OpsFirestoreRepo {
  OpsFirestoreRepo({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Lee eventos de agenda desde Firestore (agenda_events)
  Future<List<Map<String, dynamic>>> fetchAgendaEvents() async {
    final snapshot = await _firestore.collection('agenda_events').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Lee censoPacientes desde Firestore (censoPacientes)
  Future<List<Map<String, dynamic>>> fetchCensoPacientes() async {
    final snapshot = await _firestore.collection('censoPacientes').get();
    return snapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Construye pendientes derivados de agenda_events y censoPacientes (Fase 1)
  Future<List<OpsPendingRecord>> buildDerivedPendings() async {
    final now = DateTime.now();
    final proximos3dias = now.add(const Duration(days: 3));
    final List<OpsPendingRecord> result = [];
    final Set<String> agendaKeys = <String>{};
    final Set<String> patientIdsWithAgenda = <String>{};

    // 1. Pendientes de agenda_events
    final agendaEvents = await fetchAgendaEvents();
    for (final event in agendaEvents) {
      final estadoAgenda = (event['estadoAgenda'] ?? '').toString().toLowerCase();
      final String cancelReason = (event['cancelReason'] ?? '').toString().toLowerCase();
      final DateTime? fechaEvento = _readDate(event['fecha']);
      final String agendaKey =
          '${event['patientId'] ?? ''}|${fechaEvento == null ? '' : _dateKey(fechaEvento)}|${event['motivoKey'] ?? ''}';

      if (estadoAgenda == 'cancelada' ||
          cancelReason == 'infusor_unico_por_dia' ||
          cancelReason == 'normalizacion_infusor' ||
          !agendaKeys.add(agendaKey)) {
        continue;
      }
      final String patientId = (event['patientId'] ?? '').toString().trim();
      if (patientId.isNotEmpty) {
        patientIdsWithAgenda.add(patientId);
      }

      // 1.1 Agenda vencida/no cerrada
      if (fechaEvento != null && fechaEvento.isBefore(now) &&
          estadoAgenda != 'cerrada' && estadoAgenda != 'finalizada' && estadoAgenda != 'cancelada') {
        result.add(OpsPendingRecord(
          id: 'derived-agenda-vencida-${event['id'] ?? event.hashCode}',
          tipo: 'Agenda vencida',
          paciente: (event['patientDisplay'] ?? event['pacienteNombre'] ?? event['nombrePaciente'] ?? '').toString(),
          vencimiento: fechaEvento,
          detalle: 'Agenda vencida/no cerrada',
          rutaContexto: '/schedule',
          contextoLabel: 'Agenda',
          visitId: event['id']?.toString(),
          patientId: event['patientId']?.toString(),
          pendingId: null,
          status: 'pendiente',
          responsable: (event['responsableNombre'] ?? '').toString(),
        ));
      }

      // 1.2 Agenda sin responsable
      final responsableId = (event['responsableId'] ?? event['responsableUid'] ?? '').toString();
      final responsableNombre = (event['responsableNombre'] ?? '').toString();
      if ((estadoAgenda == 'programada' || estadoAgenda == 'pendiente') &&
          responsableId.isEmpty &&
          responsableNombre.isEmpty &&
          (fechaEvento == null || !fechaEvento.isBefore(now))) {
        result.add(OpsPendingRecord(
          id: 'derived-agenda-sin-resp-${event['id'] ?? event.hashCode}',
          tipo: 'Agenda sin responsable',
          paciente: (event['patientDisplay'] ?? event['pacienteNombre'] ?? event['nombrePaciente'] ?? '').toString(),
          vencimiento: fechaEvento ?? now,
          detalle: 'Agenda programada sin responsable asignado',
          rutaContexto: '/schedule',
          contextoLabel: 'Agenda',
          visitId: event['id']?.toString(),
          patientId: event['patientId']?.toString(),
          pendingId: null,
          status: 'pendiente',
          responsable: 'Sin asignar',
        ));
      }
    }

    // 2. Pendientes de tratamiento próximo a finalizar (censoPacientes)
    final censoPacientes = await fetchCensoPacientes();
    for (final paciente in censoPacientes) {
      final String estadoPad = (paciente['estadoPad'] ?? '').toString().toLowerCase();
      final String estado = (paciente['estado'] ?? '').toString().toLowerCase();
      final bool activo = paciente['activo'] == true ||
          paciente['activoPad'] == true ||
          estado == 'activo' ||
          estadoPad == 'activo en pad' ||
          estadoPad == 'activo';
      if (!activo) continue;
      final String patientId = (paciente['id'] ?? '').toString().trim();
      if (patientId.isEmpty || !patientIdsWithAgenda.contains(patientId)) {
        continue;
      }
        final Map<String, dynamic>? detalleMotivos =
          paciente['detalleMotivos'] is Map
          ? Map<String, dynamic>.from(paciente['detalleMotivos'] as Map)
          : null;
        final Map<String, dynamic>? finalizar =
          detalleMotivos != null && detalleMotivos['finalizar_tratamiento'] is Map
          ? Map<String, dynamic>.from(
            detalleMotivos['finalizar_tratamiento'] as Map,
          )
          : null;
      final fechaFinRaw = finalizar != null ? finalizar['fechaProbableFinalizacion'] : null;
      final DateTime? fechaFin = _readDate(fechaFinRaw);
      if (fechaFin != null && fechaFin.isAfter(now) && fechaFin.isBefore(proximos3dias)) {
        result.add(OpsPendingRecord(
          id: 'derived-trat-fin-${paciente['id'] ?? paciente.hashCode}',
          tipo: 'Tratamiento próximo a finalizar',
          paciente: (paciente['nombreCompleto'] ?? paciente['nombre'] ?? '').toString(),
          vencimiento: fechaFin,
          detalle: 'Tratamiento próximo a finalizar (${fechaFin.day.toString().padLeft(2, '0')}/${fechaFin.month.toString().padLeft(2, '0')})',
          rutaContexto: '/cases',
          contextoLabel: 'Paciente',
          visitId: null,
          patientId: paciente['id']?.toString(),
          pendingId: null,
          status: 'pendiente',
          responsable: '',
        ));
      }

      if (_requiresLocationPending(paciente)) {
        result.add(OpsPendingRecord(
          id: 'derived-ubicacion-${paciente['id'] ?? paciente.hashCode}',
          tipo: 'Ubicación incompleta',
          paciente: (paciente['nombreCompleto'] ?? paciente['nombre'] ?? '').toString(),
          vencimiento: now,
          detalle: 'Completar dirección y al menos un contacto operativo.',
          rutaContexto: '/schedule',
          contextoLabel: 'Agenda',
          visitId: null,
          patientId: patientId,
          pendingId: null,
          status: 'pendiente',
          responsable: '',
        ));
      }
    }

    return result;
  }

  DateTime? _readDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) {
      final String value = raw.trim();
      if (value.isEmpty) return null;
      final DateTime? iso = DateTime.tryParse(value);
      if (iso != null) return iso;
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

  String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  bool _hasMinimumOperativeLocation(Map<String, dynamic> paciente) {
    final Map<String, dynamic> ubicacion = paciente['ubicacion'] is Map
        ? Map<String, dynamic>.from(paciente['ubicacion'] as Map)
        : <String, dynamic>{};
    final String direccion =
        (ubicacion['direccionAdministrativa'] ??
                ubicacion['direccion'] ??
                paciente['direccion'] ??
                '')
            .toString()
            .trim();
    if (direccion.isEmpty) {
      return false;
    }
    final dynamic rawContacts = ubicacion['contactos'];
    if (rawContacts is! List) {
      return false;
    }
    return rawContacts.whereType<Map>().any((contact) {
      final String nombre = (contact['nombre'] ?? '').toString().trim();
      final String telefono = (contact['telefono'] ?? '').toString().trim();
      final String parentesco = (contact['parentesco'] ?? '').toString().trim();
      return nombre.isNotEmpty && telefono.isNotEmpty && parentesco.isNotEmpty;
    });
  }

  bool _requiresLocationPending(Map<String, dynamic> paciente) {
    final Map<String, dynamic> ubicacion = paciente['ubicacion'] is Map
        ? Map<String, dynamic>.from(paciente['ubicacion'] as Map)
        : <String, dynamic>{};
    final String estadoUbicacion = _resolveLocationStatus(ubicacion, paciente);
    return estadoUbicacion == 'pendiente_administrativa' ||
        estadoUbicacion == 'requiere_correccion';
  }

  String _resolveLocationStatus(
    Map<String, dynamic> ubicacion,
    Map<String, dynamic> paciente,
  ) {
    final String explicit = (ubicacion['estadoUbicacion'] ?? '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final Map<String, dynamic> verificacion =
        ubicacion['verificacionEnSitio'] is Map
            ? Map<String, dynamic>.from(
              ubicacion['verificacionEnSitio'] as Map,
            )
            : <String, dynamic>{};
    if (verificacion['confirmada'] == true) {
      return 'verificada_en_sitio';
    }
    return _hasMinimumOperativeLocation(paciente)
        ? 'completa_administrativa'
        : 'pendiente_administrativa';
  }

  CollectionReference<Map<String, dynamic>> get _visitsRef =>
      _firestore.collection('agendaVisits');

  CollectionReference<Map<String, dynamic>> get _pendingRef =>
      _firestore.collection('pendingItems');

  Stream<List<OpsVisitRecord>> watchVisits() {
    return Stream<List<OpsVisitRecord>>.multi((
      MultiStreamController<List<OpsVisitRecord>> controller,
    ) {
      final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub =
          _visitsRef.snapshots().listen(
            (QuerySnapshot<Map<String, dynamic>> qs) {
              controller.add(_mapVisitsSnapshot(qs));
            },
            onError: (Object _, StackTrace stackTrace) {
              controller.add(_fallbackVisits());
            },
          );

      controller.onCancel = () => sub.cancel();
    });
  }

  Stream<List<OpsPendingRecord>> watchPendings() {
    return Stream<List<OpsPendingRecord>>.multi((
      MultiStreamController<List<OpsPendingRecord>> controller,
    ) {
      final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub =
          _pendingRef.snapshots().listen(
            (QuerySnapshot<Map<String, dynamic>> qs) {
              controller.add(_mapPendingSnapshot(qs));
            },
            onError: (Object _, StackTrace stackTrace) {
              controller.add(_fallbackPendings());
            },
          );

      controller.onCancel = () => sub.cancel();
    });
  }

  Future<void> updatePending({
    required String id,
    String? status,
    String? responsable,
    DateTime? dueAt,
  }) async {
    final Map<String, dynamic> patch = <String, dynamic>{
      ...?status == null ? null : <String, dynamic>{'status': status},
      ...?responsable == null
          ? null
          : <String, dynamic>{'responsable': responsable},
      ...?dueAt == null
          ? null
          : <String, dynamic>{'dueAt': Timestamp.fromDate(dueAt)},
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (patch.isEmpty) return;
    try {
      await _pendingRef.doc(id).set(patch, SetOptions(merge: true));
    } on FirebaseException {
      // Keep UI responsive when Firestore write is blocked by rules.
    }
  }

  List<OpsVisitRecord> _mapVisitsSnapshot(
    QuerySnapshot<Map<String, dynamic>> qs,
  ) {
    final List<OpsVisitRecord> items = qs.docs.map((
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      return OpsVisitRecord.fromFirestore(doc);
    }).toList();
    items.sort((OpsVisitRecord a, OpsVisitRecord b) {
      return a.date.compareTo(b.date);
    });
    return items;
  }

  List<OpsPendingRecord> _mapPendingSnapshot(
    QuerySnapshot<Map<String, dynamic>> qs,
  ) {
    String readString(dynamic value) {
      if (value == null) return '';
      return value.toString().trim();
    }

    final List<OpsPendingRecord> items = qs.docs
        .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          final String status = readString(
            readString(data['status']).isNotEmpty ? data['status'] : data['estado'],
          ).toLowerCase();
          return data['isClosed'] != true &&
              status != 'resuelto' &&
              status != 'cerrado';
        })
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return OpsPendingRecord.fromFirestore(doc);
        })
        .toList();
    items.sort((OpsPendingRecord a, OpsPendingRecord b) {
      return a.vencimiento.compareTo(b.vencimiento);
    });
    return items;
  }

  List<OpsVisitRecord> _fallbackVisits() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return <OpsVisitRecord>[
      OpsVisitRecord(
        id: 'visit-20260330-1000-rosa-arrieta',
        visitId: 'visit-20260330-1000-rosa-arrieta',
        pendingId: 'pending-curacion-rosa-arrieta',
        patientId: 'patient-rosa-arrieta-atencio',
        date: today.add(const Duration(hours: 10)),
        patientName: 'Rosa Arrieta Atencio',
        patientDisplay: 'Rosa Arrieta Atencio 45456552',
        modality: 'Domicilio',
        doctor: 'Dr. Diaz',
        auxiliar: 'Katerine Cabarcas',
        location: 'Barrio Boston',
        status: 'pendiente',
        dx: 'L984 Ulcera cronica de la piel',
        tratamiento: 'Curacion por clinica de herida',
        barrio: 'Caracoles',
        direccion: 'MZ 65 L 5',
        contacto: '3005687846',
        pendiente: 'CURACION',
        sexo: 'F',
        edad: 72,
      ),
    ];
  }

  List<OpsPendingRecord> _fallbackPendings() {
    final DateTime now = DateTime.now();
    return <OpsPendingRecord>[
      OpsPendingRecord(
        id: 'pending-curacion-rosa-arrieta',
        tipo: 'Curacion',
        paciente: 'Rosa Arrieta Atencio',
        vencimiento: now.add(const Duration(hours: 4)),
        detalle: 'Clinica de herida pendiente de confirmacion.',
        rutaContexto: '/schedule',
        contextoLabel: 'Agenda',
        visitId: 'visit-20260330-1000-rosa-arrieta',
        patientId: 'patient-rosa-arrieta-atencio',
        pendingId: 'pending-curacion-rosa-arrieta',
        status: 'pendiente',
        responsable: 'Sin asignar',
      ),
      OpsPendingRecord(
        id: 'pending-sin-match-demo',
        tipo: 'Seguimiento',
        paciente: 'Caso sin asociacion',
        vencimiento: now.add(const Duration(hours: 8)),
        detalle: 'Pendiente sin item relacionado para prueba negativa.',
        rutaContexto: '/schedule',
        contextoLabel: 'Agenda',
        visitId: 'visit-inexistente-demo',
        patientId: 'patient-inexistente-demo',
        pendingId: 'pending-inexistente-demo',
        status: 'pendiente',
        responsable: 'Sin asignar',
      ),
    ];
  }
}

class OpsVisitRecord {
  const OpsVisitRecord({
    required this.id,
    required this.date,
    required this.patientName,
    required this.patientDisplay,
    this.patientId,
    this.visitId,
    this.pendingId,
    this.modality = '',
    this.doctor = '',
    this.auxiliar = '',
    this.location = '',
    this.status = '',
    this.durationMinutes = 60,
    this.dx = '',
    this.tratamiento = '',
    this.barrio = '',
    this.direccion = '',
    this.referencia = '',
    this.contacto = '',
    this.pendiente = '',
    this.aseguradora = '',
    this.sexo = '',
    this.edad,
  });

  final String id;
  final DateTime date;
  final String patientName;
  final String patientDisplay;
  final String? patientId;
  final String? visitId;
  final String? pendingId;
  final String modality;
  final String doctor;
  final String auxiliar;
  final String location;
  final String status;
  final int durationMinutes;
  final String dx;
  final String tratamiento;
  final String barrio;
  final String direccion;
  final String referencia;
  final String contacto;
  final String pendiente;
  final String aseguradora;
  final String sexo;
  final int? edad;

  factory OpsVisitRecord.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    final DateTime parsedDate =
        _readDate(data['date']) ??
        _readDate(data['fecha']) ??
        _readDateFromDateAndHour(data['fecha'], data['hora']) ??
        DateTime.now();

    final String patientName =
        _readString(data['patientName']) ??
        _readString(data['pacienteNombre']) ??
        '';
    final String patientDocument =
        _readString(data['patientDocument']) ??
        _readString(data['pacienteDocumento']) ??
        '';

    return OpsVisitRecord(
      id: doc.id,
      date: parsedDate,
      patientName: patientName,
      patientDisplay: patientDocument.trim().isEmpty
          ? patientName
          : '$patientName $patientDocument',
      patientId: _readString(data['patientId']),
      visitId:
          _readString(data['visitId']) ?? _readString(data['id']) ?? doc.id,
      pendingId: _readString(data['pendingId']),
      modality:
          _readString(data['modality']) ?? _readString(data['modalidad']) ?? '',
      doctor: _readString(data['doctor']) ?? '',
      auxiliar: _readString(data['auxiliar']) ?? '',
      location:
          _readString(data['location']) ?? _readString(data['direccion']) ?? '',
      status: _readString(data['status']) ?? _readString(data['estado']) ?? '',
      durationMinutes: _readInt(data['durationMinutes']) ?? 60,
      dx: _readString(data['dx']) ?? '',
      tratamiento: _readString(data['tratamiento']) ?? '',
      barrio: _readString(data['barrio']) ?? '',
      direccion: _readString(data['direccion']) ?? '',
      referencia: _readString(data['referencia']) ?? '',
      contacto:
          _readString(data['contacto']) ??
          _joinContacts(
            _readString(data['contacto1']) ?? '',
            _readString(data['contacto2']) ?? '',
          ),
      pendiente: _readString(data['pendiente']) ?? '',
      aseguradora: _readString(data['aseguradora']) ?? '',
      sexo: _readString(data['sexo']) ?? '',
      edad: _readInt(data['edad']),
    );
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      final DateTime? iso = DateTime.tryParse(value.trim());
      if (iso != null) return iso;
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

  static DateTime? _readDateFromDateAndHour(dynamic date, dynamic hour) {
    final DateTime? parsedDate = _readDate(date);
    if (parsedDate == null) return null;
    final String rawHour = _readString(hour) ?? '';
    final List<String> parts = rawHour.split(':');
    final int h = parts.isEmpty ? 0 : int.tryParse(parts[0]) ?? 0;
    final int m = parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, h, m);
  }

  static String _joinContacts(String c1, String c2) {
    final List<String> values = <String>[
      c1.trim(),
      c2.trim(),
    ].where((String v) => v.isNotEmpty).toList();
    return values.join(' + ');
  }
}

class OpsPendingRecord {
  const OpsPendingRecord({
    required this.id,
    required this.tipo,
    required this.paciente,
    required this.vencimiento,
    required this.detalle,
    required this.rutaContexto,
    required this.contextoLabel,
    this.visitId,
    this.patientId,
    this.pendingId,
    this.status,
    this.responsable,
  });

  final String id;
  final String tipo;
  final String paciente;
  final DateTime vencimiento;
  final String detalle;
  final String rutaContexto;
  final String contextoLabel;
  final String? visitId;
  final String? patientId;
  final String? pendingId;
  final String? status;
  final String? responsable;

  factory OpsPendingRecord.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    return OpsPendingRecord(
      id: doc.id,
      tipo: _readString(data['tipo']) ?? 'Pendiente',
      paciente: _readString(data['paciente']) ?? '',
      vencimiento:
          _readDate(data['dueAt']) ??
          _readDate(data['vencimiento']) ??
          DateTime.now(),
      detalle: _readString(data['detalle']) ?? '',
      rutaContexto: _readString(data['rutaContexto']) ?? '/schedule',
      contextoLabel: _readString(data['contextoLabel']) ?? 'Agenda',
      visitId: _readString(data['visitId']),
      patientId: _readString(data['patientId']),
      pendingId: _readString(data['pendingId']) ?? doc.id,
      status: _readString(data['status']),
      responsable: _readString(data['responsable']),
    );
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
