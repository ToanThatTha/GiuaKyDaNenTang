import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_service.dart';
import '../utils.dart';
import 'user_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _matkhau = TextEditingController();
  bool _anMatKhau = true;
  bool _dangXuLy = false;

  @override
  void dispose() {
    _email.dispose();
    _matkhau.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangXuLy = true);
    try {
      final user = await ApiService.dangNhap(_email.text.trim(), _matkhau.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UserListScreen()));
      thongBao(context, 'Xin chào ${user.hoten}!');
    } catch (e) {
      if (mounted) thongBao(context, e.toString(), loi: true);
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 72, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text('Đăng nhập quản trị',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Vui lòng nhập email';
                          if (!emailRegex.hasMatch(s)) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _matkhau,
                        obscureText: _anMatKhau,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _dangNhap(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_anMatKhau ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                          ),
                        ),
                        validator: (v) => (v ?? '').isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _dangXuLy ? null : _dangNhap,
                        icon: _dangXuLy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.login),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Đăng nhập'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tài khoản mặc định: admin@gmail.com / 123456\nServer: ${AppConfig.baseUrl}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
