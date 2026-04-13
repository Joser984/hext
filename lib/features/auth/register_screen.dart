import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:hext/shared/widgets/light_input.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final AuthNotifier notifier = context.read<AuthNotifier>();
    final bool ok = await notifier.register(
      nombre: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? errorMessage = context.select<AuthNotifier, String?>(
      (n) => n.errorMessage,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 80,
                  minWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Card(
                          elevation: 0,
                          color: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFD9E2E7)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF17726D),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Registro rapido de usuario',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  LightInput(
                                    label: 'Nombre',
                                    hint: 'Nombre completo',
                                    controller: _nameCtrl,
                                    textInputAction: TextInputAction.next,
                                    validator: (String? v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Ingresa tu nombre.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  LightInput(
                                    label: 'Correo electronico',
                                    hint: 'usuario@clinica.com',
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (String? v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Ingresa tu correo.';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Correo no valido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  LightInput(
                                    label: 'Contrasena',
                                    hint: 'Minimo 6 caracteres',
                                    controller: _passwordCtrl,
                                    obscureText: true,
                                    textInputAction: TextInputAction.next,
                                    validator: (String? v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Ingresa una contrasena.';
                                      }
                                      if (v.length < 6) {
                                        return 'Debe tener minimo 6 caracteres.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  LightInput(
                                    label: 'Confirmar contrasena',
                                    hint: 'Repite tu contrasena',
                                    controller: _confirmCtrl,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    validator: (String? v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Confirma tu contrasena.';
                                      }
                                      if (v != _passwordCtrl.text) {
                                        return 'Las contrasenas no coinciden.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (errorMessage != null) ...<Widget>[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF1F1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFF3CDCD),
                                        ),
                                      ),
                                      child: Text(
                                        errorMessage,
                                        style: const TextStyle(
                                          color: Color(0xFFB42318),
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 40,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF17726D,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      onPressed: _loading ? null : _submit,
                                      child: _loading
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Registrar'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => context.go('/login'),
                                    child: const Text('Ya tengo cuenta'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
