// lib/app/modules/home/widgets/alert_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_controller/app/data/models/security_log.dart';

class AlertList extends StatelessWidget {
  final List<SecurityLog> logs;
  final bool showPagination;
  final bool compact;

  const AlertList({
    required this.logs,
    this.showPagination = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStateColor(log.state),
                  child: Icon(
                    _getStateIcon(log.state),
                    color: Colors.white,
                  ),
                ),
                title: Text(log.message),
                subtitle: Text(
                  DateFormat('MMM d, y HH:mm').format(log.timestamp),
                ),
                trailing: log.imageUrl != null
                    ? IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () => _showImage(context, log.imageUrl!),
                )
                    : null,
              );
            },
          ),
        ),
        if (showPagination)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.chevron_left),
                ),
                Text('Page 1 of 5'),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getStateColor(String state) {
    switch (state.toUpperCase()) {
      case 'RED':
        return Colors.red;
      case 'YELLOW':
        return Colors.amber;
      case 'GREEN':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state.toUpperCase()) {
      case 'RED':
        return Icons.warning;
      case 'YELLOW':
        return Icons.warning_amber;
      case 'GREEN':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  void _showImage(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Alert Image'),
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ),
            Image.network(imageUrl),
          ],
        ),
      ),
    );
  }
}