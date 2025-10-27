import 'package:flutter/material.dart';
import 'presentation/app_initializer.dart';
import 'services/api_client.dart';

void main() {
  // Initialize API client before running app
  ApiClient().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Storedo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AppInitializer(),
    );
  }
}
