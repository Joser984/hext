import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class OpsFirestoreRepo {
  OpsFirestoreRepo({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    final List<OpsPendingRecord> items = qs.docs.map((
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      return OpsPendingRecord.fromFirestore(doc);
    }).toList();
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
