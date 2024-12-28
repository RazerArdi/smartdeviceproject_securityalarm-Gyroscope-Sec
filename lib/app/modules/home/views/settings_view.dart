// lib/app/modules/home/views/settings_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class SettingsView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Card(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text('Motion Sensitivity'),
                    subtitle: Text('Adjust motion detection threshold'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text('Notification Settings'),
                    subtitle: Text('Configure alert notifications'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text('Camera Settings'),
                    subtitle: Text('Adjust camera parameters'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text('System Maintenance'),
                    subtitle: Text('Backup and restore settings'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

