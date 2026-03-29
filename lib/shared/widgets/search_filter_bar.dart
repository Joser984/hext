import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onOpenFilters;
  final List<Widget>? activeFilters;
  final List<Widget>? actions;

  const SearchFilterBar({super.key, this.searchHint, this.onSearchChanged, this.onOpenFilters, this.activeFilters, this.actions});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged ?? (String _) {},
                    decoration: InputDecoration(
                      hintText: searchHint ?? 'Buscar...',
                      prefixIcon: const Icon(Icons.search, size: 22),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.tune, size: 22),
                  tooltip: 'Filtros',
                  onPressed: onOpenFilters,
                  color: const Color(0xFF1C2228),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            if (activeFilters != null && activeFilters!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: activeFilters!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
