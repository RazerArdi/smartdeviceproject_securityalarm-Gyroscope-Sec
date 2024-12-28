// lib/app/modules/auth/bindings/auth_binding.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_app_controller/app/modules/home/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
  }
}


