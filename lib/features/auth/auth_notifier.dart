import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hext/core/models/app_user.dart';
import 'package:hext/core/repositories/user_repository.dart';
import 'package:hext/core/services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    required AuthService authService,
    required UserRepository userRepository,
  })  : _authService = authService,
        _userRepository = userRepository {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  final UserRepository _userRepository;

  static const String _demoEmail = 'demo@hext.local';
  static const String _demoPassword = 'hext123';

  AuthStatus _status = AuthStatus.loading;
  AppUser? _appUser;
  String? _errorMessage;
  bool _isDemoSession = false;

  AuthStatus get status => _status;
  AppUser? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      if (_isDemoSession) {
        return;
      }
      _appUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _isDemoSession = false;
    final AppUser? user = await _userRepository.fetchById(firebaseUser.uid);
    _appUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    if (_trySignInDemo(email: email, password: password)) {
      notifyListeners();
      return true;
    }
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageFor(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final UserCredential cred = await _authService.signUp(
        email: email,
        password: password,
      );
      final String? uid = cred.user?.uid;
      if (uid == null) {
        _errorMessage = 'No se pudo crear la cuenta.';
        notifyListeners();
        return false;
      }

      final _UsernameCandidate usernameCandidate =
          await _buildUniqueUsername(nombre);

      final AppUser newUser = AppUser(
        uid: uid,
        nombre: nombre.trim(),
        email: email.trim(),
        username: usernameCandidate.username,
        normalizedUsernameBase: usernameCandidate.base,
        rol: AppUserRole.auxiliarAdministrativa,
        sede: 'General',
        activo: true,
        createdAt: DateTime.now(),
      );
      await _userRepository.create(newUser);
      _appUser = newUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageFor(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _errorMessage = null;
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageFor(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isDemoSession = false;
    _appUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    await _authService.signOut();
  }

  bool _trySignInDemo({
    required String email,
    required String password,
  }) {
    if (!kDebugMode) {
      return false;
    }
    if (email.trim().toLowerCase() != _demoEmail || password != _demoPassword) {
      return false;
    }
    _isDemoSession = true;
    _appUser = AppUser(
      uid: 'demo-local-user',
      nombre: 'Usuario Demo',
      email: _demoEmail,
      rol: AppUserRole.admin,
      sede: 'HEXT',
      activo: true,
      createdAt: DateTime.now(),
    );
    _status = AuthStatus.authenticated;
    return true;
  }

  static String _messageFor(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'email-already-in-use':
        return 'Este correo ya esta registrado.';
      case 'weak-password':
        return 'La contrasena es demasiado debil.';
      case 'invalid-email':
        return 'Correo electronico invalido.';
      default:
        return 'Error de autenticación. Intenta de nuevo.';
    }
  }

  Future<_UsernameCandidate> _buildUniqueUsername(String fullName) async {
    final _NameParts parts = _parseNameParts(fullName);
    final String base = '${parts.firstInitial}${parts.firstSurname}';
    final String withSecondInitial = parts.secondSurnameInitial == null
        ? base
        : '$base${parts.secondSurnameInitial}';

    if (!await _userRepository.usernameExists(base)) {
      return _UsernameCandidate(username: base, base: base);
    }

    if (withSecondInitial != base &&
        !await _userRepository.usernameExists(withSecondInitial)) {
      return _UsernameCandidate(username: withSecondInitial, base: base);
    }

    int suffix = 2;
    String candidate = '$withSecondInitial$suffix';
    while (await _userRepository.usernameExists(candidate)) {
      suffix++;
      candidate = '$withSecondInitial$suffix';
    }
    return _UsernameCandidate(username: candidate, base: base);
  }

  static _NameParts _parseNameParts(String fullName) {
    final List<String> tokens = _normalizeForUsername(fullName)
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return const _NameParts(
        firstInitial: 'u',
        firstSurname: 'usuario',
        secondSurnameInitial: null,
      );
    }

    final String firstName = tokens.first;
    if (tokens.length == 1) {
      return _NameParts(
        firstInitial: firstName.substring(0, 1),
        firstSurname: 'usuario',
        secondSurnameInitial: null,
      );
    }

    final String firstSurname =
      tokens.length == 2 ? tokens[1] : tokens[tokens.length - 2];
    final String? secondSurnameInitial =
      tokens.length >= 3 ? tokens.last.substring(0, 1) : null;

    return _NameParts(
      firstInitial: firstName.substring(0, 1),
      firstSurname: firstSurname,
      secondSurnameInitial: secondSurnameInitial,
    );
  }

  static String _normalizeForUsername(String raw) {
    final String lower = raw.toLowerCase().trim();
    const Map<String, String> replacements = <String, String>{
      'a': 'a',
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'e': 'e',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'i': 'i',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'o': 'o',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'u': 'u',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'n': 'n',
      'ñ': 'n',
      'c': 'c',
      'ç': 'c',
    };

    final StringBuffer sb = StringBuffer();
    for (final int codePoint in lower.runes) {
      final String ch = String.fromCharCode(codePoint);
      final String mapped = replacements[ch] ?? ch;
      if (RegExp(r'[a-z0-9\s]').hasMatch(mapped)) {
        sb.write(mapped);
      }
    }
    return sb.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _UsernameCandidate {
  const _UsernameCandidate({required this.username, required this.base});

  final String username;
  final String base;
}

class _NameParts {
  const _NameParts({
    required this.firstInitial,
    required this.firstSurname,
    required this.secondSurnameInitial,
  });

  final String firstInitial;
  final String firstSurname;
  final String? secondSurnameInitial;
}
