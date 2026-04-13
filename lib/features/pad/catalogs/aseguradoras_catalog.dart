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
  // EPS (28)
  AseguradoraOption(
    key: 'coosalud_eps_s',
    label: 'Coosalud EPS-S',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'nueva_eps', label: 'Nueva EPS', tipo: 'eps'),
  AseguradoraOption(key: 'mutual_ser', label: 'Mutual Ser', tipo: 'eps'),
  AseguradoraOption(key: 'salud_mia', label: 'Salud Mía', tipo: 'eps'),
  AseguradoraOption(
    key: 'aliansalud_eps',
    label: 'Aliansalud EPS',
    tipo: 'eps',
  ),
  AseguradoraOption(
    key: 'salud_total_eps',
    label: 'Salud Total EPS',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'eps_sanitas', label: 'EPS Sanitas', tipo: 'eps'),
  AseguradoraOption(key: 'eps_sura', label: 'EPS SURA', tipo: 'eps'),
  AseguradoraOption(key: 'famisanar_eps', label: 'Famisanar EPS', tipo: 'eps'),
  AseguradoraOption(
    key: 'sos_eps',
    label: 'Servicio Occidental de Salud EPS SOS',
    tipo: 'eps',
  ),
  AseguradoraOption(
    key: 'comfenalco_valle_eps',
    label: 'Comfenalco Valle EPS',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'compensar_eps', label: 'Compensar EPS', tipo: 'eps'),
  AseguradoraOption(
    key: 'epm_empresas_publicas_medellin',
    label: 'EPM - Empresas Públicas de Medellín',
    tipo: 'eps',
  ),
  AseguradoraOption(
    key: 'fondo_pasivo_ferrocarriles',
    label: 'Fondo de Pasivo Social de Ferrocarriles Nacionales de Colombia',
    tipo: 'eps',
  ),
  AseguradoraOption(
    key: 'cajacopi_atlantico',
    label: 'Cajacopi Atlántico',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'capresoca', label: 'Capresoca', tipo: 'eps'),
  AseguradoraOption(key: 'comfachoco', label: 'Comfachocó', tipo: 'eps'),
  AseguradoraOption(key: 'comfaoriente', label: 'Comfaoriente', tipo: 'eps'),
  AseguradoraOption(
    key: 'eps_familiar_colombia',
    label: 'EPS Familiar de Colombia',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'asmet_salud', label: 'Asmet Salud', tipo: 'eps'),
  AseguradoraOption(key: 'emssanar_ess', label: 'Emssanar E.S.S.', tipo: 'eps'),
  AseguradoraOption(
    key: 'capital_salud_eps_s',
    label: 'Capital Salud EPS-S',
    tipo: 'eps',
  ),
  AseguradoraOption(
    key: 'savia_salud_eps',
    label: 'Savia Salud EPS',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'dusakawi_epsi', label: 'Dusakawi EPSI', tipo: 'eps'),
  AseguradoraOption(
    key: 'aic_epsi',
    label: 'Asociación Indígena del Cauca EPSI',
    tipo: 'eps',
  ),
  AseguradoraOption(
    key: 'anas_wayuu_epsi',
    label: 'Anas Wayuu EPSI',
    tipo: 'eps',
  ),
  AseguradoraOption(key: 'mallamas_epsi', label: 'Mallamas EPSI', tipo: 'eps'),
  AseguradoraOption(
    key: 'pijaos_salud_epsi',
    label: 'Pijaos Salud EPSI',
    tipo: 'eps',
  ),

  // Medicina prepagada (5)
  AseguradoraOption(
    key: 'colsanitas_prepagada',
    label: 'Colsanitas Medicina Prepagada',
    tipo: 'prepagada',
  ),
  AseguradoraOption(
    key: 'medisanitas_prepagada',
    label: 'Medisanitas Medicina Prepagada',
    tipo: 'prepagada',
  ),
  AseguradoraOption(
    key: 'colmedica_prepagada',
    label: 'Colmédica Medicina Prepagada',
    tipo: 'prepagada',
  ),
  AseguradoraOption(
    key: 'medplus_prepagada',
    label: 'MedPlus Medicina Prepagada',
    tipo: 'prepagada',
  ),
  AseguradoraOption(
    key: 'coomeva_prepagada',
    label: 'Coomeva Medicina Prepagada',
    tipo: 'prepagada',
  ),

  // Póliza (17)
  AseguradoraOption(key: 'seguros_sura', label: 'Seguros SURA', tipo: 'poliza'),
  AseguradoraOption(
    key: 'sura_salud_clasica',
    label: 'SURA Salud Clásica',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'sura_salud_global',
    label: 'SURA Salud Global',
    tipo: 'poliza',
  ),
  AseguradoraOption(key: 'allianz', label: 'Allianz', tipo: 'poliza'),
  AseguradoraOption(
    key: 'allianz_salud_care',
    label: 'Allianz Salud Care',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'allianz_gold_plus',
    label: 'Allianz Gold Plus',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'axa_colpatria',
    label: 'AXA Colpatria',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'axa_original_amparado',
    label: 'AXA Colpatria Plan Original Amparado',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'axa_alterno_amparado',
    label: 'AXA Colpatria Plan Alterno Amparado',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'axa_salud_ideal',
    label: 'AXA Colpatria Salud Ideal',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'seguros_bolivar',
    label: 'Seguros Bolívar',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'bolivar_salud_integral',
    label: 'Seguros Bolívar Salud Integral',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'bolivar_bupa',
    label: 'Seguros Bolívar + BUPA',
    tipo: 'poliza',
  ),
  AseguradoraOption(key: 'mapfre', label: 'MAPFRE', tipo: 'poliza'),
  AseguradoraOption(
    key: 'mapfre_excelencia',
    label: 'MAPFRE Salud Excelencia',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'mapfre_preferencial',
    label: 'MAPFRE Salud Preferencial',
    tipo: 'poliza',
  ),
  AseguradoraOption(
    key: 'mapfre_vital',
    label: 'MAPFRE Salud Vital',
    tipo: 'poliza',
  ),
];

List<OptionItem<String>> aseguradorasPorTipo(String? tipo) {
  if (tipo == null) return [];
  final items = kAseguradoras.where((a) => a.tipo == tipo).toList();
  final optionItems =
      items
          .map((e) => OptionItem<String>(value: e.key, label: e.label))
          .toList()
        ..sort(
          (OptionItem<String> a, OptionItem<String> b) =>
              a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
  if (tipo == 'otro') {
    optionItems.add(const OptionItem<String>(value: 'otro', label: 'Otra'));
  }
  return optionItems;
}
