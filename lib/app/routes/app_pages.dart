// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import 'package:mobile_app_controller/app/modules/home/bindings/auth_binding.dart';
import 'package:mobile_app_controller/app/modules/home/views/login_view.dart';
import 'package:mobile_app_controller/main.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
  ];
}