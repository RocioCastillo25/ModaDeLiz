import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/prenda.dart';
import '../../data/models/prenda_ficha.dart';
import '../../shared/error_message.dart';
import '../../shared/glass_card.dart';
import '../../shared/gradient_background.dart';
import '../../shared/prenda_image.dart';
import '../../shared/primary_button.dart';
import '../../shared/stock_badge.dart';
import 'ficha_view_model.dart';
import 'matriz_existencias.dart';

/// Ficha de una prenda: foto, características y existencia en las 5 sucursales.
class FichaView extends StatefulWidget {
  const FichaView({
    super.key,
    required this.viewModel,
    this.prendaId,
    this.barcode,
    this.initial,
    this.onSell,
  }) : assert(
         prendaId != null || barcode != null || initial != null,
         'Se necesita un identificador, un código de barras o una ficha',
       );

  final FichaViewModel viewModel;
  final int? prendaId;
  final String? barcode;

  /// Ficha ya consultada (la del escáner): se muestra sin pedirla otra vez.
  final PrendaFicha? initial;

  /// Abre el descuento de piezas. Si es `null`, la acción no se ofrece.
  final Future<void> Function(BuildContext context, FichaViewModel viewModel)?
  onSell;

  @override
  State<FichaView> createState() => _FichaViewState();
}

class _FichaViewState extends State<FichaView> {
  FichaViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_showRefreshError);
    if (widget.initial != null) {
      _vm.showLoaded(widget.initial!);
    } else if (widget.prendaId != null) {
      _vm.load(widget.prendaId!);
    } else {
      _vm.loadByBarcode(widget.barcode!);
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_showRefreshError);
    super.dispose();
  }

  /// Si falla al actualizar, avisa sin quitar los datos que ya se veían.
  void _showRefreshError() {
    final message = _vm.refreshError;
    if (!mounted || message == null) return;
    _vm.clearRefreshError();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) => Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Text(
              'Ficha de prenda',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_vm.status) {
      case FichaStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.pink),
        );
      case FichaStatus.error:
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ErrorMessage(
              message: _vm.errorMessage ?? 'No pudimos abrir la ficha.',
              onRetry: _vm.refresh,
            ),
          ],
        );
      case FichaStatus.data:
        return _buildData();
    }
  }

  Widget _buildData() {
    final ficha = _vm.ficha!;
    final prenda = ficha.prenda;
    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: _vm.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassCard(child: _Summary(prenda: prenda, total: ficha.totalStock)),
          const SizedBox(height: 16),
          const Text(
            'Existencia por sucursal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          MatrizExistencias(
            stock: ficha.stock,
            ownBranchId: _vm.ownBranchId,
            levelOf: _vm.levelOf,
          ),
          const SizedBox(height: 8),
          if (widget.onSell != null && _vm.canSell) ...[
            PrimaryButton(
              label: 'Descontar piezas',
              onPressed: () => widget.onSell!(context, _vm),
            ),
            const SizedBox(height: 12),
          ],
          // El traspaso llega en el Sprint 3.
          const _TransferPlaceholder(),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.prenda, required this.total});

  final Prenda prenda;
  final int total;

  @override
  Widget build(BuildContext context) {
    final level = Prenda(
      id: prenda.id,
      barcode: prenda.barcode,
      description: prenda.description,
      alertThreshold: prenda.alertThreshold,
      totalStock: total,
    ).stockLevel;
    final details = <(String, String?)>[
      ('Marca', prenda.brand),
      ('Categoría', prenda.category),
      ('Temporada', prenda.season),
      ('Código', prenda.barcode),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: PrendaImage(url: prenda.photoUrl, size: 160, radius: 20)),
        const SizedBox(height: 12),
        Text(
          prenda.description,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Text(
              'Total en las sucursales:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            StockBadge(quantity: total, level: level),
          ],
        ),
        const SizedBox(height: 10),
        for (final (label, value) in details)
          if (value != null && value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _TransferPlaceholder extends StatelessWidget {
  const _TransferPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Solicitar traspaso, próximamente, no disponible',
      enabled: false,
      excludeSemantics: true,
      child: const Opacity(
        opacity: 0.6,
        child: OutlinedButton(
          onPressed: null,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Solicitar traspaso',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Próximamente',
                  style: TextStyle(color: AppColors.amber, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
