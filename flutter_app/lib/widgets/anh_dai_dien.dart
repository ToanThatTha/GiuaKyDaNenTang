import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Ảnh đại diện: ảnh base64 -> ảnh URL -> chữ cái đầu của tên
class AnhDaiDien extends StatelessWidget {
  final String hoten;
  final Uint8List? bytes;
  final String url;
  final double radius;

  const AnhDaiDien({
    super.key,
    required this.hoten,
    this.bytes,
    this.url = '',
    this.radius = 24,
  });

  static const _mau = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.brown,
  ];

  String get _chuCai {
    final parts = hoten.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.last.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (bytes != null) {
      img = MemoryImage(bytes!);
    } else if (url.startsWith('http')) {
      img = NetworkImage(url);
    }
    final mau = _mau[hoten.hashCode.abs() % _mau.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: img == null ? mau : Colors.grey.shade200,
      backgroundImage: img,
      child: img == null
          ? Text(_chuCai, style: TextStyle(color: Colors.white, fontSize: radius * 0.8, fontWeight: FontWeight.bold))
          : null,
    );
  }
}
