import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UhvaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool horizontal;

  const UhvaLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: UhvaColors.primary,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.5, size * 0.5),
          painter: _PlayTrianglePainter(),
        ),
      ),
    );

    if (!showText) return icon;

    final text = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'UHVA ',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          TextSpan(
            text: 'Player',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w400,
              color: UhvaColors.primaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 10),
          text,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 10),
        text,
      ],
    );
  }
}

class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.15, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.15, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
