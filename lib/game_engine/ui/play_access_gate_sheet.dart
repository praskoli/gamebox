import 'package:flutter/material.dart';

import '../../platform/play_access/data/play_access_repository.dart';
import '../../platform/play_access/data/play_access_service.dart';
import '../../platform/play_access/domain/play_access_approval_request.dart';
import '../../platform/play_access/domain/play_access_guard_result.dart';
import '../../platform/play_access/domain/play_pause_message.dart';
import '../../platform/play_access/presentation/widgets/animated_play_pause_message_card.dart';

class PlayAccessGateSheet extends StatefulWidget {
  const PlayAccessGateSheet({
    super.key,
    required this.gameId,
    required this.levelNumber,
    required this.guardResult,
  });

  final String gameId;
  final int levelNumber;
  final PlayAccessGuardResult guardResult;

  static Future<bool> show({
    required BuildContext context,
    required String gameId,
    required int levelNumber,
    required PlayAccessGuardResult guardResult,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayAccessGateSheet(
        gameId: gameId,
        levelNumber: levelNumber,
        guardResult: guardResult,
      ),
    );
    return result ?? false;
  }

  @override
  State<PlayAccessGateSheet> createState() => _PlayAccessGateSheetState();
}

class _PlayAccessGateSheetState extends State<PlayAccessGateSheet> {
  final TextEditingController _otpController = TextEditingController();

  bool _isRequesting = false;
  bool _isVerifying = false;
  String? _error;
  PlayAccessApprovalRequest? _request;
  _GateStep _step = _GateStep.blocked;

  @override
  void initState() {
    super.initState();
    _step = widget.guardResult.canStart && widget.guardResult.shouldWarn
        ? _GateStep.warning
        : _GateStep.blocked;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestParentApproval() async {
    if (_isRequesting) return;

    setState(() {
      _error = null;
      _isRequesting = true;
    });

    try {
      final request = await PlayAccessService.instance.requestExtraPlay(
        gameId: widget.gameId,
        levelNumber: widget.levelNumber,
      );

      if (!mounted) return;

      setState(() {
        _request = request;
        _step = _GateStep.otp;
      });
    } on PlayAccessRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not request parent approval right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying || _request == null) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit OTP sent to the parent email.';
      });
      return;
    }

    setState(() {
      _error = null;
      _isVerifying = true;
    });

    try {
      final ok = await PlayAccessService.instance.verifyOtpForRequest(
        requestId: _request!.requestId,
        otp: otp,
      );

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'That OTP was not valid. Please check and try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not verify the OTP right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = widget.guardResult.canStart;
    final isWarning = _step == _GateStep.warning;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.34),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            if (_step == _GateStep.warning) ...[
              _buildWarningContent(),
            ] else if (_step == _GateStep.blocked) ...[
              _buildBlockedContent(),
            ] else ...[
              _buildOtpContent(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A6E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF5A6E).withOpacity(0.26),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFFBAC3),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isWarning) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Continue to Game',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Not Now',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ] else if (_step == _GateStep.blocked) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestParentApproval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B67F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Ask Parent',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextField(
                  controller: _otpController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.24),
                      letterSpacing: 6,
                      fontWeight: FontWeight.w900,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF93C5FD),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Unlock Bonus Play',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _step = canContinue ? _GateStep.warning : _GateStep.blocked;
                      _otpController.clear();
                      _error = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningContent() {
    return Column(
      children: [
        const _MiniHero(
          title: 'Play Window Running Low',
          subtitle:
          'You are close to today’s play limit. You can continue now or come back refreshed later.',
          gradient: [Color(0xFFF59E0B), Color(0xFFFB7185)],
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 14),
        _BudgetStrip(
          minutesRemaining: widget.guardResult.minutesRemaining,
          levelsRemaining: widget.guardResult.levelsRemaining,
          accent: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildBlockedContent() {
    return Column(
      children: [
        AnimatedPlayPauseMessageCard(
          message: const PlayPauseMessage(
            title: 'Today’s Play Limit Reached',
            message:
            'You can unlock bonus time with parent approval. Your progress stays safe and you can return anytime.',
            variant: PlayPauseMessageVariant.bonusRequest,
            animationStyle: PlayPauseAnimationStyle.familyUnlock,
            icon: Icons.family_restroom_rounded,
            gradientColors: [Color(0xFF5B67F1), Color(0xFF8B5CF6)],
          ),
          isBlocking: false,
        ),
        const SizedBox(height: 14),
        _BudgetStrip(
          minutesRemaining: widget.guardResult.minutesRemaining,
          levelsRemaining: widget.guardResult.levelsRemaining,
          accent: const Color(0xFF5B67F1),
        ),
      ],
    );
  }

  Widget _buildOtpContent() {
    final request = _request;

    return Column(
      children: [
        const _MiniHero(
          title: 'Parent Approval Requested',
          subtitle:
          'Enter the 6-digit OTP sent to the configured parent email to unlock bonus play time.',
          gradient: [Color(0xFF22C55E), Color(0xFF14B8A6)],
          icon: Icons.mark_email_read_rounded,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OTP sent to',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                request?.destinationMasked.isNotEmpty == true
                    ? request!.destinationMasked
                    : 'Parent email',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: 'Valid 10 min',
                    color: const Color(0xFF22C55E),
                  ),
                  _InfoChip(
                    icon: Icons.bolt_rounded,
                    label:
                    '+${request?.grantMinutes ?? 0} mins / +${request?.grantLevels ?? 0} levels',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _GateStep {
  warning,
  blocked,
  otp,
}

class _MiniHero extends StatelessWidget {
  const _MiniHero({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStrip extends StatelessWidget {
  const _BudgetStrip({
    required this.minutesRemaining,
    required this.levelsRemaining,
    required this.accent,
  });

  final int minutesRemaining;
  final int levelsRemaining;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BudgetCard(
            icon: Icons.schedule_rounded,
            title: 'Minutes Left',
            value: '$minutesRemaining',
            accent: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BudgetCard(
            icon: Icons.emoji_events_rounded,
            title: 'Levels Left',
            value: '$levelsRemaining',
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}