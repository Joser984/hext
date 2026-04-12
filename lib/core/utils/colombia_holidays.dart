final Set<DateTime> colombiaHolidays = <DateTime>{
  DateTime(2026, 1, 1), // Año Nuevo
  DateTime(2026, 1, 12), // Reyes Magos
  DateTime(2026, 3, 23), // San José
  DateTime(2026, 4, 2), // Jueves Santo
  DateTime(2026, 4, 3), // Viernes Santo
  DateTime(2026, 5, 1), // Día del Trabajo
  DateTime(2026, 5, 18), // Ascensión
  DateTime(2026, 6, 8), // Corpus Christi
  DateTime(2026, 6, 15), // Sagrado Corazón
  DateTime(2026, 6, 29), // San Pedro y San Pablo
  DateTime(2026, 7, 20), // Independencia
  DateTime(2026, 8, 7), // Batalla de Boyacá
  DateTime(2026, 8, 17), // Asunción
  DateTime(2026, 10, 12), // Día de la Raza
  DateTime(2026, 11, 2), // Todos los Santos
  DateTime(2026, 11, 16), // Independencia de Cartagena
  DateTime(2026, 12, 8), // Inmaculada Concepción
  DateTime(2026, 12, 25), // Navidad
  DateTime(2027, 1, 1), // Año Nuevo
};

DateTime stripHolidayDate(DateTime d) => DateTime(d.year, d.month, d.day);

bool isColombiaHoliday(DateTime date) => colombiaHolidays.contains(stripHolidayDate(date));

bool isHolidayOrSunday(DateTime date) {
  final DateTime d = stripHolidayDate(date);
  return d.weekday == DateTime.sunday || colombiaHolidays.contains(d);
}

String? holidayName(DateTime date) {
  final DateTime d = stripHolidayDate(date);
  const Map<String, String> names = <String, String>{
    '2026-01-01': 'Año Nuevo',
    '2026-01-12': 'Reyes Magos',
    '2026-03-23': 'San José',
    '2026-04-02': 'Jueves Santo',
    '2026-04-03': 'Viernes Santo',
    '2026-05-01': 'Día del Trabajo',
    '2026-05-18': 'Ascensión',
    '2026-06-08': 'Corpus Christi',
    '2026-06-15': 'Sagrado Corazón',
    '2026-06-29': 'San Pedro y San Pablo',
    '2026-07-20': 'Independencia',
    '2026-08-07': 'Batalla de Boyacá',
    '2026-08-17': 'Asunción',
    '2026-10-12': 'Día de la Raza',
    '2026-11-02': 'Todos los Santos',
    '2026-11-16': 'Independencia de Cartagena',
    '2026-12-08': 'Inmaculada Concepción',
    '2026-12-25': 'Navidad',
    '2027-01-01': 'Año Nuevo',
  };

  final String key =
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  if (names.containsKey(key)) return names[key];
  if (d.weekday == DateTime.sunday) return 'Domingo';
  return null;
}