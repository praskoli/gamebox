import 'package:flutter/material.dart';

class TimeTrialOverlay extends StatelessWidget {
  final String timerText;
  final bool isUrgent;

  const TimeTrialOverlay({
    super.key,
    required this.timerText,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isUrgent
                ? [Color(0xFFB71C1C), Color(0xFFE53935)]
                : [Color(0xFF1A2A6C), Color(0xFF2E7D32)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              timerText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}