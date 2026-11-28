import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/branch.dart';
import '../../data/models/search_filters.dart';
import '../../shared/primary_button.dart';

/// Hoja inferior con los filtros de talla, color y sucursal.
class FiltrosSheet extends StatefulWidget {
  const FiltrosSheet({
    super.key,
    required this.filters,
    required this.branches,
    required this.onApply,
    required this.onClear,
  });

  final SearchFilters filters;
  final List<Branch> branches;
  final void Function(SearchFilters filters) onApply;
  final VoidCallback onClear;

  @override
  State<FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<FiltrosSheet> {
  late final TextEditingController _size;
  late final TextEditingController _color;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    _size = TextEditingController(text: widget.filters.size ?? '');
    _color = TextEditingController(text: widget.filters.color ?? '');
    final selected = widget.filters.branchId;
    _branchId = widget.branches.any((branch) => branch.id == selected)
        ? selected
        : null;
  }

  @override
  void dispose() {
    _size.dispose();
    _color.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      SearchFilters(
        query: widget.filters.query,
        size: _size.text,
        color: _color.text,
        branchId: _branchId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _size,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Talla',
                hintText: 'Por ejemplo: M o 30',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _color,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Color',
                hintText: 'Por ejemplo: Rosa',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _branchId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sucursal'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las sucursales'),
                ),
                for (final branch in widget.branches)
                  DropdownMenuItem<String?>(
                    value: branch.id,
                    child: Text(branch.name),
                  ),
              ],
              onChanged: (value) => setState(() => _branchId = value),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Aplicar filtros', onPressed: _apply),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onClear,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.pink,
              ),
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
