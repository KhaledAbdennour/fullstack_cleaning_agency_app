import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xFF3B82F6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.cleaspaceAlgeria,
              style: const TextStyle(
                color: Colors.white70,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.readyToLaunch,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.createAccountDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
