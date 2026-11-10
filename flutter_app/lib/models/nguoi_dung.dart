import 'dart:convert';
import 'dart:typed_data';

/// Model khớp đúng các trường trong MongoDB: email, matkhau, hoten, hinhanh
/// (_id do MongoDB tự sinh; matkhau không bao giờ được server trả về)
class NguoiDung {
  final String id;
  final String email;
  final String hoten;
  final String hinhanh; // data URI base64 hoặc URL

  NguoiDung({
    required this.id,
    required this.email,
    required this.hoten,
    this.hinhanh = '',
  });

  factory NguoiDung.fromJson(Map<String, dynamic> j) => NguoiDung(
        id: (j['_id'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        hoten: (j['hoten'] ?? '').toString(),
        hinhanh: (j['hinhanh'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'hoten': hoten,
        'hinhanh': hinhanh,
      };

  /// Giải mã ảnh 1 lần, dùng lại khi vẽ danh sách
  late final Uint8List? anhBytes = giaiMaAnh(hinhanh);
}

Uint8List? giaiMaAnh(String s) {
  if (s.isEmpty || !s.startsWith('data:')) return null;
  try {
    final i = s.indexOf(',');
    return base64Decode(s.substring(i + 1));
  } catch (_) {
    return null;
  }
}
