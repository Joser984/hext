// =============================================================================
// Instrucciones del motor de programación HEXT — versión canónica
// =============================================================================
//
// 1. Códigos de turno
//    M = Mañana             06:00–14:00
//    T = Tarde              14:00–22:00
//    R = Refuerzo           08:00–17:00 · 8 h efectivas + 1 h almuerzo
//    J = Jornada completa   06:00–22:00 (contingencia)
//    L = Libre
//    I = Incapacidad · V = Vacaciones · P = Permiso / licencia
//    A = Ausencia          · X = Sin asignación
//
// 2. Horas efectivas
//    M = 8 h · T = 8 h · R = 8 h · J = 16 h
//    L / I / V / P / A / X = 0 h
//
// 3. Cobertura diaria obligatoria
//    - M y T siempre deben quedar cubiertos.
//    - R es opcional; es el primer turno en removerse ante restricción o rebalanceo.
//    - R nunca se asigna en domingos ni festivos.
//
// 4. Patrón base según auxiliares activos
//    1 aux : cobertura insuficiente; no se genera semana normal.
//    2 aux : M + T, sin R.
//    3 aux : patrón base M + T + R (rotación perpetua de 3 semanas).
//    4 aux : las primeras tres entran al patrón base; la cuarta es auxiliar
//            de alivio — no entra en la rotación semanal perpetua, se usa
//            para domingos, festivos, novedades y desequilibrios de carga.
//
// 5. Calendario perpetuo
//    - La rotación no se reinicia por cambio de mes.
//    - Semanas completas lunes–domingo; días de mes adyacente se incluyen.
//    - Días fuera del mes visible se muestran atenuados pero cuentan para
//      horas, libres, rebalanceo y justicia del reparto.
//
// 6. Rotación perpetua con 3 auxiliares base
//    Sem A: Aux 1 = M, Aux 2 = T, Aux 3 = R
//    Sem B: Aux 1 = T, Aux 2 = R, Aux 3 = M
//    Sem C: Aux 1 = R, Aux 2 = M, Aux 3 = T  → se repite.
//    Semana determinada por delta absoluto desde [kRotationAnchorMonday].
//
// 7. Domingos
//    - Sin R en domingo.
//    - Cobertura mínima: 2 auxiliares (M + T).
//    - Con 3 aux: patrón M + T + L por rotación justa.
//    - J es contingencia; se usa cuando sólo hay 2 aux disponibles.
//
// 8. Justicia dominical
//    3 aux : tope preferente 2 domingos; se permite 3 si el mes no cierra.
//    4 aux : mes 4 dom → meta 2-2-2-2; mes 5 dom → meta 2-2-3-3.
//            Quienes reciban 3 domingos deben rotar en meses siguientes.
//
// 9. Regla de la cuarta auxiliar
//    - No entra al patrón perpetuo semanal de días regulares (recibe L).
//    - Prioridad: domingos excedidos, festivos críticos, incapacidades,
//      permisos, vacaciones, desequilibrios de carga.
//    - Objetivo: evitar sobrecarga y mejorar justicia mensual.
//
// 10. Libre semanal
//     - Cada auxiliar debe tener 1 día libre por semana.
//     - La auxiliar de alivio tiene L en días regulares; las alertas de
//       "sin libre" y "más de 1 libre" no aplican para ella.
//
// 11. Rebalanceo semanal
//     Caso 1: sobrecargado en M o T → R cubre ese turno; sobrecargado pasa a L.
//     Caso 2: sobrecargado en R     → R se elimina; ese auxiliar pasa a L.
//     M y T nunca se dejan vacíos.
//
// 12. Ajuste de cumplimiento de horas (pendiente de implementar)
//     Cuando proyecte exceso y exista R: recortar 2 h en 2 días del auxiliar de M
//     (06:00→12:00); R cubre 12:00–14:00; reduce 4 h semanales al auxiliar de M.
//
// 13. Novedades laborales
//     V · I · P · compensatorio sufragio · jurado · día de familia bloquean
//     la asignación ese día; el motor recalcula con el personal disponible;
//     alerta si no alcanza cobertura.
//
// 14. Responsable en Agenda
//     M → responsable de mañana. T → responsable de tarde. R no recibe asignación.
//
// 15. Alertas obligatorias
//     Cobertura insuficiente · semana en alerta · exceso crítico · sin libre ·
//     más de 1 libre sin justificación · vacaciones pendientes · compensatorio
//     vencido · jurado vencido · cobertura forzada por domingos excedidos.
//
// 16. Principios del motor (orden de prioridad)
//     1. Cubrir siempre M.          4. Proteger el libre semanal.
//     2. Cubrir siempre T.          5. Distribuir carga en equilibrio.
//     3. Usar R sólo como apoyo.    6. Repartir domingos con justicia.
//     No reiniciar la lógica por cambio de mes.
//
// 17. Regla visual
//     Semanas completas (lun–dom) en pantalla; días adyacentes atenuados;
//     cálculos de horas y alertas sobre la semana completa.
// =============================================================================

/// Lunes ancla del calendario perpetuo de auxiliares.
/// Cambiar este valor desplaza toda la rotación hacia adelante o atrás.
final DateTime kRotationAnchorMonday = DateTime(2026, 1, 5);

class AuxScheduleResult {
  const AuxScheduleResult({
    required this.assignmentsByAuxiliar,
    required this.warnings,
    required this.weeklySummaries,
    required this.notes,
  });

  final Map<String, Map<DateTime, AuxScheduleCode>> assignmentsByAuxiliar;
  final List<String> warnings;
  final List<AuxWeeklyHoursSummary> weeklySummaries;
  final AuxPlanNotes notes;
}

class AuxPlanNotes {
  const AuxPlanNotes({
    required this.maxWorkedSundaysRuleDescription,
    this.reliefAuxiliarNombre,
  });

  final String maxWorkedSundaysRuleDescription;

  /// Nombre de la auxiliar de alivio (cuarta), o null si hay ≤ 3 auxiliares.
  final String? reliefAuxiliarNombre;
}

class AuxWeeklyHoursSummary {
  const AuxWeeklyHoursSummary({
    required this.auxiliarNombre,
    required this.weekStart,
    required this.weekOrdinal,
    required this.totalHours,
    required this.targetHours,
    required this.freeDays,
    required this.status,
  });

  final String auxiliarNombre;
  final DateTime weekStart;
  final int weekOrdinal;
  final int totalHours;
  final int targetHours;
  final int freeDays;
  final AuxWeeklyHoursStatus status;
}

enum AuxWeeklyHoursStatus {
  ok,
  alert,
  invalid,
}

extension AuxWeeklyHoursStatusX on AuxWeeklyHoursStatus {
  String get label {
    switch (this) {
      case AuxWeeklyHoursStatus.ok:
        return 'OK';
      case AuxWeeklyHoursStatus.alert:
        return 'ALERTA';
      case AuxWeeklyHoursStatus.invalid:
        return 'EXCESO';
    }
  }
}

enum AuxScheduleCode {
  m,
  t,
  r,
  j,
  l,
  i,
  v,
  p,
  a,
  x,
}

extension AuxScheduleCodeX on AuxScheduleCode {
  String get label {
    switch (this) {
      case AuxScheduleCode.m:
        return 'M';
      case AuxScheduleCode.t:
        return 'T';
      case AuxScheduleCode.r:
        return 'R';
      case AuxScheduleCode.j:
        return 'J';
      case AuxScheduleCode.l:
        return 'L';
      case AuxScheduleCode.i:
        return 'I';
      case AuxScheduleCode.v:
        return 'V';
      case AuxScheduleCode.p:
        return 'P';
      case AuxScheduleCode.a:
        return 'A';
      case AuxScheduleCode.x:
        return 'X';
    }
  }

  int get hours {
    switch (this) {
      case AuxScheduleCode.m:
        return 8;
      case AuxScheduleCode.t:
        return 8;
      case AuxScheduleCode.r:
        return 9;
      case AuxScheduleCode.j:
        return 16;
      case AuxScheduleCode.l:
      case AuxScheduleCode.i:
      case AuxScheduleCode.v:
      case AuxScheduleCode.p:
      case AuxScheduleCode.a:
      case AuxScheduleCode.x:
        return 0;
    }
  }

  bool get isCoverageBase => this == AuxScheduleCode.m || this == AuxScheduleCode.t;
}

enum TwoAuxSundayPolicy {
  contingencyJ,
  normalMT,
}

class AuxScheduleGenerator {
  const AuxScheduleGenerator();

  AuxScheduleResult generateMonth({
    required int year,
    required int month,
    required List<String> nombres,
    required Set<DateTime> holidays,
    Map<String, Map<DateTime, AuxScheduleCode>> overrides =
        const <String, Map<DateTime, AuxScheduleCode>>{},
    TwoAuxSundayPolicy twoAuxSundayPolicy = TwoAuxSundayPolicy.contingencyJ,
  }) {
    if (nombres.isEmpty || nombres.length > 4) {
      throw Exception('Solo se permiten 1, 2, 3 o 4 auxiliares de enfermería.');
    }

    final Set<DateTime> normalizedHolidays =
        holidays.map(_onlyDate).toSet();

    final List<DateTime> days = _daysOfMonth(DateTime(year, month, 1));
    final int totalAuxiliares = nombres.length;

    // Con 4 auxiliares, la última es la auxiliar de alivio (no entra en la
    // rotación perpetua; cubre domingos excedidos, novedades y desequilibrios).
    final String? reliefAuxiliarNombre =
        totalAuxiliares == 4 ? nombres.last : null;

    final List<Map<DateTime, AuxScheduleCode>> assignments =
        List<Map<DateTime, AuxScheduleCode>>.generate(
      totalAuxiliares,
      (_) => <DateTime, AuxScheduleCode>{},
    );

    final List<_SpecialLoad> loads =
        List<_SpecialLoad>.generate(totalAuxiliares, (_) => _SpecialLoad());

    int specialOrder = 0;

    for (final DateTime day in days) {
      final DateTime key = _onlyDate(day);

      if (_isSpecialDay(day, normalizedHolidays)) {
        _assignSpecialDay(
          date: day,
          key: key,
          totalAuxiliares: totalAuxiliares,
          assignments: assignments,
          loads: loads,
          specialOrder: specialOrder,
          twoAuxSundayPolicy: twoAuxSundayPolicy,
        );
        specialOrder += 1;
        continue;
      }

      _assignRegularDay(
        date: day,
        key: key,
        totalAuxiliares: totalAuxiliares,
        assignments: assignments,
      );
    }

    if (totalAuxiliares >= 3) {
      // Solo se rebalancea el trío base; la auxiliar de alivio (índice 3)
      // descansa en días regulares y no participa en la rotación M/T/R.
      _rebalanceOptionalRToRest(
        days: days,
        assignments: assignments.sublist(0, 3),
        holidays: normalizedHolidays,
      );
    }

    for (int index = 0; index < nombres.length; index++) {
      final String nombre = nombres[index];
      final Map<DateTime, AuxScheduleCode>? byName = overrides[nombre];
      if (byName == null) continue;

      byName.forEach((DateTime date, AuxScheduleCode code) {
        assignments[index][_onlyDate(date)] = code;
      });
    }

    final Map<String, Map<DateTime, AuxScheduleCode>> byAuxiliar =
        <String, Map<DateTime, AuxScheduleCode>>{};

    for (int i = 0; i < nombres.length; i++) {
      byAuxiliar[nombres[i]] = assignments[i];
    }

    final List<AuxWeeklyHoursSummary> weeklySummaries =
        _buildWeeklySummaries(
      days: days,
      nombres: nombres,
      assignmentsByAuxiliar: byAuxiliar,
    );

    final List<String> warnings = _buildWarnings(
      nombres: nombres,
      assignmentsByAuxiliar: byAuxiliar,
      weeklySummaries: weeklySummaries,
      reliefAuxiliarNombre: reliefAuxiliarNombre,
    );

    return AuxScheduleResult(
      assignmentsByAuxiliar: byAuxiliar,
      warnings: warnings,
      weeklySummaries: weeklySummaries,
      notes: AuxPlanNotes(
        maxWorkedSundaysRuleDescription:
            'tope preferente ${nombres.length >= 4 ? 3 : 2}, con fallback a balance cuando la cobertura obliga',
        reliefAuxiliarNombre: reliefAuxiliarNombre,
      ),
    );
  }

  List<String> _buildWarnings({
    required List<String> nombres,
    required Map<String, Map<DateTime, AuxScheduleCode>> assignmentsByAuxiliar,
    required List<AuxWeeklyHoursSummary> weeklySummaries,
    String? reliefAuxiliarNombre,
  }) {
    final List<String> warnings = <String>[];

    for (final AuxWeeklyHoursSummary summary in weeklySummaries) {
      if (summary.status == AuxWeeklyHoursStatus.alert) {
        warnings.add(
          '${summary.auxiliarNombre} supera objetivo semanal en S${summary.weekOrdinal}: '
          '${summary.totalHours}h sobre ${summary.targetHours}h.',
        );
      }

      if (summary.status == AuxWeeklyHoursStatus.invalid) {
        warnings.add(
          '${summary.auxiliarNombre} está en EXCESO en S${summary.weekOrdinal}: '
          '${summary.totalHours}h sobre ${summary.targetHours}h.',
        );
      }

      // La auxiliar de alivio tiene L en días regulares; sus conteos de
      // libre no se alertan (son estructuralmente esperados).
      if (summary.freeDays == 0 &&
          summary.auxiliarNombre != reliefAuxiliarNombre) {
        warnings.add(
          '${summary.auxiliarNombre} quedó sin día libre en S${summary.weekOrdinal}.',
        );
      }

      if (summary.freeDays > 1 &&
          summary.auxiliarNombre != reliefAuxiliarNombre) {
        warnings.add(
          '${summary.auxiliarNombre} quedó con más de 1 libre en S${summary.weekOrdinal}.',
        );
      }
    }

    for (final String nombre in nombres) {
      final Map<DateTime, AuxScheduleCode> map =
          assignmentsByAuxiliar[nombre] ?? <DateTime, AuxScheduleCode>{};

      final List<DateTime> dates = map.keys.toList()
        ..sort((DateTime a, DateTime b) => a.compareTo(b));

      int consecutiveJ = 0;
      int sundaysWorked = 0;

      for (final DateTime d in dates) {
        final AuxScheduleCode code = map[d] ?? AuxScheduleCode.x;

        if (d.weekday == DateTime.sunday && code.hours > 0) {
          sundaysWorked += 1;
        }

        if (code == AuxScheduleCode.j) {
          consecutiveJ += 1;
          if (consecutiveJ >= 2) {
            warnings.add(
              '$nombre tiene 2 jornadas J consecutivas (${_fmt(d)}).',
            );
            break;
          }
        } else {
          consecutiveJ = 0;
        }
      }

      // Con 4 aux en mes de 5 domingos, hasta 3 domingos son esperados (meta 2-2-3-3).
      final int sundayWarningLimit = nombres.length >= 4 ? 3 : 2;
      if (sundaysWorked > sundayWarningLimit) {
        warnings.add(
          '$nombre supera el tope preferente de $sundayWarningLimit domingos trabajados.',
        );
      }
    }

    return warnings;
  }

  static void _assignRegularDay({
    required DateTime date,
    required DateTime key,
    required int totalAuxiliares,
    required List<Map<DateTime, AuxScheduleCode>> assignments,
  }) {
    final int weekDelta = _weeksBetween(
      _mondayOfWeek(kRotationAnchorMonday),
      _mondayOfWeek(date),
    );

    switch (totalAuxiliares) {
      case 1:
        assignments[0][key] =
            weekDelta.isEven ? AuxScheduleCode.m : AuxScheduleCode.t;
        return;

      case 2:
        if (weekDelta.isEven) {
          assignments[0][key] = AuxScheduleCode.m;
          assignments[1][key] = AuxScheduleCode.t;
        } else {
          assignments[0][key] = AuxScheduleCode.t;
          assignments[1][key] = AuxScheduleCode.m;
        }
        return;

      case 3:
        final int cycle = ((weekDelta % 3) + 3) % 3;

        const List<List<AuxScheduleCode>> rotations =
            <List<AuxScheduleCode>>[
          <AuxScheduleCode>[
            AuxScheduleCode.m,
            AuxScheduleCode.t,
            AuxScheduleCode.r,
          ],
          <AuxScheduleCode>[
            AuxScheduleCode.t,
            AuxScheduleCode.r,
            AuxScheduleCode.m,
          ],
          <AuxScheduleCode>[
            AuxScheduleCode.r,
            AuxScheduleCode.m,
            AuxScheduleCode.t,
          ],
        ];

        for (int i = 0; i < 3; i++) {
          assignments[i][key] = rotations[cycle][i];
        }
        return;

      case 4:
        // Las tres auxiliares base siguen la rotación perpetua de 3 ciclos.
        // La cuarta (alivio) descansa en todos los días regulares.
        final int cycle4 = ((weekDelta % 3) + 3) % 3;
        const List<List<AuxScheduleCode>> rotations4 =
            <List<AuxScheduleCode>>[
          <AuxScheduleCode>[
            AuxScheduleCode.m,
            AuxScheduleCode.t,
            AuxScheduleCode.r,
          ],
          <AuxScheduleCode>[
            AuxScheduleCode.t,
            AuxScheduleCode.r,
            AuxScheduleCode.m,
          ],
          <AuxScheduleCode>[
            AuxScheduleCode.r,
            AuxScheduleCode.m,
            AuxScheduleCode.t,
          ],
        ];
        for (int i = 0; i < 3; i++) {
          assignments[i][key] = rotations4[cycle4][i];
        }
        assignments[3][key] = AuxScheduleCode.l;
        return;
    }
  }

  static void _assignSpecialDay({
    required DateTime date,
    required DateTime key,
    required int totalAuxiliares,
    required List<Map<DateTime, AuxScheduleCode>> assignments,
    required List<_SpecialLoad> loads,
    required int specialOrder,
    required TwoAuxSundayPolicy twoAuxSundayPolicy,
  }) {
    final bool isSunday = date.weekday == DateTime.sunday;

    if (totalAuxiliares == 1) {
      assignments[0][key] = AuxScheduleCode.j;
      _registerSpecialLoad(
        load: loads[0],
        date: date,
        specialOrder: specialOrder,
        isJ: true,
      );
      return;
    }

    if (totalAuxiliares == 2) {
      if (isSunday && twoAuxSundayPolicy == TwoAuxSundayPolicy.contingencyJ) {
        final int worker = _pickSundayJWorker(
          date: date,
          loads: loads,
        );
        final int rest = worker == 0 ? 1 : 0;

        assignments[worker][key] = AuxScheduleCode.j;
        assignments[rest][key] = AuxScheduleCode.l;

        _registerSpecialLoad(
          load: loads[worker],
          date: date,
          specialOrder: specialOrder,
          isJ: true,
        );
        return;
      }

      final List<AuxScheduleCode> shifts = _orderedSpecialShifts(specialOrder);

      assignments[0][key] = shifts[0];
      assignments[1][key] = shifts[1];

      _registerSpecialLoad(
        load: loads[0],
        date: date,
        specialOrder: specialOrder,
        isJ: false,
      );
      _registerSpecialLoad(
        load: loads[1],
        date: date,
        specialOrder: specialOrder,
        isJ: false,
      );
      return;
    }

    final List<int> workers = _pickFairSpecialWorkers(
      date: date,
      loads: loads,
      count: 2,
    );

    final List<AuxScheduleCode> shifts = _orderedSpecialShifts(specialOrder);

    for (int auxiliarIndex = 0;
        auxiliarIndex < totalAuxiliares;
        auxiliarIndex++) {
      if (auxiliarIndex == workers[0]) {
        assignments[auxiliarIndex][key] = shifts[0];
      } else if (auxiliarIndex == workers[1]) {
        assignments[auxiliarIndex][key] = shifts[1];
      } else {
        assignments[auxiliarIndex][key] = AuxScheduleCode.l;
      }
    }

    _registerSpecialLoad(
      load: loads[workers[0]],
      date: date,
      specialOrder: specialOrder,
      isJ: false,
    );
    _registerSpecialLoad(
      load: loads[workers[1]],
      date: date,
      specialOrder: specialOrder,
      isJ: false,
    );
  }

  static void _registerSpecialLoad({
    required _SpecialLoad load,
    required DateTime date,
    required int specialOrder,
    required bool isJ,
  }) {
    load.specialWorked += 1;
    load.lastSpecialOrder = specialOrder;

    if (date.weekday == DateTime.sunday) {
      load.sundaysWorked += 1;
    }

    if (isJ) {
      load.lastJDate = _onlyDate(date);
    }
  }

  static int _pickSundayJWorker({
    required DateTime date,
    required List<_SpecialLoad> loads,
  }) {
    final List<int> candidates = List<int>.generate(
      loads.length,
      (int index) => index,
    );

    candidates.sort((int a, int b) {
      final _SpecialLoad loadA = loads[a];
      final _SpecialLoad loadB = loads[b];

      final bool aWasLastSundayJ = loadA.lastJDate != null &&
          _onlyDate(date).difference(loadA.lastJDate!).inDays == 7;
      final bool bWasLastSundayJ = loadB.lastJDate != null &&
          _onlyDate(date).difference(loadB.lastJDate!).inDays == 7;

      final int consecutiveCompare =
          (aWasLastSundayJ ? 1 : 0).compareTo(bWasLastSundayJ ? 1 : 0);
      if (consecutiveCompare != 0) return consecutiveCompare;

      final int sundayCompare =
          loadA.sundaysWorked.compareTo(loadB.sundaysWorked);
      if (sundayCompare != 0) return sundayCompare;

      final int specialCompare =
          loadA.specialWorked.compareTo(loadB.specialWorked);
      if (specialCompare != 0) return specialCompare;

      final int lastA = loadA.lastSpecialOrder ?? -9999;
      final int lastB = loadB.lastSpecialOrder ?? -9999;
      final int restCompare = lastA.compareTo(lastB);
      if (restCompare != 0) return restCompare;

      return a.compareTo(b);
    });

    return candidates.first;
  }

  static List<int> _pickFairSpecialWorkers({
    required DateTime date,
    required List<_SpecialLoad> loads,
    required int count,
  }) {
    final bool isSunday = date.weekday == DateTime.sunday;

    final List<int> sorted = List<int>.generate(
      loads.length,
      (int index) => index,
    );

    sorted.sort((int a, int b) {
      final _SpecialLoad loadA = loads[a];
      final _SpecialLoad loadB = loads[b];

      if (isSunday) {
        final int sundayCompare =
            loadA.sundaysWorked.compareTo(loadB.sundaysWorked);
        if (sundayCompare != 0) return sundayCompare;
      }

      final int specialCompare =
          loadA.specialWorked.compareTo(loadB.specialWorked);
      if (specialCompare != 0) return specialCompare;

      final int lastA = loadA.lastSpecialOrder ?? -9999;
      final int lastB = loadB.lastSpecialOrder ?? -9999;
      final int restCompare = lastA.compareTo(lastB);
      if (restCompare != 0) return restCompare;

      return a.compareTo(b);
    });

    if (!isSunday) {
      return sorted.take(count).toList();
    }

    final List<int> underLimit = sorted
        .where((int index) => loads[index].sundaysWorked < 2)
        .toList();

    if (underLimit.length >= count) {
      return underLimit.take(count).toList();
    }

    final List<int> result = <int>[...underLimit];
    for (final int index in sorted) {
      if (!result.contains(index)) {
        result.add(index);
        if (result.length == count) break;
      }
    }

    return result;
  }

  static List<AuxScheduleCode> _orderedSpecialShifts(int specialOrder) {
    return specialOrder.isEven
        ? <AuxScheduleCode>[AuxScheduleCode.m, AuxScheduleCode.t]
        : <AuxScheduleCode>[AuxScheduleCode.t, AuxScheduleCode.m];
  }

  static void _rebalanceOptionalRToRest({
    required List<DateTime> days,
    required List<Map<DateTime, AuxScheduleCode>> assignments,
    required Set<DateTime> holidays,
  }) {
    final Map<DateTime, List<DateTime>> weeks =
        _groupDaysByWeek(_padToFullWeeks(days));

    final List<DateTime> weekStarts = weeks.keys.toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    for (final DateTime weekStart in weekStarts) {
      final List<DateTime> weekDays = weeks[weekStart] ?? <DateTime>[];
      final int targetHours = _weeklyTargetHoursForWeek(weekStart);

      bool changedInWeek = true;
      while (changedInWeek) {
        changedInWeek = false;

        final List<int> weeklyHours = List<int>.generate(
          assignments.length,
          (int index) => _sumHoursForWeek(
            assignments: assignments[index],
            weekDays: weekDays,
          ),
        );

        final List<int> overloaded = List<int>.generate(
          assignments.length,
          (int index) => index,
        )..sort((int a, int b) => weeklyHours[b].compareTo(weeklyHours[a]));

        for (final int overloadedIndex in overloaded) {
          if (weeklyHours[overloadedIndex] <= targetHours) {
            continue;
          }

          DateTime? selectedDay;
          int? selectedReserve;
          AuxScheduleCode? selectedCoverage;

          for (final DateTime day in weekDays) {
            final DateTime key = _onlyDate(day);

            if (_isSpecialDay(day, holidays)) {
              continue;
            }

            final AuxScheduleCode overloadedCode =
                assignments[overloadedIndex][key] ?? AuxScheduleCode.x;

            if (overloadedCode == AuxScheduleCode.r) {
              assignments[overloadedIndex][key] = AuxScheduleCode.l;
              changedInWeek = true;
              break;
            }

            if (!overloadedCode.isCoverageBase) {
              continue;
            }

            final List<int> reserveCandidates = List<int>.generate(
              assignments.length,
              (int index) => index,
            )
                .where(
                  (int index) =>
                      index != overloadedIndex &&
                      (assignments[index][key] ?? AuxScheduleCode.x) ==
                          AuxScheduleCode.r,
                )
                .toList()
              ..sort((int a, int b) => weeklyHours[a].compareTo(weeklyHours[b]));

            if (reserveCandidates.isEmpty) {
              continue;
            }

            final int reserveIndex = reserveCandidates.first;

            if (!_rebalanceImprovesWeekBalance(
              weeklyHours: weeklyHours,
              overloadedIndex: overloadedIndex,
              reserveIndex: reserveIndex,
              overloadedCode: overloadedCode,
            )) {
              continue;
            }

            selectedDay = key;
            selectedReserve = reserveIndex;
            selectedCoverage = overloadedCode;
            break;
          }

          if (changedInWeek) {
            break;
          }

          if (selectedDay == null ||
              selectedReserve == null ||
              selectedCoverage == null) {
            continue;
          }

          assignments[overloadedIndex][selectedDay] = AuxScheduleCode.l;
          assignments[selectedReserve][selectedDay] = selectedCoverage;
          changedInWeek = true;
          break;
        }

        if (!changedInWeek && assignments.length == 3) {
          final List<int> refreshedHours = List<int>.generate(
            assignments.length,
            (int index) => _sumHoursForWeek(
              assignments: assignments[index],
              weekDays: weekDays,
            ),
          );

          final List<int> refreshedFree = List<int>.generate(
            assignments.length,
            (int index) => _sumFreeDaysForWeek(
              assignments: assignments[index],
              weekDays: weekDays,
            ),
          );

          final List<int> noRest = List<int>.generate(
            assignments.length,
            (int index) => index,
          )..sort((int a, int b) => refreshedHours[b].compareTo(refreshedHours[a]));

          for (final int overloadedIndex in noRest) {
            if (refreshedFree[overloadedIndex] > 0) {
              continue;
            }

            for (final DateTime day in weekDays) {
              if (_isSpecialDay(day, holidays)) continue;
              final DateTime key = _onlyDate(day);

              final AuxScheduleCode overloadedCode =
                  assignments[overloadedIndex][key] ?? AuxScheduleCode.x;

              if (!overloadedCode.isCoverageBase) continue;

              final List<int> reserveCandidates = List<int>.generate(
                assignments.length,
                (int index) => index,
              )
                  .where(
                    (int index) =>
                        index != overloadedIndex &&
                        (assignments[index][key] ?? AuxScheduleCode.x) ==
                            AuxScheduleCode.r,
                  )
                  .toList()
                ..sort((int a, int b) => refreshedHours[a].compareTo(refreshedHours[b]));

              if (reserveCandidates.isEmpty) {
                continue;
              }

              final int reserveIndex = reserveCandidates.first;
              assignments[overloadedIndex][key] = AuxScheduleCode.l;
              assignments[reserveIndex][key] = overloadedCode;
              changedInWeek = true;
              break;
            }

            if (changedInWeek) {
              break;
            }
          }
        }
      }
    }
  }

  static bool _rebalanceImprovesWeekBalance({
    required List<int> weeklyHours,
    required int overloadedIndex,
    required int reserveIndex,
    required AuxScheduleCode overloadedCode,
  }) {
    final List<int> before = List<int>.from(weeklyHours);
    final List<int> after = List<int>.from(weeklyHours);

    after[overloadedIndex] -= overloadedCode.hours;
    after[reserveIndex] += overloadedCode.hours - AuxScheduleCode.r.hours;

    final int beforeMax = before.reduce((int a, int b) => a > b ? a : b);
    final int beforeMin = before.reduce((int a, int b) => a < b ? a : b);
    final int afterMax = after.reduce((int a, int b) => a > b ? a : b);
    final int afterMin = after.reduce((int a, int b) => a < b ? a : b);

    return (afterMax - afterMin) < (beforeMax - beforeMin);
  }

  static List<AuxWeeklyHoursSummary> _buildWeeklySummaries({
    required List<DateTime> days,
    required List<String> nombres,
    required Map<String, Map<DateTime, AuxScheduleCode>> assignmentsByAuxiliar,
  }) {
    final Map<DateTime, List<DateTime>> weeks =
        _groupDaysByWeek(_padToFullWeeks(days));
    final List<DateTime> weekStarts = weeks.keys.toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    final List<AuxWeeklyHoursSummary> result = <AuxWeeklyHoursSummary>[];

    for (final String nombre in nombres) {
      final Map<DateTime, AuxScheduleCode> assignments =
          assignmentsByAuxiliar[nombre] ?? <DateTime, AuxScheduleCode>{};

      for (int weekIndex = 0; weekIndex < weekStarts.length; weekIndex++) {
        final DateTime weekStart = weekStarts[weekIndex];
        final List<DateTime> weekDays = weeks[weekStart] ?? <DateTime>[];

        final int totalHours = _sumHoursForWeek(
          assignments: assignments,
          weekDays: weekDays,
        );

        final int freeDays = _sumFreeDaysForWeek(
          assignments: assignments,
          weekDays: weekDays,
        );

        final int targetHours = _weeklyTargetHoursForWeek(weekStart);

        result.add(
          AuxWeeklyHoursSummary(
            auxiliarNombre: nombre,
            weekStart: weekStart,
            weekOrdinal: weekIndex + 1,
            totalHours: totalHours,
            targetHours: targetHours,
            freeDays: freeDays,
            status: _hoursStatus(
              totalHours: totalHours,
              targetHours: targetHours,
            ),
          ),
        );
      }
    }

    return result;
  }

  static AuxWeeklyHoursStatus _hoursStatus({
    required int totalHours,
    required int targetHours,
  }) {
    if (totalHours > targetHours + 12) {
      return AuxWeeklyHoursStatus.invalid;
    }
    if (totalHours > targetHours) {
      return AuxWeeklyHoursStatus.alert;
    }
    return AuxWeeklyHoursStatus.ok;
  }

  static int _weeklyTargetHoursForWeek(DateTime weekStart) {
    final DateTime cutoff = DateTime(2026, 7, 15);
    return weekStart.isBefore(cutoff) ? 44 : 42;
  }

  static int _sumHoursForWeek({
    required Map<DateTime, AuxScheduleCode> assignments,
    required List<DateTime> weekDays,
  }) {
    int total = 0;
    for (final DateTime day in weekDays) {
      final AuxScheduleCode code = assignments[_onlyDate(day)] ?? AuxScheduleCode.x;
      total += code.hours;
    }
    return total;
  }

  static int _sumFreeDaysForWeek({
    required Map<DateTime, AuxScheduleCode> assignments,
    required List<DateTime> weekDays,
  }) {
    int total = 0;
    for (final DateTime day in weekDays) {
      final AuxScheduleCode code = assignments[_onlyDate(day)] ?? AuxScheduleCode.x;
      if (code == AuxScheduleCode.l) {
        total += 1;
      }
    }
    return total;
  }

  static Map<DateTime, List<DateTime>> _groupDaysByWeek(List<DateTime> days) {
    final Map<DateTime, List<DateTime>> result = <DateTime, List<DateTime>>{};

    for (final DateTime day in days) {
      final DateTime weekStart = _mondayOfWeek(day);
      result.putIfAbsent(weekStart, () => <DateTime>[]).add(day);
    }

    return result;
  }

  /// Expands [days] so that the first and last weeks are complete ISO weeks
  /// (Mon–Sun), even if they cross a month boundary. Days outside the original
  /// range are appended so their shifts can be read from the assignments map
  /// (returning 0 h for days with no entry, which is correct for unscheduled
  /// adjacent-month days).
  static List<DateTime> _padToFullWeeks(List<DateTime> days) {
    if (days.isEmpty) return days;
    final DateTime firstMonday = _mondayOfWeek(days.first);
    final DateTime lastDay = days.last;
    final DateTime lastSunday = lastDay
        .add(Duration(days: DateTime.sunday - lastDay.weekday));
    final List<DateTime> padded = <DateTime>[];
    DateTime cursor = firstMonday;
    while (!cursor.isAfter(lastSunday)) {
      padded.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return padded;
  }

  static List<DateTime> _daysOfMonth(DateTime month) {
    final DateTime start = DateTime(month.year, month.month, 1);
    final DateTime end = DateTime(month.year, month.month + 1, 0);

    return List<DateTime>.generate(
      end.day,
      (int index) => DateTime(start.year, start.month, index + 1),
    );
  }

  static DateTime _onlyDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _mondayOfWeek(DateTime date) {
    final DateTime d = _onlyDate(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static int _weeksBetween(DateTime mondayA, DateTime mondayB) {
    return mondayB.difference(mondayA).inDays ~/ 7;
  }

  static bool _isSpecialDay(DateTime date, Set<DateTime> holidays) {
    final DateTime d = _onlyDate(date);
    return d.weekday == DateTime.sunday || holidays.contains(d);
  }

  static String _fmt(DateTime d) {
    final String day = d.day.toString().padLeft(2, '0');
    final String month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }
}

class _SpecialLoad {
  int sundaysWorked = 0;
  int specialWorked = 0;
  int? lastSpecialOrder;
  DateTime? lastJDate;
}