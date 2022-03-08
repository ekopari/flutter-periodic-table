import 'dart:math';

import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/ElementInfoDialog.dart';
import 'package:periodic_table_puzzle/gui/ElementSquare.dart';
import 'package:periodic_table_puzzle/gui/GameFinishedDialog.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/gui/GameTypeChooser.dart';
import 'package:periodic_table_puzzle/gui/SineCurve.dart';
import 'package:periodic_table_puzzle/gui/TableGrid.dart';
import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/events/ChemicalElementEvent.dart';
import 'package:periodic_table_puzzle/models/events/GameFinished.dart';
import 'package:periodic_table_puzzle/models/events/MoveEvent.dart';
import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/events/ShuffleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/PuzzleCell.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class DisplayPeriodicTable extends StatefulWidget {
  final SlidePuzzle puzzle;
  final GameSettings gameSettings;
  final bool showCells;
  const DisplayPeriodicTable({Key? key, required this.puzzle, required this.gameSettings, required this.showCells})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DisplayPeriodicTableState();
  }
}

class _DisplayPeriodicTableState extends State<DisplayPeriodicTable> with TickerProviderStateMixin {
  final Random random = Random();
  late SlidePuzzle puzzle;
  late GameSettings settings;
  late bool showCells;
  late Size containerSize;
  late Map<ChemicalElement, PuzzleCell> elementCells;
  final Map<ChemicalElement, Offset> relativeElementOffsets = {};
  final Map<ChemicalElement, double> elementRotations = {};
  final Map<ChemicalElement, double> elementCellOpacities = {};
  final Map<ChemicalElement, AnimationController> elementAnimationControllers = {};
  final Map<ChemicalElement, CurvedAnimation> elementAnimationsCurved = {};
  final Map<ChemicalElement, Tween<Offset>> elementOffsetTweens = {};
  final Map<ChemicalElement, Animation<Offset>> elementOffsetAnimations = {};
  final Map<ChemicalElement, Tween<double>> elementRotationTweens = {};
  final Map<ChemicalElement, Animation<double>> elementRotationAnimations = {};
  final Map<ChemicalElement, Function()> elementOffsetAnimationListeners = {};
  final Map<ChemicalElement, Function()> elementRotationAnimationListeners = {};

  final Map<ChemicalElement, Offset> elementDragStartingCoords = {};
  final Map<ChemicalElement, Offset> elementDragLocalStartingCoords = {};
  final Map<ChemicalElement, Move> intendedElementMoves = {};
  final Map<ChemicalElement, List<ChemicalElement>> affectedMoveElements = {};

  final Map<PuzzleCell, AmbiguitySquare> ambiguityCells = {};

  void _puzzleEventListener(PuzzleEvent event) {
    if (event is ChemicalElementRemovedEvent) {
      _onElementRemoved(event);
    } else if (event is MoveEvent) {
      _onMoveEvent(event);
    } else if (event is ShuffleEvent) {
      _onShuffleEvent(event);
    } else if (event is GameFinishedEvent) {
      _onGameFinishedEvent(event);
    } else if (event is ChemicalelementAddedEvent) {
      _onElementAdded(event);
    }
  }

  Duration get _elementEnterLeaveAnimationDuration {
    return const Duration(milliseconds: 800);
  }

  /// pixels per millisecond
  double get _elementMoveSpeed {
    return 0.25;
  }

  double _getElementLeaveRotation() {
    double minRotation = pi;
    double maxRotation = 3 * pi;
    double amount = random.nextDouble();
    double rotation = minRotation + amount * (maxRotation - minRotation);
    if (random.nextBool()) {
      rotation *= -1;
    }
    return rotation;
  }

  Offset _getElementExitOffset(ChemicalElement element) {
    double radius = sqrt(pow(containerSize.width, 2) + pow(containerSize.height, 2)) / 2;
    radius *= 1.3;
    Offset baseOffset = _getCellBaseOffsets(containerSize)[elementCells[element]]!;
    Offset centre = Offset(containerSize.width / 2, containerSize.height / 2);
    Offset elementAngleVector = baseOffset - centre;
    double elementAngle = elementAngleVector.direction;
    Offset targetOffset = Offset(radius * cos(elementAngle), radius * sin(elementAngle));
    return targetOffset;
  }

  void _removeAllElementAnimationListeners(ChemicalElement element, bool removeElementFromLists) {
    var elementController = elementAnimationControllers.remove(element);
    var elementAnimationCurved = elementAnimationsCurved.remove(element);
    elementOffsetTweens.remove(element);
    var elementOffsetAnimation = elementOffsetAnimations.remove(element);
    elementRotationTweens.remove(element);
    var rotationAnimation = elementRotationAnimations.remove(element);
    if (removeElementFromLists) {
      setState(() {
        elementCells.remove(element);
        relativeElementOffsets.remove(element);
        elementRotations.remove(element);
        elementCellOpacities.remove(element);
      });
    }
    var offsetAnimationListener = elementOffsetAnimationListeners.remove(element);
    var rotationAnimationListener = elementRotationAnimationListeners.remove(element);
    if (elementOffsetAnimation != null) {
      elementOffsetAnimation.removeListener(offsetAnimationListener!);
    }
    if (rotationAnimation != null) {
      rotationAnimation.removeListener(rotationAnimationListener!);
    }
    if (elementAnimationCurved != null) {
      elementAnimationCurved.dispose();
    }
    if (elementController != null) {
      elementController.dispose();
    }
    if (puzzle.currentElementPositions.containsKey(element)) {
      setState(() {
        elementCells[element] = puzzle.currentElementPositions[element]!;
        relativeElementOffsets[element] = Offset.zero;
      });
    }
  }

  void _onElementRemoved(ChemicalElementRemovedEvent event) {
    AnimationController elementController =
        AnimationController(vsync: this, duration: _elementEnterLeaveAnimationDuration);
    CurvedAnimation elementAnimationCurved = CurvedAnimation(parent: elementController, curve: Curves.easeInCubic);
    Tween<Offset> elementTween = Tween(begin: Offset.zero, end: _getElementExitOffset(event.chamicalElement));
    Animation<Offset> elementOffsetAnimation = elementAnimationCurved.drive(elementTween);
    Tween<double> rotationTween = Tween(begin: 0, end: _getElementLeaveRotation());
    Animation<double> rotationAnimation = elementController.drive(rotationTween);
    elementAnimationControllers[event.chamicalElement] = elementController;
    elementAnimationsCurved[event.chamicalElement] = elementAnimationCurved;
    elementOffsetTweens[event.chamicalElement] = elementTween;
    elementOffsetAnimations[event.chamicalElement] = elementOffsetAnimation;
    elementRotationTweens[event.chamicalElement] = rotationTween;
    elementRotationAnimations[event.chamicalElement] = rotationAnimation;
    Function() rotationAnimationListener = () {
      setState(() {
        elementRotations[event.chamicalElement] = elementRotationAnimations[event.chamicalElement]!.value;
      });
    };
    Function() offsetAnimationListener = () {
      setState(() {
        relativeElementOffsets[event.chamicalElement] = elementOffsetAnimations[event.chamicalElement]!.value;
      });
    };
    elementOffsetAnimationListeners[event.chamicalElement] = offsetAnimationListener;
    elementRotationAnimationListeners[event.chamicalElement] = rotationAnimationListener;
    elementOffsetAnimation.addListener(offsetAnimationListener);
    rotationAnimation.addListener(rotationAnimationListener);
    elementController.forward().then((value) {
      _removeAllElementAnimationListeners(event.chamicalElement, true);
    });
  }

  void _onElementAdded(ChemicalelementAddedEvent event) {
    ChemicalElement added = event.chamicalElement;
    PuzzleCell cell = puzzle.currentElementPositions[added]!;
    setState(() {
      elementCells[added] = cell;
      relativeElementOffsets[added] = Offset.zero;
      elementRotations[added] = 0;
      elementCellOpacities[added] = 0;
    });
    Future delayed = Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        elementCellOpacities[added] = 1;
      });
    });
    delayed.ignore();
  }

  void _onMoveEvent(MoveEvent event) {
    var affectedElements = event.affectedElements;
    Axis moveAxis = event.move.axis;
    double cellSize = TableGrid.getCellSize(settings, containerSize);
    Map<ChemicalElement, double> targetElementMovementInAxis = {};
    double maxMovement = 0;
    SineCurve sineCurve = const SineCurve();
    for (var element in affectedElements) {
      PuzzleCell newCell = puzzle.currentElementPositions[element]!;
      PuzzleCell oldCell = elementCells[element]!;
      Offset currentRelativeOffset = relativeElementOffsets[element]!;
      Offset cellsOffset = puzzle.getRelativeOffset(oldCell, newCell);
      double cellsDistanceInAxis;
      double currentRelativeOffsetInAxis;
      if (moveAxis == Axis.vertical) {
        cellsDistanceInAxis = cellsOffset.dy;
        currentRelativeOffsetInAxis = currentRelativeOffset.dy;
      } else {
        cellsDistanceInAxis = cellsOffset.dx;
        currentRelativeOffsetInAxis = currentRelativeOffset.dx;
      }
      cellsDistanceInAxis *= cellSize;
      double targetMovement = cellsDistanceInAxis - currentRelativeOffsetInAxis;
      maxMovement = max(maxMovement, targetMovement.abs());
      targetElementMovementInAxis[element] = targetMovement;
    }
    Duration animationDuration = Duration(milliseconds: maxMovement ~/ _elementMoveSpeed);
    for (var element in affectedElements) {
      double elementMovement = targetElementMovementInAxis[element]!;
      double maxMovementRatio = elementMovement / maxMovement;
      double startT = sineCurve.tWhereValueIs(1 - maxMovementRatio.abs());
      DelayedSineCurve delayedCurve = DelayedSineCurve(delay: startT);
      Offset targetEndOffset;
      Offset currentOffset = relativeElementOffsets[element]!;
      if (moveAxis == Axis.vertical) {
        targetEndOffset = Offset(currentOffset.dx, currentOffset.dy + elementMovement);
      } else {
        targetEndOffset = Offset(currentOffset.dx + elementMovement, currentOffset.dy);
      }
      if (!elementAnimationControllers.containsKey(element)) {
        AnimationController elementController = AnimationController(vsync: this, duration: animationDuration);
        CurvedAnimation elementAnimationCurved = CurvedAnimation(parent: elementController, curve: delayedCurve);
        Tween<Offset> elementTween = Tween(begin: relativeElementOffsets[element], end: targetEndOffset);
        Animation<Offset> elementOffsetAnimation = elementAnimationCurved.drive(elementTween);
        elementAnimationControllers[element] = elementController;
        elementAnimationsCurved[element] = elementAnimationCurved;
        elementOffsetTweens[element] = elementTween;
        elementOffsetAnimations[element] = elementOffsetAnimation;
        Function() offsetAnimationListener = () {
          setState(() {
            relativeElementOffsets[element] = elementOffsetAnimations[element]!.value;
          });
        };
        elementOffsetAnimationListeners[element] = offsetAnimationListener;
        elementOffsetAnimation.addListener(offsetAnimationListener);
        elementController.forward().then((value) {
          _removeAllElementAnimationListeners(element, false);
        });
      } else {
        elementOffsetTweens[element]!.end = targetEndOffset;
      }
    }
  }

  void _onShuffleEvent(ShuffleEvent event) {
    double cellSize = TableGrid.getCellSize(settings, containerSize);
    for (ChemicalElement element in elementCells.keys) {
      PuzzleCell oldCell = elementCells[element]!;
      PuzzleCell newCell = puzzle.currentElementPositions[element]!;
      Offset cellsOffset = puzzle.getRelativeOffset(oldCell, newCell);
      cellsOffset *= cellSize;
      double distance = cellsOffset.distance;
      Duration animationDuration = Duration(milliseconds: distance ~/ _elementMoveSpeed);
      AnimationController elementController = AnimationController(vsync: this, duration: animationDuration);
      CurvedAnimation elementAnimationCurved = CurvedAnimation(parent: elementController, curve: const SineCurve());
      Tween<Offset> elementTween = Tween(begin: relativeElementOffsets[element], end: cellsOffset);
      Animation<Offset> elementOffsetAnimation = elementAnimationCurved.drive(elementTween);
      elementAnimationControllers[element] = elementController;
      elementAnimationsCurved[element] = elementAnimationCurved;
      elementOffsetTweens[element] = elementTween;
      elementOffsetAnimations[element] = elementOffsetAnimation;
      Function() offsetAnimationListener = () {
        setState(() {
          relativeElementOffsets[element] = elementOffsetAnimations[element]!.value;
        });
      };
      elementOffsetAnimationListeners[element] = offsetAnimationListener;
      elementOffsetAnimation.addListener(offsetAnimationListener);
      elementController.forward().then((value) {
        _removeAllElementAnimationListeners(element, false);
      });
    }
  }

  void _onGameFinishedEvent(GameFinishedEvent event) {
    settings.showRadiationEffects.value = true;
    settings.showAtomicMasses.value = true;
    settings.showAtomicNumbers.value = true;
    Future delayed = Future.delayed(const Duration(milliseconds: 1600), () async {
      var dialogResult = await GameFinishedDialog.showGameFinishedDialog(puzzle, context);
      if (dialogResult == GameFinishedDialogResult.NewGame) {
        GameTypeChooser.showGameTypeChooser(context, settings);
      }
    });
    delayed.ignore();
  }

  void _resetElementPosition(ChemicalElement element) {
    double distanceFromCell = relativeElementOffsets[element]!.distance;
    Duration animationDuration = Duration(milliseconds: distanceFromCell ~/ _elementMoveSpeed);
    AnimationController elementController = AnimationController(vsync: this, duration: animationDuration);
    CurvedAnimation elementAnimationCurved = CurvedAnimation(parent: elementController, curve: const SineCurve());
    Tween<Offset> elementTween = Tween(begin: relativeElementOffsets[element], end: Offset.zero);
    Animation<Offset> elementOffsetAnimation = elementAnimationCurved.drive(elementTween);
    elementAnimationControllers[element] = elementController;
    elementAnimationsCurved[element] = elementAnimationCurved;
    elementOffsetTweens[element] = elementTween;
    elementOffsetAnimations[element] = elementOffsetAnimation;
    Function() offsetAnimationListener = () {
      setState(() {
        relativeElementOffsets[element] = elementOffsetAnimations[element]!.value;
      });
    };
    elementOffsetAnimationListeners[element] = offsetAnimationListener;
    elementOffsetAnimation.addListener(offsetAnimationListener);
    elementController.forward().then((value) {
      _removeAllElementAnimationListeners(element, false);
    });
  }

  void _updateShowCells(bool newShowCells) {
    showCells = newShowCells;
    if (!showCells) {
      setState(() {
        for (var element in elementCellOpacities.keys) {
          elementCellOpacities[element] = 0;
        }
      });
    } else {
      var baseOffsets = _getCellBaseOffsets(containerSize);
      for (var element in elementCellOpacities.keys) {
        PuzzleCell elementCell = elementCells[element]!;
        Offset cellOffset = baseOffsets[elementCell]!;
        Duration delay = Duration(milliseconds: cellOffset.distance.toInt());
        Future delayed = Future.delayed(delay, () {
          setState(() {
            elementCellOpacities[element] = 1;
          });
        });
        delayed.ignore();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    containerSize = Size.zero;
    puzzle = widget.puzzle;
    showCells = widget.showCells;
    settings = widget.gameSettings;
    puzzle.addEventListener(_puzzleEventListener);
    elementCells = Map.of(puzzle.currentElementPositions);
    for (var element in puzzle.elements) {
      relativeElementOffsets[element] = Offset.zero;
      elementRotations[element] = 0;
      elementCellOpacities[element] = showCells ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(covariant DisplayPeriodicTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (puzzle != widget.puzzle) {
      puzzle.removeEventListener(_puzzleEventListener);
      puzzle = widget.puzzle;
      puzzle.addEventListener(_puzzleEventListener);
      for (var element in elementCells.keys) {
        _removeAllElementAnimationListeners(element, false);
      }
      elementCells = Map.of(puzzle.currentElementPositions);
      relativeElementOffsets.clear();
      elementRotations.clear();
      elementCellOpacities.clear();
      for (var element in puzzle.elements) {
        relativeElementOffsets[element] = Offset.zero;
        elementRotations[element] = 0;
        elementCellOpacities[element] = showCells ? 1 : 0;
      }
    }
    if (showCells != widget.showCells) {
      _updateShowCells(widget.showCells);
    }
    settings = widget.gameSettings;
  }

  @override
  void dispose() {
    puzzle.removeEventListener(_puzzleEventListener);
    for (var element in elementCells.keys) {
      _removeAllElementAnimationListeners(element, true);
    }
    super.dispose();
  }

  Map<PuzzleCell, Offset> _getCellBaseOffsets(Size containerSize) {
    Map<PuzzleCell, Offset> baseOffsets = {};
    Rect drawingArea = TableGrid.getTableDrawingSpace(settings, containerSize);
    Offset topLeftCellOffset =
        drawingArea.topLeft + Offset(settings.leftLineExtension.value, settings.topLineExtension.value);
    double cellSize = TableGrid.getCellSize(settings, containerSize);
    int y = 0;
    while (y < puzzle.periods.length) {
      var period = puzzle.periods[y];
      int x = 0;
      while (x < period.length) {
        var cell = period[x];
        if (cell != null) {
          baseOffsets[cell] = topLeftCellOffset + Offset(x * cellSize, y * cellSize);
        }
        x++;
      }
      y++;
    }
    return baseOffsets;
  }

  void _containerResized() {
    for (var movingElement in elementOffsetTweens.keys) {
      elementOffsetTweens[movingElement]!.end = _getElementExitOffset(movingElement);
    }
  }

  void _elementTapped(ChemicalElement element) {
    if (!puzzle.isGameStarted) {
      ElementInfoDialog.showElementInfoDialog(element, context);
    } else {
      var elementMoves = puzzle.getMovesForElement(element);
      if (elementMoves.length == 1) {
        puzzle.performMove(elementMoves.first);
      } else {
        setState(() {
          _showMoveAmbiguityMarks(element);
        });
      }
    }
  }

  void _showMoveAmbiguityMarks(ChemicalElement element) {
    List<PuzzleCell> emptyTargets = [];
    PuzzleCell? currentCell = elementCells[element];
    while (currentCell != null) {
      if (currentCell.content == null) {
        emptyTargets.add(currentCell);
      }
      currentCell = currentCell.topCell;
    }
    currentCell = elementCells[element];
    while (currentCell != null) {
      if (currentCell.content == null) {
        emptyTargets.add(currentCell);
      }
      currentCell = currentCell.bottomCell;
    }
    currentCell = elementCells[element];
    while (currentCell != null) {
      if (currentCell.content == null) {
        emptyTargets.add(currentCell);
      }
      currentCell = currentCell.leftCell;
    }
    currentCell = elementCells[element];
    while (currentCell != null) {
      if (currentCell.content == null) {
        emptyTargets.add(currentCell);
      }
      currentCell = currentCell.rightCell;
    }
    double cellSize = TableGrid.getCellSize(settings, containerSize);
    for (PuzzleCell target in emptyTargets) {
      AmbiguitySquare ambiguitySquare = AmbiguitySquare(
        key: ObjectKey(target),
        outsideSize: cellSize,
        blurAmount: 0,
        cornerRadius: 8,
        backgroundColor: settings.backgroundColor.value,
        onAnimationFinished: () {
          _removeAmbiguityMark(target);
        },
      );
      ambiguityCells[target] = ambiguitySquare;
    }
  }

  void _removeAmbiguityMark(PuzzleCell cell) {
    setState(() {
      ambiguityCells.remove(cell);
    });
  }

  void _elementDragStart(ChemicalElement element, DragStartDetails details, Axis axis) {
    elementDragStartingCoords[element] = details.globalPosition;
    elementDragLocalStartingCoords[element] = details.localPosition;
  }

  void _elementDragUpdate(ChemicalElement element, DragUpdateDetails details, Axis axis) {
    List<Move> moves = puzzle.getMovesForElement(element);
    if (moves.isEmpty) {
      return;
    }
    var movesInAxis = moves.where((move) => move.axis == axis);
    if (movesInAxis.isEmpty) {
      return;
    }
    var delta = details.globalPosition - elementDragStartingCoords[element]!;
    Offset grabPosition = elementDragLocalStartingCoords[element]!;
    double deltaInAxis;
    double grabPositionInAxis;
    if (axis == Axis.vertical) {
      deltaInAxis = delta.dy;
      grabPositionInAxis = grabPosition.dy;
    } else {
      deltaInAxis = delta.dx;
      grabPositionInAxis = grabPosition.dx;
    }

    double cellSize = TableGrid.getCellSize(settings, containerSize);
    double grabIntentOffset;
    if (deltaInAxis > 0) {
      grabIntentOffset = grabPositionInAxis;
    } else {
      grabIntentOffset = grabPositionInAxis - cellSize;
    }
    int intendedMoveAmount = (deltaInAxis + grabIntentOffset) ~/ cellSize; // may be zero
    int minAvailableMoveAmount = movesInAxis.first.amount;
    int maxAvailableMoveAmount = minAvailableMoveAmount;
    for (var move in movesInAxis) {
      var amount = move.amount;
      minAvailableMoveAmount = min(minAvailableMoveAmount, amount);
      maxAvailableMoveAmount = max(maxAvailableMoveAmount, amount);
    }
    if ((minAvailableMoveAmount.sign == maxAvailableMoveAmount.sign &&
            deltaInAxis.sign != maxAvailableMoveAmount.sign) ||
        deltaInAxis == 0) {
      // trying to move in wrong direction (no available moves in drag direction)
      intendedElementMoves.remove(element);
      List<ChemicalElement>? affectedElements = affectedMoveElements.remove(element);
      if (affectedElements != null) {
        for (var ae in affectedElements) {
          setState(() {
            relativeElementOffsets[ae] = Offset.zero;
          });
        }
      }
      return;
    }
    minAvailableMoveAmount = min(0, minAvailableMoveAmount);
    maxAvailableMoveAmount = max(0, maxAvailableMoveAmount);
    if (intendedMoveAmount > maxAvailableMoveAmount) {
      intendedMoveAmount = maxAvailableMoveAmount;
    }
    if (intendedMoveAmount < minAvailableMoveAmount) {
      intendedMoveAmount = minAvailableMoveAmount;
    }
    Move intendedMove;
    if (intendedMoveAmount != 0) {
      intendedMove = movesInAxis.firstWhere((move) => move.amount == intendedMoveAmount);
    } else {
      if (deltaInAxis > 0) {
        intendedMove = movesInAxis.firstWhere((move) => move.amount == 1);
      } else {
        intendedMove = movesInAxis.firstWhere((move) => move.amount == -1);
      }
    }
    if (deltaInAxis > cellSize * maxAvailableMoveAmount) {
      deltaInAxis = cellSize * maxAvailableMoveAmount;
    }
    if (deltaInAxis < cellSize * minAvailableMoveAmount) {
      deltaInAxis = cellSize * minAvailableMoveAmount;
    }
    Offset dragOffset;
    if (axis == Axis.vertical) {
      dragOffset = Offset(0, deltaInAxis);
    } else {
      dragOffset = Offset(deltaInAxis, 0);
    }
    List<ChemicalElement>? oldAffectedElements = affectedMoveElements[element];
    Map<ChemicalElement, int> newAffectedElements = puzzle.getElementsAffectedByMove(intendedMove);

    for (var ae in newAffectedElements.keys) {
      int elementMoveCells = newAffectedElements[ae]!;
      Offset multiStepDragCorrection;
      if (axis == Axis.vertical) {
        multiStepDragCorrection = Offset(0, (intendedMove.amount - elementMoveCells) * cellSize);
      } else {
        multiStepDragCorrection = Offset((intendedMove.amount - elementMoveCells) * cellSize, 0);
      }
      setState(() {
        relativeElementOffsets[ae] = dragOffset - multiStepDragCorrection;
      });
    }
    if (oldAffectedElements != null) {
      for (var ae in oldAffectedElements) {
        if (!newAffectedElements.keys.contains(ae)) {
          setState(() {
            relativeElementOffsets[ae] = Offset.zero;
          });
        }
      }
    }
    affectedMoveElements[element] = List.from(newAffectedElements.keys);
    if (intendedMoveAmount != 0) {
      intendedElementMoves[element] = intendedMove;
    } else {
      intendedElementMoves.remove(element);
    }
  }

  void _elementDragEnd(ChemicalElement element, DragEndDetails details, Axis axis) {
    elementDragStartingCoords.remove(element);
    elementDragLocalStartingCoords.remove(element);
    Move? intendedMove = intendedElementMoves.remove(element);
    if (intendedMove != null) {
      affectedMoveElements.remove(element);
      puzzle.performMove(intendedMove);
    } else {
      List<ChemicalElement>? affectedElements = affectedMoveElements.remove(element);
      if (affectedElements != null) {
        for (var ae in affectedElements) {
          _resetElementPosition(ae);
        }
      }
    }
  }

  void _elementLongPress(ChemicalElement element) {
    if (puzzle.isGameStarted) {
      puzzle.hintsUsed++;
    }
    ElementInfoDialog.showElementInfoDialog(element, context);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
      var oldContainerSize = containerSize;
      containerSize = constraints.biggest;
      if (oldContainerSize != containerSize) {
        _containerResized();
      }
      var cellBaseOffsets = _getCellBaseOffsets(containerSize);
      double cellSize = TableGrid.getCellSize(settings, containerSize);
      List<Widget> stackChildren = [];
      for (var element in elementCells.keys) {
        var elementCell = elementCells[element]!;
        Offset baseCellOffset = cellBaseOffsets[elementCell]!;
        Offset elementRelativeOffset = relativeElementOffsets[element]!;
        Rect positionedRect = (baseCellOffset + elementRelativeOffset) & Size(cellSize, cellSize);
        double elementSquareRotation = elementRotations[element]!;
        double elementCellOpacity = elementCellOpacities[element]!;
        GestureTapCallback tapHandler = () {
          _elementTapped(element);
        };
        GestureLongPressCallback longPressHandler = () {
          _elementLongPress(element);
        };
        GestureDragStartCallback vDragStartHandler = (details) {
          _elementDragStart(element, details, Axis.vertical);
        };
        GestureDragUpdateCallback vDragUpdateHandler = (details) {
          _elementDragUpdate(element, details, Axis.vertical);
        };
        GestureDragEndCallback vDragEndHandler = (details) {
          _elementDragEnd(element, details, Axis.vertical);
        };
        GestureDragStartCallback hDragStartHandler = (details) {
          _elementDragStart(element, details, Axis.horizontal);
        };
        GestureDragUpdateCallback hDragUpdateHandler = (details) {
          _elementDragUpdate(element, details, Axis.horizontal);
        };
        GestureDragEndCallback hDragEndHandler = (details) {
          _elementDragEnd(element, details, Axis.horizontal);
        };
        Positioned cellPositioned = Positioned.fromRect(
          key: ObjectKey(element),
          rect: positionedRect,
          child: ElementSquare(
            rotation: elementSquareRotation,
            opacity: elementCellOpacity,
            chemicalElement: element,
            gameTheme: settings,
            tapHandler: tapHandler,
            longPressHandler: longPressHandler,
            vDragStartHandler: vDragStartHandler,
            vDragUpdateHandler: vDragUpdateHandler,
            vDragEndHandler: vDragEndHandler,
            hDragStartHandler: hDragStartHandler,
            hDragUpdateHandler: hDragUpdateHandler,
            hDragEndHandler: hDragEndHandler,
          ),
        );
        stackChildren.add(cellPositioned);
      }
      for (var ambiguityCell in ambiguityCells.keys) {
        var ambiguityWidget = ambiguityCells[ambiguityCell]!;
        Offset baseCellOffset = cellBaseOffsets[ambiguityCell]!;
        Rect positionedRect = baseCellOffset & Size(cellSize, cellSize);
        Positioned ambiguityPositioned = Positioned.fromRect(
          key: ObjectKey(ambiguityCell),
          rect: positionedRect,
          child: ambiguityWidget,
        );
        stackChildren.add(ambiguityPositioned);
      }
      return Stack(
        fit: StackFit.passthrough,
        children: stackChildren,
      );
    });
  }
}
