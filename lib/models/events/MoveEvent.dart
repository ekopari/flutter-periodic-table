import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/PuzzleCell.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class MoveEvent extends PuzzleEvent {
  final Move move;
  final Map<ChemicalElement, PuzzleCell> oldElementPositions;
  final List<ChemicalElement> affectedElements;
  final bool isShuffleMove;
  MoveEvent({
    required SlidePuzzle puzzle,
    required this.move,
    required this.oldElementPositions,
    required this.affectedElements,
    required this.isShuffleMove,
  }) : super(puzzle: puzzle);
}
