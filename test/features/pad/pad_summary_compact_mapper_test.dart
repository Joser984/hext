import 'package:flutter_test/flutter_test.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_vm.dart';

void main() {
  group('mapPadSummary', () {
    test('uses explicit principal when provided', () {
      final PadSummaryCompactVm vm = mapPadSummary(
        const PadCaseData(
          motivoPrincipal: 'Finalizar tratamiento instaurado',
          motivosActivos: <String>[
            'Definir conducta medica',
            'Finalizar tratamiento instaurado',
          ],
          detalleClinicoResumido: 'Detalle inicial',
          situacionAsistencial: 'Activos en PAD',
          barrio: '',
        ),
      );

      expect(vm.principalLabel, 'Finalizar tratamiento instaurado');
      expect(vm.principalInferred, isFalse);
      expect(vm.generalStatusLabel, 'Activo');
      expect(vm.statusTone, PadSummaryTone.active);
    });

    test(
      'infers principal from first active reason when explicit is empty',
      () {
        final PadSummaryCompactVm vm = mapPadSummary(
          const PadCaseData(
            motivosActivos: <String>['Definir pertinencia ingreso PAD'],
            detalleClinicoResumido: 'Detalle',
            estadoPad: 'Pendiente decision',
            barrio: '',
          ),
        );

        expect(vm.principalLabel, 'Definir pertinencia ingreso PAD');
        expect(vm.principalInferred, isTrue);
        expect(vm.generalStatusLabel, 'En valoracion');
        expect(vm.statusTone, PadSummaryTone.evaluating);
      },
    );

    test('falls back when there are no reasons', () {
      final PadSummaryCompactVm vm = mapPadSummary(
        const PadCaseData(
          motivosActivos: <String>[],
          observaciones: 'Sin detalle estructurado',
          barrio: '',
        ),
      );

      expect(vm.principalLabel, 'Sin motivo principal');
      expect(vm.principalInferred, isFalse);
      expect(vm.activeReasonLabels, isEmpty);
      expect(vm.shortDetail, 'Sin detalle estructurado');
    });

    test('returns unclassified state when source status is not resolvable', () {
      final PadSummaryCompactVm vm = mapPadSummary(
        const PadCaseData(
          motivoPrincipalLabel: 'Curaciones',
          observaciones: 'Observacion',
          situacionAsistencial: 'Estado experimental',
          barrio: '',
        ),
      );

      expect(vm.generalStatusLabel, 'Estado no clasificado');
      expect(vm.statusTone, PadSummaryTone.neutral);
    });
  });
}
