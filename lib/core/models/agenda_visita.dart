import 'package:flutter/foundation.dart';

@immutable
class AgendaVisita {
  final String id;
  final DateTime fecha;
  final String hora; // HH:mm

  final String pacienteNombre;
  final String pacienteDocumento;

  final String tratamiento;
  final String dx;

  final String contacto1;
  final String contacto2;

  final String direccion;
  final String pendiente;

  final String personalAsignadoId;
  final String observaciones;
  final String estado; // programada, realizada, cancelada

  const AgendaVisita({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.pacienteNombre,
    required this.pacienteDocumento,
    required this.tratamiento,
    required this.dx,
    required this.contacto1,
    required this.contacto2,
    required this.direccion,
    required this.pendiente,
    required this.personalAsignadoId,
    required this.observaciones,
    required this.estado,
  });

  String get pacienteDisplay {
    if (pacienteDocumento.trim().isEmpty) return pacienteNombre;
    return '$pacienteNombre · $pacienteDocumento';
  }

  String get contactoDisplay {
    final List<String> values = <String>[
      contacto1.trim(),
      contacto2.trim(),
    ].where((String e) => e.isNotEmpty).toList();

    return values.join(' · ');
  }

  AgendaVisita copyWith({
    String? id,
    DateTime? fecha,
    String? hora,
    String? pacienteNombre,
    String? pacienteDocumento,
    String? tratamiento,
    String? dx,
    String? contacto1,
    String? contacto2,
    String? direccion,
    String? pendiente,
    String? personalAsignadoId,
    String? observaciones,
    String? estado,
  }) {
    return AgendaVisita(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      pacienteNombre: pacienteNombre ?? this.pacienteNombre,
      pacienteDocumento: pacienteDocumento ?? this.pacienteDocumento,
      tratamiento: tratamiento ?? this.tratamiento,
      dx: dx ?? this.dx,
      contacto1: contacto1 ?? this.contacto1,
      contacto2: contacto2 ?? this.contacto2,
      direccion: direccion ?? this.direccion,
      pendiente: pendiente ?? this.pendiente,
      personalAsignadoId: personalAsignadoId ?? this.personalAsignadoId,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'fechaIso': fecha.toIso8601String(),
      'hora': hora,
      'pacienteNombre': pacienteNombre,
      'pacienteDocumento': pacienteDocumento,
      'tratamiento': tratamiento,
      'dx': dx,
      'contacto1': contacto1,
      'contacto2': contacto2,
      'direccion': direccion,
      'pendiente': pendiente,
      'personalAsignadoId': personalAsignadoId,
      'observaciones': observaciones,
      'estado': estado,
    };
  }

  factory AgendaVisita.fromMap(Map<String, dynamic> map) {
    return AgendaVisita(
      id: map['id'] as String? ?? '',
      fecha: DateTime.tryParse(map['fechaIso'] as String? ?? '') ?? DateTime.now(),
      hora: map['hora'] as String? ?? '',
      pacienteNombre: map['pacienteNombre'] as String? ?? '',
      pacienteDocumento: map['pacienteDocumento'] as String? ?? '',
      tratamiento: map['tratamiento'] as String? ?? '',
      dx: map['dx'] as String? ?? '',
      contacto1: map['contacto1'] as String? ?? '',
      contacto2: map['contacto2'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      pendiente: map['pendiente'] as String? ?? '',
      personalAsignadoId: map['personalAsignadoId'] as String? ?? '',
      observaciones: map['observaciones'] as String? ?? '',
      estado: map['estado'] as String? ?? 'programada',
    );
  }
}