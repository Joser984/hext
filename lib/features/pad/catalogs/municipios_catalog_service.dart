import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MunicipiosCatalogService {
  static const String _collection = 'catalog_municipios';
  static const String _prefsKey = 'catalog_municipios_cache_v1';

  static Future<List<String>> obtenerMunicipios(List<String> semilla) async {
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
          .where((String value) => value.isNotEmpty)
          .toList();

      final List<String> merged = _mergeUnique(base, remotos);
      await prefs.setStringList(_prefsKey, merged);
      return merged;
    } catch (_) {
      return base;
    }
  }

  static Future<void> guardarMunicipio(
    String rawValue, {
    List<String> semilla = const <String>[],
  }) async {
    final String nombre = _normalizeMunicipio(rawValue);
    if (nombre.isEmpty) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> cacheLocal =
        prefs.getStringList(_prefsKey) ?? <String>[];
    final List<String> merged = _mergeUnique(
      semilla,
      <String>[...cacheLocal, nombre],
    );

    await prefs.setStringList(_prefsKey, merged);

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_slug(nombre))
          .set(<String, dynamic>{
        'nombre': nombre,
        'nombreBusqueda': nombre.toLowerCase(),
        'activo': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Ya quedó guardado localmente para uso offline.
    }
  }

  static List<String> _mergeUnique(List<String> first, List<String> second) {
    final Map<String, String> unique = <String, String>{};

    for (final String item in <String>[...first, ...second]) {
      final String trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      unique.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
    }

    return unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  static String _normalizeMunicipio(String value) {
    final String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return '';
    if (cleaned.toLowerCase() == 'cartagena') return 'Cartagena de Indias';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sáéíóúñ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
