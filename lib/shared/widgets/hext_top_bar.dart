import 'package:flutter/material.dart';

class HextTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const HextTopBar({required this.title, this.actions, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
          letterSpacing: 0.5,
        ),
      ),
      actions: actions,
      toolbarHeight: 48,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFD9E2E7)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(49);
}
