import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/gui/GameTypeChooser.dart';
import 'package:periodic_table_puzzle/gui/TableGrid.dart';
import 'package:periodic_table_puzzle/gui/fullscreen/FullscreenStub.dart';
import 'package:periodic_table_puzzle/gui/fullscreen/FullscreenManager.dart';
import 'package:periodic_table_puzzle/models/events/GameFinished.dart';
import 'package:periodic_table_puzzle/models/events/GameStarted.dart';
import 'package:periodic_table_puzzle/models/events/PuzzleEvent.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class GameControls extends StatefulWidget {
  final SlidePuzzle puzzle;
  final GameSettings settings;

  const GameControls({Key? key, required this.puzzle, required this.settings}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GameControlsState();
  }
}

class _GameControlsState extends State<GameControls> with TickerProviderStateMixin {
  late SlidePuzzle puzzle;
  late GameSettings settings;
  late bool isGameStarted;
  late bool isGameFinished = false;
  late Size containerSize;
  late TableType tableType;
  late FullscreenManager fullscreenManager;
  bool building = false;

  final Map<_ButtonType, bool> buttonsShowing = {};
  final Map<_ButtonType, AnimationController> buttonOpacityControllers = {};
  final Map<_ButtonType, CurvedAnimation> buttonOpacityControllersCurved = {};
  final Map<_ButtonType, Function()> buttonOpacityHandlers = {};
  final Map<_ButtonType, double> buttonCurrentOpacities = {};
  final Map<_ButtonType, double> buttonTargetOpacities = {};
  final Map<_ButtonType, double> buttonStartingOpacities = {};
  final Map<_ButtonType, AnimationController> buttonOffsetControllers = {};
  final Map<_ButtonType, CurvedAnimation> buttonOffsetControllersCurved = {};
  final Map<_ButtonType, Tween<Offset>> buttonOffsetTweens = {};
  final Map<_ButtonType, Animation<Offset>> buttonOffsetAnimations = {};
  final Map<_ButtonType, Function()> buttonOffsetHandlers = {};
  final Map<_ButtonType, Offset> buttonCurrentOffsets = {};

  Duration get _buttonAnimationDuration {
    return const Duration(milliseconds: 700);
  }

  void puzzleEventHandler(PuzzleEvent event) {
    if (event is GameStartedEvent) {
      setState(() {
        isGameStarted = true;
        _updateButtonPositionsAndVisibility();
      });
    }
    if (event is GameFinishedEvent) {
      setState(() {
        isGameFinished = true;
        _updateButtonPositionsAndVisibility();
      });
    }
  }

  void tableTypeChanged() {
    setState(() {
      _updateButtonPositionsAndVisibility();
    });
  }

  _ButtonsBasePosition _calculateButtonsBasePosition() {
    Rect tableDrawingArea = TableGrid.getTableDrawingSpace(settings, containerSize);
    double spaceOnSide = tableDrawingArea.left;
    double spaceAtTop = tableDrawingArea.top;
    Axis axis;
    Offset buttonsOffset;
    if (spaceOnSide > spaceAtTop) {
      axis = Axis.vertical;
      buttonsOffset = Offset(spaceOnSide / 2, containerSize.height / 2);
    } else {
      axis = Axis.horizontal;
      buttonsOffset = Offset(containerSize.width / 2, spaceAtTop / 2);
    }
    return _ButtonsBasePosition(axis: axis, offset: buttonsOffset);
  }

  bool _shouldButtonTypeBeShown(_ButtonType bt) {
    if (bt == _ButtonType.StartGame) {
      return !isGameStarted;
    } else if (bt == _ButtonType.NewGame) {
      return isGameStarted;
    } else if (bt == _ButtonType.Hint) {
      return isGameStarted && !isGameFinished;
    } else if (bt == _ButtonType.Maximize) {
      return fullscreenManager.isAvailable && !fullscreenManager.isFullscreen.value;
    } else if (bt == _ButtonType.Minimize) {
      return fullscreenManager.isAvailable && fullscreenManager.isFullscreen.value;
    }
    return true;
  }

  Map<_ButtonType, Offset> _getButtonGlobalOffsets() {
    _ButtonsBasePosition basePosition = _calculateButtonsBasePosition();
    double buttonSize = _ActionButton.buttonSize;
    List<_ButtonType> buttons = _ButtonType.values;
    List<_ButtonType> shownButtons = [];
    for (var bt in buttons) {
      if (_shouldButtonTypeBeShown(bt)) {
        shownButtons.add(bt);
      }
    }
    Map<_ButtonType, Offset> offsets = {};
    double groupLength = buttonSize * shownButtons.length;
    int i = 0;
    while (i < buttons.length) {
      _ButtonType bt = buttons[i];
      int showIndex = shownButtons.indexOf(bt);
      if (showIndex < 0) {
        showIndex = shownButtons.length;
      }
      double offsetInAxis = -groupLength / 2 + showIndex * buttonSize;
      Offset offsetFromBase;
      if (basePosition.axis == Axis.vertical) {
        offsetFromBase = Offset(-buttonSize / 2, offsetInAxis);
      } else {
        offsetFromBase = Offset(offsetInAxis, -buttonSize / 2);
      }
      offsets[bt] = offsetFromBase + basePosition.offset;
      i++;
    }
    return offsets;
  }

  void _updateButtonPositionsAndVisibility() {
    Map<_ButtonType, Offset> globalOffsets = _getButtonGlobalOffsets();
    for (var bt in _ButtonType.values) {
      bool oldShowing = buttonsShowing[bt]!;
      bool newShowing = _shouldButtonTypeBeShown(bt);
      buttonsShowing[bt] = newShowing;
      if (oldShowing != newShowing) {
        double targetOpacity = newShowing ? 1 : 0;
        double startingOpacity = buttonCurrentOpacities[bt]!;
        buttonStartingOpacities[bt] = startingOpacity;
        buttonTargetOpacities[bt] = targetOpacity;
        buttonOpacityControllers[bt]!.forward(from: 0);
      }
      Offset oldTargetOffset = buttonOffsetTweens[bt]!.end!;
      Offset newTargetOffset = globalOffsets[bt]!;
      if (oldTargetOffset != newTargetOffset) {
        buttonOffsetTweens[bt]!.end = newTargetOffset;
        AnimationController offsetController = buttonOffsetControllers[bt]!;
        if (!offsetController.isAnimating) {
          Offset currentButtonOffset = buttonCurrentOffsets[bt]!;
          buttonOffsetTweens[bt]!.begin = currentButtonOffset;
          offsetController.forward(from: 0);
        }
      }
    }
  }

  void _buttonOpacityHandler(_ButtonType bt) {
    double startingOpacity = buttonStartingOpacities[bt]!;
    double targetOpacity = buttonTargetOpacities[bt]!;
    double animationValue = buttonOpacityControllersCurved[bt]!.value;
    double opacity = startingOpacity + (targetOpacity - startingOpacity) * animationValue;
    if (!building) {
      setState(() {
        buttonCurrentOpacities[bt] = opacity;
      });
    } else {
      buttonCurrentOpacities[bt] = opacity;
    }
  }

  void _buttonOffsetHandler(_ButtonType bt) {
    Offset currentOffset = buttonOffsetAnimations[bt]!.value;
    if (!building) {
      setState(() {
        buttonCurrentOffsets[bt] = currentOffset;
      });
    } else {
      buttonCurrentOffsets[bt] = currentOffset;
    }
  }

  void _newGamePressed() {
    GameTypeChooser.showGameTypeChooser(context, settings);
  }

  void _startGamePressed() {
    settings.showRadiationEffects.value = false;
    settings.showAtomicMasses.value = false;
    settings.showAtomicNumbers.value = false;
    puzzle.startGame();
  }

  void _hintPressed() {
    puzzle.useHint(settings);
  }

  void _minimizePressed() {
    fullscreenManager.isFullscreen.value = false;
  }

  void _maximizePressed() {
    fullscreenManager.isFullscreen.value = true;
  }

  _ActionButton _createWidgetForButtonType(_ButtonType bt) {
    IconData icon;
    Function() onAction;
    String tooltip;
    double opacity = buttonCurrentOpacities[bt]!;
    switch (bt) {
      case _ButtonType.StartGame:
        {
          icon = Icons.play_arrow;
          onAction = _startGamePressed;
          tooltip = "Start game";
        }
        break;
      case _ButtonType.NewGame:
        {
          icon = Icons.refresh;
          onAction = _newGamePressed;
          tooltip = "New game";
        }
        break;
      case _ButtonType.Hint:
        {
          icon = Icons.lightbulb_outline;
          onAction = _hintPressed;
          tooltip = "Hint";
        }
        break;
      case _ButtonType.Minimize:
        {
          icon = Icons.fit_screen;
          onAction = _minimizePressed;
          tooltip = "Exit fullscreen";
        }
        break;
      case _ButtonType.Maximize:
        {
          icon = Icons.fit_screen;
          onAction = _maximizePressed;
          tooltip = "Fullscreen";
        }
    }
    return _ActionButton(icon: Icon(icon), onAction: onAction, tooltip: tooltip, opacity: opacity);
  }

  @override
  void initState() {
    super.initState();
    fullscreenManager = getFullscreenManager();
    if (fullscreenManager.isAvailable) {
      fullscreenManager.isFullscreen.addListener(_updateButtonPositionsAndVisibility);
    }
    containerSize = Size.zero;
    puzzle = widget.puzzle;
    settings = widget.settings;
    isGameStarted = puzzle.isGameStarted;
    isGameFinished = puzzle.timeSpentSolving != null;
    settings.tableType.addListener(tableTypeChanged);
    tableType = settings.tableType.value;
    puzzle.addEventListener(puzzleEventHandler);
    for (_ButtonType buttonType in _ButtonType.values) {
      bool buttonShowing = _shouldButtonTypeBeShown(buttonType);
      buttonsShowing[buttonType] = buttonShowing;
      double targetOpacity = buttonShowing ? 1 : 0;
      buttonCurrentOpacities[buttonType] = 0;
      buttonStartingOpacities[buttonType] = 0;
      buttonTargetOpacities[buttonType] = targetOpacity;
      AnimationController opacityController = AnimationController(vsync: this, duration: _buttonAnimationDuration);
      CurvedAnimation opacityCurved = CurvedAnimation(parent: opacityController, curve: Curves.easeInOut);
      var opacityHandler = () {
        _buttonOpacityHandler(buttonType);
      };
      buttonOpacityHandlers[buttonType] = opacityHandler;
      opacityCurved.addListener(opacityHandler);
      buttonOpacityControllers[buttonType] = opacityController;
      buttonOpacityControllersCurved[buttonType] = opacityCurved;
      opacityController.forward(from: 0);

      buttonCurrentOffsets[buttonType] = Offset.zero;
      AnimationController offsetController = AnimationController(vsync: this, duration: _buttonAnimationDuration);
      CurvedAnimation offsetCurved = CurvedAnimation(parent: offsetController, curve: Curves.easeOutBack);
      Tween<Offset> offsetTween = Tween(begin: Offset.zero, end: Offset.zero);
      Animation<Offset> offsetAnimation = offsetCurved.drive(offsetTween);
      var offsetHandler = () {
        _buttonOffsetHandler(buttonType);
      };
      buttonOffsetHandlers[buttonType] = offsetHandler;
      offsetAnimation.addListener(offsetHandler);
      buttonOffsetControllers[buttonType] = offsetController;
      buttonOffsetControllersCurved[buttonType] = offsetCurved;
      buttonOffsetTweens[buttonType] = offsetTween;
      buttonOffsetAnimations[buttonType] = offsetAnimation;
    }
  }

  @override
  void didUpdateWidget(covariant GameControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (puzzle != widget.puzzle) {
      puzzle.removeEventListener(puzzleEventHandler);
      puzzle = widget.puzzle;
      puzzle.addEventListener(puzzleEventHandler);
      isGameStarted = puzzle.isGameStarted;
      isGameFinished = puzzle.timeSpentSolving != null;
    }
    if (settings != widget.settings) {
      settings.tableType.removeListener(tableTypeChanged);
      settings = widget.settings;
      settings.tableType.addListener(tableTypeChanged);
      tableType = settings.tableType.value;
    }
  }

  @override
  void dispose() {
    puzzle.removeEventListener(puzzleEventHandler);
    settings.tableType.removeListener(tableTypeChanged);
    if (fullscreenManager.isAvailable) {
      fullscreenManager.isFullscreen.removeListener(_updateButtonPositionsAndVisibility);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
      building = true;
      containerSize = constraints.biggest;
      _updateButtonPositionsAndVisibility();
      List<Positioned> stackChildren = [];
      for (_ButtonType bt in _ButtonType.values) {
        Offset offset = buttonCurrentOffsets[bt]!;
        Size buttonSize = const Size(_ActionButton.buttonSize, _ActionButton.buttonSize);
        Rect positionedRect = offset & buttonSize;
        Positioned positioned = Positioned.fromRect(
          rect: positionedRect,
          key: ObjectKey(bt),
          child: _createWidgetForButtonType(bt),
        );
        stackChildren.add(positioned);
      }
      ConstrainedBox constrainedBox = ConstrainedBox(
        constraints: BoxConstraints.tight(containerSize),
        child: Stack(
          fit: StackFit.passthrough,
          children: stackChildren,
        ),
      );
      building = false;
      return constrainedBox;
    });
  }
}

enum _ButtonType { StartGame, NewGame, Hint, Maximize, Minimize }

class _ButtonsBasePosition {
  final Offset offset;
  final Axis axis;
  _ButtonsBasePosition({required this.axis, required this.offset});
}

class _ActionButton extends StatelessWidget {
  static const double buttonSize = 85;
  final Icon icon;
  final Function() onAction;
  final String? tooltip;
  final double opacity;

  const _ActionButton(
      {Key? key, required this.icon, required this.onAction, required this.tooltip, required this.opacity})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget p = Padding(
      padding: const EdgeInsets.all(20),
      child: Ink(
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: const Color(0xff749379).withOpacity(opacity),
        ),
        child: IconButton(
          onPressed: opacity < 1 ? null : onAction,
          icon: icon,
          color: Colors.white,
          tooltip: tooltip,
        ),
      ),
    );
    if (opacity < 1) {
      p = Opacity(
        opacity: opacity,
        child: p,
      );
      p = IgnorePointer(
        child: p,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: buttonSize, height: buttonSize),
      child: p,
    );
  }
}
