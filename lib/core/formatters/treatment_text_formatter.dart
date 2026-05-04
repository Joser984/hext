class TreatmentDisplayData {
  const TreatmentDisplayData({
    required this.mainLine,
    this.frequencyLine,
    this.infusorLine,
  });

  final String mainLine;
  final String? frequencyLine;
  final String? infusorLine;
}

class TreatmentTextFormatter {
  const TreatmentTextFormatter._();

  static TreatmentDisplayData formatTreatment(Map<String, dynamic> data) {
    final String mainLine = _buildMainLine(data);
    final String? frequencyLine = _buildFrequencyLine(data);
    final String? infusorLine = _buildInfusorLine(data);

    return TreatmentDisplayData(
      mainLine: mainLine.isEmpty ? 'ACTIVIDAD PROGRAMADA' : mainLine,
      frequencyLine: _nullIfEmpty(frequencyLine),
      infusorLine: _nullIfEmpty(infusorLine),
    );
  }

  static String _buildMainLine(Map<String, dynamic> data) {
    final List<String> parts = <String>[
      _normalizeMedicationName(data['nombreTratamiento']),
      _normalizeDose(data['dosis']),
      _normalizeRoute(data['via']),
    ].where((String part) => part.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    final String rawMainLine = _normalizeFreeformMedication(
      data['mainLine'] ?? data['tratamiento'],
    );
    if (rawMainLine.isNotEmpty) {
      return rawMainLine;
    }

    return _normalizeMedicationName(data['nombreTratamiento']);
  }

  static String? _buildFrequencyLine(Map<String, dynamic> data) {
    return _normalizeFrequency(data['frecuencia']);
  }

  static String? _buildInfusorLine(Map<String, dynamic> data) {
    final String value = _normalizeString(data['pacienteCuentaConInfusor'])
        .toLowerCase();
    if (value.isEmpty) {
      return 'Infusor: Por confirmar';
    }
    switch (value) {
      case 'si':
        return 'Infusor: Sí';
      case 'no':
        return 'Infusor: No';
      case 'por_confirmar':
        return 'Infusor: Por confirmar';
      default:
        return 'Infusor: Por confirmar';
    }
  }

  static String _normalizeMedicationName(dynamic value) {
    return _normalizeString(value).toUpperCase();
  }

  static String _normalizeDose(dynamic value) {
    String normalized = _normalizeString(value).toUpperCase();
    if (normalized.isEmpty) {
      return '';
    }

    normalized = normalized
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*GRS?\b'),
          (match) => '${match.group(1)} GR',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*GRAMOS?\b'),
          (match) => '${match.group(1)} GR',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*MGS?\b'),
          (match) => '${match.group(1)} MG',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*MILS?\b'),
          (match) => '${match.group(1)} ML',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*MLS?\b'),
          (match) => '${match.group(1)} ML',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*UIS?\b'),
          (match) => '${match.group(1)} UI',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+(?:[.,]\d+)?)\s*AMP(?:OLLA)?S?\b'),
          (match) => '${match.group(1)} AMP',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  static String _normalizeRoute(dynamic value) {
    final String normalized = _normalizeString(value).toLowerCase();
    switch (normalized) {
      case 'iv':
      case 'intravenoso':
      case 'intravenosa':
      case 'endovenoso':
      case 'endovenosa':
        return 'IV';
      case 'vo':
      case 'oral':
        return 'VO';
      case 'im':
      case 'intramuscular':
        return 'IM';
      case 'sc':
      case 'subcutaneo':
      case 'subcutanea':
        return 'SC';
      case 'sl':
      case 'sublingual':
        return 'SL';
      default:
        return normalized.toUpperCase();
    }
  }

  static String? _normalizeFrequency(dynamic value) {
    final String normalized = _normalizeString(value).toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final RegExpMatch? hoursMatch = RegExp(
      r'(?:cada|c/)\s*(\d+)\s*(?:h|hr|hrs|hora|horas)',
    ).firstMatch(normalized);
    if (hoursMatch != null) {
      return 'c/${hoursMatch.group(1)} h';
    }

    final RegExpMatch? hoursOnlyMatch =
        RegExp(r'\b(\d+)\s*h\b').firstMatch(normalized);
    if (hoursOnlyMatch != null) {
      return 'c/${hoursOnlyMatch.group(1)} h';
    }

    return _toSentenceCase(normalized);
  }

  static String _normalizeFreeformMedication(dynamic value) {
    String normalized = _normalizeString(value).toUpperCase();
    if (normalized.isEmpty) {
      return '';
    }

    normalized = normalized
        .replaceAll(RegExp(r'\bINTRAVENOS[AO]\b'), 'IV')
        .replaceAll(RegExp(r'\bENDOVENOS[AO]\b'), 'IV')
        .replaceAll(RegExp(r'\bSUBCUTANE[AO]\b'), 'SC')
        .replaceAll(RegExp(r'\bORAL\b'), 'VO')
        .replaceAll(RegExp(r'\bINTRAMUSCULAR\b'), 'IM')
        .replaceAll(RegExp(r'\bSUBLINGUAL\b'), 'SL')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    normalized = _normalizeDose(normalized);
    return normalized;
  }

  static String _normalizeString(dynamic value) {
    return (value ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _nullIfEmpty(String? value) {
    if (value == null) {
      return null;
    }
    final String normalized = _normalizeString(value);
    return normalized.isEmpty ? null : normalized;
  }

  static String _toSentenceCase(String text) {
    if (text.isEmpty) {
      return text;
    }
    final String lower = text.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
}
