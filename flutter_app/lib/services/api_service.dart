import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/nguoi_dung.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const _kToken = 'token';
  static const _kUser = 'user';

  static String? _token;
  static NguoiDung? currentUser;

  // ---------- Gọi HTTP chung ----------
  static Future<dynamic> _goi(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final req = http.Request(method, uri);
    req.headers['Content-Type'] = 'application/json; charset=utf-8';
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu (${AppConfig.baseUrl})');
    } catch (_) {
      throw ApiException('Không kết nối được máy chủ ${AppConfig.baseUrl}.\nKiểm tra backend đã chạy chưa.');
    }

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final msg = (data is Map && data['message'] != null) ? data['message'].toString() : 'Lỗi ${res.statusCode}';
    if (res.statusCode == 401 && path != '/api/auth/login') await _xoaPhien();
    throw ApiException(msg, res.statusCode);
  }

  // ---------- Phiên đăng nhập ----------
  static Future<void> _luuPhien(String token, NguoiDung user) async {
    _token = token;
    currentUser = user;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  static Future<void> _capNhatUserHienTai(NguoiDung user) async {
    currentUser = user;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  static Future<void> _xoaPhien() async {
    _token = null;
    currentUser = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUser);
  }

  /// Mở app: nếu còn token hợp lệ thì vào thẳng màn hình quản lý
  static Future<bool> khoiPhucPhien() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_kToken);
    if (_token == null) return false;
    try {
      final data = await _goi('GET', '/api/auth/me');
      await _capNhatUserHienTai(NguoiDung.fromJson(data));
      return true;
    } catch (_) {
      await _xoaPhien();
      return false;
    }
  }

  static Future<NguoiDung> dangNhap(String email, String matkhau) async {
    final data = await _goi('POST', '/api/auth/login', body: {'email': email, 'matkhau': matkhau});
    final user = NguoiDung.fromJson(data['user']);
    await _luuPhien(data['token'], user);
    return user;
  }

  static Future<void> dangXuat() => _xoaPhien();

  // ---------- CRUD người dùng ----------
  static Future<List<NguoiDung>> layDanhSach({String q = ''}) async {
    final path = q.isEmpty ? '/api/users' : '/api/users?q=${Uri.encodeQueryComponent(q)}';
    final data = await _goi('GET', path) as List;
    return data.map((e) => NguoiDung.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<NguoiDung> layMot(String id) async {
    return NguoiDung.fromJson(await _goi('GET', '/api/users/$id'));
  }

  static Future<NguoiDung> them({
    required String email,
    required String matkhau,
    required String hoten,
    required String hinhanh,
  }) async {
    final data = await _goi('POST', '/api/users', body: {
      'email': email,
      'matkhau': matkhau,
      'hoten': hoten,
      'hinhanh': hinhanh,
    });
    return NguoiDung.fromJson(data);
  }

  /// matkhau rỗng = giữ nguyên mật khẩu cũ
  static Future<NguoiDung> sua(
    String id, {
    required String email,
    required String hoten,
    required String hinhanh,
    String matkhau = '',
  }) async {
    final body = <String, dynamic>{'email': email, 'hoten': hoten, 'hinhanh': hinhanh};
    if (matkhau.isNotEmpty) body['matkhau'] = matkhau;
    final user = NguoiDung.fromJson(await _goi('PUT', '/api/users/$id', body: body));
    if (user.id == currentUser?.id) await _capNhatUserHienTai(user);
    return user;
  }

  static Future<void> xoa(String id) async {
    await _goi('DELETE', '/api/users/$id');
  }
}
