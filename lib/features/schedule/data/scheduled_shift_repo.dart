import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hext/features/schedule/models/scheduled_shift.dart';

class FirestoreScheduledShiftRepo {
  FirestoreScheduledShiftRepo({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('scheduled_shifts');

  Stream<List<ScheduledShift>> watchRange({
    required DateTime start,
    required DateTime endExclusive,
  }) {
    return Stream<List<ScheduledShift>>.multi((
      MultiStreamController<List<ScheduledShift>> controller,
    ) {
      final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub =
          _collection
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('fecha', isLessThan: Timestamp.fromDate(endExclusive))
              .orderBy('fecha')
              .snapshots()
              .listen(
                (QuerySnapshot<Map<String, dynamic>> snapshot) {
                  final List<ScheduledShift> items = snapshot.docs
                      .map(
                        (
                          QueryDocumentSnapshot<Map<String, dynamic>> doc,
                        ) => ScheduledShift.fromMap(doc.data()),
                      )
                      .toList()
                    ..sort((ScheduledShift a, ScheduledShift b) {
                      final int byDate = a.fecha.compareTo(b.fecha);
                      if (byDate != 0) return byDate;
                      return a.auxiliarNombre.toLowerCase().compareTo(
                        b.auxiliarNombre.toLowerCase(),
                      );
                    });
                  controller.add(items);
                },
                onError: (Object _, StackTrace _) {
                  controller.add(const <ScheduledShift>[]);
                },
              );

      controller.onCancel = () => sub.cancel();
    });
  }

  Stream<List<ScheduledShift>> watchMonth(DateTime month) {
    final DateTime start = DateTime(month.year, month.month, 1);
    final DateTime end = DateTime(month.year, month.month + 1, 1);
    return watchRange(start: start, endExclusive: end);
  }

  Future<void> upsertShift(ScheduledShift shift) async {
    await _collection.doc(shift.documentId).set(shift.toFirestore());
  }

  Future<void> upsertMany(Iterable<ScheduledShift> shifts) async {
    final WriteBatch batch = _firestore.batch();
    for (final ScheduledShift shift in shifts) {
      batch.set(_collection.doc(shift.documentId), shift.toFirestore());
    }
    await batch.commit();
  }
}
