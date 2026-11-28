import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/prenda_ficha.dart';
import '../../data/services/barcode_scanner_service.dart';
import '../../shared/error_message.dart';
import '../../shared/glass_card.dart';
import '../../shared/gradient_background.dart';
import '../../shared/primary_button.dart';
import 'escaner_view_model.dart';

/// Pantalla del escáner de códigos: explica el uso de la cámara, lee la
/// etiqueta y abre la ficha de la prenda.
class EscanerView extends StatefulWidget {
  const EscanerView({
    super.key,
    required this.viewModel,
    required this.scanner,
    required this.onOpenFicha,
  });

  final EscanerViewModel viewModel;

  /// Solo se usa para mostrar la vista previa de la cámara.
  final BarcodeScannerService scanner;

  /// Abre la ficha encontrada; termina cuando el usuario regresa de ella.
  final Future<void> Function(PrendaFicha ficha) onOpenFicha;

  @override
  State<EscanerView> createState() => _EscanerViewState();
}

class _EscanerViewState extends State<EscanerView> {
  final TextEditingController _manual = TextEditingController();
  bool _showManual = false;
  bool _opening = false;

  EscanerViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_openFichaWhenFound);
  }

  @override
  void dispose() {
    _vm.removeListener(_openFichaWhenFound);
    _manual.dispose();
    super.dispose();
  }

  /// Cuando se encuentra una prenda, abre su ficha y, al volver, retoma el
  /// escaneo.
  Future<void> _openFichaWhenFound() async {
    final ficha = _vm.foundFicha;
    if (_vm.status != EscanerStatus.found || ficha == null || _opening) return;
    _opening = true;
    await widget.onOpenFicha(ficha);
    _opening = false;
    if (mounted) {
      _manual.clear();
      _vm.resume();
    }
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
                    _header(),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
              'Escanear código',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          if (_vm.status == EscanerStatus.scanning ||
              _vm.status == EscanerStatus.resolving)
            IconButton.filledTonal(
              tooltip: _vm.torchOn ? 'Apagar la linterna' : 'Encender la linterna',
              onPressed: _vm.toggleTorch,
              icon: Icon(_vm.torchOn ? Icons.flashlight_off : Icons.flashlight_on),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_vm.status) {
      case EscanerStatus.explaining:
        return _explaining();
      case EscanerStatus.scanning:
      case EscanerStatus.resolving:
      case EscanerStatus.found:
        return _scanning();
      case EscanerStatus.notFound:
      case EscanerStatus.error:
        return _notice();
      case EscanerStatus.permissionDenied:
        return _noCamera(
          'Sin permiso de cámara',
          'No podemos leer etiquetas sin la cámara. Puedes activar el permiso '
              'en los ajustes del teléfono o escribir el código a mano.',
        );
      case EscanerStatus.unavailable:
        return _noCamera(
          'Cámara no disponible',
          'No pudimos usar la cámara. Escribe el código de la etiqueta para '
              'buscar la prenda.',
        );
    }
  }

  Widget _explaining() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.qr_code_scanner, size: 56, color: AppColors.pink),
              const SizedBox(height: 12),
              const Text(
                'Usaremos la cámara',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para leer el código de barras de la etiqueta y abrir la ficha '
                'de la prenda. La cámara solo se usa mientras esta pantalla '
                'está abierta y no se guardan fotos.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Activar cámara', onPressed: _vm.start),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _manualToggleOrField(),
      ],
    );
  }

  Widget _scanning() {
    final resolving = _vm.status == EscanerStatus.resolving;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.textPrimary,
                    child: widget.scanner.buildPreview(context),
                  ),
                  Center(
                    child: Container(
                      width: 260,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.pinkSoft, width: 3),
                      ),
                    ),
                  ),
                  if (resolving)
                    const ColoredBox(
                      color: AppColors.scrim,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.pinkSoft),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              resolving ? 'Buscando la prenda…' : 'Apunta al código de barras de la etiqueta',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          _manualToggleOrField(),
        ],
      ),
    );
  }

  Widget _notice() {
    final notFound = _vm.status == EscanerStatus.notFound;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErrorMessage(
          message: notFound
              ? 'Prenda no encontrada. Revisa que sea una etiqueta de Moda de Lizz.'
              : (_vm.message ?? 'No pudimos buscar la prenda.'),
          icon: notFound ? Icons.search_off : Icons.error_outline,
          color: notFound ? AppColors.amber : AppColors.danger,
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Escanear otra vez', onPressed: _vm.rescan),
        const SizedBox(height: 12),
        _manualToggleOrField(),
      ],
    );
  }

  Widget _noCamera(String title, String text) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErrorMessage(
          message: '$title. $text',
          icon: Icons.no_photography_outlined,
          color: AppColors.amber,
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Intentar con la cámara', onPressed: _vm.start),
        const SizedBox(height: 16),
        _manualField(),
      ],
    );
  }

  /// Enlace para escribir el código; con la cámara negada se muestra directo.
  Widget _manualToggleOrField() {
    if (_vm.canLookUpManually || _showManual) return _manualField();
    return TextButton.icon(
      onPressed: () => setState(() => _showManual = true),
      icon: const Icon(Icons.keyboard_outlined),
      label: const Text('Escribir el código a mano'),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.pink,
      ),
    );
  }

  Widget _manualField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _manual,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          onSubmitted: _vm.lookUp,
          decoration: InputDecoration(
            labelText: 'Código de barras',
            errorText: _vm.manualError,
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Buscar por código',
          isLoading: _vm.status == EscanerStatus.resolving,
          onPressed: () => _vm.lookUp(_manual.text),
        ),
      ],
    );
  }
}
