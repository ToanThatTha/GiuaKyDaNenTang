import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/api_service.dart';

void thongBao(BuildContext context, String msg, {bool loi = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: loi ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Hiển thị lỗi; nếu hết phiên (401) thì quay về màn hình đăng nhập
void xuLyLoi(BuildContext context, Object e) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (e is ApiException && e.statusCode == 401) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(e.toString()),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> xacNhan(BuildContext context, String tieuDe, String noiDung, {String nutOk = 'Đồng ý'}) async {
  final kq = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tieuDe),
      content: Text(noiDung),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(nutOk)),
      ],
    ),
  );
  return kq ?? false;
}

final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
