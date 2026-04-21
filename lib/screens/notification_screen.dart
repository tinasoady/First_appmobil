import 'package:flutter/material.dart';


class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text('Notifications', style: TextStyle(fontSize: 24)),
          Text('Aucune notification pour le moment'),
        ],
      ),
    );
  }
}
