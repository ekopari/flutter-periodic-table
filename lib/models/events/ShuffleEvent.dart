import 'package:periodic_table_puzzle/models/events/MoveEvent.dart';
import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class ShuffleEvent extends PuzzleEvent {
  final List<MoveEvent> moveEvents;
  ShuffleEvent({required SlidePuzzle puzzle, required this.moveEvents}) : super(puzzle: puzzle);
}
