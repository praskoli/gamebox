import 'sort_session.dart';

class SortMoveResult {
  const SortMoveResult({
    required this.didMove,
    required this.isValid,
    required this.isCompleted,
    required this.session,
    this.message,
  });

  final bool didMove;
  final bool isValid;
  final bool isCompleted;
  final SortSession session;
  final String? message;
}
