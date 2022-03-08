import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/events/ChemicalElementEvent.dart';
import 'package:periodic_table_puzzle/models/events/GameFinished.dart';
import 'package:periodic_table_puzzle/models/events/GameStarted.dart';
import 'package:periodic_table_puzzle/models/events/MoveEvent.dart';
import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/events/ShuffleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/GameHint.dart';

import 'PuzzleCell.dart';

class SlidePuzzle {
  final Random random = Random();
  final List<List<PuzzleCell?>> periods;
  final List<ChemicalElement> elements;
  final Map<ChemicalElement, PuzzleCell> currentElementPositions = {};
  final List<Function(PuzzleEvent)> eventListeners = [];
  final TableType tableType;
  final Map<ChemicalElement, PuzzleCell> removedElementPositions = {};
  final List<GameHint> hints = [];
  bool _gameStarted = false;
  DateTime? startTime;
  DateTime? endTime;
  Duration? timeSpentSolving;
  bool _countingMoves = false;
  int moveCount = 0;
  int hintsUsed = 0;

  static SlidePuzzle fromTableType(TableType tableType) {
    List<List<PuzzleCell?>> periods;
    switch (tableType) {
      case TableType.StandardTable:
        {
          periods = _CellArrangements.standardTable();
        }
        break;
      case TableType.CompactTable:
        {
          periods = _CellArrangements.compactTable();
        }
        break;
      case TableType.DBlock:
        {
          periods = _CellArrangements.dBlockTable();
        }
        break;
      case TableType.PBlock:
        {
          periods = _CellArrangements.pBlockTable();
        }
        break;
      case TableType.ExtendedTable:
        {
          periods = _CellArrangements.extendedTable();
        }
        break;
      case TableType.LeftStepTable:
        {
          periods = _CellArrangements.leftStepTable();
        }
        break;
    }
    List<ChemicalElement> elements = [];
    for (var period in periods) {
      for (var cell in period) {
        if (cell != null) {
          elements.add(cell.targetElement);
        }
      }
    }
    return SlidePuzzle(periods: periods, elements: elements, tableType: tableType);
  }

  SlidePuzzle({required this.periods, required this.elements, required this.tableType}) {
    var elementsToCheck = List.from(elements);
    for (var period in periods) {
      for (var cell in period) {
        if (cell != null) {
          elementsToCheck.remove(cell.targetElement);
          assert(cell.content == null);
          if (elements.contains(cell.targetElement)) {
            cell.content = cell.targetElement;
            currentElementPositions[cell.targetElement] = cell;
          }
        }
      }
    }
    assert(elementsToCheck.isEmpty, "some elements do not have corresponding cells");
    hints.addAll(GameHint.allHints());
  }

  void addEventListener(Function(PuzzleEvent) listener) {
    eventListeners.add(listener);
  }

  void removeEventListener(Function(PuzzleEvent) listener) {
    eventListeners.remove(listener);
  }

  void _sendEvent(PuzzleEvent event) {
    for (var listener in eventListeners) {
      listener(event);
    }
  }

  int get _numberOfShuffleMoves {
    return 20 * allCells.length;
  }

  List<PuzzleCell> get allCells {
    List<PuzzleCell> cells = [];
    for (var period in periods) {
      for (var cell in period) {
        if (cell != null) {
          cells.add(cell);
        }
      }
    }
    return cells;
  }

  List<PuzzleCell> get emptyCells {
    List<PuzzleCell> emptyCells = [];
    for (var cell in allCells) {
      if (cell.content == null) {
        emptyCells.add(cell);
      }
    }
    return emptyCells;
  }

  /// Left-to-right
  List<PuzzleCell> _getContinuousRow(PuzzleCell cell) {
    while (cell.leftCell != null) {
      cell = cell.leftCell!;
    }
    List<PuzzleCell> row = [cell];
    while (cell.rightCell != null) {
      row.add(cell.rightCell!);
      cell = cell.rightCell!;
    }
    return row;
  }

  /// Top-to-bottom
  List<PuzzleCell> _getContinuousColumn(PuzzleCell cell) {
    while (cell.topCell != null) {
      cell = cell.topCell!;
    }
    List<PuzzleCell> col = [cell];
    while (cell.bottomCell != null) {
      col.add(cell.bottomCell!);
      cell = cell.bottomCell!;
    }
    return col;
  }

  List<int> _getValidMoves(PuzzleCell cell, List<PuzzleCell> group) {
    assert(group.contains(cell));
    assert(cell.content != null);
    List<int> moves = [];
    int cellIndex = group.indexOf(cell);
    int emptiesBefore = 0;
    int emptiesAfter = 0;
    int i = 0;
    while (i < group.length) {
      if (group[i].content == null) {
        if (i < cellIndex) {
          emptiesBefore++;
        } else {
          emptiesAfter++;
        }
      }
      i++;
    }
    i = -emptiesBefore;
    while (i < emptiesAfter) {
      int move = i < 0 ? i : i + 1;
      moves.add(move);
      i++;
    }
    return moves;
  }

  List<Move> getMovesForElement(ChemicalElement element) {
    assert(currentElementPositions.containsKey(element));
    PuzzleCell elementCell = currentElementPositions[element]!;
    var row = _getContinuousRow(elementCell);
    var col = _getContinuousColumn(elementCell);
    List<int> hMoves = _getValidMoves(elementCell, row);
    List<int> vMoves = _getValidMoves(elementCell, col);
    List<Move> moves = [];
    for (var moveAmount in hMoves) {
      moves.add(Move(cell: elementCell, axis: Axis.horizontal, amount: moveAmount));
    }
    for (var moveAmount in vMoves) {
      moves.add(Move(cell: elementCell, axis: Axis.vertical, amount: moveAmount));
    }
    return moves;
  }

  Map<ChemicalElement, int> getElementsAffectedByMove(Move move) {
    assert(move.cell.content != null);
    List<PuzzleCell> group;
    if (move.axis == Axis.vertical) {
      group = _getContinuousColumn(move.cell);
    } else {
      group = _getContinuousRow(move.cell);
    }
    Map<ChemicalElement, int> affected = {};
    int amount = move.amount;
    int startIndex = group.indexOf(move.cell);
    int emptiesEncountered = 0;
    int i = startIndex;
    while (emptiesEncountered < amount.abs()) {
      var cell = group[i];
      if (cell.content == null) {
        emptiesEncountered++;
      } else {
        affected[cell.content!] = amount - emptiesEncountered * amount.sign;
      }
      i += amount.sign;
    }
    return affected;
  }

  /// offset in number of cells, c2 minus c1
  Offset getRelativeOffset(PuzzleCell c1, PuzzleCell c2) {
    // int deltaY = c2.period - c1.period;
    // int topPeriod = periods[0].firstWhere((pc) => pc != null)!.period;
    // List<PuzzleCell?> c1Period = periods[c1.period - topPeriod];
    // List<PuzzleCell?> c2Period = periods[c2.period - topPeriod];
    List<PuzzleCell?> c1Period = periods.firstWhere((l) => l.contains(c1));
    List<PuzzleCell?> c2Period = periods.firstWhere((l) => l.contains(c2));
    int deltaY = periods.indexOf(c2Period) - periods.indexOf(c1Period);
    int c1i = c1Period.indexOf(c1);
    int c2i = c2Period.indexOf(c2);
    int deltaX = c2i - c1i;
    return Offset(deltaX.toDouble(), deltaY.toDouble());
  }

  void shuffle() {
    // PuzzleCell Bcell = currentElementPositions[elements[4]]!;
    // PuzzleCell Licell = currentElementPositions[elements[2]]!;
    // print(getRelativeOffset(Bcell, Licell));
    int i = 0;
    List<MoveEvent> moveEvents = [];
    while (i < _numberOfShuffleMoves) {
      i++;
      List<PuzzleCell> empties = emptyCells;
      PuzzleCell empty = empties[random.nextInt(empties.length)];
      var row = _getContinuousRow(empty);
      var col = _getContinuousColumn(empty);
      Axis axis;
      List<PuzzleCell> group;
      if (random.nextBool() && row.length > 1) {
        axis = Axis.horizontal;
        group = row;
      } else {
        axis = Axis.vertical;
        group = col;
      }
      if (group.length == 1 || group.every((c) => c.content == null)) {
        continue;
      }
      PuzzleCell? toMove;
      while (toMove == null || toMove.content == null) {
        toMove = group[random.nextInt(group.length)];
      }
      List<int> validMoves = _getValidMoves(toMove, group);
      if (validMoves.isEmpty) {
        continue;
      }
      int moveAmount = validMoves[random.nextInt(validMoves.length)];
      Move move = Move(amount: moveAmount, axis: axis, cell: toMove);
      moveEvents.add(performMove(move, isShuffleMove: true, suppressEvent: true));
    }
    _sendEvent(ShuffleEvent(puzzle: this, moveEvents: moveEvents));
  }

  bool get isCorrect {
    for (var period in periods) {
      for (var cell in period) {
        if (cell != null) {
          ChemicalElement targetElement = cell.targetElement;
          ChemicalElement? actualElement = cell.content;
          if (elements.contains(targetElement) && targetElement != actualElement) {
            return false;
          }
        }
      }
    }
    return true;
  }

  MoveEvent performMove(Move move, {bool isShuffleMove = false, suppressEvent = false}) {
    List<PuzzleCell> group;
    if (move.axis == Axis.horizontal) {
      group = _getContinuousRow(move.cell);
    } else {
      group = _getContinuousColumn(move.cell);
    }
    List<int> validMoves = _getValidMoves(move.cell, group);
    assert(validMoves.contains(move.amount));
    int toMoveIndex = group.indexOf(move.cell);
    List<ChemicalElement?> newArrangement = [];
    int i = 0;
    while (i < group.length) {
      newArrangement.add(group[i].content);
      i++;
    }
    i = move.amount;
    while (i != 0) {
      int sgni = i < 0 ? -1 : 1;
      int firstEmptyAfterMoveIndex = -1;
      int j = toMoveIndex + sgni;
      while (true) {
        assert(j >= 0);
        assert(j < newArrangement.length);
        if (newArrangement[j] == null) {
          firstEmptyAfterMoveIndex = j;
          break;
        }
        j += sgni;
      }
      assert(firstEmptyAfterMoveIndex >= 0);
      j = firstEmptyAfterMoveIndex;
      while (j != toMoveIndex) {
        newArrangement[j] = newArrangement[j - sgni];
        j -= sgni;
      }
      newArrangement[toMoveIndex] = null;
      i -= sgni;
      toMoveIndex += sgni;
    }
    var oldElementPositions = Map.of(currentElementPositions);
    List<ChemicalElement> affectedElements = List.from(getElementsAffectedByMove(move).keys);
    i = 0;
    while (i < newArrangement.length) {
      group[i].content = newArrangement[i];
      if (newArrangement[i] != null) {
        currentElementPositions[newArrangement[i]!] = group[i];
      }
      i++;
    }

    MoveEvent event = MoveEvent(
      puzzle: this,
      move: move,
      oldElementPositions: oldElementPositions,
      affectedElements: affectedElements,
      isShuffleMove: isShuffleMove,
    );
    if (_countingMoves) {
      moveCount++;
    }
    if (!suppressEvent) {
      _sendEvent(event);
    }
    if (isCorrect && !isShuffleMove) {
      _gameFinished();
    }
    return event;
  }

  void _gameFinished() {
    endTime = DateTime.now();
    timeSpentSolving = endTime!.difference(startTime!);
    for (var removedElement in removedElementPositions.keys) {
      addElement(removedElement);
    }
    removedElementPositions.clear();
    _sendEvent(GameFinishedEvent(
      puzzle: this,
      timeSpentSolving: timeSpentSolving!,
      hintsUsed: hintsUsed,
      moves: moveCount,
    ));
  }

  void addElement(ChemicalElement element) {
    assert(!elements.contains(element));
    assert(allCells.where((cell) => cell.targetElement == element).isNotEmpty);
    assert(allCells.where((cell) => cell.content == null).isNotEmpty);
    ChemicalelementAddedEvent event = ChemicalelementAddedEvent(puzzle: this, chamicalElement: element);
    elements.add(element);
    var empties = emptyCells;
    for (var cell in empties) {
      if (cell.targetElement == element) {
        cell.content = element;
        currentElementPositions[element] = cell;
        _sendEvent(event);
        return;
      }
    }
    PuzzleCell target = empties[random.nextInt(empties.length)];
    target.content = element;
    currentElementPositions[element] = target;
    _sendEvent(event);
  }

  void removeElement(ChemicalElement element) {
    assert(elements.contains(element));
    removedElementPositions[element] = currentElementPositions[element]!;
    elements.remove(element);
    PuzzleCell? currentElementCell = currentElementPositions.remove(element);
    assert(currentElementCell != null);
    currentElementCell!.content = null;
    ChemicalElementRemovedEvent event = ChemicalElementRemovedEvent(
      puzzle: this,
      chamicalElement: element,
      removedElementCell: currentElementCell,
    );
    _sendEvent(event);
  }

  bool get isGameStarted {
    return _gameStarted;
  }

  void startGame() {
    if (isGameStarted) {
      return;
    }
    _gameStarted = true;
    _sendEvent(GameStartedEvent(puzzle: this));
    int numCellsToRemove = 1;
    if (tableType == TableType.StandardTable ||
        tableType == TableType.CompactTable ||
        tableType == TableType.PBlock ||
        tableType == TableType.ExtendedTable) {
      numCellsToRemove = 2;
    }
    while (numCellsToRemove > 0) {
      removeElement(elements.last);
      numCellsToRemove--;
    }
    Future delayed = Future.delayed(const Duration(milliseconds: 1000), () {
      shuffle();
      startTime = DateTime.now();
      _countingMoves = true;
    });
    delayed.ignore();
  }

  void useHint(GameSettings settings) {
    List<GameHint> availableHints = [];
    for (var hint in hints) {
      if (hint.isApplicable(settings, this)) {
        availableHints.add(hint);
      }
    }
    if (availableHints.isEmpty) {
      return;
    }
    GameHint hint = availableHints[random.nextInt(availableHints.length)];
    hint.applyHint(settings, this);
    hintsUsed++;
  }
}

class Move {
  final int amount;
  final Axis axis;
  final PuzzleCell cell;
  Move({required this.cell, required this.axis, required this.amount});

  @override
  String toString() {
    String cellContent = "<empty>";
    if (cell.content != null) {
      cellContent = cell.content!.symbol;
    }
    return "move $cellContent $axis $amount";
  }
}

class _CellArrangements {
  static void _assignNeighbors(List<List<PuzzleCell?>> periods) {
    int y = 0;
    while (y < periods.length) {
      var period = periods[y];
      int x = 0;
      while (x < period.length) {
        var cell = period[x];
        if (cell != null) {
          if (x > 0 && period[x - 1] != null) {
            cell.leftCell = period[x - 1];
          }
          if (x < period.length - 1 && period[x + 1] != null) {
            cell.rightCell = period[x + 1];
          }
          if (y > 0 && periods[y - 1][x] != null) {
            cell.topCell = periods[y - 1][x];
          }
          if (y < periods.length - 1 && periods[y + 1][x] != null) {
            cell.bottomCell = periods[y + 1][x];
          }
        }
        x++;
      }
      y++;
    }
  }

  static List<List<PuzzleCell?>> standardTable() {
    List<List<PuzzleCell?>> periods = List.generate(7, (index) => List.generate(18, (index2) => null));
    List<ChemicalElement> allElements = ChemicalElements.getElements();
    for (ChemicalElement e in allElements) {
      if (e.block != "f") {
        var cell = PuzzleCell(targetElement: e, period: e.period, group: e.group);
        periods[cell.period - 1][cell.group! - 1] = cell;
      }
    }
    _assignNeighbors(periods);
    return periods;
  }

  static List<List<PuzzleCell?>> compactTable() {
    List<List<PuzzleCell?>> periods = List.generate(7, (index) => List.generate(8, (index2) => null));
    List<ChemicalElement> allElements = ChemicalElements.getElements();
    for (ChemicalElement e in allElements) {
      if (e.block == "s" || e.block == "p") {
        var cell = PuzzleCell(targetElement: e, period: e.period, group: e.group);
        int column;
        if (cell.group! <= 2) {
          column = cell.group! - 1;
        } else {
          column = cell.group! - 11;
        }
        periods[cell.period - 1][column] = cell;
      }
    }
    _assignNeighbors(periods);
    return periods;
  }

  static List<List<PuzzleCell?>> pBlockTable() {
    List<List<PuzzleCell?>> periods = List.generate(7, (index) => List.generate(6, (index2) => null));
    List<ChemicalElement> allElements = ChemicalElements.getElements();
    for (ChemicalElement e in allElements) {
      if (e.block == "p" || e.atomicNumber == 2) {
        var cell = PuzzleCell(targetElement: e, period: e.period, group: e.group);
        int column = cell.group! - 13;
        periods[cell.period - 1][column] = cell;
      }
    }
    _assignNeighbors(periods);
    return periods;
  }

  static List<List<PuzzleCell?>> dBlockTable() {
    List<List<PuzzleCell?>> periods = List.generate(4, (index) => List.generate(10, (index2) => null));
    List<ChemicalElement> allElements = ChemicalElements.getElements();
    for (ChemicalElement e in allElements) {
      if (e.block == "d") {
        var cell = PuzzleCell(targetElement: e, period: e.period, group: e.group);
        int row = cell.period - 4;
        int col = cell.group! - 3;
        periods[row][col] = cell;
      }
    }
    _assignNeighbors(periods);
    return periods;
  }

  static List<List<PuzzleCell?>> extendedTable() {
    List<List<PuzzleCell?>> periods = List.generate(7, (index) => List.generate(32, (index2) => null));
    List<ChemicalElement> allElements = ChemicalElements.getElements();
    for (ChemicalElement e in allElements) {
      var cell = PuzzleCell(targetElement: e, period: e.period, group: e.group);
      int col;
      if (cell.group != null) {
        if (cell.group! <= 2) {
          col = cell.group! - 1;
        } else {
          col = cell.group! + 13;
        }
      } else {
        if (cell.period == 6) {
          col = cell.targetElement.atomicNumber - 57 + 2;
        } else {
          col = cell.targetElement.atomicNumber - 89 + 2;
        }
      }
      periods[cell.period - 1][col] = cell;
    }
    _assignNeighbors(periods);
    return periods;
  }

  static List<List<PuzzleCell?>> leftStepTable() {
    List<List<PuzzleCell?>> periods = List.generate(8, (index) => List.generate(32, (index2) => null));
    List<ChemicalElement> allelements = ChemicalElements.getElements();
    for (ChemicalElement e in allelements) {
      var cell = PuzzleCell(targetElement: e, period: e.period, group: e.group);
      int col;
      int row;
      switch (cell.targetElement.block) {
        case "s":
          {
            row = cell.period - 1;
            if (cell.group! == 18 || cell.group! == 2) {
              col = 31;
            } else {
              col = 30;
            }
          }
          break;
        case "p":
          {
            row = cell.period;
            col = 11 + cell.group!;
          }
          break;
        case "d":
          {
            row = cell.period;
            col = 11 + cell.group!;
          }
          break;
        case "f":
          {
            row = cell.period;
            if (cell.period == 6) {
              col = cell.targetElement.atomicNumber - 57;
            } else {
              col = cell.targetElement.atomicNumber - 89;
            }
          }
          break;
        default:
          {
            throw AssertionError();
          }
      }
      periods[row][col] = cell;
    }
    _assignNeighbors(periods);
    return periods;
  }
}
