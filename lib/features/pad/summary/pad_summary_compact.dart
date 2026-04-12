import 'package:flutter/material.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_vm.dart';
import 'package:hext/shared/widgets/app_chip.dart';

class PadSummaryCompact extends StatelessWidget {
  const PadSummaryCompact({
    super.key,
    required this.vm,
    this.maxReasonChips = 3,
  });

  final PadSummaryCompactVm vm;
  final int maxReasonChips;

  @override
  Widget build(BuildContext context) {
    final List<String> visibleReasons = vm.activeReasonLabels
        .take(maxReasonChips)
        .toList();
    final int overflow = vm.activeReasonLabels.length - visibleReasons.length;
    final bool isPrincipalFallback =
        vm.principalLabel.trim().toLowerCase() == 'sin motivo principal';
    final AppChipTone principalTone = isPrincipalFallback
        ? AppChipTone.warning
        : _chipToneFor(vm.principalTone);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isNarrow = constraints.maxWidth < 340;
        final int detailMaxLines = constraints.maxWidth < 340 ? 1 : 2;
        final int principalChipChars = isNarrow ? 18 : 32;
        final int reasonChipChars = isNarrow ? 16 : 32;
        final int statusChipChars = isNarrow ? 20 : 28;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  AppChip(
                    label: _chipLabel(
                      vm.principalLabel,
                      maxChars: principalChipChars,
                    ),
                    tone: principalTone,
                    leadingDot: !isPrincipalFallback,
                  ),
                  if (vm.principalInferred)
                    const AppChip(label: 'Inferido', tone: AppChipTone.neutral),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (visibleReasons.isEmpty)
                    const AppChip(
                      label: 'Sin motivos activos',
                      tone: AppChipTone.warning,
                    )
                  else
                    ...visibleReasons.map(
                      (String reason) => AppChip(
                        label: _chipLabel(reason, maxChars: reasonChipChars),
                        tone: AppChipTone.neutral,
                      ),
                    ),
                  if (overflow > 0)
                    AppChip(label: '+$overflow', tone: AppChipTone.info),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                vm.shortDetail,
                maxLines: detailMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 10),
              AppChip(
                label: _chipLabel(vm.generalStatusLabel, maxChars: statusChipChars),
                tone: _chipToneFor(vm.statusTone),
                leadingDot: true,
              ),
            ],
          ),
        );
      },
    );
  }

  AppChipTone _chipToneFor(PadSummaryTone tone) {
    switch (tone) {
      case PadSummaryTone.dominant:
        return AppChipTone.info;
      case PadSummaryTone.secondary:
        return AppChipTone.neutral;
      case PadSummaryTone.active:
        return AppChipTone.success;
      case PadSummaryTone.evaluating:
        return AppChipTone.warning;
      case PadSummaryTone.closed:
        return AppChipTone.neutral;
      case PadSummaryTone.neutral:
        return AppChipTone.neutral;
    }
  }

  String _chipLabel(String value, {int maxChars = 32}) {
    final String normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars - 1)}…';
  }
}
