import 'package:hext/features/pad/summary/pad_summary_compact_vm.dart';

class PadCaseData {
  const PadCaseData({
    this.motivoPrincipal,
    this.motivoPrincipalLabel,
    this.motivosActivos,
    this.motivos,
    this.detalleClinicoResumido,
    this.resumenClinico,
    this.detalleClinico,
    this.observaciones,
    this.situacionAsistencial,
    this.estadoPad,
    this.resolucionPad,
  });

  final String? motivoPrincipal;
  final String? motivoPrincipalLabel;
  final List<String>? motivosActivos;
  final List<String>? motivos;

  final String? detalleClinicoResumido;
  final String? resumenClinico;
  final String? detalleClinico;
  final String? observaciones;

  final String? situacionAsistencial;
  final String? estadoPad;
  final String? resolucionPad;
}

PadSummaryCompactVm mapPadSummary(PadCaseData caseData) {
  final List<String> activeReasons = normalizeStringList(
    caseData.motivosActivos ?? caseData.motivos ?? const <String>[],
  );

  final String explicitPrincipal = firstNonEmpty(
    caseData.motivoPrincipal,
    caseData.motivoPrincipalLabel,
    '',
    '',
    '',
  );

  final bool inferred = explicitPrincipal.isEmpty && activeReasons.isNotEmpty;

  final String principal = explicitPrincipal.isNotEmpty
      ? explicitPrincipal
      : activeReasons.isNotEmpty
      ? activeReasons.first
      : 'Sin motivo principal';

  final String detail = firstNonEmpty(
    caseData.detalleClinicoResumido,
    caseData.resumenClinico,
    caseData.detalleClinico,
    caseData.observaciones,
    'Sin detalle clinico resumido',
  );

  final String generalStatus = resolveGeneralStatus(
    situacionAsistencial: caseData.situacionAsistencial,
    estadoPad: caseData.estadoPad,
    resolucionPad: caseData.resolucionPad,
  );

  return PadSummaryCompactVm(
    principalLabel: principal,
    principalInferred: inferred,
    activeReasonLabels: activeReasons,
    shortDetail: detail,
    generalStatusLabel: generalStatus,
    principalTone: PadSummaryTone.dominant,
    statusTone: mapStatusTone(generalStatus),
  );
}

String firstNonEmpty(
  String? first,
  String? second,
  String? third,
  String? fourth,
  String fallback,
) {
  final List<String?> candidates = <String?>[first, second, third, fourth];
  for (final String? candidate in candidates) {
    final String value = _normalizeSpaces(candidate ?? '');
    if (value.isNotEmpty) {
      return value;
    }
  }
  return fallback;
}

List<String> normalizeStringList(List<String> source) {
  final List<String> result = <String>[];
  final Set<String> dedupe = <String>{};

  for (final String item in source) {
    final String normalized = _normalizeSpaces(item);
    if (normalized.isEmpty) {
      continue;
    }
    final String dedupeKey = normalized.toLowerCase();
    if (dedupe.contains(dedupeKey)) {
      continue;
    }
    dedupe.add(dedupeKey);
    result.add(normalized);
  }

  return result;
}

String resolveGeneralStatus({
  String? situacionAsistencial,
  String? estadoPad,
  String? resolucionPad,
}) {
  final String source = firstNonEmpty(
    situacionAsistencial,
    estadoPad,
    resolucionPad,
    '',
    '',
  );

  final String normalized = _normalizeToken(source);

  const Set<String> active = <String>{
    'activos en pad',
    'activo',
    'extension hospitalaria',
    'reingreso desde extension hospitalaria',
    'en curso',
    'ingreso aprobado',
  };

  const Set<String> evaluating = <String>{
    'en valoracion',
    'pendiente decision',
    'revalorar',
    'candidato',
    'por definir',
  };

  const Set<String> closed = <String>{
    'alta',
    'egresado',
    'alta exitosa',
    'ingreso no aprobado',
    'no ingreso',
    'cerrado',
    'finalizado',
  };

  if (active.contains(normalized)) {
    return 'Activo';
  }
  if (evaluating.contains(normalized)) {
    return 'En valoracion';
  }
  if (closed.contains(normalized)) {
    return 'Cerrado';
  }
  return 'Estado no clasificado';
}

PadSummaryTone mapStatusTone(String generalStatus) {
  switch (_normalizeToken(generalStatus)) {
    case 'activo':
      return PadSummaryTone.active;
    case 'en valoracion':
      return PadSummaryTone.evaluating;
    case 'cerrado':
      return PadSummaryTone.closed;
    default:
      return PadSummaryTone.neutral;
  }
}

String _normalizeToken(String value) {
  String output = _normalizeSpaces(value).toLowerCase();

  const Map<String, String> accentMap = <String, String>{
    'a': 'a',
    'e': 'e',
    'i': 'i',
    'o': 'o',
    'u': 'u',
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ä': 'a',
    'ë': 'e',
    'ï': 'i',
    'ö': 'o',
    'ü': 'u',
  };

  final StringBuffer buffer = StringBuffer();
  for (final int rune in output.runes) {
    final String char = String.fromCharCode(rune);
    buffer.write(accentMap[char] ?? char);
  }

  return buffer.toString();
}

String _normalizeSpaces(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
