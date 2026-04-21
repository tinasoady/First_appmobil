import 'package:flutter/material.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Services', style: TextStyle(fontSize: 24)),
            Text('Liste des services disponibles'),
          ],
        ),
      ),
    );
  }
}