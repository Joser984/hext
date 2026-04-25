enum PadSummaryTone { dominant, secondary, active, evaluating, closed, neutral }

class PadSummaryCompactVm {
  final String barrio;
  final String principalLabel;
  final bool principalInferred;
  final List<String> activeReasonLabels;
  final String shortDetail;
  final String generalStatusLabel;
  final PadSummaryTone principalTone;
  final PadSummaryTone statusTone;

  const PadSummaryCompactVm({
    required this.barrio,
    required this.principalLabel,
    required this.principalInferred,
    required this.activeReasonLabels,
    required this.shortDetail,
    required this.generalStatusLabel,
    required this.principalTone,
    required this.statusTone,
  });
}
