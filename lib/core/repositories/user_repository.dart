import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hext/core/models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users');

  Future<AppUser?> fetchById(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _col.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> watchById(String uid) {
    return _col.doc(uid).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> doc) =>
              doc.exists ? AppUser.fromFirestore(doc) : null,
        );
  }

  Future<void> create(AppUser user) async {
    await _col.doc(user.uid).set(user.toFirestore());
  }

  Future<bool> usernameExists(String username) async {
    final String normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> setActive(String uid, {required bool activo}) async {
    await _col.doc(uid).update(<String, dynamic>{'activo': activo});
  }

  Future<void> setRol(String uid, AppUserRole rol) async {
    final String rolKey = AppUser(
      uid: uid,
      nombre: '',
      email: '',
      rol: rol,
      sede: '',
      activo: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ).toFirestore()['rol'] as String;
    await _col.doc(uid).update(<String, dynamic>{'rol': rolKey});
  }

  Stream<List<AppUser>> watchAll() {
    return _col.snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    AppUser.fromFirestore(d),
              )
              .toList(),
        );
  }
}
