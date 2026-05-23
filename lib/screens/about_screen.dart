import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: const Text('About'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E3A5F),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 36, color: Color(0xFF00D4AA)),
                    const SizedBox(height: 2),
                    const Icon(Icons.build_rounded, size: 16, color: Color(0xFFFFD166)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PhoneFX+',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.build_circle, 'Purpose', 'Repair shop management & billing'),
                    const Divider(color: Colors.grey, height: 24),
                    _infoRow(Icons.person, 'Developer', 'PhoneFX+ Team'),
                    const Divider(color: Colors.grey, height: 24),
                    _infoRow(Icons.description, 'License', 'All rights reserved'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Repair · Bill · Done',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00D4AA)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
