import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool isClosed;
  final String? responsableId;
  final String? responsableNombre;

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
    required this.isClosed,
    this.responsableId,
    this.responsableNombre,
  });

  factory AgendaEventRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Timestamp? fechaTs = data['fecha'] as Timestamp?;
    final DateTime fecha = fechaTs?.toDate() ?? DateTime.now();

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
      isClosed: data['isClosed'] == true,
      responsableId: data['responsableId']?.toString(),
      responsableNombre: data['responsableNombre']?.toString(),
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
    bool? isClosed,
    String? responsableId,
    String? responsableNombre,
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
      isClosed: isClosed ?? this.isClosed,
      responsableId: responsableId ?? this.responsableId,
      responsableNombre: responsableNombre ?? this.responsableNombre,
    );
  }
}

abstract class AgendaRepo {
  Stream<List<AgendaEventRecord>> watchAgendaEvents();
}

class FirestoreAgendaRepo implements AgendaRepo {
  final FirebaseFirestore _firestore;

  FirestoreAgendaRepo({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<AgendaEventRecord>> watchAgendaEvents() {
    return _firestore
        .collection('agenda_events')
        .orderBy('fecha')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AgendaEventRecord.fromFirestore(doc))
              .toList(),
        );
  }

  /// Crea un evento de agenda a partir de los datos mínimos requeridos.
  Future<void> createAgendaEvent({
    required String patientId,
    required String patientDisplay,
    required DateTime fecha,
    required String hora,
    required String dx,
    required String tratamiento,
    required String barrio,
    required String direccion,
    required String referencia,
    required String contacto,
    String estadoAgenda = 'programada',
    String sourceType = 'manual',
    bool isClosed = false,
    String? responsableId,
    String? responsableNombre,
  }) async {
    await _firestore.collection('agenda_events').add({
      'patientId': patientId,
      'patientDisplay': patientDisplay,
      'fecha': Timestamp.fromDate(fecha),
      'hora': hora,
      'dx': dx,
      'tratamiento': tratamiento,
      'barrio': barrio,
      'direccion': direccion,
      'referencia': referencia,
      'contacto': contacto,
      'estadoAgenda': estadoAgenda,
      'sourceType': sourceType,
      'isClosed': isClosed,
      'responsableId': ?responsableId,
      'responsableNombre': ?responsableNombre,
    });
  }
}
