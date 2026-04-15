import '../domain/sort_level.dart';
import '../domain/sort_move.dart';
import '../domain/sort_move_result.dart';
import '../domain/sort_session.dart';

abstract class SortPuzzleEngine {
  SortSession createSession(SortLevel level);
  SortMoveResult applyMove(SortSession session, SortMove move);
  bool canMove(SortSession session, SortMove move);
  bool isSolved(SortSession session);
  bool hasAnyValidMoves(SortSession session);
  SortMove? findHintMove(SortSession session);
  SortSession undo(SortSession session);
}
