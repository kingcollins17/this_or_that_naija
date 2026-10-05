import 'package:flutter/material.dart';

class StatsProgressBar extends StatelessWidget {
  final double percentA;
  final double percentB;

  const StatsProgressBar({
    super.key,
    required this.percentA,
    required this.percentB,
  });

  @override
  Widget build(BuildContext context) {
    final double flexA = percentA.clamp(0.0, 100.0);
    final double flexB = percentB.clamp(0.0, 100.0);
    final int intA = (flexA * 10).toInt();
    final int intB = (flexB * 10).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 12,
        width: double.infinity,
        color: Colors.grey.shade800,
        child: Row(
          children: [
            if (intA > 0)
              Expanded(
                flex: intA,
                child: Container(color: const Color(0xFF007A3D)),
              ),
            if (intB > 0)
              Expanded(
                flex: intB,
                child: Container(color: const Color(0xFFC62828)),
              ),
          ],
        ),
      ),
    );
  }
}
