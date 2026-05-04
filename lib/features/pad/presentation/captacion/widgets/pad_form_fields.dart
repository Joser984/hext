import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

import 'pad_form_styles.dart';

class PadFieldShell extends StatelessWidget {
  const PadFieldShell({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: PadFormTextStyles.labelCampo),
        const SizedBox(height: PadFormMetrics.labelGap),
        child,
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(errorText!, style: PadFormTextStyles.error),
        ],
      ],
    );
  }
}

class PadInputBox extends StatelessWidget {
  const PadInputBox({
    super.key,
    required this.child,
    this.height = PadFormMetrics.alturaCampo,
    this.enabled = true,
    this.error = false,
    this.onTap,
    this.trailing,
    this.alignment = Alignment.centerLeft,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PadFormMetrics.paddingCampoHorizontal,
    ),
  });

  final Widget child;
  final double height;
  final bool enabled;
  final bool error;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: enabled
            ? PadFormColors.blanco
            : PadFormColors.fondoSubtarjeta,
        borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
        border: Border.all(
          color: error
              ? PadFormColors.error
              : enabled
              ? PadFormColors.bordeSuave
              : PadFormColors.bordeInterno,
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              right: trailing == null ? 0 : 26,
              child: Align(alignment: alignment, child: child),
            ),
            if (trailing != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(child: trailing),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
        onTap: enabled ? onTap : null,
        child: content,
      ),
    );
  }
}

InputDecoration _padInputDecoration({required String hint}) {
  final String normalizedHint = _capitalizeFirst(hint);
  return InputDecoration(
    hintText: normalizedHint,
    hintStyle: PadFormTextStyles.textoCampo.copyWith(
      color: PadFormColors.textoMuted,
    ),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      vertical: PadFormMetrics.paddingCampoVertical,
    ),
    counterText: '',
  );
}

class PadTextInput extends StatelessWidget {
  const PadTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (FormFieldState<String> field) {
        if (field.value != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) {
              field.didChange(controller.text);
            }
          });
        }

        return PadFieldShell(
          label: label,
          errorText: field.errorText,
          child: PadInputBox(
            enabled: enabled,
            error: field.hasError,
            trailing: trailing,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: enabled,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: (String value) {
                field.didChange(value);
                onChanged?.call(value);
              },
              maxLines: 1,
              style: PadFormTextStyles.textoCampo,
              textAlignVertical: TextAlignVertical.center,
              decoration: _padInputDecoration(hint: hint ?? label),
            ),
          ),
        );
      },
    );
  }
}

class PadSelectInput<T> extends StatelessWidget {
  const PadSelectInput({
    super.key,
    required this.value,
    required this.label,
    this.hint,
    this.items,
    this.itemLabel,
    this.dropdownItems,
    this.onChanged,
    this.validator,
    this.enabled = true,
  }) : assert(
         (items != null && itemLabel != null) || dropdownItems != null,
         'Provide items + itemLabel or dropdownItems.',
       );

  final T? value;
  final String label;
  final String? hint;
  final List<T>? items;
  final String Function(T)? itemLabel;
  final List<DropdownMenuItem<T>>? dropdownItems;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<T>> resolvedItems =
        dropdownItems ??
        items!.map<DropdownMenuItem<T>>((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel!(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();

    return FormField<T>(
      key: ValueKey<String>('select_${label}_${value.toString()}'),
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<T> field) {
        return PadFieldShell(
          label: label,
          errorText: field.errorText,
          child: SizedBox(
            height: PadFormMetrics.alturaCampo,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PadFormMetrics.paddingCampoHorizontal,
                vertical: PadFormMetrics.paddingCampoVertical,
              ),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: enabled
                    ? PadFormColors.blanco
                    : PadFormColors.fondoSubtarjeta,
                borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
                border: Border.all(
                  color: field.hasError
                      ? PadFormColors.error
                      : enabled
                      ? PadFormColors.bordeSuave
                      : PadFormColors.bordeInterno,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: field.value,
                  isExpanded: true,
                  isDense: true,
                  alignment: Alignment.centerLeft,
                  iconSize: 18,
                  borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
                  dropdownColor: PadFormColors.fondoTarjeta,
                  style: PadFormTextStyles.textoCampo.copyWith(
                    color: enabled
                        ? PadFormColors.textoPrincipal
                        : PadFormColors.textoMuted,
                  ),
                  hint: Text(
                    _capitalizeFirst(hint ?? label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PadFormTextStyles.textoCampo.copyWith(
                      color: PadFormColors.textoMuted,
                    ),
                  ),
                  items: resolvedItems,
                  selectedItemBuilder: (BuildContext context) {
                    return resolvedItems.map((DropdownMenuItem<T> item) {
                      final Widget child = item.child;
                      final String text = child is Text && child.data != null
                          ? child.data!
                          : item.value?.toString() ?? '';

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PadFormTextStyles.textoCampo.copyWith(
                            color: enabled
                                ? PadFormColors.textoPrincipal
                                : PadFormColors.textoMuted,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  onChanged: enabled
                      ? (T? selected) {
                          field.didChange(selected);
                          onChanged?.call(selected);
                        }
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PadAutocompleteInput extends StatefulWidget {
  const PadAutocompleteInput({
    super.key,
    required this.sourceController,
    required this.label,
    this.hintText,
    required this.options,
    this.onChanged,
    this.validator,
  });

  final TextEditingController sourceController;
  final String label;
  final String? hintText;
  final List<String> options;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  State<PadAutocompleteInput> createState() => _PadAutocompleteInputState();
}

class _PadAutocompleteInputState extends State<PadAutocompleteInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey<String>('autocomplete_${widget.label}'),
      initialValue: widget.sourceController.text,
      validator: widget.validator,
      builder: (FormFieldState<String> field) {
        if (field.value != widget.sourceController.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) {
              field.didChange(widget.sourceController.text);
            }
          });
        }

        return PadFieldShell(
          label: widget.label,
          errorText: field.errorText,
          child: RawAutocomplete<String>(
            key: ValueKey<String>('pad_autocomplete_${widget.label}'),
            textEditingController: widget.sourceController,
            focusNode: _focusNode,
            optionsBuilder: (TextEditingValue value) {
              final String query = value.text.trim().toLowerCase();
              if (query.length < 2) return const Iterable<String>.empty();

              return widget.options
                  .where((String option) => option.toLowerCase().contains(query))
                  .take(8);
            },
            onSelected: (String selection) {
              widget.sourceController.text = selection;
              field.didChange(selection);
              widget.onChanged?.call(selection);
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return PadInputBox(
                error: field.hasError,
                child: TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onChanged: (String value) {
                    field.didChange(value);
                    widget.onChanged?.call(value);
                  },
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  maxLines: 1,
                  style: PadFormTextStyles.textoCampo,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _padInputDecoration(
                    hint: widget.hintText ?? widget.label,
                  ),
                ),
              );
            },
            optionsViewBuilder: (
              BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> filteredOptions,
            ) {
              final List<String> items = filteredOptions.toList();
              if (items.isEmpty) return const SizedBox.shrink();

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  child: Container(
                    width: PadFormMetrics.autocompleteWidth,
                    constraints: const BoxConstraints(
                      maxHeight: PadFormMetrics.autocompleteMaxHeight,
                    ),
                    margin: const EdgeInsets.only(top: PadFormMetrics.labelGap),
                    decoration: BoxDecoration(
                      color: PadFormColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(
                        PadFormMetrics.radioBase,
                      ),
                      border: Border.all(color: PadFormColors.bordeSuave),
                      boxShadow: HextShadows.card,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: PadFormMetrics.labelGap,
                      ),
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = items[index];

                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  PadFormMetrics.autocompleteItemHorizontalPadding,
                              vertical:
                                  PadFormMetrics.autocompleteItemVerticalPadding,
                            ),
                            child: Text(
                              option,
                              style: PadFormTextStyles.textoCampo,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class PadDateInput extends StatelessWidget {
  const PadDateInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PadTextInput(
      controller: controller,
      label: label,
      hint: hint,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      trailing: const Icon(
        Icons.calendar_today_outlined,
        size: 16,
        color: PadFormColors.textoSecundario,
      ),
    );
  }
}

class PadTimeInput extends StatelessWidget {
  const PadTimeInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PadTextInput(
      controller: controller,
      label: label,
      hint: hint,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      trailing: const Icon(
        Icons.schedule_outlined,
        size: 16,
        color: PadFormColors.textoSecundario,
      ),
    );
  }
}

class PadTextField extends StatelessWidget {
  const PadTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return PadTextInput(
      controller: controller,
      label: label,
      hint: hint,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
    );
  }
}

class PadDropdownField<T> extends StatelessWidget {
  const PadDropdownField({
    super.key,
    required this.value,
    required this.label,
    this.hint,
    this.items,
    this.itemLabel,
    this.dropdownItems,
    this.onChanged,
    this.validator,
  });

  final T? value;
  final String label;
  final String? hint;
  final List<T>? items;
  final String Function(T)? itemLabel;
  final List<DropdownMenuItem<T>>? dropdownItems;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return PadSelectInput<T>(
      value: value,
      label: label,
      hint: hint,
      items: items,
      itemLabel: itemLabel,
      dropdownItems: dropdownItems,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class PadAutocompleteField extends StatelessWidget {
  const PadAutocompleteField({
    super.key,
    required this.sourceController,
    required this.label,
    this.hintText,
    required this.options,
    this.onChanged,
    this.validator,
  });

  final TextEditingController sourceController;
  final String label;
  final String? hintText;
  final List<String> options;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return PadAutocompleteInput(
      sourceController: sourceController,
      label: label,
      hintText: hintText,
      options: options,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class PadAutocompleteTextField extends StatelessWidget {
  const PadAutocompleteTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.options,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final List<String> options;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return PadAutocompleteInput(
      sourceController: controller,
      label: label,
      hintText: hint,
      options: options,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class PadReadonlyField extends StatelessWidget {
  const PadReadonlyField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.onTap,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return PadTextInput(
      controller: controller,
      label: label,
      hint: hint,
      readOnly: true,
      onTap: onTap,
      validator: validator,
    );
  }
}

class PadMultilineField extends StatelessWidget {
  const PadMultilineField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 2,
    this.maxLines = 4,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (FormFieldState<String> field) {
        if (field.value != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) {
              field.didChange(controller.text);
            }
          });
        }

        return PadFieldShell(
          label: label,
          errorText: field.errorText,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PadFormMetrics.paddingCampoHorizontal,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: PadFormColors.blanco,
              borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
              border: Border.all(
                color: field.hasError
                    ? PadFormColors.error
                    : PadFormColors.bordeSuave,
              ),
            ),
            child: TextFormField(
              controller: controller,
              minLines: minLines,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: (String value) {
                field.didChange(value);
                onChanged?.call(value);
              },
              style: PadFormTextStyles.textoCampo,
              decoration: _padInputDecoration(hint: hint ?? label),
            ),
          ),
        );
      },
    );
  }
}

class PadSelectableChip extends StatelessWidget {
  const PadSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PadFormMetrics.alturaChip,
      child: FilterChip(
        label: Text(label),
        selected: selected,
        labelStyle: selected
            ? PadFormTextStyles.chip
            : PadFormTextStyles.chipNoSeleccionado,
        selectedColor: const Color(0xFFE8F3F1),
        backgroundColor: Colors.white,
        checkmarkColor: PadFormColors.verdePrincipal,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: PadFormMetrics.paddingCampoHorizontal,
        ),
        side: BorderSide(
          color: selected
              ? PadFormColors.verdePrincipal
              : PadFormColors.chipBorde,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: onSelected,
      ),
    );
  }
}

class PadStatusBadge extends StatelessWidget {
  const PadStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PadFormMetrics.alturaCampo,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: PadFormMetrics.paddingCampoHorizontal,
        ),
        decoration: BoxDecoration(
          color: PadFormColors.chipSeleccionado,
          borderRadius: BorderRadius.circular(PadFormMetrics.radioBase),
          border: Border.all(color: PadFormColors.chipBorde),
        ),
        child: Text(label, style: PadFormTextStyles.chip),
      ),
    );
  }
}

class PadPrimaryButton extends StatelessWidget {
  const PadPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PadFormMetrics.alturaBoton,
      child: FilledButton(
        style: padPrimaryButtonStyle(context),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class PadSecondaryButton extends StatelessWidget {
  const PadSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PadFormMetrics.alturaBoton,
      child: OutlinedButton(
        onPressed: onPressed,
        style: padSecondaryButtonStyle(context),
        child: Text(label),
      ),
    );
  }
}

class PadNeutralButton extends StatelessWidget {
  const PadNeutralButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PadFormMetrics.alturaBoton,
      child: OutlinedButton(
        onPressed: onPressed,
        style: padNeutralButtonStyle(context),
        child: Text(label),
      ),
    );
  }
}

String _capitalizeFirst(String value) {
  final String trimmed = value.trimLeft();
  if (trimmed.isEmpty) return value;
  final int start = value.indexOf(trimmed);
  final String prefix = start > 0 ? value.substring(0, start) : '';
  return '$prefix${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
