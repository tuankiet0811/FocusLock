import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:focuslock/screens/home_screen.dart';
import 'package:focuslock/services/focus_service.dart';
import 'package:focuslock/services/auth_service.dart';
import '../test_helper.dart';
import '../mocks/test_data.dart';
import '../mocks/mock_services.dart';

void main() {
  group('HomeScreen Tests', () {
    late MockFocusService mockFocusService;
    late MockAuthService mockAuthService;

    setUp(() async {
      await TestHelper.setupTestEnvironment();
      mockFocusService = MockFocusService();
      mockAuthService = MockAuthService();
    });

    tearDown(() async {
      TestHelper.cleanup();
    });

    testWidgets('should render home screen correctly', (WidgetTester tester) async {
      reset(mockFocusService);
      reset(mockAuthService);
      
      when(mockFocusService.sessions).thenReturn([]);
      when(mockFocusService.isActive).thenReturn(false);
      when(mockAuthService.isLoggedIn).thenReturn(true);
      when(mockAuthService.currentUser).thenReturn(TestData.createTestUser());
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FocusService>.value(value: mockFocusService),
            ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // Cleanup properly
      await tester.binding.setSurfaceSize(null);
    });
  });
}