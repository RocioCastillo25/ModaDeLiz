import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/glass_card.dart';
import '../../shared/gradient_background.dart';
import 'home_view_model.dart';

/// Pantalla principal: confirma quién entró y muestra los accesos futuros.
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_showForbiddenNotice);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_showForbiddenNotice);
    super.dispose();
  }

  /// Un 403 avisa de la falta de permisos sin cerrar la sesión.
  void _showForbiddenNotice() {
    if (!mounted || !widget.viewModel.takeForbiddenNotice()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No tienes permiso para realizar esta acción.'),
      ),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await widget.viewModel.logout();
    if (mounted) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) => _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final vm = widget.viewModel;
    return Column(
      children: [
        Expanded(child: _buildScrollable(vm)),
        // El botón queda fijo al pie para alcanzarlo siempre con una mano.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: OutlinedButton.icon(
            onPressed: _loggingOut ? null : _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollable(HomeViewModel vm) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      children: [
        const Text(
          'CheckLizz',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.pink,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola,',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              Text(
                vm.userName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Rol',
                value: vm.roleLabel,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.storefront_outlined,
                label: 'Sucursal',
                value: vm.branchName,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Secciones',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        for (final section in vm.sections) ...[
          _SectionTile(section: section),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final HomeSection section;

  IconData get _icon {
    switch (section.id) {
      case HomeSectionId.search:
        return Icons.search;
      case HomeSectionId.scanner:
        return Icons.qr_code_scanner;
      case HomeSectionId.transfers:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = section.hint;
    return Semantics(
      label: hint == null
          ? section.title
          : '${section.title}, ${hint.toLowerCase()}, no disponible',
      enabled: section.enabled,
      excludeSemantics: true,
      child: Opacity(
        opacity: section.enabled ? 1 : 0.6,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(_icon, color: AppColors.violet),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              if (hint != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.amber),
                  ),
                  child: Text(
                    hint,
                    style: const TextStyle(color: AppColors.amber, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
