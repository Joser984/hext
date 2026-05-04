import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color green = Color(0xFF17726D);
  static const Color gold = Color(0xFFCCBA86);
  static const Color border = Color(0xFFD0D5DD);
  static const Color hint = Color(0xFF98A2B3);
  static const Color text = Color(0xFF0F172A);
  static const Color subtext = Color(0xFF667085);
  static const Color divider = Color(0xFFE4E7EC);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final AuthNotifier notifier = context.read<AuthNotifier>();
    final bool ok = await notifier.signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.go('/dashboard');
  }

  Future<void> _forgotPassword() async {
    final String email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo para recuperar la contrasena.'),
        ),
      );
      return;
    }
    final AuthNotifier notifier = context.read<AuthNotifier>();
    final bool ok = await notifier.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Se envio el correo de recuperacion.'
              : (notifier.errorMessage ?? 'No se pudo enviar el correo.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? errorMessage = context.select<AuthNotifier, String?>(
      (AuthNotifier notifier) => notifier.errorMessage,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: <Widget>[
          const Expanded(
            flex: 1,
            child: _BrandPanel(),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 500,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 32,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.language_outlined,
                                    size: 18,
                                    color: subtext,
                                  ),
                                  label: const Text(
                                    'Espanol',
                                    style: TextStyle(color: text),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.help_outline_rounded,
                                    size: 18,
                                    color: subtext,
                                  ),
                                  label: const Text(
                                    'Ayuda',
                                    style: TextStyle(color: text),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 76),
                            const Text(
                              'Bienvenido a HEXT',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Inicia sesion para continuar',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtext,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: 56,
                              height: 2,
                              color: gold,
                            ),
                            const SizedBox(height: 28),
                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Correo electronico',
                              hintText: 'ejemplo@hext.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu correo.';
                                }
                                if (!value.contains('@')) {
                                  return 'Correo no valido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordCtrl,
                              label: 'Contrasena',
                              hintText: 'Ingresa tu contrasena',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                                color: subtext,
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contrasena.';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Olvidaste tu contrasena?',
                                  style: TextStyle(color: gold),
                                ),
                              ),
                            ),
                            if (errorMessage != null) ...<Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFDA29B),
                                  ),
                                ),
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                    : const Text(
                                        'INICIAR SESION',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: <Widget>[
                                const Expanded(child: Divider(color: divider)),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'O',
                                    style: TextStyle(
                                      color: subtext.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: divider)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: gold,
                                  side: const BorderSide(color: gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.shield_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'INICIAR SESION CON SSO',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtext,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(text: 'Necesitas ayuda? '),
                                    TextSpan(
                                      text: 'Contacta a soporte',
                                      style: TextStyle(color: gold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Row(
                              children: <Widget>[
                                Expanded(
                                  child: _InfoItem(
                                    icon: Icons.verified_user_outlined,
                                    title: 'Seguridad',
                                    subtitle: 'Datos protegidos',
                                  ),
                                ),
                                SizedBox(
                                  height: 72,
                                  child: VerticalDivider(color: divider),
                                ),
                                Expanded(
                                  child: _InfoItem(
                                    icon: Icons.lock_outline_rounded,
                                    title: 'Privacidad',
                                    subtitle: 'Cumplimos estandares',
                                  ),
                                ),
                                SizedBox(
                                  height: 72,
                                  child: VerticalDivider(color: divider),
                                ),
                                Expanded(
                                  child: _InfoItem(
                                    icon: Icons.cloud_outlined,
                                    title: 'Disponibilidad',
                                    subtitle: 'Sistema siempre activo',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 56),
                            const Divider(color: divider),
                            const SizedBox(height: 12),
                            const Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '(c) 2024 HEXT. Todos los derechos reservados.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtext,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Terminos y condiciones',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtext,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Politica de privacidad',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtext,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const String _backgroundAssetPath =
      'assets/images/login/connected_healthcare_platform_branding_design_login_panel.png';

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: Image.asset(
          _backgroundAssetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _LoginScreenState.text,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            onFieldSubmitted: onFieldSubmitted,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: _LoginScreenState.hint,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 20,
                color: _LoginScreenState.hint,
              ),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _LoginScreenState.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: _LoginScreenState.green,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFDA29B)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFDA29B)),
              ),
              errorStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(
          icon,
          size: 30,
          color: _LoginScreenState.green,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _LoginScreenState.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: _LoginScreenState.subtext,
          ),
        ),
      ],
    );
  }
}
