import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/nguoi_dung.dart';
import '../services/api_service.dart';
import '../utils.dart';
import '../widgets/anh_dai_dien.dart';

/// Dùng chung cho Thêm (user == null) và Sửa (user != null)
class UserFormScreen extends StatefulWidget {
  final NguoiDung? user;
  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  late final _hoten = TextEditingController(text: widget.user?.hoten ?? '');
  final _matkhau = TextEditingController();
  final _xacNhan = TextEditingController();

  late String _hinhanh = widget.user?.hinhanh ?? ''; // data URI gửi lên server
  late Uint8List? _anhBytes = widget.user?.anhBytes; // để xem trước
  bool _anMatKhau = true;
  bool _dangLuu = false;

  bool get _laSua => widget.user != null;

  @override
  void dispose() {
    _email.dispose();
    _hoten.dispose();
    _matkhau.dispose();
    _xacNhan.dispose();
    super.dispose();
  }

  String _mime(XFile f) {
    if (f.mimeType != null && f.mimeType!.startsWith('image/')) return f.mimeType!;
    final ten = f.name.toLowerCase();
    if (ten.endsWith('.png')) return 'image/png';
    if (ten.endsWith('.gif')) return 'image/gif';
    if (ten.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _chonAnh(ImageSource nguon) async {
    try {
      final f = await ImagePicker().pickImage(
        source: nguon,
        maxWidth: 600, // thu nhỏ để lưu base64 trong MongoDB gọn nhẹ
        maxHeight: 600,
        imageQuality: 75,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        if (mounted) thongBao(context, 'Ảnh quá lớn (tối đa 3MB)', loi: true);
        return;
      }
      setState(() {
        _anhBytes = bytes;
        _hinhanh = 'data:${_mime(f)};base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (mounted) thongBao(context, 'Không chọn được ảnh: $e', loi: true);
    }
  }

  void _menuAnh() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(kIsWeb ? 'Chọn ảnh từ máy tính' : 'Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _chonAnh(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _chonAnh(ImageSource.camera);
                },
              ),
            if (_hinhanh.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _hinhanh = '';
                    _anhBytes = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _luu() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangLuu = true);
    try {
      if (_laSua) {
        await ApiService.sua(
          widget.user!.id,
          email: _email.text.trim(),
          hoten: _hoten.text.trim(),
          hinhanh: _hinhanh,
          matkhau: _matkhau.text,
        );
      } else {
        await ApiService.them(
          email: _email.text.trim(),
          matkhau: _matkhau.text,
          hoten: _hoten.text.trim(),
          hinhanh: _hinhanh,
        );
      }
      if (!mounted) return;
      thongBao(context, _laSua ? 'Đã cập nhật người dùng' : 'Đã thêm người dùng');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) xuLyLoi(context, e);
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_laSua ? 'Sửa người dùng' : 'Thêm người dùng')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _menuAnh,
                          child: AnhDaiDien(
                            hoten: _hoten.text.isEmpty ? '?' : _hoten.text,
                            bytes: _anhBytes,
                            url: _hinhanh,
                            radius: 56,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: Theme.of(context).colorScheme.primary,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: _menuAnh,
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Chạm vào ảnh để chọn hình', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _hoten,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}), // cập nhật chữ cái trên avatar
                    decoration: const InputDecoration(labelText: 'Họ tên', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Họ tên phải có ít nhất 2 ký tự' : null,
                  ),
                  const SizedBox(height: 16),
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
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      helperText: _laSua ? 'Để trống nếu không đổi mật khẩu' : null,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_anMatKhau ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                      ),
                    ),
                    validator: (v) {
                      final s = v ?? '';
                      if (_laSua && s.isEmpty) return null;
                      if (s.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _xacNhan,
                    obscureText: _anMatKhau,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _luu(),
                    decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu', prefixIcon: Icon(Icons.lock_reset)),
                    validator: (v) => (v ?? '') != _matkhau.text ? 'Mật khẩu nhập lại không khớp' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _dangLuu ? null : _luu,
                    icon: _dangLuu
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_laSua ? 'Lưu thay đổi' : 'Thêm người dùng'),
                    ),
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
