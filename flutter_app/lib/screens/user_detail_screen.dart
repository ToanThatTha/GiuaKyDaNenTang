import 'package:flutter/material.dart';

import '../models/nguoi_dung.dart';
import '../services/api_service.dart';
import '../utils.dart';
import '../widgets/anh_dai_dien.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final NguoiDung user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late NguoiDung _user = widget.user;
  bool _daThayDoi = false;

  bool get _laToi => _user.id == ApiService.currentUser?.id;

  Future<void> _sua() async {
    final doi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: _user)),
    );
    if (doi != true) return;
    _daThayDoi = true;
    try {
      final moi = await ApiService.layMot(_user.id);
      if (mounted) setState(() => _user = moi);
    } catch (e) {
      if (mounted) xuLyLoi(context, e);
    }
  }

  Future<void> _xoa() async {
    final ok = await xacNhan(context, 'Xóa người dùng', 'Bạn chắc chắn muốn xóa "${_user.hoten}"?', nutOk: 'Xóa');
    if (!ok || !mounted) return;
    try {
      await ApiService.xoa(_user.id);
      if (!mounted) return;
      thongBao(context, 'Đã xóa ${_user.hoten}');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) xuLyLoi(context, e);
    }
  }

  void _xemAnhLon() {
    final bytes = _user.anhBytes;
    if (bytes == null && !_user.hinhanh.startsWith('http')) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: bytes != null ? Image.memory(bytes) : Image.network(_user.hinhanh),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _daThayDoi);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Thông tin người dùng')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _xemAnhLon,
                    child: Hero(
                      tag: 'avatar_${_user.id}',
                      child: AnhDaiDien(hoten: _user.hoten, bytes: _user.anhBytes, url: _user.hinhanh, radius: 64),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_user.hoten,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (_laToi) const Padding(padding: EdgeInsets.only(top: 6), child: Chip(label: Text('Tài khoản của bạn'))),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      children: [
                        ListTile(leading: const Icon(Icons.person), title: const Text('Họ tên'), subtitle: Text(_user.hoten)),
                        const Divider(height: 1),
                        ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(_user.email)),
                        const Divider(height: 1),
                        const ListTile(
                            leading: Icon(Icons.lock), title: Text('Mật khẩu'), subtitle: Text('•••••••• (đã mã hóa)')),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.image),
                          title: const Text('Hình ảnh'),
                          subtitle: Text(_user.hinhanh.isEmpty ? 'Chưa có ảnh' : 'Đã có ảnh (chạm ảnh để phóng to)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(onPressed: _sua, icon: const Icon(Icons.edit), label: const Text('Sửa')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _laToi ? null : _xoa,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
