import 'package:flutter/material.dart';

import 'paciente_captacion_labels.dart';
import 'paciente_captacion_models.dart';

String normLabel(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

T? findEnumByLabel<T>(
  Iterable<T> values,
  String? label,
  String Function(T) labelOf,
) {
  if (label == null || label.trim().isEmpty) return null;

  final String target = normLabel(label);

  for (final T value in values) {
    if (normLabel(labelOf(value)) == target) {
      return value;
    }
  }

  return null;
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }

  if (value is String && value.trim().isNotEmpty) {
    final DateTime? parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  return null;
}

String? dateIso(DateTime? date) {
  if (date == null) return null;

  final DateTime normalized = DateTime(
    date.year,
    date.month,
    date.day,
  );

  return normalized.toIso8601String();
}

String formatDate(DateTime? date) {
  if (date == null) return 'Seleccionar fecha';

  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String formatDateOrDash(DateTime? date) {
  if (date == null) return '--';

  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

MotivoDetalleEstado motivoEstadoFromKey(String? key) {
  return key == 'finalizado'
      ? MotivoDetalleEstado.finalizado
      : MotivoDetalleEstado.enCurso;
}

ProcedimientoEstado procedimientoEstadoFromKey(String? key) {
  return key == 'realizado'
      ? ProcedimientoEstado.realizado
      : ProcedimientoEstado.pendiente;
}

String motivoEstadoKey(MotivoDetalleEstado estado) {
  return estado == MotivoDetalleEstado.finalizado ? 'finalizado' : 'en_curso';
}

String procedimientoEstadoKey(ProcedimientoEstado estado) {
  return estado == ProcedimientoEstado.realizado ? 'realizado' : 'pendiente';
}

OrigenPaciente? origenFromServicio(ServicioQuePresenta? servicio) {
  switch (servicio) {
    case ServicioQuePresenta.urgencias:
      return OrigenPaciente.urgencias;
    case ServicioQuePresenta.hospitalizacionSanFernando:
      return OrigenPaciente.hospitalizacionSanFernando;
    case ServicioQuePresenta.hospitalizacionMariaAuxiliadora:
      return OrigenPaciente.hospitalizacionMariaAuxiliadora;
    case ServicioQuePresenta.hospitalizacion:
      return OrigenPaciente.hospitalizacion;
    case ServicioQuePresenta.uci:
      return OrigenPaciente.uci;
    case ServicioQuePresenta.cirugia:
      return OrigenPaciente.cirugia;
    case ServicioQuePresenta.consultaExterna:
      return OrigenPaciente.consultaExterna;
    case ServicioQuePresenta.otro:
      return OrigenPaciente.otro;
    case null:
      return null;
  }
}

String? catalogTipoFromAseguramiento(TipoAseguramiento? tipo) {
  switch (tipo) {
    case TipoAseguramiento.eps:
      return 'eps';
    case TipoAseguramiento.medicinaPrepagada:
      return 'prepagada';
    case TipoAseguramiento.poliza:
      return 'poliza';
    case TipoAseguramiento.particular:
    case TipoAseguramiento.otro:
    case null:
      return null;
  }
}

List<T> sortedByLabel<T>(
  Iterable<T> values,
  String Function(T value) labelOf,
) {
  final List<T> sorted = values.toList();

  bool isOtherLabel(String label) {
    final String normalized = label.trim().toLowerCase();
    return normalized.startsWith('otro') || normalized.startsWith('otra');
  }

  sorted.sort((T a, T b) {
    final String labelA = labelOf(a);
    final String labelB = labelOf(b);

    final bool isOtherA = isOtherLabel(labelA);
    final bool isOtherB = isOtherLabel(labelB);

    if (isOtherA && !isOtherB) return 1;
    if (!isOtherA && isOtherB) return -1;

    return labelA.toLowerCase().compareTo(labelB.toLowerCase());
  });

  return sorted;
}

EspecialidadPrincipalTratante? especialidadFromLabel(String? label) {
  if (label == null || label.trim().isEmpty) return null;

  for (final EspecialidadPrincipalTratante value
      in EspecialidadPrincipalTratante.values) {
    if (especialidadPrincipalTratanteLabel(value).toLowerCase() ==
        label.trim().toLowerCase()) {
      return value;
    }
  }

  return null;
}

List<String> splitContacto(String raw) {
  final String normalized = raw.replaceAll('·', '+');

  return normalized
      .split(RegExp(r'\s*(?:\+|-|/)\s*'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList();
}

String? composeContacto({
  required String telefonoPrincipal,
  required String telefonoAlterno,
}) {
  if (telefonoPrincipal.isEmpty && telefonoAlterno.isEmpty) return null;

  if (telefonoPrincipal.isNotEmpty && telefonoAlterno.isNotEmpty) {
    return '$telefonoPrincipal + $telefonoAlterno';
  }

  return telefonoPrincipal.isNotEmpty ? telefonoPrincipal : telefonoAlterno;
}

String formatTimeOfDayStorage(TimeOfDay? time) {
  if (time == null) return '';

  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

TimeOfDay? parseTimeOfDay(dynamic value) {
  if (value == null) return null;

  final String raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final List<String> parts = raw.split(':');
  if (parts.length < 2) return null;

  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);

  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return TimeOfDay(hour: hour, minute: minute);
}
