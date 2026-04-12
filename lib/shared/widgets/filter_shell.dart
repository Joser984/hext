import 'package:flutter/material.dart';

class FilterShell extends StatelessWidget {
  const FilterShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Widget fields;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCED7E1)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140D253F),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF7B8794)),
          ),
          const SizedBox(height: 14),
          fields,
          if (actions != null) ...<Widget>[
            const SizedBox(height: 14),
            actions!,
          ],
        ],
      ),
    );
  }
}
