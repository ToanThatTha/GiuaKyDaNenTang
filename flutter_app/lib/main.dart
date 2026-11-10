import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/user_list_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý người dùng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const KhoiDong(),
    );
  }
}

/// Kiểm tra phiên đăng nhập cũ rồi chọn màn hình phù hợp
class KhoiDong extends StatefulWidget {
  const KhoiDong({super.key});

  @override
  State<KhoiDong> createState() => _KhoiDongState();
}

class _KhoiDongState extends State<KhoiDong> {
  late final Future<bool> _future = ApiService.khoiPhucPhien();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == true ? const UserListScreen() : const LoginScreen();
      },
    );
  }
}
