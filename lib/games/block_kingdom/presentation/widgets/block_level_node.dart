import 'package:flutter/material.dart';

class BlockLevelNode extends StatelessWidget {
  const BlockLevelNode({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isCompleted,
    required this.onTap,
  });

  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Gradient backgroundGradient = isCurrent
        ? const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFFB7185)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : isUnlocked
        ? const LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient(
      colors: [Color(0xFF5B5E68), Color(0xFF454854)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final Color borderColor = isCurrent
        ? Colors.white.withOpacity(0.34)
        : isUnlocked
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.08);

    final IconData icon = isUnlocked
        ? Icons.extension_rounded
        : Icons.lock_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrent
                    ? const Color(0xFFF59E0B).withOpacity(0.28)
                    : Colors.black.withOpacity(0.16),
                blurRadius: isCurrent ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isCompleted)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (isCurrent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          isUnlocked ? 0.14 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white.withOpacity(
                          isUnlocked ? 1.0 : 0.78,
                        ),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}