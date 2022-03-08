import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/models/ChemicalElement.dart';

class ElementSquare extends StatefulWidget {
  final GameSettings gameTheme;
  final ChemicalElement chemicalElement;
  final double rotation;
  final double opacity;
  final GestureDragStartCallback? hDragStartHandler;
  final GestureDragUpdateCallback? hDragUpdateHandler;
  final GestureDragEndCallback? hDragEndHandler;
  final GestureDragStartCallback? vDragStartHandler;
  final GestureDragUpdateCallback? vDragUpdateHandler;
  final GestureDragEndCallback? vDragEndHandler;
  final GestureTapCallback? tapHandler;
  final GestureLongPressCallback? longPressHandler;

  const ElementSquare({
    Key? key,
    required this.gameTheme,
    required this.chemicalElement,
    required this.rotation,
    required this.opacity,
    this.hDragStartHandler,
    this.hDragUpdateHandler,
    this.hDragEndHandler,
    this.vDragStartHandler,
    this.vDragUpdateHandler,
    this.vDragEndHandler,
    this.tapHandler,
    this.longPressHandler,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ElementSquareState();
  }
}

class _ElementSquareState extends State<ElementSquare> with TickerProviderStateMixin {
  late GameSettings gameTheme;
  late ChemicalElement chemicalElement;
  late double rotation;
  late Random random;

  Offset _boxStartOffset = Offset.zero;
  Offset _boxOffset = Offset.zero;
  Offset _boxTargetOffset = Offset.zero;
  AnimationController? _radioactivityOscillationController;

  late Color _backgroundColor;
  late AnimationController _backgroundColorController;
  late CurvedAnimation _backgroundColorCurved;
  late Tween<Color?> _backgroundColorTween;
  late Animation<Color?> _backgroundColorAnimation;

  late double _atomicNumberOpacity;
  late AnimationController _atomicNumberOpacityController;
  late CurvedAnimation _atomicNumberOpacityCurved;

  late double _atomicMassOpacity;
  late AnimationController _atomicMassOpacityController;
  late CurvedAnimation _atomicMassOpacityCurved;

  late double _cellOpacity;
  late double _targetCellOpacity;
  late double _startingCellOpacity;
  late AnimationController _cellOpacityController;
  late CurvedAnimation _cellOpacityCurved;

  GestureDragStartCallback? hDragStartHandler;
  GestureDragUpdateCallback? hDragUpdateHandler;
  GestureDragEndCallback? hDragEndHandler;
  GestureDragStartCallback? vDragStartHandler;
  GestureDragUpdateCallback? vDragUpdateHandler;
  GestureDragEndCallback? vDragEndHandler;
  GestureTapCallback? tapHandler;
  GestureLongPressCallback? longPressHandler;

  Duration get _textOpacityAnimationDuration {
    return const Duration(milliseconds: 1500);
  }

  Duration get _cellOpacityAnimationDuration {
    return const Duration(milliseconds: 1200);
  }

  void _assignNewTargetOffset() {
    _boxStartOffset = _boxOffset;
    if (gameTheme.showRadiationEffects.value) {
      double dx = (random.nextDouble() * 2 - 1) * _cellPadding / 2;
      double dy = (random.nextDouble() * 2 - 1) * _cellPadding / 2;
      _boxTargetOffset = Offset(dx, dy);
    } else {
      _boxTargetOffset = Offset.zero;
    }
  }

  void _radioactivityOscillationValueChanged() {
    var trajectory = _boxTargetOffset - _boxStartOffset;
    setState(() {
      _boxOffset = _boxStartOffset + trajectory * _radioactivityOscillationController!.value;
    });
  }

  void _targetOpacityChanged(double newTargetOpacity) {
    _startingCellOpacity = _cellOpacity;
    _targetCellOpacity = newTargetOpacity;
    _cellOpacityController.forward(from: 0);
  }

  void _repeatRadioactivityAnimation() {
    if (_radioactivityOscillationController == null) {
      return;
    }
    _assignNewTargetOffset();
    _radioactivityOscillationController!.forward(from: 0).then((value) {
      if (gameTheme.showRadiationEffects.value) {
        _repeatRadioactivityAnimation();
      } else {
        _assignNewTargetOffset();
        _radioactivityOscillationController!.forward(from: 0);
      }
    });
  }

  void _backgroundColorHandler() {
    setState(() {
      _backgroundColor = _backgroundColorAnimation.value!;
    });
  }

  void _atomicNumberOpacityHandler() {
    setState(() {
      _atomicNumberOpacity = _atomicNumberOpacityCurved.value;
    });
  }

  void _atomicMassOpacityHandler() {
    setState(() {
      _atomicMassOpacity = _atomicMassOpacityCurved.value;
    });
  }

  void _cellOpacityHandler() {
    double delta = (_targetCellOpacity - _startingCellOpacity) * _cellOpacityCurved.value;
    setState(() {
      _cellOpacity = _startingCellOpacity + delta;
    });
  }

  void _themeUpdateHandler() {
    if (gameTheme.showRadiationEffects.value) {
      _repeatRadioactivityAnimation();
    }
    if (gameTheme.showAtomicNumbers.value) {
      _atomicNumberOpacityController.forward();
    } else {
      _atomicNumberOpacityController.reverse();
    }
    if (gameTheme.showAtomicMasses.value) {
      _atomicMassOpacityController.forward();
    } else {
      _atomicMassOpacityController.reverse();
    }
    if (_backgroundColor != gameTheme.backgroundColor.value) {
      _backgroundColorTween.begin = _backgroundColor;
      _backgroundColorTween.end = gameTheme.backgroundColor.value;
      _backgroundColorController.forward(from: 0);
    }
  }

  void _elementChangedHandler() {
    _boxOffset = Offset.zero;
    _boxStartOffset = Offset.zero;
    _boxTargetOffset = Offset.zero;
    if (_radioactivityOscillationController != null) {
      _radioactivityOscillationController!.removeListener(_radioactivityOscillationValueChanged);
      _radioactivityOscillationController!.dispose();
      _radioactivityOscillationController = null;
    }
    if (chemicalElement.radioactivity > 0) {
      Duration animationDuration = Duration(milliseconds: 50000 ~/ chemicalElement.radioactivity);
      _radioactivityOscillationController = AnimationController(
        vsync: this,
        duration: animationDuration,
      );
      _radioactivityOscillationController!.addListener(_radioactivityOscillationValueChanged);
      _repeatRadioactivityAnimation();
    }
  }

  void _updateGestureHandlers() {
    tapHandler = widget.tapHandler;
    longPressHandler = widget.longPressHandler;
    vDragStartHandler = widget.vDragStartHandler;
    vDragUpdateHandler = widget.vDragUpdateHandler;
    vDragEndHandler = widget.vDragEndHandler;
    hDragStartHandler = widget.hDragStartHandler;
    hDragUpdateHandler = widget.hDragUpdateHandler;
    hDragEndHandler = widget.hDragEndHandler;
  }

  @override
  void initState() {
    super.initState();
    _updateGestureHandlers();
    rotation = widget.rotation;
    gameTheme = widget.gameTheme;
    chemicalElement = widget.chemicalElement;
    random = Random(chemicalElement.atomicNumber);
    _backgroundColor = gameTheme.backgroundColor.value;
    _backgroundColorController = AnimationController(vsync: this, duration: _textOpacityAnimationDuration);
    _backgroundColorCurved = CurvedAnimation(parent: _backgroundColorController, curve: Curves.easeInOut);
    _backgroundColorTween = ColorTween(begin: _backgroundColor, end: _backgroundColor);
    _backgroundColorAnimation = _backgroundColorCurved.drive(_backgroundColorTween);
    _backgroundColorAnimation.addListener(_backgroundColorHandler);
    _atomicNumberOpacityController = AnimationController(
        vsync: this, duration: _textOpacityAnimationDuration, value: gameTheme.showAtomicNumbers.value ? 1 : 0);
    _atomicNumberOpacity = _atomicNumberOpacityController.value;
    _atomicNumberOpacityCurved = CurvedAnimation(parent: _atomicNumberOpacityController, curve: Curves.easeInOut);
    _atomicNumberOpacityCurved.addListener(_atomicNumberOpacityHandler);
    _atomicMassOpacityController = AnimationController(
        vsync: this, duration: _textOpacityAnimationDuration, value: gameTheme.showAtomicMasses.value ? 1 : 0);
    _atomicMassOpacity = _atomicMassOpacityController.value;
    _atomicMassOpacityCurved = CurvedAnimation(parent: _atomicMassOpacityController, curve: Curves.easeInOut);
    _atomicMassOpacityCurved.addListener(_atomicMassOpacityHandler);
    _cellOpacity = widget.opacity;
    _targetCellOpacity = _cellOpacity;
    _startingCellOpacity = _cellOpacity;
    _cellOpacityController =
        AnimationController(vsync: this, duration: _cellOpacityAnimationDuration, value: _cellOpacity);
    _cellOpacityCurved = CurvedAnimation(parent: _cellOpacityController, curve: Curves.easeInOut);
    _cellOpacityCurved.addListener(_cellOpacityHandler);
    _addListeners(gameTheme);
    _themeUpdateHandler();
    _elementChangedHandler();
  }

  void _addListeners(GameSettings theme) {
    theme.backgroundColor.addListener(_themeUpdateHandler);
    theme.showAtomicMasses.addListener(_themeUpdateHandler);
    theme.showAtomicNumbers.addListener(_themeUpdateHandler);
    theme.showRadiationEffects.addListener(_themeUpdateHandler);
  }

  void _removeListeners(GameSettings theme) {
    theme.backgroundColor.removeListener(_themeUpdateHandler);
    theme.showAtomicMasses.removeListener(_themeUpdateHandler);
    theme.showAtomicNumbers.removeListener(_themeUpdateHandler);
    theme.showRadiationEffects.removeListener(_themeUpdateHandler);
  }

  @override
  void didUpdateWidget(covariant ElementSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateGestureHandlers();
    rotation = widget.rotation;
    if (oldWidget.gameTheme != widget.gameTheme) {
      _removeListeners(oldWidget.gameTheme);
      gameTheme = widget.gameTheme;
      _addListeners(gameTheme);
      _themeUpdateHandler();
    }
    if (widget.chemicalElement != oldWidget.chemicalElement) {
      chemicalElement = widget.chemicalElement;
      _elementChangedHandler();
    }
    if (widget.opacity != _targetCellOpacity) {
      _targetOpacityChanged(widget.opacity);
    }
  }

  @override
  void dispose() {
    _removeListeners(gameTheme);
    if (_radioactivityOscillationController != null) {
      _radioactivityOscillationController!.removeListener(_radioactivityOscillationValueChanged);
      _radioactivityOscillationController!.dispose();
      _radioactivityOscillationController = null;
    }
    _backgroundColorAnimation.removeListener(_backgroundColorHandler);
    _backgroundColorCurved.dispose();
    _backgroundColorController.dispose();
    _atomicNumberOpacityCurved.removeListener(_atomicNumberOpacityHandler);
    _atomicNumberOpacityCurved.dispose();
    _atomicNumberOpacityController.dispose();
    _atomicMassOpacityCurved.removeListener(_atomicMassOpacityHandler);
    _atomicMassOpacityCurved.dispose();
    _atomicMassOpacityController.dispose();
    _cellOpacityCurved.removeListener(_cellOpacityHandler);
    _cellOpacityCurved.dispose();
    _cellOpacityController.dispose();
    super.dispose();
  }

  double get _cellPadding {
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    LayoutBuilder layoutBuilder = LayoutBuilder(
      builder: (ctx, constraints) {
        var insideSize = min(constraints.maxHeight - _cellPadding, constraints.maxWidth - _cellPadding);
        Matrix4 transformMatrix = Matrix4.translationValues(_boxOffset.dx, _boxOffset.dy, 0);
        return Padding(
          padding: EdgeInsets.all(_cellPadding),
          child: Transform(
            transform: transformMatrix,
            child: _ElementSquareDisplay(
                rotation: rotation,
                cellOpacity: _cellOpacity,
                chemicalElement: chemicalElement,
                outsideSize: insideSize,
                atomicMassOpacity: _atomicMassOpacity,
                atomicNumberOpacity: _atomicNumberOpacity,
                blurAmount: 0,
                cornerRadius: 8,
                borderWidth: 3,
                backgroundColor: _backgroundColor),
          ),
        );
      },
    );
    GestureDetector gestureDetector = GestureDetector(
      child: layoutBuilder,
      onTap: tapHandler,
      onLongPress: longPressHandler,
      onVerticalDragStart: vDragStartHandler,
      onVerticalDragUpdate: vDragUpdateHandler,
      onVerticalDragEnd: vDragEndHandler,
      onHorizontalDragStart: hDragStartHandler,
      onHorizontalDragUpdate: hDragUpdateHandler,
      onHorizontalDragEnd: hDragEndHandler,
    );
    return RepaintBoundary(
      child: gestureDetector,
    );
  }
}

class _ElementSquareDisplay extends StatelessWidget {
  final ChemicalElement chemicalElement;
  final double outsideSize;
  final double atomicNumberOpacity;
  final double atomicMassOpacity;
  final double blurAmount;
  final double cornerRadius;
  final double borderWidth;
  final Color backgroundColor;
  final double rotation;
  final double cellOpacity;

  const _ElementSquareDisplay({
    Key? key,
    required this.chemicalElement,
    required this.outsideSize,
    required this.atomicMassOpacity,
    required this.atomicNumberOpacity,
    required this.blurAmount,
    required this.cornerRadius,
    required this.borderWidth,
    required this.backgroundColor,
    required this.rotation,
    required this.cellOpacity,
  }) : super(key: key);

  double get _containerSize {
    return outsideSize - blurAmount * 2;
  }

  double get _symbolFontSize {
    return _containerSize / 2.3;
  }

  double get _detailsFontSize {
    return _containerSize / 6.5;
  }

  double get _atomicNumberDisplayOffset {
    return _containerSize / 10;
  }

  double get _atomicMassDisplayOffset {
    return _containerSize / 14;
  }

  @override
  Widget build(BuildContext context) {
    Color elementColor;
    if (chemicalElement.emissionColor != null) {
      elementColor = chemicalElement.emissionColor!;
    } else {
      elementColor = Colors.white;
    }
    List<Widget> stackChildren = [
      Transform.rotate(
        angle: rotation,
        child: Container(
          width: _containerSize,
          height: _containerSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(cornerRadius)),
            // border: Border.all(
            //   color: elementColor,
            //   width: borderWidth,
            // ),
          ),
          child: Center(
            child: Text(
              chemicalElement.symbol,
              style: TextStyle(
                color: elementColor,
                fontSize: _symbolFontSize,
              ),
            ),
          ),
        ),
      ),
    ];
    stackChildren.add(
      Positioned.fill(
        top: _atomicNumberDisplayOffset,
        left: _atomicNumberDisplayOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            key: const Key("atomicNumber"),
            opacity: atomicNumberOpacity,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                chemicalElement.atomicNumber.toString(),
                style: TextStyle(
                  color: elementColor.withOpacity(atomicNumberOpacity),
                  fontSize: _detailsFontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    String atomicMassDisplay;
    if (chemicalElement.atomicMass != null) {
      atomicMassDisplay = chemicalElement.atomicMass!.toString();
      if (chemicalElement.isArtificial) {
        atomicMassDisplay = "[$atomicMassDisplay]";
      }
    } else {
      atomicMassDisplay = "?";
    }
    stackChildren.add(
      Positioned.fill(
        bottom: _atomicMassDisplayOffset,
        right: _atomicMassDisplayOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            key: const Key("atomicMass"),
            opacity: atomicMassOpacity,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                atomicMassDisplay,
                style: TextStyle(
                  color: elementColor.withOpacity(atomicMassOpacity),
                  fontSize: _detailsFontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // if (blurAmount > 0) {
    //   stackChildren.add(
    //     ClipRRect(
    //       key: const Key("blur"),
    //       borderRadius: BorderRadius.all(Radius.circular(cornerRadius)),
    //       child: BackdropFilter(
    //         filter: ImageFilter.blur(
    //           sigmaX: blurAmount,
    //           sigmaY: blurAmount,
    //         ),
    //         child: Container(
    //           color: Colors.black.withOpacity(0),
    //           width: outsideSize,
    //           height: outsideSize,
    //         ),
    //       ),
    //     ),
    //   );
    // }
    Widget w = Stack(
      alignment: Alignment.center,
      fit: StackFit.passthrough,
      children: stackChildren,
    );
    if (cellOpacity < 1) {
      w = Opacity(
        opacity: cellOpacity,
        child: w,
      );
    }
    if (blurAmount > 0) {
      w = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: w,
      );
    }
    return w;
  }
}

class AmbiguitySquare extends StatefulWidget {
  final double outsideSize;
  final double blurAmount;
  final double cornerRadius;
  final Color backgroundColor;
  final Function() onAnimationFinished;

  const AmbiguitySquare({
    Key? key,
    required this.outsideSize,
    required this.blurAmount,
    required this.cornerRadius,
    required this.backgroundColor,
    required this.onAnimationFinished,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AmbiguitySquareState();
  }
}

class _AmbiguitySquareState extends State<AmbiguitySquare> with SingleTickerProviderStateMixin {
  late double outsideSize;
  late double blurAmount;
  late double cornerRadius;
  late Color backgroundColor;
  late double cellOpacity;
  late Function() animationsFinishedHandler;
  late AnimationController opacityController;
  late CurvedAnimation opacityCurved;

  Duration get _fadeAnimationDurationOneWay {
    return const Duration(milliseconds: 600);
  }

  void _opacityHandler() {
    setState(() {
      cellOpacity = opacityCurved.value;
    });
  }

  void _animationsFinished() {
    animationsFinishedHandler();
  }

  @override
  void initState() {
    super.initState();
    outsideSize = widget.outsideSize;
    blurAmount = widget.blurAmount;
    cornerRadius = widget.cornerRadius;
    backgroundColor = widget.backgroundColor;
    animationsFinishedHandler = widget.onAnimationFinished;
    cellOpacity = 0;
    opacityController = AnimationController(vsync: this, duration: _fadeAnimationDurationOneWay);
    opacityCurved = CurvedAnimation(parent: opacityController, curve: Curves.easeInOut);
    opacityCurved.addListener(_opacityHandler);
    opacityController.forward(from: 0).then((value) async {
      await opacityController.reverse(from: 1);
    }).then((value) {
      _animationsFinished();
    });
  }

  @override
  void didUpdateWidget(covariant AmbiguitySquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    outsideSize = widget.outsideSize;
    blurAmount = widget.blurAmount;
    cornerRadius = widget.cornerRadius;
    backgroundColor = widget.backgroundColor;
    animationsFinishedHandler = widget.onAnimationFinished;
  }

  @override
  void dispose() {
    opacityCurved.removeListener(_opacityHandler);
    opacityCurved.dispose();
    opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AmbiguityCellDisplay(
      outsideSize: outsideSize,
      blurAmount: blurAmount,
      cornerRadius: cornerRadius,
      backgroundColor: backgroundColor,
      cellOpacity: cellOpacity,
    );
  }
}

class _AmbiguityCellDisplay extends StatelessWidget {
  final double outsideSize;
  final double blurAmount;
  final double cornerRadius;
  final Color backgroundColor;
  final double cellOpacity;

  const _AmbiguityCellDisplay({
    Key? key,
    required this.outsideSize,
    required this.blurAmount,
    required this.cornerRadius,
    required this.backgroundColor,
    required this.cellOpacity,
  }) : super(key: key);

  double get _containerSize {
    return outsideSize - blurAmount * 2;
  }

  Color get _ambiguityColor {
    return Colors.grey.shade200;
  }

  double get _symbolFontSize {
    return _containerSize / 2;
  }

  double get _cellPadding {
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    Container container = Container(
      width: _containerSize - _cellPadding,
      height: _containerSize - _cellPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(cornerRadius)),
        // border: Border.all(
        //   color: elementColor,
        //   width: borderWidth,
        // ),
      ),
      child: Center(
        child: Text(
          "?",
          style: TextStyle(
            color: _ambiguityColor,
            fontSize: _symbolFontSize,
          ),
        ),
      ),
    );
    Widget w = Padding(
      padding: EdgeInsets.all(_cellPadding),
      child: container,
    );
    if (cellOpacity < 1) {
      w = Opacity(
        opacity: cellOpacity,
        child: w,
      );
    }
    if (blurAmount > 0) {
      w = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: w,
      );
    }
    return w;
  }
}
