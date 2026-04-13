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
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
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
    this.onFieldSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  State<LightInput> createState() => _LightInputState();
}

class _LightInputState extends State<LightInput> {
  bool _focused = false;
  String? _errorText;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.readOnly || !widget.enabled
        ? const Color(0xFF6B7280)
        : const Color(0xFF1F2937);

    final Widget field = TextFormField(
      controller: widget.controller,
      validator: (value) {
        final error = widget.validator?.call(value);
        setState(() => _errorText = error);
        return error;
      },
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _obscure,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textAlignVertical: const TextAlignVertical(y: 0.9),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),
    );

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
            child: widget.obscureText
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child: field),
                      GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  )
                : field,
          );
        },
      ),
    );
  }
}
