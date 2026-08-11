import 'package:flutter/material.dart';

class BarChartPoint {
  const BarChartPoint(this.label, this.value);

  final String label;
  final int value;
}

/// Grafik batang ringan berbasis widget Flutter murni (tanpa dependensi
/// pihak ketiga) agar tetap cepat dibangun/dirender di web & mobile.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.points,
    this.color,
    this.height = 150,
  });

  final List<BarChartPoint> points;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = color ?? scheme.primary;
    final maxValue = points.fold<int>(0, (m, p) => p.value > m ? p.value : m);

    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Belum ada data.')),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${points[i].value}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.16),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                        child: FractionallySizedBox(
                          heightFactor: maxValue == 0
                              ? 0
                              : (points[i].value / maxValue).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: points[i].value == 0
                                  ? Colors.transparent
                                  : barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      points[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
