import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localizations.cleanSpaceFeatures,
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.everythingYouNeed,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _feature(context, Icons.verified_outlined, localizations.findVerifiedCleaners,
              localizations.browseTrustedProfessionals),
          const SizedBox(height: 24),
          _feature(context, Icons.calendar_today_outlined, localizations.easyBooking,
              localizations.postYourJob),
          const SizedBox(height: 24),
          _feature(context, Icons.work_outline, localizations.jobOpportunities,
              localizations.findStableWork),
        ],
      ),
    );
  }

  Widget _feature(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF3B82F6), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}


