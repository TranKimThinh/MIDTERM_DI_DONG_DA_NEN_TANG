import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/product_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ProductRepository repository = await _createRepository();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AdminProvider(repository),
      child: const AdminProductApp(),
    ),
  );
}

Future<ProductRepository> _createRepository() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final isPlaceholder =
        options.apiKey.startsWith('YOUR_') ||
        options.projectId.startsWith('YOUR_');

    if (isPlaceholder) {
      return LocalDemoProductRepository();
    }

    await Firebase.initializeApp(options: options);
    return FirestoreProductRepository();
  } catch (e) {
    debugPrint('Firebase chưa sẵn sàng, chuyển sang chế độ Demo tạm: $e');
    return LocalDemoProductRepository();
  }
}

class AdminProductApp extends StatelessWidget {
  const AdminProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Sản Phẩm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          return provider.isAuthenticated
              ? const AdminDashboardScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
