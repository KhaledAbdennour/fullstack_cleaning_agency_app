import 'package:flutter/material.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "CleanSpace Features",
            style: TextStyle(
              color: Color(0xFF157A6E),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Everything you need in one app",
            style: TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _feature(Icons.verified_outlined, "Find Verified Cleaners",
              "Browse trusted professionals with verified profiles and ratings"),
          const SizedBox(height: 24),
          _feature(Icons.calendar_today_outlined, "Easy Booking",
              "Post your job and receive offers from qualified cleaners"),
          const SizedBox(height: 24),
          _feature(Icons.work_outline, "Job Opportunities",
              "Find stable work and grow your cleaning business"),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFE6F4F1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF157A6E), size: 28),
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


