import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarriosCatalogService {
  static const String _collection = 'catalog_barrios';
  static const String _prefsKey = 'catalog_barrios_cache_v1';

  static Future<List<String>> obtenerBarrios(List<String> semilla) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> cacheLocal =
        prefs.getStringList(_prefsKey) ?? <String>[];

    final List<String> base = _mergeUnique(semilla, cacheLocal);

    try {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await FirebaseFirestore.instance
              .collection(_collection)
              .where('activo', isEqualTo: true)
              .get();

      final List<String> remotos = snap.docs
          .map((doc) => (doc.data()['nombre'] as String?)?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();

      final List<String> merged = _mergeUnique(base, remotos);
      await prefs.setStringList(_prefsKey, merged);
      return merged;
    } catch (_) {
      return base;
    }
  }

  static Future<void> guardarBarrio(
    String rawValue, {
    List<String> semilla = const <String>[],
  }) async {
    final String nombre = _normalizeBarrio(rawValue);
    if (nombre.isEmpty) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> cacheLocal =
        prefs.getStringList(_prefsKey) ?? <String>[];

    final List<String> merged = _mergeUnique(
      semilla,
      <String>[...cacheLocal, nombre],
    );

    // Primero local: queda disponible offline de inmediato
    await prefs.setStringList(_prefsKey, merged);

    try {
      final String docId = _slug(nombre);

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(docId)
          .set(<String, dynamic>{
        'nombre': nombre,
        'nombreBusqueda': nombre.toLowerCase(),
        'activo': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Si no hay red, ya quedó persistido localmente.
    }
  }

  static List<String> _mergeUnique(
    List<String> first,
    List<String> second,
  ) {
    final Map<String, String> unique = <String, String>{};

    for (final String item in <String>[...first, ...second]) {
      final String trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      unique.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
    }

    final List<String> values = unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return values;
  }

  static String _normalizeBarrio(String value) {
    final String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return '';
    final String lower = cleaned.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sáéíóúñ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
