// Modelo para opciones de aseguradora
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
