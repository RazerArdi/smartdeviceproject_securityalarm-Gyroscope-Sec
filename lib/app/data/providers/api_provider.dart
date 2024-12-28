// lib/app/data/providers/api_provider.dart
import 'package:get/get.dart';
import 'package:mobile_app_controller/app/data/models/dashboard_stats.dart';
import 'package:mobile_app_controller/app/data/models/security_log.dart';

class ApiProvider extends GetConnect {
  static const String apiBaseUrl = 'http://192.168.18.14/UAP/upload.php';

  @override
  void onInit() {
    httpClient.baseUrl = apiBaseUrl;
    httpClient.defaultDecoder = (map) {
      if (map is Map<String, dynamic>) return SecurityLog.fromJson(map);
      if (map is List) return map.map((item) => SecurityLog.fromJson(item)).toList();
    };
    super.onInit();
  }

  Future<List<SecurityLog>> getLogs() async {
    final response = await get('?endpoint=get_all_logs');
    if (response.hasError) {
      throw response.statusText!;
    }
    return response.body;
  }

  Future<DashboardStats> getStats() async {
    final response = await get('?endpoint=get_stats');
    if (response.hasError) {
      throw response.statusText!;
    }
    return DashboardStats.fromJson(response.body);
  }
}
