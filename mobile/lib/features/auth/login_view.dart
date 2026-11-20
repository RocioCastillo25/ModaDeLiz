import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/error_message.dart';
import '../../shared/glass_card.dart';
import '../../shared/gradient_background.dart';
import '../../shared/primary_button.dart';
import 'login_view_model.dart';
import 'session_view_model.dart';

/// Pantalla de inicio de sesión. Solo muestra estado y envía acciones.
class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.viewModel,
    this.notice,
    this.showDemoHint = false,
  });

  final LoginViewModel viewModel;

  /// Aviso que explica por qué se volvió al inicio de sesión.
  final SessionNotice? notice;

  /// Muestra la ayuda con los usuarios de ejemplo (solo en modo de prueba).
  final bool showDemoHint;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_clearPasswordOnReset);
  }

  /// Si el estado se reinicia (por ejemplo, tras cerrar sesión), se vacía el formulario.
  void _clearPasswordOnReset() {
    final vm = widget.viewModel;
    if (vm.status == LoginStatus.idle &&
        vm.error == null &&
        !vm.showAdminNotice &&
        _passwordController.text.isNotEmpty) {
      _passwordController.clear();
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_clearPasswordOnReset);
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    widget.viewModel.submit(_usernameController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) => _buildContent(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final vm = widget.viewModel;
    final loading = vm.status == LoginStatus.loading;
    final error = vm.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'CheckLizz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Inventario conectado',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 28),
        GlassCard(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.notice == SessionNotice.expired &&
                    error == null) ...[
                  const ErrorMessage(
                    message: 'Tu sesión venció. Inicia sesión de nuevo.',
                    icon: Icons.info_outline,
                    color: AppColors.amber,
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _usernameController,
                  enabled: !loading,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person_outline),
                    errorText: vm.usernameMissing ? 'Escribe tu usuario' : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !loading,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText:
                        vm.passwordMissing ? 'Escribe tu contraseña' : null,
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (error != null && error != LoginError.emptyFields) ...[
                  const SizedBox(height: 16),
                  ErrorMessage(
                    message: _messageFor(error),
                    onRetry: _canRetry(error) ? _submit : null,
                  ),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Iniciar sesión',
                  isLoading: loading,
                  onPressed: vm.canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
        if (widget.showDemoHint) ...[
          const SizedBox(height: 16),
          const _DemoHint(),
        ],
      ],
    );
  }

  bool _canRetry(LoginError error) =>
      error == LoginError.noConnection || error == LoginError.serviceUnavailable;

  String _messageFor(LoginError error) {
    switch (error) {
      case LoginError.emptyFields:
        return 'Escribe tu usuario y tu contraseña.';
      case LoginError.invalidCredentials:
        return 'Usuario o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.';
      case LoginError.accountDisabled:
        return 'Tu cuenta está desactivada. Habla con la persona encargada de tu tienda.';
      case LoginError.noConnection:
        return 'Sin conexión a internet. Revisa tu conexión e inténtalo de nuevo.';
      case LoginError.serviceUnavailable:
        return 'No pudimos iniciar sesión en este momento. Inténtalo de nuevo en unos minutos.';
      case LoginError.incompleteData:
        return 'No pudimos completar tu acceso. Avisa a la persona encargada de tu cuenta.';
    }
  }
}

/// Ayuda visible solo en modo de prueba: identifica los datos como de ejemplo.
class _DemoHint extends StatelessWidget {
  const _DemoHint();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: AppColors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'MODO DE PRUEBA',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Usuarios de ejemplo: demo.vendedor, demo.encargado, demo.admin y '
            'demo.desactivado. Contraseña: demo1234.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
