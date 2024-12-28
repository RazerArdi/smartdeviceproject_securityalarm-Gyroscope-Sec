// lib/app/modules/home/widgets/motion_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_app_controller/app/modules/home/controllers/home_controller.dart';
import 'package:intl/intl.dart'; // Import the intl package

class MotionChart extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.stats.value?.motionHistory ?? [];
      if (data.isEmpty) return Center(child: Text('No motion data available'));

      return LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}°',
                    Get.textTheme.bodyMedium!,
                  );
                }).toList();
              },
              getTooltipColor: (spot) => Get.theme.colorScheme.surfaceVariant,
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 10,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°',
                    style: Get.textTheme.bodySmall,
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: Get.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.map((item) {
                return FlSpot(
                  item.timestamp.millisecondsSinceEpoch.toDouble(),
                  item.value,
                );
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Get.theme.colorScheme.primary,
                  Get.theme.colorScheme.tertiary,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Get.theme.colorScheme.primary.withOpacity(0.2),
                    Get.theme.colorScheme.tertiary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
