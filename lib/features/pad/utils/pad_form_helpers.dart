// Helpers y validadores reutilizables para formularios PAD

String? validateRequired(String? value, String fieldLabel) {
	if (value == null || value.trim().isEmpty) {
		return 'Ingresa $fieldLabel';
	}
	return null;
}

String? validateDropdownRequired(String? value, String fieldLabel) {
	if (value == null || value.trim().isEmpty) {
		return 'Selecciona $fieldLabel';
	}
	return null;
}

String normalizeText(String value) {
	return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
