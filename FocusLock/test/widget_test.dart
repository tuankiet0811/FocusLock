import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:focuslock/screens/home_screen.dart';
import 'package:focuslock/services/focus_service.dart';
import 'package:focuslock/services/auth_service.dart';
import 'package:focuslock/widgets/focus_timer_widget.dart';
import 'package:focuslock/widgets/quick_start_widget.dart';
import 'package:focuslock/models/session_status.dart';
import 'test_helper.dart';
import 'mocks/mock_services.dart';
import 'mocks/test_data.dart';

void main() {
  group('HomeScreen Tests', () {
    late MockFocusService mockFocusService;
    late MockAuthService mockAuthService;

    setUp(() async {
      await TestHelper.setupTestEnvironment();
      mockFocusService = MockFocusService();
      mockAuthService = MockAuthService();
    });

    tearDown(() {
      TestHelper.cleanup();
    });

    Widget createHomeScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<FocusService>.value(value: mockFocusService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render home screen correctly', (WidgetTester tester) async {
        // Reset and setup mocks
        reset(mockFocusService);
        reset(mockAuthService);
        
        // Setup mock responses
        when(mockFocusService.sessions).thenReturn([]);
        when(mockFocusService.isActive).thenReturn(false);
        when(mockFocusService.currentSession).thenReturn(null);
        when(mockFocusService.remainingSeconds).thenReturn(0);
        when(mockFocusService.blockedApps).thenReturn([]);
        when(mockFocusService.hasSelectedApps).thenReturn(false);
        when(mockFocusService.selectedApps).thenReturn([]);
        when(mockAuthService.isLoggedIn).thenReturn(true);
        when(mockAuthService.currentUser).thenReturn(TestData.createTestUser());
        
        await tester.pumpWidget(createHomeScreen());
        await tester.pump();
        
        // Verify home screen is rendered
        expect(find.byType(HomeScreen), findsOneWidget);
        
        // Proper cleanup
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      });
      
      testWidgets('should show focus timer when session is active', (WidgetTester tester) async {
        final testSession = TestData.createTestSession(status: SessionStatus.running);
        
        // Reset and setup fresh mocks
        reset(mockFocusService);
        reset(mockAuthService);
        
        when(mockFocusService.sessions).thenReturn([testSession]);
        when(mockFocusService.isActive).thenReturn(true);
        when(mockFocusService.currentSession).thenReturn(testSession);
        when(mockFocusService.remainingSeconds).thenReturn(1500);
        when(mockFocusService.blockedApps).thenReturn([]);
        when(mockFocusService.hasSelectedApps).thenReturn(true);
        when(mockFocusService.selectedApps).thenReturn([]);
        when(mockAuthService.isLoggedIn).thenReturn(true);
        when(mockAuthService.currentUser).thenReturn(TestData.createTestUser());
        
        await tester.pumpWidget(createHomeScreen());
        await tester.pump();
        
        // Verify focus timer is shown when session is active
        expect(find.byType(FocusTimerWidget), findsOneWidget);
        
        // Proper cleanup
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      });
    });
  });
}