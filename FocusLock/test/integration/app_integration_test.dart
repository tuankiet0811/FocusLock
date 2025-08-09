import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:focuslock/services/focus_service.dart';
import 'package:focuslock/services/auth_service.dart';
import 'package:focuslock/screens/login_screen.dart';
import 'package:focuslock/screens/home_screen.dart';
import '../test_helper.dart';
import '../mocks/mock_services.dart';

void main() {
  group('App Integration Tests', () {
    late MockFocusService mockFocusService;
    late MockAuthService mockAuthService;

    setUp(() async {
      await TestHelper.setupTestEnvironment();
      mockFocusService = MockFocusService();
      mockAuthService = MockAuthService();
      
      // Mock authStateChanges to return a stream with no user (logged out state)
      when(mockAuthService.authStateChanges())
          .thenAnswer((_) => Stream.value(null));
    });

    testWidgets('App starts and displays basic UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FocusService>.value(value: mockFocusService),
            ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ],
          child: MaterialApp(
            title: 'FocusLock Test',
            home: AuthGate(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Test that the MaterialApp is created
      expect(find.byType(MaterialApp), findsOneWidget);
      // Since authStateChanges returns null, should show LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final focusService = Provider.of<FocusService>(context, listen: false);
    
    return StreamBuilder(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Có lỗi xảy ra khi xác thực!')),
          );
        }
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            focusService.loadUserData();
          });
          return HomeScreen();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await focusService.clearUserData();
          });
          return LoginScreen();
        }
      },
    );
  }
}