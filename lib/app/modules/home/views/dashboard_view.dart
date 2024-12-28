// lib/app/modules/home/views/dashboard_view.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_app_controller/app/modules/home/widgets/StatCard.dart';
import 'package:mobile_app_controller/app/modules/home/widgets/alert_list.dart';
import '../controllers/home_controller.dart';
import '../widgets/motion_chart.dart';

class DashboardView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 32),
            _buildStatCards(),
            SizedBox(height: 32),
            _buildCharts(),
            SizedBox(height: 32),
            _buildRecentAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Dashboard',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Real-time monitoring and analytics',
              style: Get.textTheme.titleMedium?.copyWith(
                color: Get.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'Today', label: Text('Today')),
            ButtonSegment(value: 'Week', label: Text('Week')),
            ButtonSegment(value: 'Month', label: Text('Month')),
          ],
          selected: {controller.selectedTimeRange.value},
          onSelectionChanged: (Set<String> newSelection) {
            controller.changeTimeRange(newSelection.first);
          },
        ),
        SizedBox(width: 16),
        Obx(() => Switch(
          value: controller.systemActive.value,
          onChanged: (_) => controller.toggleSystem(),
        )),
      ],
    );
  }

  Widget _buildStatCards() {
    return Obx(() {
      final stats = controller.stats.value;
      if (stats == null) return SizedBox();

      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          StatCard(
            title: 'Total Alerts',
            value: stats.totalAlerts.toString(),
            icon: Icons.notifications,
            color: Get.theme.colorScheme.primary,
            trend: 5,
          ),
          StatCard(
            title: 'Red Alerts',
            value: stats.redAlerts.toString(),
            icon: Icons.warning,
            color: Colors.red,
            trend: -2,
          ),
          StatCard(
            title: 'Yellow Alerts',
            value: stats.yellowAlerts.toString(),
            icon: Icons.warning_amber,
            color: Colors.amber,
            trend: 3,
          ),
          StatCard(
            title: 'Average Motion',
            value: '${stats.averageMotion.toStringAsFixed(1)}°',
            icon: Icons.motion_photos_on,
            color: Get.theme.colorScheme.tertiary,
            trend: 1,
          ),
        ],
      );
    });
  }

  Widget _buildCharts() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motion Activity',
                    style: Get.textTheme.titleLarge,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: MotionChart(),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts by Hour',
                    style: Get.textTheme.titleLarge,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildAlertsByHourChart(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsByHourChart() {
    return Obx(() {
      final data = controller.stats.value?.alertsByHour ?? {};
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isEmpty ? 10 : data.values.reduce(max).toDouble() * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (spot) => Get.theme.colorScheme.surfaceVariant,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()} alerts',
                  Get.textTheme.bodyMedium!,
                );
              },
            ),
          ),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
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
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '${value.toInt()}h',
                      style: Get.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.entries.map((entry) {
            return BarChartGroupData(
              x: int.parse(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  gradient: LinearGradient(
                    colors: [
                      Get.theme.colorScheme.primary,
                      Get.theme.colorScheme.primaryContainer,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildRecentAlerts() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Alerts', style: Get.textTheme.titleLarge),
                TextButton.icon(
                  onPressed: () => controller.currentView.value = 1,
                  icon: Icon(Icons.history),
                  label: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 16),
            AlertList(
              logs: controller.logs.take(5).toList(),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
