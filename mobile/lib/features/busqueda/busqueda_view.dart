import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/prenda.dart';
import '../../shared/error_message.dart';
import '../../shared/gradient_background.dart';
import '../../shared/prenda_image.dart';
import '../../shared/stock_badge.dart';
import 'busqueda_view_model.dart';
import 'filtros_sheet.dart';

/// Pantalla de búsqueda de prendas con filtros.
class BusquedaView extends StatefulWidget {
  const BusquedaView({
    super.key,
    required this.viewModel,
    required this.onOpenFicha,
  });

  final BusquedaViewModel viewModel;

  /// Se llama al tocar una prenda para abrir su ficha.
  final void Function(Prenda prenda) onOpenFicha;

  @override
  State<BusquedaView> createState() => _BusquedaViewState();
}

class _BusquedaViewState extends State<BusquedaView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  BusquedaViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _controller.text = _vm.filters.query;
    _scroll.addListener(_onScroll);
    // Al abrir se carga la lista inicial y las sucursales del filtro.
    if (_vm.status == BusquedaStatus.idle) _vm.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _vm.loadMore();
    }
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundEnd,
      builder: (sheetContext) => FiltrosSheet(
        filters: _vm.filters,
        branches: _vm.branches,
        onApply: (filters) {
          Navigator.of(sheetContext).pop();
          _vm.applyFilters(filters);
        },
        onClear: () {
          Navigator.of(sheetContext).pop();
          _vm.clearFilters();
        },
      ),
    );
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
    final filters = _vm.activeFilterCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Buscar prendas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: _vm.onQueryChanged,
                    onSubmitted: _vm.updateQuery,
                    decoration: InputDecoration(
                      hintText: 'Nombre, marca o descripción',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Borrar texto',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _controller.clear();
                                _vm.updateQuery('');
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: filters > 0,
                  label: Text('$filters'),
                  child: IconButton.filledTonal(
                    tooltip: 'Filtros',
                    onPressed: _openFilters,
                    iconSize: 28,
                    constraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 52,
                    ),
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          if (filters > 0) _buildFilterSummary(),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    final f = _vm.filters;
    final parts = <String>[
      if (f.size != null) 'Talla ${f.size}',
      if (f.color != null) 'Color ${f.color}',
      if (f.branchId != null)
        _vm.branches
            .where((b) => b.id == f.branchId)
            .map((b) => b.name)
            .firstOrNull ??
            'Sucursal',
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parts.join(' · '),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: _vm.clearFilters,
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_vm.status) {
      case BusquedaStatus.idle:
      case BusquedaStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.pink),
        );
      case BusquedaStatus.error:
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ErrorMessage(
              message: _vm.errorMessage ?? 'No pudimos buscar. Inténtalo de nuevo.',
              onRetry: _vm.retry,
            ),
          ],
        );
      case BusquedaStatus.empty:
        return const _EmptyState();
      case BusquedaStatus.results:
        return _buildList();
    }
  }

  Widget _buildList() {
    final items = _vm.visibleResults;
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length + (_vm.hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.pink),
            ),
          );
        }
        final prenda = items[index];
        return _ResultTile(
          prenda: prenda,
          onTap: () => widget.onOpenFicha(prenda),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.prenda, required this.onTap});

  final Prenda prenda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (prenda.brand != null) prenda.brand!,
      if (prenda.category != null) prenda.category!,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${prenda.description}, ${prenda.totalStock} piezas',
      excludeSemantics: true,
      child: Material(
        color: AppColors.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                PrendaImage(url: prenda.photoUrl, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prenda.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 6),
                      StockBadge(
                        quantity: prenda.totalStock,
                        level: prenda.stockLevel,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.pink),
            SizedBox(height: 12),
            Text(
              'No encontramos prendas con esos datos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Prueba con otro nombre o quita algún filtro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
