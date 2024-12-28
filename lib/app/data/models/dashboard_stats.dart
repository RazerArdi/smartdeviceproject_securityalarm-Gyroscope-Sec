// lib/app/data/models/dashboard_stats.dart
class DashboardStats {
  final int totalAlerts;
  final int redAlerts;
  final int yellowAlerts;
  final double averageMotion;
  final List<MotionData> motionHistory;
  final Map<String, int> alertsByHour;

  DashboardStats({
    required this.totalAlerts,
    required this.redAlerts,
    required this.yellowAlerts,
    required this.averageMotion,
    required this.motionHistory,
    required this.alertsByHour,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAlerts: json['total_alerts'] ?? 0,
      redAlerts: json['red_alerts'] ?? 0,
      yellowAlerts: json['yellow_alerts'] ?? 0,
      averageMotion: (json['average_motion'] ?? 0).toDouble(),
      motionHistory: (json['motion_history'] as List<dynamic>?)
          ?.map((item) => MotionData.fromJson(item))
          .toList() ??
          [],
      alertsByHour: Map<String, int>.from(json['alerts_by_hour'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_alerts': totalAlerts,
      'red_alerts': redAlerts,
      'yellow_alerts': yellowAlerts,
      'average_motion': averageMotion,
      'motion_history': motionHistory.map((item) => item.toJson()).toList(),
      'alerts_by_hour': alertsByHour,
    };
  }
}

class MotionData {
  final DateTime timestamp;
  final double value;

  MotionData(this.timestamp, this.value);

  factory MotionData.fromJson(Map<String, dynamic> json) {
    return MotionData(
      DateTime.parse(json['timestamp']),
      (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }
}
