import 'package:hext/core/models/option_item.dart';

// Helper to find an AseguradoraOption by key
AseguradoraOption? findAseguradoraByKey(String? key) {
  if (key == null) return null;
  try {
    return kAseguradoras.firstWhere((a) => a.key == key);
  } catch (_) {
    return null;
  }
}

const List<OptionItem<String>> kTipoAseguradoraOptions = [
  OptionItem(value: 'arl', label: 'ARL'),
  OptionItem(value: 'eps', label: 'EPS'),
  OptionItem(value: 'prepagada', label: 'Medicina prepagada'),
  OptionItem(value: 'particular', label: 'Particular'),
  OptionItem(value: 'poliza', label: 'Póliza'),
  OptionItem(value: 'soat', label: 'SOAT'),
  OptionItem(value: 'otro', label: 'Otro'),
];

class AseguradoraOption {
  final String key;
  final String label;
  final String tipo; // eps, prepagada, soat, poliza, particular, otra
  final String? regimen; // contributivo, subsidiado, ambos, especial, null

  const AseguradoraOption({
    required this.key,
    required this.label,
    required this.tipo,
    this.regimen,
  });
}

const List<AseguradoraOption> kAseguradoras = [
  AseguradoraOption(key: 'sura', label: 'Sura', tipo: 'eps', regimen: 'contributivo'),
  AseguradoraOption(key: 'sanitas', label: 'Sanitas', tipo: 'eps', regimen: 'contributivo'),
  AseguradoraOption(key: 'compensar', label: 'Compensar', tipo: 'eps', regimen: 'contributivo'),
  // ...agrega más aseguradoras aquí...
];

List<OptionItem<String>> aseguradorasPorTipo(String? tipo) {
  if (tipo == null) return [];
  final items = kAseguradoras.where((a) => a.tipo == tipo).toList();
  final optionItems = items.map((e) => OptionItem<String>(value: e.key, label: e.label)).toList();
  if (tipo == 'otro') {
    optionItems.add(const OptionItem<String>(value: 'otro', label: 'Otra'));
  }
  return optionItems;
}
