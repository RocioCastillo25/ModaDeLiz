import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Foto de una prenda. Si no hay foto, mientras carga o si falla, muestra una
/// imagen de marcador de posición.
class PrendaImage extends StatelessWidget {
  const PrendaImage({
    super.key,
    required this.url,
    this.size = 64,
    this.radius = 14,
  });

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.pinkSoft.withValues(alpha: 0.35),
      child: Icon(
        Icons.checkroom_rounded,
        size: size * 0.5,
        color: AppColors.pink,
      ),
    );
    final address = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: (address == null || address.isEmpty)
            ? placeholder
            : Image.network(
                address,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (context, error, stack) => placeholder,
              ),
      ),
    );
  }
}
