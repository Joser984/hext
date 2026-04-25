// Servicio para guardar caso PAD en Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hext/features/agenda/data/agenda_repo.dart';

class PadFirestoreService {
        /// Actualiza un caso PAD en la colección censoPacientes por id.
        static Future<void> actualizarCensoPaciente(String id, Map<String, dynamic> data) async {
          _requireUser();
          final docRef = _censoPacientesRef.doc(id);
          await docRef.update({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('[PadFirestoreService.actualizarCensoPaciente] docId = $id');
        }
      /// Obtiene un caso PAD desde la colección censoPacientes por id.
      static Future<Map<String, dynamic>?> obtenerCensoPaciente(String id) async {
        _requireUser();
        final doc = await _censoPacientesRef.doc(id).get();
        if (!doc.exists) return null;
        return <String, dynamic>{
          'id': doc.id,
          ...doc.data()!,
        };
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

  static Future<String> guardarCandidato(Map<String, dynamic> data) async {
    debugPrint('[PadFirestoreService.guardarCandidato] inicio');
    try {
      final User user = _requireUser();
      debugPrint('[PadFirestoreService.guardarCandidato] uid = ${user.uid}');
      debugPrint('[PadFirestoreService.guardarCandidato] email = ${user.email}');
      debugPrint('[PadFirestoreService.guardarCandidato] collection = censoPacientes');

      final now = FieldValue.serverTimestamp();
      final String decision = (data['decision'] ?? '').toString();
      final String resultadoPadLabel =
          decision == 'Ingreso aprobado' ? 'Ingreso aprobado' : decision;
      final String situacionAsistencialLabel =
          decision == 'Ingreso aprobado' ? 'Activo en PAD' : 'En valoración';

      final docRef = await _censoPacientesRef.add(<String, dynamic>{
        ...data,

        // Campos canónicos para el censo
        'diagnosticos': data['diagnostico'],
        'especialidadLabel': data['especialidadPrincipalTratante'],
        'aseguradoraLabel': data['aseguradora'],
        'sexoLabel': data['sexo'],
        'unidadFuncionalOrigenLabel': data['unidadFuncionalOrigen'],
        'situacionAsistencialLabel': situacionAsistencialLabel,
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

      // Crear evento de agenda si corresponde
      if ((data['requiereVisita'] == true || data['requiereVisita'] == 'true') &&
          data['fechaVisita'] != null && data['horaVisita'] != null) {
        try {
          debugPrint('[PadFirestoreService.guardarCandidato] entrando a createAgendaEvent');
          debugPrint('[PadFirestoreService.guardarCandidato] data = $data');
          final agendaRepo =
              FirestoreAgendaRepo(firestore: _firestore);
          await agendaRepo.createAgendaEvent(
            patientId: docRef.id,
            patientDisplay: data['nombreCompleto'] ?? '',
            fecha: (data['fechaVisita'] as DateTime),
            hora: data['horaVisita'].toString(),
            dx: data['diagnostico']?.toString() ?? '',
            tratamiento: data['tratamiento']?.toString() ?? '',
            barrio: data['barrio']?.toString() ?? '',
            direccion: data['direccion']?.toString() ?? '',
            referencia: data['referencia']?.toString() ?? '',
            contacto: data['contacto']?.toString() ?? '',
            estadoAgenda: 'programada',
            sourceType: 'manual',
            isClosed: false,
          );
          debugPrint('[PadFirestoreService.guardarCandidato] agenda_event creado');
        } catch (e, st) {
          debugPrint('[PadFirestoreService.guardarCandidato] ERROR agenda_event = $e');
          debugPrint('[PadFirestoreService.guardarCandidato] STACK agenda_event = $st');
        }
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

  static Future<Map<String, dynamic>?> obtenerCandidato(String candidatoId) async {
    _requireUser();

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _candidatosRef.doc(candidatoId).get();

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
}
