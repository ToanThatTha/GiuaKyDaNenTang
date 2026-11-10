import 'dart:async';

import 'package:flutter/material.dart';

import '../models/nguoi_dung.dart';
import '../services/api_service.dart';
import '../utils.dart';
import '../widgets/anh_dai_dien.dart';
import 'login_screen.dart';
import 'user_detail_screen.dart';
import 'user_form_screen.dart';

enum SapXep { moiNhat, tenAZ, tenZA, email }

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _timKiem = TextEditingController();
  Timer? _debounce;
  List<NguoiDung> _ds = [];
  bool _dangTai = true;
  String? _loi;
  SapXep _sapXep = SapXep.moiNhat;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _timKiem.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final ds = await ApiService.layDanhSach(q: _timKiem.text.trim());
      if (!mounted) return;
      setState(() => _ds = _sapXepDs(ds));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loi = e.toString());
      xuLyLoi(context, e);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  List<NguoiDung> _sapXepDs(List<NguoiDung> ds) {
    final kq = [...ds];
    switch (_sapXep) {
      case SapXep.moiNhat:
        break; // server đã sắp xếp mới nhất trước
      case SapXep.tenAZ:
        kq.sort((a, b) => a.hoten.toLowerCase().compareTo(b.hoten.toLowerCase()));
      case SapXep.tenZA:
        kq.sort((a, b) => b.hoten.toLowerCase().compareTo(a.hoten.toLowerCase()));
      case SapXep.email:
        kq.sort((a, b) => a.email.compareTo(b.email));
    }
    return kq;
  }

  void _onTimKiem(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _tai);
    setState(() {}); // cập nhật nút xóa ô tìm kiếm
  }

  Future<void> _moForm([NguoiDung? user]) async {
    final doi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (doi == true) _tai();
  }

  Future<void> _moChiTiet(NguoiDung user) async {
    final doi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    );
    if (doi == true) _tai();
  }

  Future<void> _xoa(NguoiDung user) async {
    if (user.id == ApiService.currentUser?.id) {
      thongBao(context, 'Không thể tự xóa tài khoản đang đăng nhập', loi: true);
      return;
    }
    final ok = await xacNhan(context, 'Xóa người dùng', 'Bạn chắc chắn muốn xóa "${user.hoten}"?', nutOk: 'Xóa');
    if (!ok || !mounted) return;
    try {
      await ApiService.xoa(user.id);
      if (!mounted) return;
      setState(() => _ds.removeWhere((e) => e.id == user.id));
      thongBao(context, 'Đã xóa ${user.hoten}');
    } catch (e) {
      if (mounted) xuLyLoi(context, e);
    }
  }

  Future<void> _dangXuat() async {
    final ok = await xacNhan(context, 'Đăng xuất', 'Bạn muốn đăng xuất?');
    if (!ok) return;
    await ApiService.dangXuat();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          PopupMenuButton<SapXep>(
            tooltip: 'Sắp xếp',
            icon: const Icon(Icons.sort),
            initialValue: _sapXep,
            onSelected: (v) {
              _sapXep = v;
              if (v == SapXep.moiNhat) {
                _tai();
              } else {
                setState(() => _ds = _sapXepDs(_ds));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: SapXep.moiNhat, child: Text('Mới nhất')),
              PopupMenuItem(value: SapXep.tenAZ, child: Text('Tên A → Z')),
              PopupMenuItem(value: SapXep.tenZA, child: Text('Tên Z → A')),
              PopupMenuItem(value: SapXep.email, child: Text('Theo email')),
            ],
          ),
          IconButton(tooltip: 'Tải lại', onPressed: _tai, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Đăng xuất', onPressed: _dangXuat, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _moForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              if (me != null)
                ListTile(
                  leading: AnhDaiDien(hoten: me.hoten, bytes: me.anhBytes, url: me.hinhanh),
                  title: Text('Xin chào, ${me.hoten}'),
                  subtitle: Text(me.email),
                  trailing: TextButton(onPressed: () => _moForm(me), child: const Text('Hồ sơ')),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _timKiem,
                  onChanged: _onTimKiem,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo họ tên hoặc email...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _timKiem.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _timKiem.clear();
                              _onTimKiem('');
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tổng: ${_ds.length} người dùng', style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: _noiDung()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai && _ds.isEmpty) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _tai,
      child: _ds.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Icon(_loi != null ? Icons.cloud_off : Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  _loi ?? (_timKiem.text.isEmpty ? 'Chưa có người dùng nào' : 'Không tìm thấy kết quả'),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
              itemCount: _ds.length,
              itemBuilder: (_, i) {
                final u = _ds[i];
                final laToi = u.id == ApiService.currentUser?.id;
                return Card(
                  child: ListTile(
                    onTap: () => _moChiTiet(u),
                    leading: Hero(
                      tag: 'avatar_${u.id}',
                      child: AnhDaiDien(hoten: u.hoten, bytes: u.anhBytes, url: u.hinhanh),
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(u.hoten, overflow: TextOverflow.ellipsis)),
                        if (laToi) ...[
                          const SizedBox(width: 6),
                          const Chip(label: Text('Bạn'), visualDensity: VisualDensity.compact),
                        ],
                      ],
                    ),
                    subtitle: Text(u.email, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'xem') _moChiTiet(u);
                        if (v == 'sua') _moForm(u);
                        if (v == 'xoa') _xoa(u);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'xem', child: ListTile(leading: Icon(Icons.visibility), title: Text('Xem'))),
                        const PopupMenuItem(value: 'sua', child: ListTile(leading: Icon(Icons.edit), title: Text('Sửa'))),
                        PopupMenuItem(
                          value: 'xoa',
                          enabled: !laToi,
                          child: const ListTile(
                              leading: Icon(Icons.delete, color: Colors.red), title: Text('Xóa')),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
