import 'package:periodic_table_puzzle/models/ChemicalElement.dart';

class PuzzleCell {
  PuzzleCell? leftCell;
  PuzzleCell? rightCell;
  PuzzleCell? topCell;
  PuzzleCell? bottomCell;
  final ChemicalElement targetElement;
  final int? group;
  final int period;
  ChemicalElement? content;
  PuzzleCell({required this.targetElement, required this.period, required this.group});
}
