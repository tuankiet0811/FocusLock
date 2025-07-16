import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/focus_service.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FocusService
  final focusService = FocusService();
  await focusService.init();
  await Firebase.initializeApp();
  runApp(MyApp(focusService: focusService));
}

class MyApp extends StatelessWidget {
  final FocusService focusService;
  
  const MyApp({
    super.key,
    required this.focusService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FocusService>.value(
      value: focusService,
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
        home: const HomeScreen(),
      ),
    );
  }
}
