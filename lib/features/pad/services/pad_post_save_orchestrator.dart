import 'package:flutter/foundation.dart';
import 'package:hext/features/pad/services/pad_pending_reconciler.dart';

/// Orquestador post-guardado para conciliacion de agenda y pendientes PAD.
class PadPostSaveOrchestrator {
  static final PadPendingReconciler _pendingReconciler = PadPendingReconciler();

  /// Orquestador post-guardado PAD: coordina reconciliadores de agenda y pendientes.
  static Future<void> reconcileAfterSave({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    final motivos =
        (data['motivosIngresoActivos'] as List?)?.cast<String>() ?? <String>[];
    final detalleMotivos =
        (data['detalleMotivos'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    debugPrint('[PadPostSaveOrchestrator] Motivos activos: $motivos');
    debugPrint('[PadPostSaveOrchestrator] Detalle motivos: $detalleMotivos');
    debugPrint(
      '[PadPostSaveOrchestrator] Agenda delegada a PadFirestoreService para evitar duplicados por motivo.',
    );

    await _pendingReconciler.reconcile(patientId: patientId, data: data);
  }
}
