import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hext/core/models/agenda_visita.dart';
import 'package:hext/core/repositories/agenda_repo.dart';

class InMemoryAgendaRepo extends ChangeNotifier implements AgendaRepo {
  final List<AgendaVisita> _items = <AgendaVisita>[
    AgendaVisita(
      id: 'ag-1',
      fecha: DateTime(2026, 3, 30),
      hora: '06:00',
      pacienteNombre: 'GLORIA CRISTINA VARGAS DE ROJANO',
      pacienteDocumento: '30769875',
      tratamiento:
          'AMLODIPINO TAB 10MG VO CADA DÍA, CARVEDILOL TAB 6.25MG VO CADA 12 HORAS, LINAGLIPTINA TAB 5MG VO CADA DÍA',
      dx: 'CELULITIS MIEMBRO INFERIOR IZQUIERDO + INSUFICIENCIA VENOSA',
      contacto1: '3245304998',
      contacto2: '3245897047',
      direccion: 'BARRIO BOSTON CRR 46 N° 31D - 32',
      pendiente: '',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-2',
      fecha: DateTime(2026, 3, 30),
      hora: '07:00',
      pacienteNombre: 'JOSE RAUL FRANCO ORREGO',
      pacienteDocumento: '98474062',
      tratamiento: 'PARACETAMOL 1 GR IV CADA 12 HR, DIPIRONA 2 GR IV CADA 12 HR',
      dx: 'S623 - FRACTURA DE OTROS HUESOS METACARPIANOS',
      contacto1: '3155879002',
      contacto2: '3147519384',
      direccion: 'SIMON BOLIVAR SECTOR 11 DE NOVIEMBRE MZ 41',
      pendiente: '',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-3',
      fecha: DateTime(2026, 3, 30),
      hora: '08:00',
      pacienteNombre: 'ANA CANDELARIA PEREZ HERRERA',
      pacienteDocumento: '33153174',
      tratamiento:
          'TRIMETOPRIM/SULFAMETOXAZOL AMP 80/400, PARACETAMOL 1G IV, GLUCOMETRÍAS PRECOMIDAS',
      dx: 'L031 - CELULITIS DE OTRAS PARTES DE LOS MIEMBROS + DIABETES',
      contacto1: '3215261361',
      contacto2: '3222252817',
      direccion: 'EL CAMPES TRE M7 LOTE 58',
      pendiente: '',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-4',
      fecha: DateTime(2026, 3, 30),
      hora: '10:00',
      pacienteNombre: 'JOSE MIGUEL AVENDAÑO MONTERO',
      pacienteDocumento: '73082847',
      tratamiento: 'PARACETAMOL 1 GR IV CADA 12 HR + TRAMAL 50 MG CADA 24 HORAS',
      dx: 'S424 - FRACTURA DE LA EPÍFISIS INFERIOR DEL HÚMERO',
      contacto1: '3122194537',
      contacto2: '',
      direccion: 'EL EDUCADOR SECTOR BUENOS AIRES CR 75 A #3 C-03',
      pendiente: '',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-5',
      fecha: DateTime(2026, 3, 30),
      hora: '11:00',
      pacienteNombre: 'ROSA ARRIETA ATENCIO',
      pacienteDocumento: '45456552',
      tratamiento: 'CURACIÓN POR CLÍNICA DE HERIDA + PARACETAMOL CADA 12 HORAS',
      dx: 'L984 - ÚLCERA CRÓNICA DE LA PIEL + DIABETES MELLITUS',
      contacto1: '3005687846',
      contacto2: '',
      direccion: 'CARACOLES MZ 65 L5',
      pendiente: '',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-6',
      fecha: DateTime(2026, 3, 30),
      hora: '12:00',
      pacienteNombre: 'JUAN DAVID FERIA PERTUZ',
      pacienteDocumento: '1007154767',
      tratamiento: 'PARACETAMOL 2 GR IV CADA 24 HORAS',
      dx: 'FRACTURA SUPRA E INTERCONDÍLEA DE HÚMERO DERECHO',
      contacto1: '3043835121',
      contacto2: '3024683411',
      direccion: 'SAN FERNANDO SECTOR NUEVA JERUSALÉN',
      pendiente: '',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-7',
      fecha: DateTime(2026, 3, 30),
      hora: '13:00',
      pacienteNombre: 'JHORDAN JESITH MELENDEZ ALCALA',
      pacienteDocumento: '1050038030',
      tratamiento: 'DIPIRONA 1 GR IV CADA 12 HR + PARACETAMOL 1 GR IV CADA 12 HR',
      dx: 'S923 - FRACTURA DE HUESO DEL METATARSO',
      contacto1: '3206700469',
      contacto2: '3212948616',
      direccion: 'TURBACO CALLE 4',
      pendiente: 'LABORATORIOS CONTROL',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-8',
      fecha: DateTime(2026, 3, 30),
      hora: '14:00',
      pacienteNombre: 'AUGUSTO PUELLO ACUÑA',
      pacienteDocumento: '9281001',
      tratamiento: 'ERTAPENEM 1 GR IV CADA 24 HORAS + INSULINA GLARGINA',
      dx: 'N390 - INFECCIÓN DE VÍAS URINARIAS + DIABETES',
      contacto1: '3148394354',
      contacto2: '3243173597',
      direccion: 'TURBACO BARRIO LAS COCAS',
      pendiente: 'LABORATORIOS CONTROL',
      personalAsignadoId: '1',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-9',
      fecha: DateTime(2026, 3, 30),
      hora: '14:00',
      pacienteNombre: 'GLORIA CRISTINA VARGAS DE ROJANO',
      pacienteDocumento: '30769875',
      tratamiento: 'PARACETAMOL 1 GR IV CADA 8 HORAS',
      dx: 'CELULITIS MIEMBRO INFERIOR IZQUIERDO',
      contacto1: '3245304998',
      contacto2: '3245897047',
      direccion: 'BARRIO BOSTON CRR 46 N° 31D - 32',
      pendiente: '',
      personalAsignadoId: '2',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-10',
      fecha: DateTime(2026, 3, 30),
      hora: '15:00',
      pacienteNombre: 'JOSE MIGUEL AVENDAÑO MONTERO',
      pacienteDocumento: '73082847',
      tratamiento: 'PARACETAMOL 1 GR IV CADA 12 HR + TRAMAL 50 MG',
      dx: 'S424 - FRACTURA DE LA EPÍFISIS INFERIOR DEL HÚMERO',
      contacto1: '3122194537',
      contacto2: '',
      direccion: 'EL EDUCADOR SECTOR BUENOS AIRES',
      pendiente: '',
      personalAsignadoId: '2',
      observaciones: '',
      estado: 'programada',
    ),
    AgendaVisita(
      id: 'ag-11',
      fecha: DateTime(2026, 3, 30),
      hora: '16:00',
      pacienteNombre: 'CARLOS ANDRES BATISTA ALTAMAR',
      pacienteDocumento: '1123627705',
      tratamiento: 'CURACIÓN POR CLÍNICA DE HERIDA + PARACETAMOL CADA 12 HORAS',
      dx: 'S624 - FRACTURAS MÚLTIPLES DE HUESOS METACARPIANOS',
      contacto1: '3014250913',
      contacto2: '',
      direccion: '',
      pendiente: '',
      personalAsignadoId: '2',
      observaciones: '',
      estado: 'programada',
    ),
  ];

  @override
  List<AgendaVisita> get items {
    final List<AgendaVisita> sorted = List<AgendaVisita>.from(_items)
      ..sort((AgendaVisita a, AgendaVisita b) {
        final int byDate = DateUtils.dateOnly(a.fecha)
            .compareTo(DateUtils.dateOnly(b.fecha));
        if (byDate != 0) return byDate;

        final int byHour = a.hora.compareTo(b.hora);
        if (byHour != 0) return byHour;

        return a.pacienteNombre.toLowerCase().compareTo(
              b.pacienteNombre.toLowerCase(),
            );
      });

    return UnmodifiableListView<AgendaVisita>(sorted);
  }

  @override
  Future<void> load() async {
    notifyListeners();
  }

  @override
  List<AgendaVisita> itemsByDate(DateTime date) {
    final DateTime target = DateUtils.dateOnly(date);
    return items.where((AgendaVisita item) {
      return DateUtils.dateOnly(item.fecha) == target;
    }).toList();
  }

  @override
  AgendaVisita? findById(String id) {
    try {
      return _items.firstWhere((AgendaVisita e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addVisita(AgendaVisita visita) async {
    _items.add(visita);
    notifyListeners();
  }

  @override
  Future<void> updateVisita(AgendaVisita visita) async {
    final int index = _items.indexWhere((AgendaVisita e) => e.id == visita.id);
    if (index == -1) return;

    _items[index] = visita;
    notifyListeners();
  }

  @override
  Future<void> deleteVisita(String id) async {
    _items.removeWhere((AgendaVisita e) => e.id == id);
    notifyListeners();
  }
}
