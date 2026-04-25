import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hext/core/models/auxiliar_domiciliario.dart';
import 'package:hext/core/models/novedad_laboral.dart';
import 'package:hext/core/repositories/in_memory_novedades_repo.dart';
import 'package:hext/core/repositories/in_memory_personal_repo.dart';
import 'package:hext/shared/widgets/agenda_subnav.dart';
import 'package:hext/shared/widgets/app_chip.dart';
import 'package:hext/shared/widgets/module_header.dart';

// Convierte un string a 'Title Case' (iniciales en mayúscula)
String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .toLowerCase()
      .split(' ')
      .map(
        (word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
      )
      .join(' ');
}

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InMemoryPersonalRepo repo = context.watch<InMemoryPersonalRepo>();
    final InMemoryNovedadesRepo novedadesRepo =
        context.watch<InMemoryNovedadesRepo>();
    final List<AuxiliarDomiciliario> items = repo.items;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontalPadding =
              constraints.maxWidth >= 900 ? 16 : 12;
          final double topScrollOffset = constraints.maxWidth >= 900 ? 8 : 6;

          return Padding(
            padding: EdgeInsets.only(top: topScrollOffset),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const ModuleHeader(
                    title: 'Personal',
                    subtitle:
                        'Gestión de auxiliares, novedades laborales y estado operativo.',
                  ),
                  const SizedBox(height: 10),
                  _SubnavWithAction(onAdd: () => _openForm(context)),
                  const SizedBox(height: 12),
                  _HeaderSummary(items: items),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _EmptyState(onAdd: () => _openForm(context))
                  else
                    Column(
                      children: items
                          .map(
                            (AuxiliarDomiciliario item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AuxiliarCard(
                                auxiliar: item,
                                novedadesActivas:
                                    novedadesRepo.activeForAuxiliar(item.id),
                                alertaVacaciones:
                                    novedadesRepo.vacacionesVencidas(
                                  auxiliarId: item.id,
                                  fechaIngreso: item.fechaIngreso,
                                ),
                                onEdit: () =>
                                    _openForm(context, auxiliar: item),
                                onDelete: () => _confirmDelete(context, item),
                                onToggleActivo: (bool value) {
                                  context
                                      .read<InMemoryPersonalRepo>()
                                      .toggleActivo(item.id, value);
                                },
                                onGestionarNovedades: () =>
                                    _openNovedades(context, item),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    AuxiliarDomiciliario? auxiliar,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AuxiliarFormDialog(auxiliar: auxiliar),
    );
  }

  Future<void> _openNovedades(
    BuildContext context,
    AuxiliarDomiciliario auxiliar,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _NovedadesDialog(auxiliar: auxiliar),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AuxiliarDomiciliario auxiliar,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar auxiliar'),
          content: Text('¿Deseas eliminar a ${auxiliar.nombreCompleto}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok == true && context.mounted) {
      await context.read<InMemoryPersonalRepo>().deleteAuxiliar(auxiliar.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Auxiliar eliminado')));
      }
    }
  }
}

class _HeaderSummary extends StatelessWidget {
  final List<AuxiliarDomiciliario> items;

  const _HeaderSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final int activos = items.where((e) => e.activo).length;
    final int inactivos = items.where((e) => !e.activo).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text(
            'Resumen del módulo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          AppChip(label: 'Total: ${items.length}', tone: AppChipTone.info),
          AppChip(label: 'Activos: $activos', tone: AppChipTone.success),
          AppChip(label: 'Inactivos: $inactivos', tone: AppChipTone.neutral),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E7EC)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.groups_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              'Aún no hay personal registrado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea el primer auxiliar para comenzar a gestionar el personal desde Agenda.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar personal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuxiliarCard extends StatelessWidget {
  final AuxiliarDomiciliario auxiliar;
  final List<NovedadLaboral> novedadesActivas;
  final bool alertaVacaciones;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActivo;
  final VoidCallback onGestionarNovedades;

  const _AuxiliarCard({
    required this.auxiliar,
    required this.novedadesActivas,
    required this.alertaVacaciones,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActivo,
    required this.onGestionarNovedades,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle secondaryStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: const Color(0xFF8A9199),
      fontSize: 12.5,
    );

    final List<Widget> alertWidgets = <Widget>[
      if (novedadesActivas.isNotEmpty) ..._buildNovedadesPreview(context),
      if (alertaVacaciones)
        const _AlertaBadge(text: 'Vacaciones pendientes por programar'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x08000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool narrow = constraints.maxWidth < 760;

            final Widget leftContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  auxiliar.nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF243247),
                  ),
                ),
                if (alertWidgets.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: alertWidgets),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    AppChip(
                      label: auxiliar.cargo,
                      tone: AppChipTone.neutral,
                      leadingDot: true,
                    ),
                    AppChip(
                      label: auxiliar.modalidad,
                      tone: AppChipTone.neutral,
                      leadingDot: true,
                    ),
                  ],
                ),
                if (auxiliar.fechaIngreso != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Ingreso: ${_formatDate(auxiliar.fechaIngreso!)}',
                    style: secondaryStyle,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _CardActionLink(
                      icon: Icons.edit_outlined,
                      label: 'Editar',
                      color: const Color(0xFF17726D),
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 14),
                    _CardActionLink(
                      icon: Icons.delete_outline_rounded,
                      label: 'Eliminar',
                      color: const Color(0xFFB42318),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            );

            final Widget controlColumn = SizedBox(
              width: narrow ? double.infinity : 108,
              child: narrow
                  ? Row(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              auxiliar.activo ? 'Activo' : 'Inactivo',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                color: const Color(0xFF5C6370),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Switch.adaptive(
                              value: auxiliar.activo,
                              onChanged: onToggleActivo,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Badge(
                          isLabelVisible: novedadesActivas.isNotEmpty,
                          label: Text('${novedadesActivas.length}'),
                          child: InkWell(
                            onTap: onGestionarNovedades,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE3EAF0),
                                ),
                              ),
                              child: const Icon(
                                Icons.event_note_outlined,
                                size: 20,
                                color: Color(0xFF5F6B7A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          auxiliar.activo ? 'Activo' : 'Inactivo',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                            color: const Color(0xFF5C6370),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Transform.scale(
                          scale: 0.9,
                          alignment: Alignment.centerRight,
                          child: Switch.adaptive(
                            value: auxiliar.activo,
                            onChanged: onToggleActivo,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Badge(
                          isLabelVisible: novedadesActivas.isNotEmpty,
                          label: Text('${novedadesActivas.length}'),
                          child: InkWell(
                            onTap: onGestionarNovedades,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE3EAF0),
                                ),
                              ),
                              child: const Icon(
                                Icons.event_note_outlined,
                                size: 20,
                                color: Color(0xFF5F6B7A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  leftContent,
                  const SizedBox(height: 12),
                  controlColumn,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: leftContent),
                const SizedBox(width: 14),
                controlColumn,
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildNovedadesPreview(BuildContext context) {
    if (novedadesActivas.length <= 2) {
      return novedadesActivas
          .map((NovedadLaboral n) => _NovedadBadge(novedad: n))
          .toList();
    }

    return <Widget>[
      _NovedadBadge(novedad: novedadesActivas.first),
      _NovedadBadge(novedad: novedadesActivas[1]),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE3E7EC)),
        ),
        child: Text(
          '+${novedadesActivas.length - 2} más',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: const Color(0xFF5C6370)),
        ),
      ),
    ];
  }

  static String _formatDate(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

class _CardActionLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CardActionLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovedadBadge extends StatelessWidget {
  final NovedadLaboral novedad;

  const _NovedadBadge({required this.novedad});

  static const Map<EstadoNovedad, Color> _bg = <EstadoNovedad, Color>{
    EstadoNovedad.pendiente: Color(0xFFFFF3E0),
    EstadoNovedad.programado: Color(0xFFE3F2FD),
    EstadoNovedad.disfrutado: Color(0xFFE8F5E9),
    EstadoNovedad.vencido: Color(0xFFFCE4EC),
  };

  static const Map<EstadoNovedad, Color> _fg = <EstadoNovedad, Color>{
    EstadoNovedad.pendiente: Color(0xFFE65100),
    EstadoNovedad.programado: Color(0xFF1565C0),
    EstadoNovedad.disfrutado: Color(0xFF2E7D32),
    EstadoNovedad.vencido: Color(0xFFB71C1C),
  };

  @override
  Widget build(BuildContext context) {
    final Color bg = _bg[novedad.estado] ?? const Color(0xFFF7F8FA);
    final Color fg = _fg[novedad.estado] ?? const Color(0xFF5C6370);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.40)),
      ),
      child: Text(
        '${novedad.estado.label} · ${novedad.tipo.label}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AlertaBadge extends StatelessWidget {
  final String text;

  const _AlertaBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 13,
            color: Color(0xFFB71C1C),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB71C1C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuxiliarFormDialog extends StatefulWidget {
  final AuxiliarDomiciliario? auxiliar;

  const _AuxiliarFormDialog({this.auxiliar});

  @override
  State<_AuxiliarFormDialog> createState() => _AuxiliarFormDialogState();
}

class _AuxiliarFormDialogState extends State<_AuxiliarFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late String _cargo;
  late String _modalidad;
  DateTime? _fechaIngreso;
  late bool _activo;

  static const List<String> _cargos = <String>[
    'Auxiliar domiciliario',
    'Auxiliar de enfermería',
    'Cuidador',
    'Terapeuta',
  ];

  static const List<String> _modalidades = <String>[
    'Tiempo completo',
    'Medio tiempo',
    'Prestación de servicios',
    'Por evento',
  ];

  bool get isEdit => widget.auxiliar != null;

  @override
  void initState() {
    super.initState();
    final AuxiliarDomiciliario? item = widget.auxiliar;

    _nombreController = TextEditingController(text: item?.nombreCompleto ?? '');
    _cargo = item?.cargo ?? _cargos.first;
    _modalidad = item?.modalidad ?? _modalidades.first;
    _fechaIngreso = item?.fechaIngreso;
    _activo = item?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      title: Text(isEdit ? 'Editar auxiliar' : 'Nuevo auxiliar'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _formFieldDecoration('Nombre completo'),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _cargo,
                  decoration: _formFieldDecoration('Cargo'),
                  items: _cargos
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _cargo = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _modalidad,
                  decoration: _formFieldDecoration('Modalidad'),
                  items: _modalidades
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _modalidad = value);
                  },
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Fecha de ingreso',
                  value: _fechaIngreso,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaIngreso ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _fechaIngreso = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _activo,
                  onChanged: (bool value) {
                    setState(() => _activo = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEdit ? 'Guardar cambios' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final InMemoryPersonalRepo repo = context.read<InMemoryPersonalRepo>();
    final String nombreFormateado = toTitleCase(_nombreController.text.trim());

    if (isEdit) {
      final AuxiliarDomiciliario updated = AuxiliarDomiciliario(
        id: widget.auxiliar!.id,
        nombreCompleto: nombreFormateado,
        cargo: _cargo,
        modalidad: _modalidad,
        fechaIngreso: _fechaIngreso,
        activo: _activo,
      );

      await repo.updateAuxiliar(updated);
    } else {
      final AuxiliarDomiciliario created = AuxiliarDomiciliario(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nombreCompleto: nombreFormateado,
        cargo: _cargo,
        modalidad: _modalidad,
        fechaIngreso: _fechaIngreso,
        activo: _activo,
      );

      await repo.addAuxiliar(created);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit ? 'Auxiliar actualizado' : 'Auxiliar creado'),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  static String _fmt(DateTime d) {
    final String dd = d.day.toString().padLeft(2, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: _formFieldDecoration(
          label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value != null ? _fmt(value!) : 'No especificada',
          style: value == null
              ? Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB0B7BF))
              : null,
        ),
      ),
    );
  }
}

InputDecoration _formFieldDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    suffixIcon: suffixIcon,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF7F9FC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF17726D), width: 1.4),
    ),
  );
}

// ─── Gestión de novedades laborales ───────────────────────────────────────────

class _NovedadesDialog extends StatelessWidget {
  final AuxiliarDomiciliario auxiliar;

  const _NovedadesDialog({required this.auxiliar});

  @override
  Widget build(BuildContext context) {
    final InMemoryNovedadesRepo repo = context.watch<InMemoryNovedadesRepo>();
    final List<NovedadLaboral> novedades = repo.forAuxiliar(auxiliar.id);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.event_note_outlined, size: 24),
          const SizedBox(height: 6),
          const Text('Novedades laborales'),
          Text(
            auxiliar.nombreCompleto,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8A9199)),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: novedades.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin novedades registradas.'),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: novedades.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (BuildContext context, int index) {
                  final NovedadLaboral nov = novedades[index];
                  return _NovedadTile(
                    novedad: nov,
                    onMarcarDisfrutado:
                        (nov.estado == EstadoNovedad.pendiente ||
                                nov.estado == EstadoNovedad.programado)
                            ? () => context
                                  .read<InMemoryNovedadesRepo>()
                                  .marcarDisfrutado(nov.id)
                            : null,
                    onDelete: () =>
                        context.read<InMemoryNovedadesRepo>().delete(nov.id),
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await showDialog<void>(
              context: context,
              builder: (_) => _AddNovedadDialog(auxiliarId: auxiliar.id),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _NovedadTile extends StatelessWidget {
  final NovedadLaboral novedad;
  final VoidCallback? onMarcarDisfrutado;
  final VoidCallback onDelete;

  const _NovedadTile({
    required this.novedad,
    required this.onMarcarDisfrutado,
    required this.onDelete,
  });

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle secondary =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: const Color(0xFF8A9199),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        novedad.tipo.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _EstadoChip(estado: novedad.estado),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Causación: ${_fmt(novedad.fechaCausacion)}',
                  style: secondary,
                ),
                if (novedad.fechaInicio != null && novedad.fechaFin != null)
                  Text(
                    'Período: ${_fmt(novedad.fechaInicio!)} – ${_fmt(novedad.fechaFin!)}',
                    style: secondary,
                  ),
                if (novedad.fechaLimiteDisfrute != null)
                  Text(
                    'Límite: ${_fmt(novedad.fechaLimiteDisfrute!)}',
                    style: secondary,
                  ),
                if (novedad.observaciones != null)
                  Text(novedad.observaciones!, style: secondary),
              ],
            ),
          ),
          if (onMarcarDisfrutado != null)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Marcar como disfrutado',
              iconSize: 20,
              onPressed: onMarcarDisfrutado,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            iconSize: 20,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final EstadoNovedad estado;

  const _EstadoChip({required this.estado});

  static const Map<EstadoNovedad, Color> _bg = <EstadoNovedad, Color>{
    EstadoNovedad.pendiente: Color(0xFFFFF3E0),
    EstadoNovedad.programado: Color(0xFFE3F2FD),
    EstadoNovedad.disfrutado: Color(0xFFE8F5E9),
    EstadoNovedad.vencido: Color(0xFFFCE4EC),
  };

  static const Map<EstadoNovedad, Color> _fg = <EstadoNovedad, Color>{
    EstadoNovedad.pendiente: Color(0xFFE65100),
    EstadoNovedad.programado: Color(0xFF1565C0),
    EstadoNovedad.disfrutado: Color(0xFF2E7D32),
    EstadoNovedad.vencido: Color(0xFFB71C1C),
  };

  @override
  Widget build(BuildContext context) {
    final Color bg = _bg[estado] ?? const Color(0xFFF7F8FA);
    final Color fg = _fg[estado] ?? const Color(0xFF5C6370);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.40)),
      ),
      child: Text(
        estado.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddNovedadDialog extends StatefulWidget {
  final String auxiliarId;

  const _AddNovedadDialog({required this.auxiliarId});

  @override
  State<_AddNovedadDialog> createState() => _AddNovedadDialogState();
}

class _AddNovedadDialogState extends State<_AddNovedadDialog> {
  TipoNovedad _tipo = TipoNovedad.vacaciones;
  DateTime _fechaCausacion = DateTime.now();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _obsController = TextEditingController();

  DateTime? get _autoFechaLimite {
    final int? dias = _tipo.diasLimiteDisfrute;
    if (dias == null) return null;
    return _fechaCausacion.add(Duration(days: dias));
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      title: const Text('Nueva novedad'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<TipoNovedad>(
                initialValue: _tipo,
                decoration: _formFieldDecoration('Tipo de novedad'),
                items: TipoNovedad.values
                    .map(
                      (TipoNovedad t) => DropdownMenuItem<TipoNovedad>(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (TipoNovedad? v) {
                  if (v == null) return;
                  setState(() {
                    _tipo = v;
                    _fechaInicio = null;
                    _fechaFin = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              _DatePickerField(
                label: 'Fecha causación',
                value: _fechaCausacion,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaCausacion,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _fechaCausacion = picked);
                  }
                },
              ),
              if (_tipo.tienePeriodo) ...<Widget>[
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Fecha inicio disfrute',
                  value: _fechaInicio,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaInicio ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _fechaInicio = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Fecha fin disfrute',
                  value: _fechaFin,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _fechaFin ?? (_fechaInicio ?? DateTime.now()),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _fechaFin = picked);
                    }
                  },
                ),
              ],
              if (_autoFechaLimite != null) ...<Widget>[
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: _formFieldDecoration(
                    'Límite de disfrute (automático)',
                  ),
                  child: Text(_DatePickerField._fmt(_autoFechaLimite!)),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _obsController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: _formFieldDecoration('Observaciones (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Registrar')),
      ],
    );
  }

  Future<void> _save() async {
    final InMemoryNovedadesRepo repo = context.read<InMemoryNovedadesRepo>();

    final NovedadLaboral novedad = NovedadLaboral(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      auxiliarId: widget.auxiliarId,
      tipo: _tipo,
      fechaCausacion: _fechaCausacion,
      fechaLimiteDisfrute: _autoFechaLimite,
      fechaInicio: _tipo.tienePeriodo ? _fechaInicio : null,
      fechaFin: _tipo.tienePeriodo ? _fechaFin : null,
      estado: EstadoNovedad.pendiente,
      observaciones: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
    );

    await repo.add(novedad);

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _SubnavWithAction extends StatelessWidget {
  const _SubnavWithAction({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget actionButton = SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF17726D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar personal'),
          ),
        );

        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AgendaSubnav(section: AgendaSubnavSection.auxiliares),
              const SizedBox(height: 10),
              actionButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Expanded(
              child: AgendaSubnav(section: AgendaSubnavSection.auxiliares),
            ),
            const SizedBox(width: 12),
            actionButton,
          ],
        );
      },
    );
  }
}