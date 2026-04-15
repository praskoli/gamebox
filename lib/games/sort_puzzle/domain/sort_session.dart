import 'sort_container.dart';
import 'sort_level.dart';

class SortSession {
  const SortSession({
    required this.level,
    required this.containers,
    required this.moveCount,
    required this.hintsUsed,
    required this.elapsed,
    required this.undoStack,
    required this.selectedContainerIndex,
  });

  final SortLevel level;
  final List<SortContainer> containers;
  final int moveCount;
  final int hintsUsed;
  final Duration elapsed;
  final List<List<SortContainer>> undoStack;
  final int? selectedContainerIndex;

  SortSession copyWith({
    SortLevel? level,
    List<SortContainer>? containers,
    int? moveCount,
    int? hintsUsed,
    Duration? elapsed,
    List<List<SortContainer>>? undoStack,
    Object? selectedContainerIndex = _sentinel,
  }) {
    return SortSession(
      level: level ?? this.level,
      containers: containers ?? this.containers,
      moveCount: moveCount ?? this.moveCount,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsed: elapsed ?? this.elapsed,
      undoStack: undoStack ?? this.undoStack,
      selectedContainerIndex: identical(selectedContainerIndex, _sentinel)
          ? this.selectedContainerIndex
          : selectedContainerIndex as int?,
    );
  }

  int get starsEarned {
    if (moveCount <= level.star3Target) return 3;
    if (moveCount <= level.star2Target) return 2;
    return 1;
  }
}

const Object _sentinel = Object();
