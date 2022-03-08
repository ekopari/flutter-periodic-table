import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/GameControls.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/gui/PeriodicTable.dart';
import 'package:periodic_table_puzzle/gui/TableGrid.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class SlideGameUI extends StatefulWidget {
  final GameSettings settings;

  const SlideGameUI({Key? key, required this.settings}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SlideGameUIState();
  }
}

class _SlideGameUIState extends State<SlideGameUI> {
  late GameSettings settings;
  late SlidePuzzle puzzle;

  static const displayDelay = 0; // seconds

  bool displaying = false;
  bool showCells = false;

  void _tableTypeChanged() {
    setState(() {
      showCells = false;
    });
  }

  void _puzzleChanged() {
    setState(() {
      puzzle = settings.puzzle.value;
    });
  }

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
    puzzle = settings.puzzle.value;
    settings.tableType.addListener(_tableTypeChanged);
    settings.puzzle.addListener(_puzzleChanged);
    Future delayed = Future.delayed(Duration(seconds: displayDelay), () {
      setState(() {
        displaying = true;
      });
    });
  }

  @override
  void didUpdateWidget(covariant SlideGameUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (settings != widget.settings) {
      settings.tableType.removeListener(_tableTypeChanged);
      settings.puzzle.removeListener(_puzzleChanged);
      if (settings.tableType.value != widget.settings.tableType.value) {
        showCells = false;
      }
      settings = widget.settings;
      settings.tableType.addListener(_tableTypeChanged);
      settings.puzzle.addListener(_puzzleChanged);
    }
    if (puzzle != settings.puzzle.value) {
      _puzzleChanged();
    }
  }

  @override
  void dispose() {
    settings.tableType.removeListener(_tableTypeChanged);
    settings.puzzle.removeListener(_puzzleChanged);
    super.dispose();
  }

  void _onLineAnimationsFinished() {
    setState(() {
      showCells = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!displaying) {
      return Container();
    }
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
      return ConstrainedBox(
        constraints: BoxConstraints.tight(constraints.biggest),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            RepaintBoundary(
              child: TableGrid(gameSettings: settings, onAnimationsFinished: _onLineAnimationsFinished),
            ),
            RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: DisplayPeriodicTable(puzzle: puzzle, gameSettings: settings, showCells: showCells),
              ),
            ),
            GameControls(puzzle: puzzle, settings: settings),
          ],
        ),
      );
      // return Stack(
      //   fit: StackFit.passthrough,
      //   children: [
      //     RepaintBoundary(
      //       child: TableGrid(gameSettings: settings, onAnimationsFinished: _onLineAnimationsFinished),
      //     ),
      //     RepaintBoundary(
      //       child: DisplayPeriodicTable(puzzle: puzzle, gameSettings: settings, showCells: showCells),
      //     ),
      //     GameControls(puzzle: puzzle, settings: settings),
      //   ],
      // );
    });
  }
}
