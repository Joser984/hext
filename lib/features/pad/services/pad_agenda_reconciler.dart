import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hext/features/agenda/data/agenda_repo.dart';
import 'package:hext/features/pad/domain/pad_motivo_contract.dart';

class PadAgendaReconciler {
  final FirestoreAgendaRepo _agendaRepo;
  PadAgendaReconciler({FirestoreAgendaRepo? agendaRepo})
    : _agendaRepo = agendaRepo ?? FirestoreAgendaRepo();

  Future<void> reconcile({
    required String patientId,
    required Map<String, dynamic> data,
    required List<String> motivosActivos,
    required Map<String, dynamic> detalleMotivos,
  }) async {
    // Solo procesar programacion_procedimiento
    if (!motivosActivos.contains(PadMotivoKeys.programacionProcedimiento)) {
      return;
    }
    final motivoKey = PadMotivoKeys.programacionProcedimiento;
    final motivoLabel = padMotivoLabel(motivoKey);
    final detalle = getDetalleMotivo(detalleMotivos, motivoKey);
    final procedimientoRequerido = (detalle['procedimientoRequerido'] ?? '')
        .toString()
        .trim();
    final lugarProcedimiento = (detalle['lugarProcedimiento'] ?? '')
        .toString()
        .trim();
    final fechaProgramada = detalle['fechaProgramada'];
    final horaProgramada = (detalle['horaProgramada'] ?? '').toString().trim();
    final requiereAuxiliarEnfermeria = detalle['requiereAuxiliarEnfermeria'];
    final observaciones = (detalle['observaciones'] ?? '').toString().trim();

    if (procedimientoRequerido.isEmpty ||
        fechaProgramada == null ||
        horaProgramada.isEmpty) {
      debugPrint(
        '[PadAgendaReconciler] Datos insuficientes para programacion_procedimiento: procedimientoRequerido, fechaProgramada u horaProgramada faltantes. No se crea agenda_event.',
      );
      return;
    }

    // Idempotencia: validar si ya existe
    final exists = await _agendaRepo.agendaEventExists(
      patientId: patientId,
      fecha: fechaProgramada,
      hora: horaProgramada,
      sourceType: 'paciente_pad_motivo',
      motivoKey: motivoKey,
    );
    if (exists) {
      debugPrint(
        '[PadAgendaReconciler] Ya existe agenda_event para programacion_procedimiento en esa fecha/hora. No se duplica.',
      );
      return;
    }

    // Construir agenda_event
    final agendaEvent = <String, dynamic>{
      'patientId': patientId,
      'patientDisplay': (data['nombreCompleto'] ?? '').toString(),
      'identificacion': (data['identificacion'] ?? '').toString(),
      'motivoKey': motivoKey,
      'motivoLabel': motivoLabel,
      'fecha': Timestamp.fromDate(fechaProgramada),
      'hora': horaProgramada,
      'titulo': procedimientoRequerido,
      'descripcion': observaciones,
      'lugarProcedimiento': lugarProcedimiento,
      'requiereAuxiliarEnfermeria': requiereAuxiliarEnfermeria,
      'estadoAgenda': 'programada',
      'estadoMotivo': 'en_curso',
      'sourceType': 'paciente_pad_motivo',
      'sourceId': patientId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('agenda_events')
        .add(agendaEvent);
    debugPrint(
      '[PadAgendaReconciler] agenda_event creado para programacion_procedimiento: $agendaEvent',
    );
  }
}
