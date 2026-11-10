import 'package:flutter/foundation.dart';

class AppConfig {
  /// Chạy trên ĐIỆN THOẠI THẬT: điền IP LAN của máy tính chạy backend,
  /// ví dụ: 'http://192.168.1.5:3000' (xem bằng lệnh ipconfig trên Windows).
  /// Để trống '' nếu chạy Web (Chrome) hoặc máy ảo Android.
  static const String lanUrl = '';

  static String get baseUrl {
    if (lanUrl.isNotEmpty) return lanUrl;
    if (kIsWeb) return 'http://localhost:3000';
    // Máy ảo Android gọi về máy tính qua 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
}
