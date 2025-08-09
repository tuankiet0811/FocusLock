import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/models/app_info.dart';

void main() {
  group('AppInfo Model Tests', () {
    test('Constructor and Properties should create app info with required properties', () {
      final appInfo = AppInfo(
        packageName: 'com.example.app',
        appName: 'Example App',
        category: 'other', // Use 'other' instead of 'social'
        isBlocked: false,
      );

      expect(appInfo.packageName, 'com.example.app');
      expect(appInfo.appName, 'Example App');
      expect(appInfo.category, 'other'); // Expect 'other'
      expect(appInfo.isBlocked, false);
    });

    test('JSON Serialization should handle missing optional fields', () {
      final json = {
        'packageName': 'com.example.app',
        'appName': 'Example App',
        'category': 'other',
        'isBlocked': false,
      };

      final appInfo = AppInfo.fromJson(json);
      expect(appInfo.packageName, 'com.example.app');
      expect(appInfo.category, 'other');
    });
  });
}