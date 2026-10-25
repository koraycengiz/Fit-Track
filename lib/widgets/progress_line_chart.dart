
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/daily_entry.dart';

enum ProgressMetric {
  weight,
  calories,
  protein,
}

class ProgressLineChart extends StatelessWidget {
  final List<DailyEntry> entries;
  final ProgressMetric metric;

  const ProgressLineChart({
    super.key,
    required this.entries,
    required this.metric,
  });

  String get _metricName {
    switch (metric) {
      case ProgressMetric.weight:
        return 'Weight';
      case ProgressMetric.calories:
        return 'Calories';
      case ProgressMetric.protein:
        return 'Protein';
    }
  }

  String get _unit {
    switch (metric) {
      case ProgressMetric.weight:
        return 'kg';
      case ProgressMetric.calories:
        return 'kcal';
      case ProgressMetric.protein:
        return 'g';
    }
  }

  double? _valueOf(DailyEntry entry) {
    switch (metric) {
      case ProgressMetric.weight:
        return entry.weight;
      case ProgressMetric.calories:
        return entry.calories?.toDouble();
      case ProgressMetric.protein:
        return entry.protein;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recorded = entries
        .where((entry) => _valueOf(entry) != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recorded.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text('No data available for this period'),
        ),
      );
    }

    final firstDate = recorded.first.date;

    final spots = recorded.map((entry) {
      final x = entry.date.difference(firstDate).inDays.toDouble();
      return FlSpot(x, _valueOf(entry)!);
    }).toList();

    final values = spots.map((spot) => spot.y).toList();

    final lowest = values.reduce(
          (a, b) => a < b ? a : b,
    );

    final highest = values.reduce(
          (a, b) => a > b ? a : b,
    );

    final padding = highest == lowest
        ? (highest.abs() * 0.05).clamp(1.0, double.infinity)
        : (highest - lowest) * 0.15;

    final minY = lowest - padding;
    final maxY = highest + padding;

    final maxX = spots.last.x;

    final color = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_metricName ($_unit)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX == 0 ? 1 : maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant,
                      strokeWidth: 0.5,
                    ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: maxX <= 7 ? 1 : 5,
                    getTitlesWidget: (value, meta) {
                      final date = firstDate.add(
                        Duration(days: value.round()),
                      );

                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toStringAsFixed(
                            metric == ProgressMetric.weight ? 1 : 0,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = firstDate.add(
                        Duration(days: spot.x.round()),
                      );

                      final formattedValue = spot.y.toStringAsFixed(
                        metric == ProgressMetric.weight ? 1 : 0,
                      );

                      return LineTooltipItem(
                        '${date.day}/${date.month}\n'
                            '$formattedValue $_unit',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
