import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/stock_item.dart';
import '../../shared/error_message.dart';
import '../../shared/primary_button.dart';
import 'venta_view_model.dart';

/// Hoja inferior para descontar piezas vendidas de la sucursal del usuario.
class VentaSheet extends StatefulWidget {
  const VentaSheet({
    super.key,
    required this.viewModel,
    required this.prendaName,
  });

  final VentaViewModel viewModel;
  final String prendaName;

  @override
  State<VentaSheet> createState() => _VentaSheetState();
}

class _VentaSheetState extends State<VentaSheet> {
  final TextEditingController _quantity = TextEditingController();

  VentaViewModel get _vm => widget.viewModel;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Descontar piezas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                widget.prendaName,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ..._content(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content() {
    switch (_vm.status) {
      case VentaStatus.editing:
        return _editing();
      case VentaStatus.confirming:
      case VentaStatus.submitting:
      case VentaStatus.error:
        return _confirming();
      case VentaStatus.insufficient:
        return _insufficient();
      case VentaStatus.done:
        return _done();
    }
  }

  List<Widget> _editing() {
    if (_vm.selected == null) {
      return [
        const ErrorMessage(
          message: 'No quedan piezas de esta prenda en tu sucursal.',
          icon: Icons.info_outline,
          color: AppColors.amber,
        ),
        const SizedBox(height: 12),
        _closeButton('Cerrar'),
      ];
    }
    return [
      const Text(
        'Talla y color',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      for (final option in _vm.options) _OptionTile(
        option: option,
        selected: option.id == _vm.selected?.id,
        onTap: () => _vm.select(option),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _quantity,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onChanged: _vm.setQuantity,
        decoration: InputDecoration(
          labelText: 'Cantidad de piezas',
          errorText: _vm.quantityError,
          helperText: _vm.quantityWarning,
          helperStyle: const TextStyle(color: AppColors.amber),
        ),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Continuar',
        onPressed: _vm.canContinue ? _vm.confirm : null,
      ),
    ];
  }

  List<Widget> _confirming() {
    final busy = _vm.status == VentaStatus.submitting;
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pinkSoft.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.pink),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Confirmas la venta?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(widget.prendaName, style: const TextStyle(fontSize: 16)),
            Text(
              _vm.summary,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      if (_vm.status == VentaStatus.error && _vm.errorMessage != null) ...[
        const SizedBox(height: 12),
        ErrorMessage(message: _vm.errorMessage!),
      ],
      const SizedBox(height: 16),
      PrimaryButton(
        label: _vm.status == VentaStatus.error ? 'Reintentar' : 'Confirmar venta',
        isLoading: busy,
        onPressed: _vm.canSubmit ? _vm.submit : null,
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: busy ? null : _vm.backToEditing,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.pink,
        ),
        child: const Text('Volver'),
      ),
    ];
  }

  List<Widget> _insufficient() {
    return [
      ErrorMessage(
        message: _vm.errorMessage ?? 'No hay suficientes piezas.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.amber,
      ),
      const SizedBox(height: 4),
      const Text(
        'No se descontó nada. Corrige la cantidad e inténtalo de nuevo.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Corregir cantidad',
        onPressed: () {
          _quantity.clear();
          _vm
            ..setQuantity('')
            ..backToEditing();
        },
      ),
      const SizedBox(height: 8),
      _closeButton('Cerrar'),
    ];
  }

  List<Widget> _done() {
    final result = _vm.result;
    return [
      const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.cyan, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Venta registrada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (result != null)
        Text(
          'Talla ${result.size} · ${result.color}: ahora hay ${result.quantity} '
          '${result.quantity == 1 ? 'pieza' : 'piezas'} en ${result.branchName}.',
          style: const TextStyle(fontSize: 16),
        ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Listo',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  Widget _closeButton(String label) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    style: TextButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: AppColors.pink,
    ),
    child: Text(label),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StockItem option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = option.quantity <= 0;
    final pieces = '${option.quantity} ${option.quantity == 1 ? 'pieza' : 'piezas'}';
    return Semantics(
      button: true,
      selected: selected,
      enabled: !soldOut,
      label: 'Talla ${option.size}, ${option.color}, $pieces'
          '${soldOut ? ', agotado' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected
              ? AppColors.pinkSoft.withValues(alpha: 0.35)
              : AppColors.glass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? AppColors.pink : AppColors.glassBorder,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: soldOut ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: soldOut ? AppColors.disabled : AppColors.pink,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Talla ${option.size} · ${option.color}',
                        style: TextStyle(
                          fontSize: 16,
                          color: soldOut
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      soldOut ? 'Agotado' : pieces,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: soldOut ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
