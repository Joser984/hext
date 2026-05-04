import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

enum AgendaSubnavSection { visitas, horarios, auxiliares }

class AgendaSubnav extends StatelessWidget {
  const AgendaSubnav({
    super.key,
    required this.section,
  });

  final AgendaSubnavSection section;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _NavButton(
          label: 'Visitas',
          icon: Icons.calendar_today_outlined,
          selected: section == AgendaSubnavSection.visitas,
          onTap: () => context.go('/schedule/visitas'),
        ),
        _NavButton(
          label: 'Horarios',
          icon: Icons.schedule_outlined,
          selected: section == AgendaSubnavSection.horarios,
          onTap: () => context.go('/schedule/horarios'),
        ),
        _NavButton(
          label: 'Auxiliares',
          icon: Icons.people_outline,
          selected: section == AgendaSubnavSection.auxiliares,
          onTap: () => context.go('/schedule/auxiliares'),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 17,
          color: selected ? Colors.white : const Color(0xFF243247),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF243247),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF17726D)
              : const Color(0xFFF1F3F5),
          overlayColor: HextColors.primarySoft,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: content,
      ),
    );
  }
}
