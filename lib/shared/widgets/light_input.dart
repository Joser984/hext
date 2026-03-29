
import 'package:flutter/material.dart';
import 'field_shell.dart';

class LightInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;

  const LightInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  State<LightInput> createState() => _LightInputState();
}

class _LightInputState extends State<LightInput> {
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
            child: TextFormField(
              controller: widget.controller,
              validator: (value) {
                final error = widget.validator?.call(value);
                setState(() => _errorText = error);
                return error;
              },
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: Color(0xFF1C2228),
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  color: Color(0xFF8A94A6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
          );
        },
      ),
    );
  }
}