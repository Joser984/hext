// Catálogos y listas constantes para PAD
// Ejemplo: barrios, especialidades, unidades, GRD, aseguradoras, etc.

// Aquí irán los catálogos migrados desde nuevo_pad_screen.dart

import 'package:hext/core/models/option_item.dart';
// Catálogo de opciones de sexo
const List<OptionItem<String>> kSexoOptions = [
  OptionItem<String>(value: 'masculino', label: 'Masculino'),
  OptionItem<String>(value: 'femenino', label: 'Femenino'),
  OptionItem<String>(value: 'otro', label: 'Otro'),
];

// Catálogo de tipos de aseguradora (clave/etiqueta)
const List<Map<String, String>> kTiposAseguradora = [
	{'key': 'arl', 'label': 'ARL'},
	{'key': 'eps', 'label': 'EPS'},
	{'key': 'prepagada', 'label': 'Medicina prepagada'},
	{'key': 'particular', 'label': 'Particular'},
	{'key': 'poliza', 'label': 'Póliza'},
	{'key': 'soat', 'label': 'SOAT'},
	{'key': 'otro', 'label': 'Otro'},
];

// Catálogo de origen de captación
const List<OptionItem<String>> kOrigenCaptacionOptions = [
  OptionItem<String>(value: 'urgencias', label: 'Urgencias'),
  OptionItem<String>(value: 'consulta_externa', label: 'Consulta externa'),
  OptionItem<String>(value: 'hospitalizacion', label: 'Hospitalización'),
  OptionItem<String>(value: 'uci', label: 'UCI'),
  OptionItem<String>(value: 'otro', label: 'Otro'),
];

// Catálogo de resultado/disposición PAD
const List<OptionItem<String>> kResultadoPadOptions = [
  OptionItem<String>(value: 'aprobado', label: 'Aprobado'),
  OptionItem<String>(value: 'no_aprobado', label: 'No aprobado'),
  OptionItem<String>(value: 'pendiente', label: 'Pendiente'),
];

// Catálogo de unidades funcionales de origen
const List<String> kUnidadesFuncionalesOrigen = [
	'Unidad 1',
	'Unidad 2',
	'Unidad 3',
	'Unidad 4',
	'Otra',
];
