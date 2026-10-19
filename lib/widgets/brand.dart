import 'package:flutter/material.dart';
import '../main.dart';

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 29, height: 32, child: CustomPaint(painter: _StepMark())),
      SizedBox(width: 7),
      Text(
        'LangkahKerja',
        // The wordmark is part of the logo; page content still follows OS text size.
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -.7,
        ),
      ),
    ],
  );
}

class _StepMark extends CustomPainter {
  const _StepMark();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = plum;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * size.width / 3,
            (2 - i) * size.height / 3,
            size.width * .44,
            size.height * .44,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
