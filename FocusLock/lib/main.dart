import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/focus_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FocusService
  final focusService = FocusService();
  await focusService.init();
  await Firebase.initializeApp();
  runApp(AppRoot(focusService: focusService));
}

class AppRoot extends StatefulWidget {
  final FocusService focusService;
  const AppRoot({Key? key, required this.focusService}) : super(key: key);
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Key _appKey = UniqueKey();

  void _restartApp() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(
      key: _appKey,
      focusService: widget.focusService,
      onRestart: _restartApp,
    );
  }
}

class MyApp extends StatelessWidget {
  final FocusService focusService;
  final VoidCallback? onRestart;
  
  const MyApp({
    super.key,
    required this.focusService,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FocusService>.value(value: focusService),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(AppConstants.primaryColor),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(AppConstants.primaryColor),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(AppConstants.primaryColor),
                width: 2,
              ),
            ),
          ),
        ),
        home: AuthGate(onRestart: onRestart),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final VoidCallback? onRestart;
  const AuthGate({super.key, this.onRestart});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
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
            body: Center(child: Text('Có lỗi xảy ra khi xác thực!')), // fallback UI
          );
        }
        if (snapshot.hasData) {
          print('AuthGate: Đã đăng nhập user: \\${snapshot.data}');
          return HomeScreen(onRestart: onRestart);
        } else {
          print('AuthGate: Chưa đăng nhập');
          return LoginScreen(onRestart: onRestart);
        }
      },
    );
  }
}
