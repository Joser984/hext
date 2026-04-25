import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';


class PadCaseRecord {
  final String barrio;
  final String? motivoIngresoPrincipal;
  final List<String>? motivosIngresoActivos;
  final List<String>? motivos;
  final String? detalleClinicoResumido;
  final String? resumenClinico;
  final String? detalleClinico;
  final String? observaciones;
  final String? situacionAsistencial;
  final String? estadoPad;
  final String? resolucionPad;

  const PadCaseRecord({
    required this.barrio,
    this.motivoIngresoPrincipal,
    this.motivosIngresoActivos,
    this.motivos,
    this.detalleClinicoResumido,
    this.resumenClinico,
    this.detalleClinico,
    this.observaciones,
    this.situacionAsistencial,
    this.estadoPad,
    this.resolucionPad,
  });

  factory PadCaseRecord.fromMap(Map<String, dynamic> map) {
    List<String>? readStringList(List<String> keys) {
      for (final String key in keys) {
        final dynamic value = map[key];
        if (value is List) {
          return value
              .where((dynamic e) => e != null)
              .map((dynamic e) => e.toString())
              .toList();
        }
      }
      return null;
    }

    String? readString(List<String> keys) {
      for (final String key in keys) {
        final dynamic value = map[key];
        if (value == null) continue;
        final String text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    String norm(String? value) => (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    // Normalización de campos clave
    final String barrioRaw = (map['barrio'] as String? ?? '').trim();
    final String barrio = barrioRaw.isEmpty ? '' : barrioRaw;

    final String? tipoCaptacionPadRaw = map['tipoCaptacionPad'] as String?;
    final String? tipoCaptacionPad = tipoCaptacionPadRaw == null
        ? null
        : norm(tipoCaptacionPadRaw);

    final String? grupoRelacionadoRiesgoRaw = map['grupoRelacionadoRiesgo'] as String?;
    final String? grupoRelacionadoRiesgo = grupoRelacionadoRiesgoRaw == null
        ? null
        : norm(grupoRelacionadoRiesgoRaw);

    final String? origenPacienteRaw = map['origenPaciente'] as String?;
    final String? origenPaciente = origenPacienteRaw == null
        ? null
        : norm(origenPacienteRaw);

    final String? especialidadPrincipalTratanteRaw = map['especialidadPrincipalTratante'] as String?;
    final String? especialidadPrincipalTratante = especialidadPrincipalTratanteRaw == null
        ? null
        : norm(especialidadPrincipalTratanteRaw);

    return PadCaseRecord(
      barrio: barrio,
      motivoIngresoPrincipal: readString(const <String>[
        'motivoIngresoPrincipal',
        'motivoPrincipal',
      ]),
      motivosIngresoActivos: readStringList(const <String>[
        'motivosIngresoActivos',
        'motivosActivos',
      ]),
      motivos: readStringList(const <String>['motivos']),
      detalleClinicoResumido: readString(const <String>[
        'detalleClinicoResumido',
      ]),
      resumenClinico: readString(const <String>['resumenClinico']),
      detalleClinico: readString(const <String>['detalleClinico']),
      observaciones: readString(const <String>['observaciones']),
      situacionAsistencial: readString(const <String>['situacionAsistencial']),
      estadoPad: readString(const <String>['estadoPad']),
      resolucionPad: readString(const <String>['resolucionPad']),
      // Puedes agregar aquí los campos normalizados si los agregas al modelo
      // tipoCaptacionPad: tipoCaptacionPad,
      // grupoRelacionadoRiesgo: grupoRelacionadoRiesgo,
      // origenPaciente: origenPaciente,
      // especialidadPrincipalTratante: especialidadPrincipalTratante,
    );
  }
}

class PadSummaryDomainAdapter {
  const PadSummaryDomainAdapter._();

  static PadCaseData toPadCaseData(PadCaseRecord record) {
    return PadCaseData(
      barrio: record.barrio,
      motivoPrincipal: record.motivoIngresoPrincipal,
      motivosActivos: _mergeReasons(
        record.motivosIngresoActivos,
        record.motivos,
      ),
    detalleClinicoResumido: record.detalleClinicoResumido,
      resumenClinico: record.resumenClinico,
      detalleClinico: record.detalleClinico,
      observaciones: record.observaciones,
      situacionAsistencial: record.situacionAsistencial,
      estadoPad: record.estadoPad,
      resolucionPad: record.resolucionPad,
    );
  }

  static List<String> _mergeReasons(
    List<String>? primary,
    List<String>? legacy,
  ) {
    final List<String> ordered = <String>[];
    final Set<String> seen = <String>{};

    void addAll(List<String>? values) {
      if (values == null) return;
      for (final String raw in values) {
        final String normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (normalized.isEmpty) continue;
        final String key = normalized.toLowerCase();
        if (seen.add(key)) {
          ordered.add(normalized);
        }
      }
    }

    addAll(primary);
    addAll(legacy);
    return ordered;
  }
}
