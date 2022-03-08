import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/PuzzleCell.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

abstract class ChemicalElementEvent extends PuzzleEvent {
  final ChemicalElement chamicalElement;
  ChemicalElementEvent({required SlidePuzzle puzzle, required this.chamicalElement}) : super(puzzle: puzzle);
}

class ChemicalelementAddedEvent extends ChemicalElementEvent {
  ChemicalelementAddedEvent({required SlidePuzzle puzzle, required ChemicalElement chamicalElement})
      : super(puzzle: puzzle, chamicalElement: chamicalElement);
}

class ChemicalElementRemovedEvent extends ChemicalElementEvent {
  final PuzzleCell removedElementCell;
  ChemicalElementRemovedEvent(
      {required SlidePuzzle puzzle, required ChemicalElement chamicalElement, required this.removedElementCell})
      : super(puzzle: puzzle, chamicalElement: chamicalElement);
}
