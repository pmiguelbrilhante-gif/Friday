import 'dart:math';
import 'package:flutter/material.dart';

enum FridayState { idle, listening, thinking, speaking }

/// O núcleo visual do app: um "reator" holográfico que pulsa e gira,
/// mudando de cor e intensidade conforme o estado do Jarvis.
class ArcReactor extends StatefulWidget {
  final FridayState state;
  final double size;
  final VoidCallback? onTap;

  const ArcReactor({
    super.key,
    required this.state,
    this.size = 220,
    this.onTap,
  });

  @override
  State<ArcReactor> createState() => _ArcReactorState();
}

class _ArcReactorState extends State<ArcReactor> with TickerProviderStateMixin {
  late final AnimationController _rotationCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.state) {
      case FridayState.idle:
        return const Color(0xFF35E4E0);
      case FridayState.listening:
        return const Color(0xFF4DE8FF);
      case FridayState.thinking:
        return const Color(0xFFFFB84D);
      case FridayState.speaking:
        return const Color(0xFF6DFFB0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationCtrl, _pulseCtrl]),
        builder: (context, _) {
          final pulse = widget.state == FridayState.idle
              ? 0.0
              : (0.06 * _pulseCtrl.value);
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _ReactorPainter(
                rotation: _rotationCtrl.value * 2 * pi,
                pulse: pulse,
                color: _color,
                active: widget.state != FridayState.idle,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReactorPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color color;
  final bool active;

  _ReactorPainter({
    required this.rotation,
    required this.pulse,
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width / 2.2; // Espaço para a estrutura 3D
    final radius = baseRadius * (1 + pulse);

    // 1. Núcleo Super Brilhante (O Sol do Centro)
    final coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          color.withValues(alpha: active ? 0.9 : 0.4),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.1, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));
    canvas.drawCircle(center, radius * 0.35, coreGlow);

    // 2. Linhas Irradiantes (Spikes) igual ao print
    final spikePaint = Paint()
      ..color = color.withValues(alpha: active ? 0.6 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const int numSpikes = 12;
    for (int i = 0; i < numSpikes; i++) {
      final angle =
          rotation * (i.isEven ? 0.5 : -0.5) + (i * (2 * pi / numSpikes));
      final start = Offset(
        center.dx + cos(angle) * (radius * 0.4),
        center.dy + sin(angle) * (radius * 0.4),
      );
      final end = Offset(
        center.dx + cos(angle) * (radius * 1.1),
        center.dy + sin(angle) * (radius * 1.1),
      );
      canvas.drawLine(start, end, spikePaint);
    }

    // 3. Esfera Astrolábica Wireframe (Órbitas simulando 3D)
    final orbitPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.4 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final particlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Desenhamos 4 elipses cruzadas para criar o globo
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Rotação Híbrida: cada órbita gira em eixos levemente diferentes
      canvas.rotate(rotation + (i * pi / 4));

      // Criando a elipse (achatada para parecer 3D)
      final rect = Rect.fromCenter(
          center: Offset.zero,
          width: radius * 1.7,
          height: radius * 1.7 * (0.3 + (i * 0.15)) // Achatamento matemático
          );

      canvas.drawOval(rect, orbitPaint);

      // Desenhando os "nós" luminosos nas pontas das órbitas
      if (active) {
        final nodeX = cos(rotation * 2 + i) * (rect.width / 2);
        final nodeY = sin(rotation * 2 + i) * (rect.height / 2);
        canvas.drawCircle(Offset(nodeX, nodeY), 2.5, particlePaint);
      }

      canvas.restore();
    }

    // 4. Anel Magnético Externo (Poeira estelar)
    final outerRing = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 0.5);
    _drawDashedArc(canvas, Offset.zero, radius * 1.05, 0, outerRing, 30);
    canvas.restore();
  }

  void _drawDashedArc(Canvas canvas, Offset center, double radius,
      double rotationOffset, Paint paint, int segments) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPerSegment = (2 * pi) / segments;
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) continue; // Pula um sim, um não para tracejar fino
      final start = rotationOffset + i * sweepPerSegment;
      canvas.drawArc(rect, start, sweepPerSegment * 0.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReactorPainter oldDelegate) => true;
}
