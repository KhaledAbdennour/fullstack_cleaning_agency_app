import 'package:flutter/material.dart';

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF157A6E),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "CLEASPACE ALGERIA",
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Ready to launch your next clean space?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Create an account to book trusted cleaners, manage agencies, or offer your cleaning services to Algeria’s growing market.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

