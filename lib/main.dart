import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1419),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pomodoro',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            decoration: TextDecoration.none,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _createRoute(const SplashScreen(), settings);
      case '/timer':
        return _createRoute(const TimerScreen(), settings);
      case '/settings':
        return _createRoute(const SettingsScreen(), settings);
      default:
        return _createRoute(const TimerScreen(), settings);
    }
  }

  PageRoute _createRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.03);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var offsetAnimation = animation.drive(tween);

        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 1.0, curve: Curves.easeIn),
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFFFF6B6B);
    const accentColor = Color(0xFF4ECDC4);
    const backgroundColor = Color(0xFF0F1419);
    const surfaceColor = Color(0xFF1E2235);
    const textColor = Color(0xFFF5F5F5);
    const secondaryTextColor = Color(0xFFB0B0B0);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
        error: Color(0xFFFF6B6B),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w300,
          color: textColor,
          letterSpacing: -3,
          decoration: TextDecoration.none,
        ),
        displayMedium: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1.5,
          decoration: TextDecoration.none,
        ),
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
          decoration: TextDecoration.none,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
          decoration: TextDecoration.none,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textColor,
        size: 24,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        barBackgroundColor: surfaceColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: textColor,
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: textColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: surfaceColor.withOpacity(0.5),
            width: 1,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF2A2D3A).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF2A2D3A).withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFFFF6B6B);
    const accentColor = Color(0xFF4ECDC4);
    const backgroundColor = Color(0xFFF5F7FA);
    const surfaceColor = Color(0xFFFFFFFF);
    const textColor = Color(0xFF1A1A2E);
    const secondaryTextColor = Color(0xFF6B7280);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
        error: Color(0xFFFF6B6B),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w300,
          color: textColor,
          letterSpacing: -3,
          decoration: TextDecoration.none,
        ),
        displayMedium: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1.5,
          decoration: TextDecoration.none,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
          decoration: TextDecoration.none,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
          decoration: TextDecoration.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class AppColors {
  static const primaryFocus = Color(0xFFFF6B6B);
  static const primaryFocusDark = Color(0xFFEE5A52);
  static const primaryBreak = Color(0xFF4ECDC4);
  static const primaryBreakDark = Color(0xFF3FB8AF);

  static const backgroundGradientStart = Color(0xFF1A1A2E);
  static const backgroundGradientMiddle = Color(0xFF16213E);
  static const backgroundGradientEnd = Color(0xFF0F1419);

  static const surfacePrimary = Color(0xFF1E2235);
  static const surfaceSecondary = Color(0xFF2A2D3A);
  static const surfaceTertiary = Color(0xFF3A3D4A);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textTertiary = Color(0xFF6B7280);

  static const accentAmber = Color(0xFFFFB84D);
  static const accentPurple = Color(0xFF9B59B6);
  static const accentBlue = Color(0xFF3498DB);
}
