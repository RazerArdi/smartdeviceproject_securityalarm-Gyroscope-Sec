// lib/app/data/models/security_log.dart
class SecurityLog {
  final int id;
  final String state;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final double motionDegree;

  SecurityLog({
    required this.id,
    required this.state,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    required this.motionDegree,
  });

  factory SecurityLog.fromJson(Map<String, dynamic> json) {
    return SecurityLog(
      id: json['id'],
      state: json['state'],
      message: json['message'],
      imageUrl: json['image'],
      timestamp: DateTime.parse(json['timestamp']),
      motionDegree: double.parse(json['motion_degree'] ?? '0.0'),
    );
  }
}