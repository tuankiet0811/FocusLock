import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/focus_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase first
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Initialize FocusService after Firebase
    final focusService = FocusService();
    await focusService.init();
    print('FocusService initialized successfully');
    
    runApp(AppRoot(focusService: focusService));
  } catch (e) {
    print('Error initializing app: $e');
    // Fallback without Firebase
    final focusService = FocusService();
    await focusService.init();
    runApp(AppRoot(focusService: focusService));
  }
}

class AppRoot extends StatefulWidget {
  final FocusService focusService;
  const AppRoot({Key? key, required this.focusService}) : super(key: key);
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  Key _appKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      print('App is going to background, auto-saving session state...');
      widget.focusService.autoSaveSessionState();
      widget.focusService.autoSaveTimerState();
    }
  }

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
          
          // Beautiful Google Fonts
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
            displayMedium: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            displaySmall: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            headlineLarge: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            headlineMedium: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            headlineSmall: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            titleSmall: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF1A1A1A),
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF1A1A1A),
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF666666),
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            labelMedium: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
            labelSmall: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF999999),
            ),
          ),
          
          // Modern AppBar theme
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            iconTheme: const IconThemeData(
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Beautiful button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(AppConstants.primaryColor).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Modern card theme
          cardTheme: CardThemeData(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            color: Colors.white,
          ),
          
          // Beautiful input decoration
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(AppConstants.primaryColor),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(AppConstants.errorColor),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(AppConstants.errorColor),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          
          // Icon theme
          iconTheme: const IconThemeData(
            color: Color(0xFF666666),
            size: 24,
          ),
          
          // Floating Action Button theme
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          
          // List tile theme
          listTileTheme: ListTileThemeData(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titleTextStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            subtitleTextStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          
          // Chip theme
          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey.shade100,
            selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.1),
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
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
            body: Center(child: Text('Có lỗi xảy ra khi xác thực!')), // fallback UI
          );
        }
        if (snapshot.hasData) {
          print('AuthGate: Đã đăng nhập user: ${snapshot.data}');
          // Load user-specific data when user logs in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            focusService.loadUserData();
          });
          return HomeScreen(onRestart: onRestart);
        } else {
          print('AuthGate: Chưa đăng nhập');
          // Clear user data when user logs out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            focusService.clearUserData();
          });
          return LoginScreen(onRestart: onRestart);
        }
      },
    );
  }
}
