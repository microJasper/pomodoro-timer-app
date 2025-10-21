import 'package:flutter/material.dart';

// Oluşturduğumuz ekran dosyalarını projemize dahil ediyoruz
import 'screens/splash_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pomodoro Timer',
      initialRoute: '/',
      // Rotalarımız artık gerçek ekranları gösteriyor!
      routes: {
        '/': (context) => const SplashScreen(),
        '/timer': (context) => const TimerScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
