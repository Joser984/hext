import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:hext/core/models/novedad_laboral.dart';

class InMemoryNovedadesRepo extends ChangeNotifier {
  final List<NovedadLaboral> _items = <NovedadLaboral>[
    // Luis Orozco – compensatorio por sufragio (elecciones 09/03/2026)
    NovedadLaboral(
      id: 'n1',
      auxiliarId: '1',
      tipo: TipoNovedad.compensatorioSufragio,
      fechaCausacion: DateTime(2026, 3, 9),
      fechaLimiteDisfrute: DateTime(2026, 4, 9),
      estado: EstadoNovedad.pendiente,
    ),
    // Katerine Cabarcas – día de la familia 2026
    NovedadLaboral(
      id: 'n2',
      auxiliarId: '2',
      tipo: TipoNovedad.diaFamilia,
      fechaCausacion: DateTime(2026, 1, 1),
      fechaLimiteDisfrute: DateTime(2026, 12, 31),
      estado: EstadoNovedad.pendiente,
    ),
    // Nataly Vergara – vacaciones anuales programadas
    NovedadLaboral(
      id: 'n3',
      auxiliarId: '3',
      tipo: TipoNovedad.vacaciones,
      fechaCausacion: DateTime(2026, 1, 15),
      fechaInicio: DateTime(2026, 5, 5),
      fechaFin: DateTime(2026, 5, 19),
      estado: EstadoNovedad.programado,
    ),
  ];

  /// Todas las novedades de un auxiliar.
  List<NovedadLaboral> forAuxiliar(String auxiliarId) {
    return UnmodifiableListView<NovedadLaboral>(
      _items.where((NovedadLaboral n) => n.auxiliarId == auxiliarId).toList(),
    );
  }

  /// Novedades que requieren atención (pendiente o programado).
  List<NovedadLaboral> activeForAuxiliar(String auxiliarId) {
    return forAuxiliar(auxiliarId)
        .where(
          (NovedadLaboral n) =>
              n.estado == EstadoNovedad.pendiente ||
              n.estado == EstadoNovedad.programado,
        )
        .toList();
  }

  /// Devuelve true si el auxiliar cumplió un año o más desde [fechaIngreso]
  /// y no tiene vacaciones programadas ni disfrutadas para el período de
  /// aniversario vigente.
  bool vacacionesVencidas({
    required String auxiliarId,
    required DateTime? fechaIngreso,
  }) {
    if (fechaIngreso == null) return false;

    final DateTime hoy = DateTime.now();
    // Todavía no cumple el año
    final DateTime primerAniversario =
        DateTime(fechaIngreso.year + 1, fechaIngreso.month, fechaIngreso.day);
    if (hoy.isBefore(primerAniversario)) return false;

    // Aniversario del período vigente: el último aniversario cumplido
    final int anosCompletos = hoy.year - fechaIngreso.year -
        (hoy.month < fechaIngreso.month ||
                (hoy.month == fechaIngreso.month && hoy.day < fechaIngreso.day)
            ? 1
            : 0);
    final DateTime inicioVigente = DateTime(
      fechaIngreso.year + anosCompletos,
      fechaIngreso.month,
      fechaIngreso.day,
    );
    final DateTime finVigente = DateTime(
      fechaIngreso.year + anosCompletos + 1,
      fechaIngreso.month,
      fechaIngreso.day,
    );

    // ¿Existe alguna novedad de vacaciones programada o disfrutada cuya
    // causación caiga dentro del período de aniversario vigente?
    final bool tieneVacaciones = forAuxiliar(auxiliarId).any(
      (NovedadLaboral n) =>
          n.tipo == TipoNovedad.vacaciones &&
          (n.estado == EstadoNovedad.programado ||
              n.estado == EstadoNovedad.disfrutado) &&
          !n.fechaCausacion.isBefore(inicioVigente) &&
          n.fechaCausacion.isBefore(finVigente),
    );

    return !tieneVacaciones;
  }

  Future<void> add(NovedadLaboral novedad) async {
    _items.add(novedad);
    notifyListeners();
  }

  Future<void> update(NovedadLaboral novedad) async {
    final int index = _items.indexWhere((NovedadLaboral n) => n.id == novedad.id);
    if (index == -1) return;
    _items[index] = novedad;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((NovedadLaboral n) => n.id == id);
    notifyListeners();
  }

  Future<void> marcarDisfrutado(String id) async {
    final int index = _items.indexWhere((NovedadLaboral n) => n.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(estado: EstadoNovedad.disfrutado);
    notifyListeners();
  }
}
