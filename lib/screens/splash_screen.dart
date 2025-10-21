import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatelessWidget {
  // one-time guard so navigation is scheduled only once
  static bool _navigationScheduled = false;

  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!_navigationScheduled) {
      _navigationScheduled = true;
      Future.delayed(const Duration(seconds: 3), () {
        // ensure the route is still current before navigating
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          Navigator.of(context).pushReplacementNamed('/timer');
        }
      });
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, size: 120, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Pomodoro Timer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
