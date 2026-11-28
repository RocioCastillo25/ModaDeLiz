import 'package:flutter/material.dart';

/// Logo de Moda D' Liz (ropa y lencería).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: "Moda D' Liz, ropa y lencería",
    );
  }
}
