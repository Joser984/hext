import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledShift {
  const ScheduledShift({
    required this.fecha,
    required this.semanaInicio,
    required this.auxiliarId,
    required this.auxiliarNombre,
    required this.diaSemana,
    required this.turno,
    required this.turnoBase,
    required this.horas,
    required this.esDomingoOFestivo,
    required this.sourceType,
    required this.estado,
  });

  final DateTime fecha;
  final DateTime semanaInicio;
  final String auxiliarId;
  final String auxiliarNombre;
  final String diaSemana;
  final String turno;
  final String turnoBase;
  final int horas;
  final bool esDomingoOFestivo;
  final String sourceType;
  final String estado;

  String get documentId => buildDocumentId(fecha: fecha, auxiliarId: auxiliarId);

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'fecha': Timestamp.fromDate(_onlyDate(fecha)),
      'semanaInicio': Timestamp.fromDate(_onlyDate(semanaInicio)),
      'auxiliarId': auxiliarId,
      'auxiliarNombre': auxiliarNombre,
      'diaSemana': diaSemana,
      'turno': normalizeTurno(turno),
      'turnoBase': normalizeTurno(turnoBase),
      'horas': horas,
      'esDomingoOFestivo': esDomingoOFestivo,
      'sourceType': sourceType,
      'estado': estado,
    };
  }

  factory ScheduledShift.fromMap(Map<String, dynamic> map) {
    final DateTime now = _onlyDate(DateTime.now());
    final DateTime fecha = _readDate(map['fecha']) ?? now;
    return ScheduledShift(
      fecha: fecha,
      semanaInicio: _readDate(map['semanaInicio']) ?? fecha,
      auxiliarId: _readString(map['auxiliarId']),
      auxiliarNombre: _readString(map['auxiliarNombre']),
      diaSemana: _readString(map['diaSemana']).toUpperCase(),
      turno: normalizeTurno(_readString(map['turno'])),
      turnoBase: normalizeTurno(_readString(map['turnoBase'])),
      horas: _readInt(map['horas']),
      esDomingoOFestivo: map['esDomingoOFestivo'] == true,
      sourceType: _readString(map['sourceType']),
      estado: _readString(map['estado']),
    );
  }

  static String buildDocumentId({
    required DateTime fecha,
    required String auxiliarId,
  }) {
    return '${_formatDate(_onlyDate(fecha))}_${auxiliarId.trim()}';
  }

  static String normalizeTurno(String raw) {
    final String value = raw.trim().toUpperCase();
    if (value == 'J') return 'C';
    if (value == '4' || value == '4 H' || value == '4HRS' || value == '4HORAS') {
      return '4H';
    }
    return value;
  }

  static DateTime _onlyDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? _readDate(dynamic raw) {
    if (raw is Timestamp) {
      final DateTime parsed = raw.toDate();
      return _onlyDate(parsed);
    }
    if (raw is DateTime) {
      return _onlyDate(raw);
    }
    final String value = _readString(raw);
    if (value.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return _onlyDate(parsed);
  }

  static String _readString(dynamic raw) {
    return (raw ?? '').toString().trim();
  }

  static int _readInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(_readString(raw)) ?? 0;
  }

  static String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
