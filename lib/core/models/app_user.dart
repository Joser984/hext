import 'package:cloud_firestore/cloud_firestore.dart';

enum AppUserRole {
  admin,
  medico,
  auxiliarAdministrativa,
  auxiliarEnfermeriaClinicaHeridas,
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.nombre,
    required this.email,
    this.username,
    this.normalizedUsernameBase,
    required this.rol,
    required this.sede,
    required this.activo,
    required this.createdAt,
  });

  final String uid;
  final String nombre;
  final String email;
  final String? username;
  final String? normalizedUsernameBase;
  final AppUserRole rol;
  final String sede;
  final bool activo;
  final DateTime createdAt;

  // ── Firestore string keys ──────────────────────────────────────────────────
  static const String _kAdmin = 'admin';
  static const String _kMedico = 'medico';
  static const String _kAuxAdmin = 'auxiliar_administrativa';
  static const String _kAuxHeridas = 'auxiliar_enfermeria_clinica_heridas';

  static AppUserRole _rolFromString(String? value) {
    switch (value) {
      case _kAdmin:
        return AppUserRole.admin;
      case _kMedico:
        return AppUserRole.medico;
      case _kAuxAdmin:
        return AppUserRole.auxiliarAdministrativa;
      case _kAuxHeridas:
        return AppUserRole.auxiliarEnfermeriaClinicaHeridas;
      default:
        return AppUserRole.auxiliarAdministrativa;
    }
  }

  static String _rolToString(AppUserRole rol) {
    switch (rol) {
      case AppUserRole.admin:
        return _kAdmin;
      case AppUserRole.medico:
        return _kMedico;
      case AppUserRole.auxiliarAdministrativa:
        return _kAuxAdmin;
      case AppUserRole.auxiliarEnfermeriaClinicaHeridas:
        return _kAuxHeridas;
    }
  }

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      nombre: (data['nombre'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      username: (data['username'] as String?)?.trim(),
      normalizedUsernameBase: (data['normalizedUsernameBase'] as String?)?.trim(),
      rol: _rolFromString(data['rol'] as String?),
      sede: (data['sede'] as String?) ?? '',
      activo: (data['activo'] as bool?) ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'nombre': nombre,
      'email': email,
      if (username != null && username!.isNotEmpty) 'username': username,
      if (normalizedUsernameBase != null && normalizedUsernameBase!.isNotEmpty)
        'normalizedUsernameBase': normalizedUsernameBase,
      'rol': _rolToString(rol),
      'sede': sede,
      'activo': activo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── Helpers de acceso (base para guards por módulo) ────────────────────────
  bool get isAdmin => rol == AppUserRole.admin;
  bool get isMedico => rol == AppUserRole.medico;
  bool get isAuxiliarAdministrativa => rol == AppUserRole.auxiliarAdministrativa;
  bool get isAuxiliarHeridas =>
      rol == AppUserRole.auxiliarEnfermeriaClinicaHeridas;

  /// Puede acceder a administración de usuarios.
  bool get canManageUsers => isAdmin;

  /// Puede tomar decisiones clínicas médicas (p.ej. aprobación PAD).
  bool get canMakeClinicDecisions => isAdmin || isMedico;

  /// Puede operar flujos asistenciales y operativos.
  bool get canOperateAssistential =>
      isAdmin || isMedico || isAuxiliarAdministrativa || isAuxiliarHeridas;

  /// Puede registrar y actualizar seguimiento de clínica de heridas.
  bool get canManageHeridas =>
      isAdmin || isMedico || isAuxiliarHeridas;

  /// Puede acceder al módulo de horarios y personal.
  bool get canAccessSchedule => isAdmin || isAuxiliarAdministrativa;

  /// Puede crear un nuevo candidato PAD.
  bool get canCreatePadCandidato =>
      isAdmin || isMedico || isAuxiliarAdministrativa;
}

