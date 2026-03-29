import 'package:cloud_firestore/cloud_firestore.dart';

class CandidatoPadService {
	final FirebaseFirestore _firestore;

	CandidatoPadService({FirebaseFirestore? firestore})
			: _firestore = firestore ?? FirebaseFirestore.instance;

	Future<void> guardarCandidatoPad({
		String? id,
		required Map<String, dynamic> data,
	}) async {
		final collection = _firestore.collection('candidatosPad');

		if (id == null || id.trim().isEmpty) {
			await collection.add({
				...data,
				'createdAt': FieldValue.serverTimestamp(),
				'updatedAt': FieldValue.serverTimestamp(),
			});
			return;
		}

		await collection.doc(id).set({
			...data,
			'updatedAt': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));
	}
}
