import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_app_controller/app/modules/home/widgets/alert_list.dart';
import '../controllers/home_controller.dart';

class HistoryView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert History',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Obx(
                        () {
                      return SizedBox.expand( // Add constraints here if AlertList requires size
                        child: AlertList(
                          logs: controller.logs,
                          showPagination: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
