import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/repositories/ops_firestore_repo.dart';
import 'package:hext/shared/widgets/app_chip.dart';
import 'package:hext/shared/widgets/filter_shell.dart';
import 'package:hext/shared/widgets/light_dropdown.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:hext/shared/widgets/module_header.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final OpsFirestoreRepo _opsRepo = OpsFirestoreRepo();
  StreamSubscription<List<OpsPendingRecord>>? _pendingSubscription;

  String _tipoFiltro = 'Todos';
  String _estadoFiltro = 'Todos';
  List<_PendingItemVm> _items = <_PendingItemVm>[];

  @override
  void initState() {
    super.initState();
    _pendingSubscription = _opsRepo.watchPendings().listen((
      List<OpsPendingRecord> records,
    ) {
      if (!mounted) return;
      final Map<String, _PendingItemVm> existing = <String, _PendingItemVm>{
        for (final _PendingItemVm i in _items) i.id: i,
      };
      setState(() {
        _items = records.map((OpsPendingRecord record) {
          return _PendingItemVm.fromRecord(
            record: record,
            existing: existing[record.id],
          );
        }).toList();
      });
    });
  }

  List<_PendingItemVm> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();
    return _items.where((_PendingItemVm item) {
      final bool matchesQuery =
          query.isEmpty ||
          item.paciente.toLowerCase().contains(query) ||
          item.tipo.toLowerCase().contains(query) ||
          item.detalle.toLowerCase().contains(query) ||
          item.responsable.toLowerCase().contains(query);
      final bool matchesTipo =
          _tipoFiltro == 'Todos' || item.tipo == _tipoFiltro;
      final bool matchesEstado =
          _estadoFiltro == 'Todos' || _statusFor(item).label == _estadoFiltro;
      return matchesQuery && matchesTipo && matchesEstado;
    }).toList();
  }

  List<String> get _tipos {
    final Set<String> values = _items.map((_PendingItemVm e) => e.tipo).toSet();
    final List<String> sorted = values.toList()..sort();
    return <String>['Todos', ...sorted];
  }

  List<String> get _estados => <String>[
    'Todos',
    _PendingFlowStatus.pendiente.label,
    _PendingFlowStatus.enGestion.label,
    _PendingFlowStatus.vencido.label,
    _PendingFlowStatus.resuelto.label,
  ];

  _PendingFlowStatus _statusFor(_PendingItemVm item) {
    if (item.estadoManual == _PendingFlowStatus.resuelto) {
      return _PendingFlowStatus.resuelto;
    }
    if (item.vencimiento.isBefore(DateTime.now())) {
      return _PendingFlowStatus.vencido;
    }
    return item.estadoManual;
  }

  Future<void> _openReassignDialog(_PendingItemVm item) async {
    const List<String> responsables = <String>[
      'Luis Orozco',
      'Katerine Cabarcas',
      'Nataly Vergara',
    ];

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: responsables
                .map(
                  (String nombre) => ListTile(
                    title: Text(nombre),
                    trailing: item.responsable == nombre
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(context).pop(nombre),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      item.responsable = selected;
      if (item.estadoManual != _PendingFlowStatus.resuelto) {
        item.estadoManual = _PendingFlowStatus.enGestion;
      }
    });
  }

  Future<void> _resolveItem(_PendingItemVm item) async {
    setState(() {
      item.estadoManual = _PendingFlowStatus.resuelto;
    });
    await _opsRepo.updatePending(id: item.id, status: 'resuelto');
  }

  Future<void> _postponeItem(_PendingItemVm item) async {
    setState(() {
      item.vencimiento = item.vencimiento.add(const Duration(days: 1));
      if (item.estadoManual != _PendingFlowStatus.resuelto) {
        item.estadoManual = _PendingFlowStatus.pendiente;
      }
    });
    await _opsRepo.updatePending(
      id: item.id,
      dueAt: item.vencimiento,
      status: item.estadoManual.firestoreKey,
    );
  }

  Future<void> _markInProgress(_PendingItemVm item) async {
    if (item.estadoManual == _PendingFlowStatus.resuelto) return;
    setState(() {
      item.estadoManual = _PendingFlowStatus.enGestion;
    });
    await _opsRepo.updatePending(id: item.id, status: 'en_gestion');
  }

  void _openContext(_PendingItemVm item) {
    final String? itemId =
        (item.visitId != null && item.visitId!.trim().isNotEmpty)
        ? item.visitId
        : item.pendingId;
    final String route = Uri(
      path: item.rutaContexto,
      queryParameters: <String, String>{
        'source': 'pending',
        if (itemId != null && itemId.trim().isNotEmpty) 'itemId': itemId,
        if (item.visitId != null && item.visitId!.trim().isNotEmpty)
          'visitId': item.visitId!,
        if (item.patientId != null && item.patientId!.trim().isNotEmpty)
          'patientId': item.patientId!,
        if (item.pendingId != null && item.pendingId!.trim().isNotEmpty)
          'pendingId': item.pendingId!,
      },
    ).toString();
    context.go(route);
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_PendingItemVm> items = _filteredItems;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontalPadding = constraints.maxWidth >= 900
              ? 16
              : 12;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ModuleHeader(
                  title: 'Pendientes operativos',
                  subtitle:
                      'Control de pendientes por tipo, vencimiento y estado de gestion.',
                ),
                const SizedBox(height: 12),
                FilterShell(
                  title: 'Filtros',
                  subtitle: 'Enfoca la atencion en lo urgente y accionable.',
                  fields: Builder(
                    builder: (BuildContext context) {
                      final double maxWidth = constraints.maxWidth;
                      final double searchWidth = maxWidth >= 1280
                          ? 320
                          : maxWidth >= 900
                          ? 280
                          : maxWidth;
                      final double fieldWidth = maxWidth >= 1280
                          ? 185
                          : maxWidth >= 900
                          ? (maxWidth - 12) / 2
                          : maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          SizedBox(
                            width: searchWidth,
                            child: LightInput(
                              label: 'Buscar',
                              hint: 'Buscar paciente, tipo o detalle',
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: LightDropdown<String>(
                              label: 'Tipo',
                              value: _tipoFiltro,
                              items: _tipos
                                  .map(
                                    (String item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (String? value) {
                                if (value == null) return;
                                setState(() => _tipoFiltro = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: LightDropdown<String>(
                              label: 'Estado',
                              value: _estadoFiltro,
                              items: _estados
                                  .map(
                                    (String item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (String? value) {
                                if (value == null) return;
                                setState(() => _estadoFiltro = value);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  actions: Row(
                    children: <Widget>[
                      AppChip(
                        label: 'Total visibles: ${items.length}',
                        tone: AppChipTone.info,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _tipoFiltro = 'Todos';
                              _estadoFiltro = 'Todos';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD7DCE3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          icon: const Icon(
                            Icons.restart_alt_rounded,
                            size: 18,
                            color: Color(0xFF5B6474),
                          ),
                          label: const Text(
                            'Limpiar filtros',
                            style: TextStyle(color: Color(0xFF5B6474)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _PendingEmptyState(
                    onClear: () {
                      setState(() {
                        _searchController.clear();
                        _tipoFiltro = 'Todos';
                        _estadoFiltro = 'Todos';
                      });
                    },
                  )
                else
                  Column(
                    children: items
                        .map(
                          (_PendingItemVm item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PendingCompactCard(
                              item: item,
                              status: _statusFor(item),
                              onOpenContext: () => _openContext(item),
                              onPostpone: () => _postponeItem(item),
                              onResolve: () => _resolveItem(item),
                              onReassign: () => _openReassignDialog(item),
                              onStart: () => _markInProgress(item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingCompactCard extends StatelessWidget {
  const _PendingCompactCard({
    required this.item,
    required this.status,
    required this.onOpenContext,
    required this.onPostpone,
    required this.onResolve,
    required this.onReassign,
    required this.onStart,
  });

  final _PendingItemVm item;
  final _PendingFlowStatus status;
  final VoidCallback onOpenContext;
  final VoidCallback onPostpone;
  final VoidCallback onResolve;
  final VoidCallback onReassign;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppChip(label: item.tipo, tone: AppChipTone.neutral),
              AppChip(
                label: _deadlineLabel(item.vencimiento),
                tone: _deadlineTone(item.vencimiento, status),
              ),
              AppChip(label: status.label, tone: _statusTone(status)),
              AppChip(
                label: 'Contexto: ${item.contextoLabel}',
                tone: AppChipTone.info,
              ),
              AppChip(
                label: 'Resp: ${item.responsable}',
                tone: AppChipTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.paciente,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.detalle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5B6474)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onOpenContext,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD7DCE3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: Color(0xFF5B6474),
                    ),
                    label: Text(
                      'Abrir ${item.contextoLabel}',
                      style: const TextStyle(
                        color: Color(0xFF5B6474),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: status == _PendingFlowStatus.resuelto
                        ? null
                        : onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF17726D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Iniciar'),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Mas acciones',
                  onSelected: (String value) {
                    switch (value) {
                      case 'postpone':
                        onPostpone();
                        return;
                      case 'resolve':
                        onResolve();
                        return;
                      case 'reassign':
                        onReassign();
                        return;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'postpone',
                          child: Text('Posponer 1 dia'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'reassign',
                          child: Text('Reasignar responsable'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'resolve',
                          child: Text('Marcar como resuelto'),
                        ),
                      ],
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD7DCE3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Color(0xFF5B6474),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Acciones',
                          style: TextStyle(
                            color: Color(0xFF5B6474),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingEmptyState extends StatelessWidget {
  const _PendingEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.inbox_outlined, size: 42, color: Color(0xFF8A9BB0)),
          const SizedBox(height: 10),
          const Text(
            'No hay pendientes para los filtros actuales',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajusta tipo, estado o busqueda para recuperar items operativos.',
            style: TextStyle(fontSize: 13, color: Color(0xFF5B6474)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: FilledButton.icon(
              onPressed: onClear,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF17726D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Restablecer filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingItemVm {
  _PendingItemVm({
    required this.id,
    required this.tipo,
    required this.paciente,
    required this.vencimiento,
    required this.detalle,
    required this.rutaContexto,
    required this.contextoLabel,
    this.visitId,
    this.patientId,
    this.pendingId,
    required this.estadoManual,
    required this.responsable,
  });

  final String id;
  final String tipo;
  final String paciente;
  DateTime vencimiento;
  final String detalle;
  final String rutaContexto;
  final String contextoLabel;
  final String? visitId;
  final String? patientId;
  final String? pendingId;
  _PendingFlowStatus estadoManual;
  String responsable;

  factory _PendingItemVm.fromRecord({
    required OpsPendingRecord record,
    _PendingItemVm? existing,
  }) {
    return _PendingItemVm(
      id: record.id,
      tipo: record.tipo,
      paciente: record.paciente,
      vencimiento: record.vencimiento,
      detalle: record.detalle,
      rutaContexto: record.rutaContexto,
      contextoLabel: record.contextoLabel,
      visitId: record.visitId,
      patientId: record.patientId,
      pendingId: record.pendingId,
      estadoManual:
          _PendingFlowStatusX.fromFirestore(record.status) ??
          existing?.estadoManual ??
          _PendingFlowStatus.pendiente,
      responsable: (record.responsable?.trim().isNotEmpty ?? false)
          ? record.responsable!.trim()
          : (existing?.responsable ?? 'Sin asignar'),
    );
  }
}

AppChipTone _statusTone(_PendingFlowStatus status) {
  switch (status) {
    case _PendingFlowStatus.pendiente:
      return AppChipTone.warning;
    case _PendingFlowStatus.enGestion:
      return AppChipTone.info;
    case _PendingFlowStatus.vencido:
      return AppChipTone.danger;
    case _PendingFlowStatus.resuelto:
      return AppChipTone.success;
  }
}

AppChipTone _deadlineTone(DateTime dueAt, _PendingFlowStatus status) {
  if (status == _PendingFlowStatus.resuelto) {
    return AppChipTone.success;
  }
  return dueAt.isBefore(DateTime.now())
      ? AppChipTone.danger
      : AppChipTone.warning;
}

String _deadlineLabel(DateTime dueAt) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime tomorrow = today.add(const Duration(days: 1));
  final DateTime dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);

  final String hh = dueAt.hour.toString().padLeft(2, '0');
  final String mm = dueAt.minute.toString().padLeft(2, '0');

  if (dueDate == today) {
    return 'Hoy $hh:$mm';
  }
  if (dueDate == tomorrow) {
    return 'Manana $hh:$mm';
  }
  return '${dueAt.day.toString().padLeft(2, '0')}/'
      '${dueAt.month.toString().padLeft(2, '0')} $hh:$mm';
}

enum _PendingFlowStatus { pendiente, enGestion, vencido, resuelto }

extension _PendingFlowStatusX on _PendingFlowStatus {
  String get label {
    switch (this) {
      case _PendingFlowStatus.pendiente:
        return 'Pendiente';
      case _PendingFlowStatus.enGestion:
        return 'En gestion';
      case _PendingFlowStatus.vencido:
        return 'Vencido';
      case _PendingFlowStatus.resuelto:
        return 'Resuelto';
    }
  }

  String get firestoreKey {
    switch (this) {
      case _PendingFlowStatus.pendiente:
        return 'pendiente';
      case _PendingFlowStatus.enGestion:
        return 'en_gestion';
      case _PendingFlowStatus.vencido:
        return 'vencido';
      case _PendingFlowStatus.resuelto:
        return 'resuelto';
    }
  }

  static _PendingFlowStatus? fromFirestore(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'pendiente':
        return _PendingFlowStatus.pendiente;
      case 'en_gestion':
      case 'en gestion':
        return _PendingFlowStatus.enGestion;
      case 'vencido':
        return _PendingFlowStatus.vencido;
      case 'resuelto':
        return _PendingFlowStatus.resuelto;
      default:
        return null;
    }
  }
}
