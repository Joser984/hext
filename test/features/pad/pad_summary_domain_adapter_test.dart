import 'package:flutter_test/flutter_test.dart';
import 'package:hext/features/pad/summary/pad_summary_compact_mapper.dart';
import 'package:hext/features/pad/summary/pad_summary_domain_adapter.dart';

void main() {
  group('PadSummaryDomainAdapter', () {
    test('uses only legacy motivos when no activos are provided', () {
      final PadCaseRecord record = PadCaseRecord(
        motivos: const <String>[' Oxigeno ', '  Caidas  '],
        barrio: '',
      );

      final PadCaseData data = PadSummaryDomainAdapter.toPadCaseData(record);

      expect(data.motivosActivos, const <String>['Oxigeno', 'Caidas']);
    });

    test('infers principal from activos when principal is blank', () {
      final PadCaseRecord record = PadCaseRecord(
        motivoIngresoPrincipal: '   ',
        motivosIngresoActivos: const <String>['Dolor', 'Disnea'],
        barrio: '',
      );

      final vm = mapPadSummary(PadSummaryDomainAdapter.toPadCaseData(record));

      expect(vm.principalLabel, 'Dolor');
      expect(vm.principalInferred, isTrue);
    });

    test('falls back to observaciones when structured detail is missing', () {
      final PadCaseRecord record = PadCaseRecord(
        observaciones: 'Paciente con soporte familiar adecuado.',
        barrio: '',
      );

      final vm = mapPadSummary(PadSummaryDomainAdapter.toPadCaseData(record));

      expect(vm.shortDetail, 'Paciente con soporte familiar adecuado.');
    });

    test('keeps unclassified status when source value is not mapped', () {
      final PadCaseRecord record = PadCaseRecord(
        estadoPad: 'Pendiente comite externo',
        barrio: '',
      );

      final vm = mapPadSummary(PadSummaryDomainAdapter.toPadCaseData(record));

      expect(vm.generalStatusLabel, 'Estado no clasificado');
    });

    test('merges active and legacy lists without duplicates', () {
      final PadCaseRecord record = PadCaseRecord(
        motivosIngresoActivos: const <String>['Disnea', 'Oxigeno'],
        motivos: const <String>[' oxigeno ', 'Caidas'],
        barrio: '',
      );

      final PadCaseData data = PadSummaryDomainAdapter.toPadCaseData(record);

      expect(data.motivosActivos, const <String>[
        'Disnea',
        'Oxigeno',
        'Caidas',
      ]);
    });

    test('reads aliases from map and keeps activos priority over legacy', () {
      final Map<String, dynamic> raw = <String, dynamic>{
        'motivoPrincipal': 'Control clinico',
        'motivosActivos': <String>['Disnea', 'Oxigeno'],
        'motivos': <String>['oxigeno', 'Caidas'],
        'barrio': '',
      };

      final PadCaseRecord record = PadCaseRecord.fromMap(raw);
      final PadCaseData data = PadSummaryDomainAdapter.toPadCaseData(record);

      expect(record.motivoIngresoPrincipal, 'Control clinico');
      expect(data.motivosActivos, const <String>[
        'Disnea',
        'Oxigeno',
        'Caidas',
      ]);
    });

    test('normalizes irregular spacing and deduplicates mixed lists', () {
      final PadCaseRecord record = PadCaseRecord(
        motivosIngresoActivos: const <String>['  Oxígeno  ', 'disnea'],
        motivos: const <String>['oxígeno', '  Disnea  ', 'Caídas'],
        barrio: '',
      );

      final PadCaseData data = PadSummaryDomainAdapter.toPadCaseData(record);

      expect(data.motivosActivos, const <String>[
        'Oxígeno',
        'disnea',
        'Caídas',
      ]);
    });
  });
}
