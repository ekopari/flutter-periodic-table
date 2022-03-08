import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class GameFinishedEvent extends PuzzleEvent {
  final Duration timeSpentSolving;
  final int moves;
  final int hintsUsed;
  GameFinishedEvent(
      {required SlidePuzzle puzzle, required this.timeSpentSolving, required this.hintsUsed, required this.moves})
      : super(puzzle: puzzle);
}
