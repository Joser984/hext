import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: FormField<T>(
        initialValue: widget.value,
        validator: widget.validator,
        enabled: widget.enabled,
        builder: (FormFieldState<T> fieldState) {
          final T? currentValue = widget.value ?? fieldState.value;
          final bool hasError =
              fieldState.errorText != null && fieldState.errorText!.isNotEmpty;
          final Color valueColor = widget.enabled
            ? HextColors.textPrimary
            : HextColors.textSecondary;

          return FieldShell(
            label: widget.label,
            focused: _focused,
            error: hasError,
            enabled: widget.enabled,
            errorText: fieldState.errorText,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: currentValue,
                  items: widget.items
                      .map(
                        (DropdownMenuItem<T> item) => DropdownMenuItem<T>(
                          value: item.value,
                          child: DefaultTextStyle.merge(
                            style: HextTextStyles.field,
                            child: item.child,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.enabled
                      ? (T? value) {
                          fieldState.didChange(value);
                          widget.onChanged?.call(value);
                        }
                      : null,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: HextColors.textSecondary,
                  ),
                  style: HextTextStyles.field.copyWith(color: valueColor),
                  menuMaxHeight: 350,
                  hint: widget.hint != null
                      ? Text(
                          widget.hint!,
                          style: HextTextStyles.field.copyWith(
                            color: HextColors.textSecondary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
