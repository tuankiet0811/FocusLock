import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class TestHelper {
  /// Setup test environment with necessary configurations
  static Future<void> setupTestEnvironment() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
     await SharedPreferences.getInstance();
    // Mock MethodChannel for platform-specific calls
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{};
      }
      return null;
    });
    
    // Mock notification channel
    const MethodChannel('dexterous.com/flutter/local_notifications')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
    
    // Mock app blocking channel
    const MethodChannel('com.focuslock/app_blocking')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
    
    // Mock Firebase Core channel
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'fake-api-key',
                'appId': 'fake-app-id',
                'messagingSenderId': 'fake-sender-id',
                'projectId': 'fake-project-id',
              },
              'pluginConstants': {},
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          };
        default:
          return null;
      }
    });
    
    // Mock Firebase Auth channels
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Auth#registerIdTokenListener':
        case 'Auth#registerAuthStateListener':
          return null;
        case 'Auth#authStateChanges':
          return null;
        default:
          return null;
      }
    });
    
    // Mock Cloud Firestore channels
    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firestore#settings':
        case 'Firestore#enableNetwork':
        case 'Firestore#disableNetwork':
          return null;
        default:
          return null;
      }
    });
  }
  
  /// Cleanup test environment
  static void cleanup() {
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler(null);
    const MethodChannel('dexterous.com/flutter/local_notifications')
        .setMockMethodCallHandler(null);
    const MethodChannel('com.focuslock/app_blocking')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler(null);
  }
  
  /// Create a test widget with providers
  static Widget createTestWidget({
    required Widget child,
    List<ChangeNotifierProvider>? providers,
  }) {
    return MaterialApp(
      home: providers != null
          ? MultiProvider(
              providers: providers,
              child: child,
            )
          : child,
    );
  }
  
  /// Pump and settle with timeout - improved version
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    try {
      await tester.pumpAndSettle(timeout);
    } catch (e) {
      // If pumpAndSettle times out, try pump with intervals
      final end = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(end)) {
        await tester.pump(interval);
        if (tester.binding.hasScheduledFrame == false) {
          break;
        }
      }
    }
  }
  
  /// Wait for a specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw TimeoutException('Widget not found within timeout', timeout);
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}