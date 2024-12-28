// lib/app/modules/home/controllers/home_controller.dart
import 'package:get/get.dart';
import 'package:mobile_app_controller/app/data/models/dashboard_stats.dart';
import 'package:mobile_app_controller/app/data/models/security_log.dart';
import '../../../data/providers/api_provider.dart';

class HomeController extends GetxController {
  final ApiProvider apiProvider = Get.find<ApiProvider>();
  var logs = <SecurityLog>[].obs;
  final stats = Rxn<DashboardStats>();
  final isLoading = false.obs;
  final systemActive = false.obs;
  final selectedTimeRange = 'Today'.obs;
  final currentView = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    setupRefreshTimer();
  }

  void setupRefreshTimer() {
    ever(systemActive, (_) {
      if (systemActive.value) {
        fetchDashboardData();
      }
    });
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        apiProvider.getLogs(),
        apiProvider.getStats(),
      ]);
      logs.value = results[0] as List<SecurityLog>;
      stats.value = results[1] as DashboardStats;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSystem() {
    systemActive.value = !systemActive.value;
  }

  void changeTimeRange(String range) {
    selectedTimeRange.value = range;
    fetchDashboardData();
  }
}
