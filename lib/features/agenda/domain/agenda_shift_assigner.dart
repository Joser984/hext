export 'agenda_shift_assigner.dart' show AgendaAssignableVisit, AgendaShiftAssigner;
import 'package:hext/features/schedule/horarios_screen.dart';

class AgendaAssignableVisit {
  final String fecha;
  final String hora;
  final String paciente;
  final String? patientId;
  final String? visitId;
  final String? pendingId;
  final int? edad;
  final String? sexo;
  final String? aseguradora;
  final String dx;
  final String tratamiento;
  final String? barrio;
  final String direccion;
  final String? referencia;
  final String contacto;
  final String pendiente;
  final String personalAsignado;

  const AgendaAssignableVisit({
    required this.fecha,
    required this.hora,
    required this.paciente,
    this.patientId,
    this.visitId,
    this.pendingId,
    this.edad,
    this.sexo,
    this.aseguradora,
    required this.dx,
    required this.tratamiento,
    this.barrio,
    required this.direccion,
    this.referencia,
    required this.contacto,
    required this.pendiente,
    required this.personalAsignado,
  });

  AgendaAssignableVisit copyWith({
    String? fecha,
    String? hora,
    String? paciente,
    String? patientId,
    String? visitId,
    String? pendingId,
    int? edad,
    String? sexo,
    String? aseguradora,
    String? dx,
    String? tratamiento,
    String? barrio,
    String? direccion,
    String? referencia,
    String? contacto,
    String? pendiente,
    String? personalAsignado,
  }) {
    return AgendaAssignableVisit(
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      paciente: paciente ?? this.paciente,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      pendingId: pendingId ?? this.pendingId,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      aseguradora: aseguradora ?? this.aseguradora,
      dx: dx ?? this.dx,
      tratamiento: tratamiento ?? this.tratamiento,
      barrio: barrio ?? this.barrio,
      direccion: direccion ?? this.direccion,
      referencia: referencia ?? this.referencia,
      contacto: contacto ?? this.contacto,
      pendiente: pendiente ?? this.pendiente,
      personalAsignado: personalAsignado ?? this.personalAsignado,
    );
  }
}

class AgendaShiftAssigner {
  const AgendaShiftAssigner();

  List<AgendaAssignableVisit> assignResponsibles({
    required List<AgendaAssignableVisit> visits,
    required List<String> activeAuxiliares,
  }) {
    final Map<String, List<AgendaAssignableVisit>> grouped =
        <String, List<AgendaAssignableVisit>>{};

    for (final AgendaAssignableVisit item in visits) {
      final String key = '${item.fecha}|${item.hora}';
      grouped.putIfAbsent(key, () => <AgendaAssignableVisit>[]).add(item);
    }

    final List<AgendaAssignableVisit> resolved = <AgendaAssignableVisit>[];

    for (final MapEntry<String, List<AgendaAssignableVisit>> entry
        in grouped.entries) {
      final List<AgendaAssignableVisit> slotItems = entry.value;

      if (slotItems.isEmpty) {
        continue;
      }

      final DateTime? parsedDate = tryParseDate(slotItems.first.fecha);
      if (parsedDate == null) {
        resolved.addAll(slotItems);
        continue;
      }

      final List<String> responsibles =
          AgendaResponsibleResolver.resolveResponsiblesForSlot(
        date: parsedDate,
        hora: slotItems.first.hora,
        nombres: activeAuxiliares,
      );

      if (responsibles.isEmpty) {
        resolved.addAll(
          slotItems.map(
            (AgendaAssignableVisit item) =>
                item.copyWith(personalAsignado: ''),
          ),
        );
        continue;
      }

      for (int i = 0; i < slotItems.length; i++) {
        final AgendaAssignableVisit item = slotItems[i];
        final String responsible = responsibles[i % responsibles.length];
        resolved.add(item.copyWith(personalAsignado: responsible));
      }
    }

    return resolved;
  }

  static DateTime? tryParseDate(String text) {
    final List<String> parts = text.split('/');
    if (parts.length != 3) return null;

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
