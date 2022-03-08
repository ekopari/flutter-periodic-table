import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

abstract class PuzzleEvent {
  final SlidePuzzle puzzle;
  PuzzleEvent({required this.puzzle});
}
