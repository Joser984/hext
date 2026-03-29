
import 'package:flutter/material.dart';
import 'field_shell.dart';

class LightDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const LightDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<LightDropdown<T>> createState() => _LightDropdownState<T>();
}

class _LightDropdownState<T> extends State<LightDropdown<T>> {
  bool _focused = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: Builder(
        builder: (context) {
          return FieldShell(
            label: widget.label,
            focused: _focused,
            error: _errorText != null,
            enabled: widget.enabled,
            errorText: _errorText,
            child: DropdownButtonFormField<T>(
              initialValue: widget.value,
              items: widget.items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item.value,
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          color: Color(0xFF1C2228),
                        ),
                        child: item.child,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled ? widget.onChanged : null,
              validator: (value) {
                final error = widget.validator?.call(value);
                setState(() => _errorText = error);
                return error;
              },
              isExpanded: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: Color(0xFF1C2228),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Color(0xFF8A94A6),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                errorStyle: TextStyle(height: 0, fontSize: 0),
              ).copyWith(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  color: Color(0xFF8A94A6),
                ),
              ),
              menuMaxHeight: 350,
              disabledHint: widget.hint != null
                  ? Text(
                      widget.hint!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: Color(0xFF8A94A6),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}