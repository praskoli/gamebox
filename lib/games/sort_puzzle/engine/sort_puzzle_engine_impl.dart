import '../domain/sort_container.dart';
import '../domain/sort_level.dart';
import '../domain/sort_move.dart';
import '../domain/sort_move_result.dart';
import '../domain/sort_piece.dart';
import '../domain/sort_rule_family.dart';
import '../domain/sort_session.dart';
import 'sort_puzzle_engine.dart';

class SortPuzzleEngineImpl implements SortPuzzleEngine {
  const SortPuzzleEngineImpl();

  @override
  SortSession createSession(SortLevel level) {
    return SortSession(
      level: level,
      containers: level.containers
          .map(
            (SortContainerDefinition item) => SortContainer(
              id: item.id,
              capacity: item.capacity,
              pieces: List<SortPiece>.from(item.pieces),
            ),
          )
          .toList(growable: false),
      moveCount: 0,
      hintsUsed: 0,
      elapsed: Duration.zero,
      undoStack: const <List<SortContainer>>[],
      selectedContainerIndex: null,
    );
  }

  @override
  SortMoveResult applyMove(SortSession session, SortMove move) {
    if (!canMove(session, move)) {
      return SortMoveResult(
        didMove: false,
        isValid: false,
        isCompleted: isSolved(session),
        session: session,
        message: 'Invalid move',
      );
    }

    final List<SortContainer> containers = _cloneContainers(session.containers);
    final SortContainer from = containers[move.fromIndex];
    final SortContainer to = containers[move.toIndex];

    if (session.level.ruleFamily == SortRuleFamily.discreteStack) {
      final String group = from.topPiece!.groupKey;
      int movable = _topRunCount(from);
      movable = movable.clamp(1, to.freeSlots);
      final List<SortPiece> moved = from.pieces.sublist(from.pieces.length - movable);
      final List<SortPiece> nextFrom = from.pieces.sublist(0, from.pieces.length - movable);
      final List<SortPiece> nextTo = <SortPiece>[...to.pieces, ...moved.map((e) => e.copyWith(groupKey: group))];
      containers[move.fromIndex] = from.copyWith(pieces: nextFrom);
      containers[move.toIndex] = to.copyWith(pieces: nextTo);
    } else {
      final SortPiece sourceTop = from.topPiece!;
      final int contiguousAmount = sourceTop.amount;
      final int transferable = contiguousAmount.clamp(1, to.freeSlots);
      final List<SortPiece> nextFrom = List<SortPiece>.from(from.pieces);
      nextFrom.removeLast();
      if (sourceTop.amount > transferable) {
        nextFrom.add(sourceTop.copyWith(amount: sourceTop.amount - transferable));
      }
      final List<SortPiece> nextTo = List<SortPiece>.from(to.pieces);
      if (nextTo.isNotEmpty && nextTo.last.groupKey == sourceTop.groupKey) {
        final SortPiece merged = nextTo.removeLast();
        nextTo.add(merged.copyWith(amount: merged.amount + transferable));
      } else {
        nextTo.add(sourceTop.copyWith(amount: transferable));
      }
      containers[move.fromIndex] = from.copyWith(pieces: nextFrom);
      containers[move.toIndex] = to.copyWith(pieces: nextTo);
    }

    final SortSession next = session.copyWith(
      containers: containers,
      moveCount: session.moveCount + 1,
      undoStack: <List<SortContainer>>[
        ...session.undoStack,
        _cloneContainers(session.containers),
      ],
    );

    return SortMoveResult(
      didMove: true,
      isValid: true,
      isCompleted: isSolved(next),
      session: next,
    );
  }

  @override
  bool canMove(SortSession session, SortMove move) {
    if (move.fromIndex == move.toIndex) {
      return false;
    }
    if (move.fromIndex < 0 || move.fromIndex >= session.containers.length) {
      return false;
    }
    if (move.toIndex < 0 || move.toIndex >= session.containers.length) {
      return false;
    }
    final SortContainer from = session.containers[move.fromIndex];
    final SortContainer to = session.containers[move.toIndex];
    if (from.isEmpty || to.isFull) {
      return false;
    }
    final SortPiece sourceTop = from.topPiece!;
    final SortPiece? targetTop = to.topPiece;
    if (targetTop == null) {
      return true;
    }
    return targetTop.groupKey == sourceTop.groupKey;
  }

  @override
  SortMove? findHintMove(SortSession session) {
    for (int i = 0; i < session.containers.length; i++) {
      for (int j = 0; j < session.containers.length; j++) {
        final SortMove candidate = SortMove(fromIndex: i, toIndex: j);
        if (canMove(session, candidate)) {
          return candidate;
        }
      }
    }
    return null;
  }

  @override
  bool hasAnyValidMoves(SortSession session) => findHintMove(session) != null;

  @override
  bool isSolved(SortSession session) {
    for (final SortContainer container in session.containers) {
      if (container.isEmpty) {
        continue;
      }
      if (!container.isUniform()) {
        return false;
      }
      if (container.usedSlots != container.capacity) {
        return false;
      }
    }
    return true;
  }

  @override
  SortSession undo(SortSession session) {
    if (session.undoStack.isEmpty || !session.level.allowUndo) {
      return session;
    }
    final List<List<SortContainer>> stack = List<List<SortContainer>>.from(session.undoStack);
    final List<SortContainer> previous = stack.removeLast();
    return session.copyWith(
      containers: _cloneContainers(previous),
      moveCount: session.moveCount > 0 ? session.moveCount - 1 : 0,
      undoStack: stack,
    );
  }

  List<SortContainer> _cloneContainers(List<SortContainer> containers) {
    return containers
        .map((SortContainer container) => container.copyWith(
              pieces: container.pieces.map((SortPiece piece) => piece.copyWith()).toList(growable: false),
            ))
        .toList(growable: false);
  }

  int _topRunCount(SortContainer container) {
    if (container.pieces.isEmpty) {
      return 0;
    }
    final String top = container.pieces.last.groupKey;
    int count = 0;
    for (int i = container.pieces.length - 1; i >= 0; i--) {
      if (container.pieces[i].groupKey != top) {
        break;
      }
      count++;
    }
    return count;
  }
}
