class DiagnosisTextFormatter {
  static final List<MapEntry<RegExp, String>> _acronyms =
      <MapEntry<RegExp, String>>[
        // Especificos primero
        MapEntry(
          RegExp(r'\bcha2ds2[-\s]*vasc\b', caseSensitive: false),
          'CHA₂DS₂-VASc',
        ),
        MapEntry(RegExp(r'\bhas[-\s]*bled\b', caseSensitive: false), 'HAS-BLED'),
        MapEntry(
          RegExp(r'\bkillip[-\s]*kimball\b', caseSensitive: false),
          'Killip-Kimball',
        ),
        MapEntry(RegExp(r'\bwells\s*tvp\b', caseSensitive: false), 'Wells TVP'),
        MapEntry(RegExp(r'\bwells\s*tep\b', caseSensitive: false), 'Wells TEP'),
        MapEntry(
          RegExp(r'\blawton[-\s]*brody\b', caseSensitive: false),
          'Lawton-Brody',
        ),
        MapEntry(
          RegExp(r'\bgustilo[-\s]*anderson\b', caseSensitive: false),
          'Gustilo-Anderson',
        ),
        MapEntry(
          RegExp(r'\bchild[-\s]*pugh\b', caseSensitive: false),
          'Child-Pugh',
        ),
        MapEntry(RegExp(r'\bmeld[-\s]*na\b', caseSensitive: false), 'MELD-Na'),
        MapEntry(
          RegExp(r'\bhunt[-\s]*hess\b', caseSensitive: false),
          'Hunt-Hess',
        ),
        MapEntry(RegExp(r'\bcam[-\s]*icu\b', caseSensitive: false), 'CAM-ICU'),
        // Generales
        MapEntry(RegExp(r'\bnyha\b', caseSensitive: false), 'NYHA'),
        MapEntry(RegExp(r'\bccs\b', caseSensitive: false), 'CCS'),
        MapEntry(RegExp(r'\btimi\b', caseSensitive: false), 'TIMI'),
        MapEntry(RegExp(r'\bgrace\b', caseSensitive: false), 'GRACE'),
        MapEntry(RegExp(r'\bgeneva\b', caseSensitive: false), 'Geneva'),
        MapEntry(RegExp(r'\bgcs\b', caseSensitive: false), 'GCS'),
        MapEntry(RegExp(r'\bnihss\b', caseSensitive: false), 'NIHSS'),
        MapEntry(RegExp(r'\bmrs\b', caseSensitive: false), 'mRS'),
        MapEntry(RegExp(r'\bwfns\b', caseSensitive: false), 'WFNS'),
        MapEntry(RegExp(r'\babcd2\b', caseSensitive: false), 'ABCD²'),
        MapEntry(RegExp(r'\bmmse\b', caseSensitive: false), 'MMSE'),
        MapEntry(RegExp(r'\bmoca\b', caseSensitive: false), 'MoCA'),
        MapEntry(RegExp(r'\bcdr\b', caseSensitive: false), 'CDR'),
        MapEntry(RegExp(r'\bbraden\b', caseSensitive: false), 'Braden'),
        MapEntry(RegExp(r'\bnorton\b', caseSensitive: false), 'Norton'),
        MapEntry(RegExp(r'\bmorse\b', caseSensitive: false), 'Morse'),
        MapEntry(RegExp(r'\bbarthel\b', caseSensitive: false), 'Barthel'),
        MapEntry(RegExp(r'\bkatz\b', caseSensitive: false), 'Katz'),
        MapEntry(RegExp(r'\bfim\b', caseSensitive: false), 'FIM'),
        MapEntry(RegExp(r'\bmna\b', caseSensitive: false), 'MNA'),
        MapEntry(RegExp(r'\bcfs\b', caseSensitive: false), 'CFS'),
        MapEntry(RegExp(r'\bcci\b', caseSensitive: false), 'CCI'),
        MapEntry(RegExp(r'\bnews\s*2\b', caseSensitive: false), 'NEWS2'),
        MapEntry(RegExp(r'\bnews\b', caseSensitive: false), 'NEWS'),
        MapEntry(RegExp(r'\bqsofa\b', caseSensitive: false), 'qSOFA'),
        MapEntry(RegExp(r'\bsofa\b', caseSensitive: false), 'SOFA'),
        MapEntry(
          RegExp(r'\bapache\s*ii\b', caseSensitive: false),
          'APACHE II',
        ),
        MapEntry(RegExp(r'\bsaps\s*ii\b', caseSensitive: false), 'SAPS II'),
        MapEntry(RegExp(r'\bmeld\b', caseSensitive: false), 'MELD'),
        MapEntry(RegExp(r'\bbode\b', caseSensitive: false), 'BODE'),
        MapEntry(RegExp(r'\bdas\s*28\b', caseSensitive: false), 'DAS28'),
        MapEntry(RegExp(r'\bcdai\b', caseSensitive: false), 'CDAI'),
        MapEntry(RegExp(r'\bsdai\b', caseSensitive: false), 'SDAI'),
        MapEntry(RegExp(r'\bsledai\b', caseSensitive: false), 'SLEDAI'),
        MapEntry(RegExp(r'\bsleday\b', caseSensitive: false), 'SLEDAI'),
        MapEntry(RegExp(r'\bbasdai\b', caseSensitive: false), 'BASDAI'),
        MapEntry(RegExp(r'\bmayo\b', caseSensitive: false), 'Mayo'),
        MapEntry(RegExp(r'\bwagner\b', caseSensitive: false), 'Wagner'),
        MapEntry(RegExp(r'\bweber\b', caseSensitive: false), 'Weber'),
        // Romanos clinicos
        MapEntry(RegExp(r'\bii\b', caseSensitive: false), 'II'),
        MapEntry(RegExp(r'\biii\b', caseSensitive: false), 'III'),
        MapEntry(RegExp(r'\biv\b', caseSensitive: false), 'IV'),
        MapEntry(RegExp(r'\bvi\b', caseSensitive: false), 'VI'),
        // Otras siglas clinicas
        MapEntry(RegExp(r'\bvih\b', caseSensitive: false), 'VIH'),
        MapEntry(RegExp(r'\bdm\b', caseSensitive: false), 'DM'),
        MapEntry(RegExp(r'\berc\b', caseSensitive: false), 'ERC'),
        MapEntry(RegExp(r'\bhta\b', caseSensitive: false), 'HTA'),
        MapEntry(RegExp(r'\bacv\b', caseSensitive: false), 'ACV'),
        MapEntry(RegExp(r'\becv\b', caseSensitive: false), 'ECV'),
        MapEntry(RegExp(r'\bhc\b', caseSensitive: false), 'HC'),
        MapEntry(RegExp(r'\bpop\b', caseSensitive: false), 'POP'),
        MapEntry(RegExp(r'\btfg\b', caseSensitive: false), 'TFG'),
        MapEntry(RegExp(r'\btxm\b', caseSensitive: false), 'TXM'),
        MapEntry(RegExp(r'\bkdigo\b', caseSensitive: false), 'KDIGO'),
        MapEntry(RegExp(r'\bfevi\b', caseSensitive: false), 'FEVI'),
        MapEntry(RegExp(r'\baha\b', caseSensitive: false), 'AHA'),
        MapEntry(RegExp(r'\bpsi\b', caseSensitive: false), 'PSI'),
        MapEntry(RegExp(r'\boms\b', caseSensitive: false), 'OMS'),
        MapEntry(RegExp(r'\buci\b', caseSensitive: false), 'UCI'),
        MapEntry(RegExp(r'\btbc\b', caseSensitive: false), 'TBC'),
        MapEntry(RegExp(r'\bepoc\b', caseSensitive: false), 'EPOC'),
        MapEntry(RegExp(r'\bckd[\s-]*epi\b', caseSensitive: false), 'CKD-EPI'),
        MapEntry(RegExp(r'\bhba1c\b', caseSensitive: false), 'HbA1c'),
        MapEntry(RegExp(r'\be\.\s*coli\b', caseSensitive: false), 'E. coli'),
        MapEntry(RegExp(r'\bcurb[\s-]*65\b', caseSensitive: false), 'CURB-65'),
      ];

  static String normalizeForStorage(String raw) {
    String text = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();

    text = text.replaceAll(RegExp(r"""^["']+|["']+$"""), '').trim();
    text = _insertLineBreaks(text);
    text = _normalizeLineWhitespace(text);
    text = _toSentenceStyle(text);
    text = _normalizeAcronyms(text);
    text = _normalizeClinicalPatterns(text);

    return text.trim();
  }

  static String formatForAgenda(String raw) {
    return normalizeForStorage(raw)
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .join('\n');
  }

  static String formatAsBulletedList(String raw) {
    String text = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();

    text = text.replaceAll(RegExp(r"""^["']+|["']+$"""), '').trim();
    text = _insertLineBreaks(text);
    text = _normalizeLineWhitespace(text);
    text = _toSentenceStyle(text);
    text = _normalizeAcronyms(text);
    text = _normalizeClinicalPatterns(text);

    final List<String> lines = text
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .map((String line) => line.startsWith('- ') ? line : '- $line')
        .toList();

    return lines.join('\n').trim();
  }

  static String _normalizeClinicalPatterns(String text) {
    String output = text;

    output = output.replaceAllMapped(
      RegExp(r'\b(Weber)\s+([abc])\b', caseSensitive: false),
      (Match m) =>
          '${m.group(1)![0].toUpperCase()}${m.group(1)!.substring(1).toLowerCase()} ${m.group(2)!.toUpperCase()}',
    );

    output = output.replaceAllMapped(
      RegExp(
        r'\b(Gustilo-Anderson)\s+(i|ii|iii|iv|v|vi)\s+([abc])\b',
        caseSensitive: false,
      ),
      (Match m) =>
          '${m.group(1)} ${m.group(2)!.toUpperCase()} ${m.group(3)!.toUpperCase()}',
    );

    output = output.replaceAllMapped(
      RegExp(r'\b(Wagner)\s+(i|ii|iii|iv|v|vi)\b', caseSensitive: false),
      (Match m) => '${m.group(1)} ${m.group(2)!.toUpperCase()}',
    );

    output = output.replaceAllMapped(
      RegExp(r'\b(NYHA)\s+(i|ii|iii|iv)\b', caseSensitive: false),
      (Match m) => '${m.group(1)} ${m.group(2)!.toUpperCase()}',
    );

    return output;
  }

  static String _normalizeAcronyms(String text) {
    String output = text;
    for (final MapEntry<RegExp, String> entry in _acronyms) {
      output = output.replaceAllMapped(entry.key, (_) => entry.value);
    }
    return output;
  }

  static String _insertLineBreaks(String text) {
    String output = text;

    output = output.replaceAllMapped(
      RegExp(r'(?<!\d)(\d+\.\d+(?:\.\d+)*)\s+(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])'),
      (Match m) => '${m.group(1)}. ',
    );

    output = output.replaceAllMapped(
      RegExp(
        r'(?<!^)(?<!\n)\s*(\d+(?:\.\d+)*[\.\-\)])\s*(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])',
      ),
      (Match m) => '\n${m.group(1)} ',
    );

    output = output.replaceAllMapped(
      RegExp(r'(?<!^)(?<!\n)\s*([A-Za-zÁÉÍÓÚÑ][\.\)])\s*(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])'),
      (Match m) => '\n${m.group(1)} ',
    );

    output = output.replaceAllMapped(
      RegExp(r'(?<!^)(?<!\n)\s*([\-•*])\s+(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])'),
      (Match m) => '\n${m.group(1)} ',
    );

    output = output.replaceAllMapped(
      RegExp(r'(?<!^)(?<!\n)\s*((?:::)|(?:\*\*\*))\s*'),
      (Match m) => '\n${m.group(1)} ',
    );

    return output;
  }

  static String _toSentenceStyle(String text) {
    final List<String> lines = text.split('\n');

    return lines.map((String line) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) return '';

      String prefix = '';
      String content = trimmed;

      final RegExpMatch? numbered =
          RegExp(r'^(\d+(?:\.\d+)*[\.\-\)]\s+)(.*)$').firstMatch(trimmed);
      final RegExpMatch? bulleted =
          RegExp(r'^([\-•*]\s+)(.*)$').firstMatch(trimmed);
      final RegExpMatch? lettered =
          RegExp(r'^([A-Za-zÁÉÍÓÚÑ][\.\)]\s+)(.*)$').firstMatch(trimmed);
      final RegExpMatch? marked =
          RegExp(r'^((?:::)|(?:\*\*\*))\s*(.*)$').firstMatch(trimmed);

      if (numbered != null) {
        prefix = numbered.group(1)!;
        content = numbered.group(2)!;
      } else if (bulleted != null) {
        prefix = bulleted.group(1)!;
        content = bulleted.group(2)!;
      } else if (lettered != null) {
        prefix = lettered.group(1)!;
        content = lettered.group(2)!;
      } else if (marked != null) {
        prefix = '${marked.group(1)!} ';
        content = marked.group(2)!;
      }

      content = content.toLowerCase();
      content = _capitalizeFirstLetter(content);

      return '$prefix$content';
    }).join('\n');
  }

  static String _capitalizeFirstLetter(String value) {
    for (int i = 0; i < value.length; i++) {
      final String ch = value[i];
      if (RegExp(r'[A-Za-zÁÉÍÓÚÑáéíóúñ]').hasMatch(ch)) {
        return value.substring(0, i) +
            ch.toUpperCase() +
            value.substring(i + 1);
      }
    }
    return value;
  }

  static String _normalizeLineWhitespace(String text) {
    return text
        .split('\n')
        .map((String line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((String line) => line.isNotEmpty)
        .join('\n');
  }
}
