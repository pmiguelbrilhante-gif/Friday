import 'package:flutter/material.dart';

/// Fundo escuro com gradiente radial sutil e uma grade fina,
/// criando a sensação de um painel holográfico.
class HudBackground extends StatelessWidget {
  final Widget child;
  const HudBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.3,
              colors: [
                Color(0xFF0B1620),
                Color(0xFF040A10),
                Color(0xFF000000),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _GridPainter()),
        ),
        child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF35E4E0).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
