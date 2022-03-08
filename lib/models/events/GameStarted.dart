import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class GameStartedEvent extends PuzzleEvent {
  GameStartedEvent({required SlidePuzzle puzzle}) : super(puzzle: puzzle);
}
