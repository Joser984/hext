import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hext/features/pad/summary/pad_summary_compact.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_vm.dart';

void main() {
  PadSummaryCompactVm buildVm({
    String principalLabel = 'Finalizar tratamiento',
    bool principalInferred = false,
    List<String> reasons = const <String>['Finalizar tratamiento'],
    String detail = 'Detalle corto',
    String status = 'Activo',
  }) {
    return PadSummaryCompactVm(
      principalLabel: principalLabel,
      principalInferred: principalInferred,
      activeReasonLabels: reasons,
      shortDetail: detail,
      generalStatusLabel: status,
      principalTone: PadSummaryTone.dominant,
      statusTone: PadSummaryTone.active,
    );
  }

  Future<void> pumpSummary(
    WidgetTester tester, {
    required double width,
    required PadSummaryCompactVm vm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: PadSummaryCompact(vm: vm),
            ),
          ),
        ),
      ),
    );
  }

  group('PadSummaryCompact widget', () {
    testWidgets('shows intentional empty fallbacks', (
      WidgetTester tester,
    ) async {
      await pumpSummary(
        tester,
        width: 420,
        vm: buildVm(
          principalLabel: 'Sin motivo principal',
          reasons: const <String>[],
          detail: 'Sin detalle clinico resumido',
          status: 'Estado no clasificado',
        ),
      );

      expect(find.text('Sin motivo principal'), findsOneWidget);
      expect(find.text('Sin motivos activos'), findsOneWidget);
      expect(find.text('Estado no clasificado'), findsOneWidget);
    });

    testWidgets('uses 1 detail line on narrow width', (
      WidgetTester tester,
    ) async {
      const String detail =
          'Detalle muy largo para validar truncado en ancho estrecho.';
      await pumpSummary(tester, width: 320, vm: buildVm(detail: detail));

      final Finder detailFinder = find.text(detail);
      expect(detailFinder, findsOneWidget);
      final Text detailWidget = tester.widget<Text>(detailFinder);
      expect(detailWidget.maxLines, 1);
    });

    testWidgets('uses 2 detail lines on wide width', (
      WidgetTester tester,
    ) async {
      const String detail =
          'Detalle muy largo para validar truncado en ancho amplio.';
      await pumpSummary(tester, width: 500, vm: buildVm(detail: detail));

      final Finder detailFinder = find.text(detail);
      expect(detailFinder, findsOneWidget);
      final Text detailWidget = tester.widget<Text>(detailFinder);
      expect(detailWidget.maxLines, 2);
    });

    testWidgets('renders overflow chip when reasons exceed max', (
      WidgetTester tester,
    ) async {
      await pumpSummary(
        tester,
        width: 480,
        vm: buildVm(reasons: const <String>['A', 'B', 'C', 'D', 'E']),
      );

      expect(find.text('+2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
