import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hext/core/models/auxiliar_domiciliario.dart';
import 'package:hext/core/repositories/personal_repo.dart';

class InMemoryPersonalRepo extends ChangeNotifier implements PersonalRepo {
  final List<AuxiliarDomiciliario> _items = <AuxiliarDomiciliario>[
    AuxiliarDomiciliario(
      id: '1',
      nombreCompleto: 'Luis Orozco',
      cargo: 'Auxiliar domiciliario',
      modalidad: 'Tiempo completo',
      fechaIngreso: DateTime(2024, 3, 12),
      activo: true,
    ),
    AuxiliarDomiciliario(
      id: '2',
      nombreCompleto: 'Katerine Cabarcas',
      cargo: 'Auxiliar domiciliario',
      modalidad: 'Tiempo completo',
      fechaIngreso: DateTime(2023, 8, 1),
      activo: true,
    ),
    AuxiliarDomiciliario(
      id: '3',
      nombreCompleto: 'Nataly Vergara',
      cargo: 'Auxiliar domiciliario',
      modalidad: 'Tiempo completo',
      fechaIngreso: DateTime(2025, 1, 15),
      activo: true,
    ),
  ];

  @override
  List<AuxiliarDomiciliario> get items {
    final List<AuxiliarDomiciliario> sorted =
        List<AuxiliarDomiciliario>.from(_items)
          ..sort((AuxiliarDomiciliario a, AuxiliarDomiciliario b) {
            if (a.activo != b.activo) {
              return a.activo ? -1 : 1;
            }
            return a.nombreCompleto.toLowerCase().compareTo(
                  b.nombreCompleto.toLowerCase(),
                );
          });

    return UnmodifiableListView<AuxiliarDomiciliario>(sorted);
  }

  @override
  Future<void> load() async {
    // En memoria no hace falta cargar nada todavía.
    notifyListeners();
  }

  @override
  AuxiliarDomiciliario? findById(String id) {
    try {
      return _items.firstWhere((AuxiliarDomiciliario e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addAuxiliar(AuxiliarDomiciliario auxiliar) async {
    _items.add(auxiliar);
    notifyListeners();
  }

  @override
  Future<void> updateAuxiliar(AuxiliarDomiciliario auxiliar) async {
    final int index = _items.indexWhere(
      (AuxiliarDomiciliario e) => e.id == auxiliar.id,
    );

    if (index == -1) return;

    _items[index] = auxiliar;
    notifyListeners();
  }

  @override
  Future<void> deleteAuxiliar(String id) async {
    _items.removeWhere((AuxiliarDomiciliario e) => e.id == id);
    notifyListeners();
  }

  @override
  Future<void> toggleActivo(String id, bool activo) async {
    final AuxiliarDomiciliario? actual = findById(id);
    if (actual == null) return;

    final int index = _items.indexWhere((AuxiliarDomiciliario e) => e.id == id);
    if (index == -1) return;

    _items[index] = actual.copyWith(activo: activo);
    notifyListeners();
  }
}
