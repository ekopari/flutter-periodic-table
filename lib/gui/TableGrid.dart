import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';

class TableGrid extends StatefulWidget {
  final GameSettings gameSettings;
  final Function() onAnimationsFinished;
  const TableGrid({Key? key, required this.gameSettings, required this.onAnimationsFinished}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TableGridState();
  }

  static double getCellSize(GameSettings settings, Size size) {
    double width = size.width;
    double height = size.height;
    double availableWidth = width - settings.minimumTablePadding.value * 2;
    double availableHeight = height - settings.minimumTablePadding.value * 2;
    int numCols = settings.tableWidth;
    int numRows = settings.tableHeight;
    double availableCellsWidth = availableWidth - settings.leftLineExtension.value;
    double availableCellsHeight = availableHeight - settings.topLineExtension.value;
    double cellMaxWidth = availableCellsWidth / numCols;
    double cellMaxHeight = availableCellsHeight / numRows;
    double cellSize = min(cellMaxHeight, cellMaxWidth);
    return cellSize;
  }

  static Rect getTableDrawingSpace(GameSettings settings, Size size) {
    double cellSize = getCellSize(settings, size);
    double requiredWidth = cellSize * settings.tableWidth + settings.leftLineExtension.value;
    double requiredHeight = cellSize * settings.tableHeight + settings.topLineExtension.value;
    double startX = (size.width - requiredWidth) / 2;
    double startY = (size.height - requiredHeight) / 2;
    return Rect.fromLTWH(startX, startY, requiredWidth, requiredHeight);
  }
}

class _TableGridState extends State<TableGrid> with TickerProviderStateMixin {
  double time = 0;
  late Ticker ticker;

  late GameSettings settings;
  late double minimumTablePadding;
  late double leftLineExtension;
  late double topLineExtension;
  late TableType tableType;
  late Function() onAnimationsFinished;
  final List<_GridLineDescription> _lineDescriptions = [];
  final List<_GridColRowDefinition> _labelDescriptions = [];
  final List<Function()> _lineAnimationFinishedHandlers = [];
  final Map<_GridLineDescription, _GridLineStatusInTable> _currentLineStatuses = {};

  void _onTick(Duration ellapsed) {
    setState(() {
      time = ellapsed.inMilliseconds.toDouble() / 1000;
    });
  }

  Duration get _lineAnimationStaggerDuration {
    return const Duration(milliseconds: 80);
  }

  void _sizingSettingsHandler() {
    setState(() {
      minimumTablePadding = settings.minimumTablePadding.value;
      leftLineExtension = settings.leftLineExtension.value;
      topLineExtension = settings.leftLineExtension.value;
    });
  }

  void _tableTypeHandler() {
    var oldTableType = tableType;
    tableType = settings.tableType.value;
    for (var lineDescription in _lineDescriptions) {
      bool shouldBePresent = lineDescription.isPresentInTableType(tableType);
      bool wasPresent = lineDescription.isPresentInTableType(oldTableType);
      _GridLineStatusInTable newLineStatus;
      if (shouldBePresent && wasPresent) {
        newLineStatus = _GridLineStatusInTable.Rearranging;
      } else if (shouldBePresent && !wasPresent) {
        newLineStatus = _GridLineStatusInTable.Entering;
      } else if (!shouldBePresent && wasPresent) {
        newLineStatus = _GridLineStatusInTable.Leaving;
      } else {
        newLineStatus = _GridLineStatusInTable.Left;
      }
      _currentLineStatuses[lineDescription] = newLineStatus;
    }
  }

  void _onLineAnimationFinished(_GridLineDescription lineDescription) {
    _GridLineStatusInTable lineStatus = _currentLineStatuses[lineDescription]!;
    _GridLineStatusInTable newLineStatus;
    if (lineStatus == _GridLineStatusInTable.Leaving) {
      newLineStatus = _GridLineStatusInTable.Left;
    } else if (lineStatus == _GridLineStatusInTable.Entering) {
      newLineStatus = _GridLineStatusInTable.InPosition;
    } else if (lineStatus == _GridLineStatusInTable.Rearranging) {
      newLineStatus = _GridLineStatusInTable.InPosition;
    } else {
      newLineStatus = _GridLineStatusInTable.Left;
    }
    _currentLineStatuses[lineDescription] = newLineStatus;
    bool areLinesAnimating = false;
    for (var lineStatus in _currentLineStatuses.values) {
      if (lineStatus == _GridLineStatusInTable.Entering ||
          lineStatus == _GridLineStatusInTable.Leaving ||
          lineStatus == _GridLineStatusInTable.Rearranging) {
        areLinesAnimating = true;
        break;
      }
    }
    if (!areLinesAnimating) {
      onAnimationsFinished();
    }
  }

  @override
  void initState() {
    super.initState();
    onAnimationsFinished = widget.onAnimationsFinished;
    settings = widget.gameSettings;
    tableType = settings.tableType.value;
    int i = 0;
    while (i < 9) {
      _lineDescriptions.add(_RegularPeriodSeparatorLine(periodBelow: i + 1));
      i++;
    }
    i = 0;
    while (i < 5) {
      _lineDescriptions.add(_ExtraPeriodSeparatorLine(periodBelow: i + 1));
      i++;
    }
    i = 0;
    while (i < 19) {
      _lineDescriptions.add(_GroupSeparatorLine(groupLeft: i, isFBlock: false));
      i++;
    }
    i = 0;
    while (i < 14) {
      _lineDescriptions.add(_GroupSeparatorLine(groupLeft: i, isFBlock: true));
      i++;
    }
    i = 0;
    while (i < 8) {
      _labelDescriptions.add(_PeriodLabelDefinition(period: i + 1));
      i++;
    }
    i = 0;
    while (i < 18) {
      int groupNumber = i + 1;
      _labelDescriptions.add(_GroupNumberLabelDefinition(groupNumber: groupNumber));
      String block;
      if (groupNumber <= 2) {
        block = "s";
      } else if (groupNumber <= 12) {
        block = "d";
      } else {
        block = "p";
      }
      _labelDescriptions.add(_GroupElectronConfigurationLabelDefinition(groupNumber: groupNumber, block: block));
      i++;
    }
    i = 0;
    while (i < 14) {
      _labelDescriptions.add(_GroupElectronConfigurationLabelDefinition(groupNumber: i + 1, block: "f"));
      i++;
    }
    i = 0;
    while (i < 18) {
      for (var lineDescription in _lineDescriptions) {
        if (lineDescription.isPresentInTableType(tableType)) {
          _currentLineStatuses[lineDescription] = _GridLineStatusInTable.Entering;
        } else {
          _currentLineStatuses[lineDescription] = _GridLineStatusInTable.Left;
        }
        var _lineDescriptionCapture = lineDescription;
        Function() _lineAnimationFinishedHandler = () {
          _onLineAnimationFinished(_lineDescriptionCapture);
        };
        _lineAnimationFinishedHandlers.add(_lineAnimationFinishedHandler);
      }
      i++;
    }
    settings = widget.gameSettings;
    minimumTablePadding = settings.minimumTablePadding.value;
    leftLineExtension = settings.leftLineExtension.value;
    topLineExtension = settings.leftLineExtension.value;
    settings.minimumTablePadding.addListener(_sizingSettingsHandler);
    settings.leftLineExtension.addListener(_sizingSettingsHandler);
    settings.topLineExtension.addListener(_sizingSettingsHandler);
    settings.tableType.addListener(_tableTypeHandler);
    ticker = createTicker(_onTick);
    ticker.start();
  }

  @override
  void dispose() {
    ticker.stop();
    ticker.dispose();
    settings.minimumTablePadding.removeListener(_sizingSettingsHandler);
    settings.leftLineExtension.removeListener(_sizingSettingsHandler);
    settings.topLineExtension.removeListener(_sizingSettingsHandler);
    settings.tableType.removeListener(_tableTypeHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
      Size containerSize = constraints.biggest;
      double cellSize = TableGrid.getCellSize(settings, containerSize);
      List<_GridLine> lineWidgets = [];
      Map<_GridLine, _GridLineDescription> lineWidgetDescriptions = {};
      int i = 0;
      while (i < _lineDescriptions.length) {
        var lineDescription = _lineDescriptions[i];
        var lineStatus = _currentLineStatuses[lineDescription];
        _GridLine lineWidget = lineDescription.createWidget(
            time, cellSize, settings, containerSize, _lineAnimationFinishedHandlers[i],
            statusOverride: lineStatus);
        lineWidgets.add(lineWidget);
        lineWidgetDescriptions[lineWidget] = lineDescription;
        i++;
      }
      List<_GridLine> verticalLinesOrdered = List.from(lineWidgets.where((element) => element.axis == Axis.vertical));
      List<_GridLine> horizontalLinesOrdered =
          List.from(lineWidgets.where((element) => element.axis == Axis.horizontal));
      verticalLinesOrdered.sort((a, b) {
        return a.targetOffset.dx.compareTo(b.targetOffset.dx);
      });
      horizontalLinesOrdered.sort((a, b) {
        return a.targetOffset.dy.compareTo(b.targetOffset.dy);
      });
      i = 0;
      while (i < verticalLinesOrdered.length) {
        verticalLinesOrdered[i].animationDelay = _lineAnimationStaggerDuration * i;
        i++;
      }
      i = 0;
      while (i < horizontalLinesOrdered.length) {
        horizontalLinesOrdered[i].animationDelay = _lineAnimationStaggerDuration * i * 2;
        i++;
      }
      List<_GridColRowLabel> labelWidgets = [];
      for (var labelDescription in _labelDescriptions) {
        var labelWidget = labelDescription.createWidget(settings, cellSize, containerSize, Colors.white);
        labelWidget.animationDelay =
            const Duration(milliseconds: 1000) + Duration(milliseconds: labelWidget.offset.distance.toInt());
        labelWidgets.add(labelWidget);
      }
      List<Widget> stackChildren = List.from(lineWidgets);
      stackChildren.addAll(labelWidgets);

      //lineWidgets = [lineWidgets[0]];
      // return ConstrainedBox(
      //   constraints: BoxConstraints.tight(constraints.biggest),
      //   child: Stack(
      //     alignment: Alignment.topLeft,
      //     fit: StackFit.passthrough,
      //     children: stackChildren,
      //   ),
      // );
      return ClipRect(
        child: SizedOverflowBox(
          size: constraints.biggest,
          child: Stack(
            alignment: Alignment.topLeft,
            fit: StackFit.passthrough,
            children: stackChildren,
          ),
        ),
      );
    });
  }
}

abstract class _GridLineDescription {
  String get description;
  _GridLine createWidget(
      double time, double cellSize, GameSettings settings, Size containerSize, Function() onOffsetAnimationFinished,
      {_GridLineStatusInTable? statusOverride});
  bool isPresentInTableType(TableType tableType);
}

class _RegularPeriodSeparatorLine implements _GridLineDescription {
  /// periods begin at 1
  final int periodBelow;
  _RegularPeriodSeparatorLine({required this.periodBelow});

  @override
  _GridLine createWidget(
      double time, double cellSize, GameSettings settings, Size containerSize, Function() onOffsetAnimationFinished,
      {_GridLineStatusInTable? statusOverride}) {
    _GridLineStatusInTable lineStatus;
    if (statusOverride != null) {
      lineStatus = statusOverride;
    } else {
      if (isPresentInTableType(settings.tableType.value)) {
        lineStatus = _GridLineStatusInTable.Entering;
      } else {
        lineStatus = _GridLineStatusInTable.Left;
      }
    }
    Key widgetKey = ObjectKey(this);
    double leftExtension = settings.leftLineExtension.value;
    int cellsSpanned;
    int startCol;
    int rowIndex;
    switch (settings.tableType.value) {
      case TableType.StandardTable:
        {
          rowIndex = periodBelow - 1;
          startCol = 0;
          if (periodBelow == 1) {
            cellsSpanned = 1;
          } else if (periodBelow < 4) {
            cellsSpanned = 2;
          } else {
            cellsSpanned = 18;
          }
        }
        break;
      case TableType.ExtendedTable:
        {
          rowIndex = periodBelow - 1;
          startCol = 0;
          if (periodBelow == 1) {
            cellsSpanned = 1;
          } else if (periodBelow < 6) {
            cellsSpanned = 2;
          } else {
            cellsSpanned = 18 + 14;
          }
        }
        break;
      case TableType.LeftStepTable:
        {
          rowIndex = periodBelow - 1;
          if (periodBelow < 3) {
            cellsSpanned = 2;
            startCol = 14 + 10 + 6;
          } else if (periodBelow < 5) {
            startCol = 14 + 10;
            cellsSpanned = 8;
          } else if (periodBelow < 7) {
            startCol = 14;
            cellsSpanned = 18;
          } else if (periodBelow < 9) {
            startCol = 0;
            cellsSpanned = 18 + 14;
          } else {
            startCol = 0;
            cellsSpanned = 18 + 12;
          }
        }
        break;
      case TableType.CompactTable:
        {
          rowIndex = periodBelow - 1;
          startCol = 0;
          if (periodBelow == 1) {
            cellsSpanned = 1;
          } else {
            cellsSpanned = 8;
          }
        }
        break;
      case TableType.PBlock:
        {
          rowIndex = periodBelow - 1;
          if (periodBelow == 1) {
            startCol = 5;
            cellsSpanned = 1;
          } else {
            startCol = 0;
            cellsSpanned = 6;
          }
        }
        break;
      case TableType.DBlock:
        {
          rowIndex = periodBelow - 4;
          startCol = 0;
          cellsSpanned = 10;
        }
        break;
    }
    double lineLength = cellsSpanned * cellSize + leftExtension + 1;
    Axis lineAxis = Axis.horizontal;
    Rect drawingSpace = TableGrid.getTableDrawingSpace(settings, containerSize);
    double lineOffsetX = drawingSpace.left + startCol * cellSize;
    double lineOffsetY = drawingSpace.top + settings.topLineExtension.value + rowIndex * cellSize;
    return _GridLine(
        lineDescription: this,
        key: widgetKey,
        axis: lineAxis,
        time: time,
        targetOffset: Offset(lineOffsetX, lineOffsetY),
        length: lineLength,
        lineStatus: lineStatus,
        containerSize: containerSize,
        statusAnimationfinishedHandler: onOffsetAnimationFinished);
  }

  @override
  String get description => "regular period separator above period $periodBelow";

  @override
  bool isPresentInTableType(TableType tableType) {
    switch (tableType) {
      case TableType.StandardTable:
        {
          return periodBelow <= 8;
        }
      case TableType.ExtendedTable:
        {
          return periodBelow <= 8;
        }
      case TableType.LeftStepTable:
        {
          return true;
        }
      case TableType.CompactTable:
        {
          return periodBelow <= 8;
        }
      case TableType.DBlock:
        {
          return periodBelow >= 4 && periodBelow <= 8;
        }
      case TableType.PBlock:
        {
          return periodBelow <= 8;
        }
    }
  }

  @override
  int get hashCode => periodBelow * "regularPeriodSeparator".hashCode;

  @override
  bool operator ==(Object other) {
    if (other is _RegularPeriodSeparatorLine) {
      return periodBelow == other.periodBelow;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    return description;
  }
}

class _ExtraPeriodSeparatorLine implements _GridLineDescription {
  /// periods start at 1;
  final int periodBelow;
  _ExtraPeriodSeparatorLine({required this.periodBelow});

  @override
  _GridLine createWidget(
      double time, double cellSize, GameSettings settings, Size containerSize, Function() onOffsetAnimationFinished,
      {_GridLineStatusInTable? statusOverride}) {
    _GridLineStatusInTable lineStatus;
    if (statusOverride != null) {
      lineStatus = statusOverride;
    } else {
      if (isPresentInTableType(settings.tableType.value)) {
        lineStatus = _GridLineStatusInTable.Entering;
      } else {
        lineStatus = _GridLineStatusInTable.Left;
      }
    }
    Key widgetKey = ObjectKey(this);
    double leftExtension = settings.leftLineExtension.value;
    //double leftExtension = 0;
    int cellsSpanned;
    int startCol;
    switch (settings.tableType.value) {
      case TableType.StandardTable:
        {
          if (periodBelow > 1) {
            cellsSpanned = 6;
            startCol = 12;
          } else {
            cellsSpanned = 1;
            startCol = 17;
          }
        }
        break;
      case TableType.ExtendedTable:
        {
          if (periodBelow > 3) {
            cellsSpanned = 16;
            startCol = 2 + 14;
          } else if (periodBelow > 1) {
            cellsSpanned = 6;
            startCol = 2 + 14 + 10;
          } else {
            cellsSpanned = 1;
            startCol = 17 + 14;
          }
        }
        break;
      case TableType.CompactTable:
        {
          cellsSpanned = 1;
          startCol = 7;
        }
        break;
      case TableType.PBlock:
        {
          cellsSpanned = 1;
          startCol = 5;
        }
        break;
      case TableType.LeftStepTable:
        {
          cellsSpanned = 0;
          startCol = 0;
        }
        break;
      case TableType.DBlock:
        {
          cellsSpanned = 0;
          startCol = 0;
        }
        break;
    }
    //double lineLength = cellsSpanned * cellSize + leftExtension;
    double lineLength = cellsSpanned * cellSize + 1;
    Axis lineAxis = Axis.horizontal;
    Rect drawingSpace = TableGrid.getTableDrawingSpace(settings, containerSize);
    double lineOffsetX = drawingSpace.left + startCol * cellSize + leftExtension;
    double lineOffsetY = drawingSpace.top + settings.topLineExtension.value + (periodBelow - 1) * cellSize;
    return _GridLine(
        lineDescription: this,
        key: widgetKey,
        axis: lineAxis,
        time: time,
        targetOffset: Offset(lineOffsetX, lineOffsetY),
        length: lineLength,
        lineStatus: lineStatus,
        containerSize: containerSize,
        statusAnimationfinishedHandler: onOffsetAnimationFinished);
  }

  @override
  String get description => "additional period separator above period $periodBelow";

  @override
  bool isPresentInTableType(TableType tableType) {
    switch (tableType) {
      case TableType.StandardTable:
        {
          return periodBelow < 4;
        }
      case TableType.CompactTable:
        {
          return periodBelow == 1;
        }
      case TableType.PBlock:
        {
          return false;
        }
      case TableType.DBlock:
        {
          return false;
        }
      case TableType.LeftStepTable:
        {
          return false;
        }
      case TableType.ExtendedTable:
        {
          return periodBelow < 6;
        }
    }
  }

  @override
  int get hashCode => periodBelow * "extraPeriodSeparator".hashCode;

  @override
  bool operator ==(Object other) {
    if (other is _ExtraPeriodSeparatorLine) {
      return periodBelow == other.periodBelow;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    return description;
  }
}

class _GroupSeparatorLine extends _GridLineDescription {
  /// groups start at 1. Special convention for F-block elements.
  /// See [isFBlock]
  final int groupLeft;

  /// In the extended table we need some "groups" to identify F-block elements.
  /// For example, in the extended table, the vertical line between La and Ce would have a `groupLeft` value of `1`.
  final bool isFBlock;

  _GroupSeparatorLine({required this.groupLeft, required this.isFBlock});

  @override
  _GridLine createWidget(
      double time, double cellSize, GameSettings settings, Size containerSize, Function() onOffsetAnimationFinished,
      {_GridLineStatusInTable? statusOverride}) {
    _GridLineStatusInTable lineStatus;
    if (statusOverride != null) {
      lineStatus = statusOverride;
    } else {
      if (isPresentInTableType(settings.tableType.value)) {
        lineStatus = _GridLineStatusInTable.Entering;
      } else {
        lineStatus = _GridLineStatusInTable.Left;
      }
    }
    Key widgetKey = ObjectKey(this);
    double topExtension = settings.topLineExtension.value;
    int cellsSpanned;
    int startRow;
    int colIndex;
    switch (settings.tableType.value) {
      case TableType.StandardTable:
        {
          if (isFBlock) {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          } else if (groupLeft <= 1 || groupLeft >= 17) {
            cellsSpanned = 7;
            startRow = 0;
            colIndex = groupLeft;
          } else if (groupLeft <= 2 || groupLeft >= 12) {
            cellsSpanned = 6;
            startRow = 1;
            colIndex = groupLeft;
          } else {
            cellsSpanned = 4;
            startRow = 3;
            colIndex = groupLeft;
          }
        }
        break;
      case TableType.DBlock:
        {
          if (isFBlock) {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          } else if (groupLeft >= 2 && groupLeft <= 12) {
            cellsSpanned = 4;
            startRow = 0;
            colIndex = groupLeft - 2;
          } else {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          }
        }
        break;
      case TableType.PBlock:
        {
          if (isFBlock) {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          } else if (groupLeft >= 17) {
            cellsSpanned = 7;
            startRow = 0;
            colIndex = groupLeft - 12;
          } else if (groupLeft >= 12) {
            cellsSpanned = 6;
            startRow = 1;
            colIndex = groupLeft - 12;
          } else {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          }
        }
        break;
      case TableType.CompactTable:
        {
          if (isFBlock) {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          } else if (groupLeft <= 1) {
            cellsSpanned = 7;
            startRow = 0;
            colIndex = groupLeft;
          } else if (groupLeft >= 17) {
            cellsSpanned = 7;
            startRow = 0;
            colIndex = groupLeft - 10;
          } else if (groupLeft >= 12) {
            cellsSpanned = 6;
            startRow = 1;
            colIndex = groupLeft - 10;
          } else {
            cellsSpanned = 0;
            startRow = 0;
            colIndex = 0;
          }
        }
        break;
      case TableType.ExtendedTable:
        {
          if (!isFBlock) {
            if (groupLeft < 2) {
              cellsSpanned = 7;
              startRow = 0;
              colIndex = groupLeft;
            } else if (groupLeft < 12) {
              cellsSpanned = 4;
              startRow = 3;
              colIndex = groupLeft + 14;
            } else if (groupLeft < 17) {
              cellsSpanned = 6;
              startRow = 1;
              colIndex = groupLeft + 14;
            } else {
              cellsSpanned = 7;
              startRow = 0;
              colIndex = groupLeft + 14;
            }
          } else {
            if (groupLeft == 0) {
              cellsSpanned = 6;
              startRow = 1;
            } else {
              cellsSpanned = 2;
              startRow = 5;
            }
            colIndex = groupLeft + 2;
          }
        }
        break;
      case TableType.LeftStepTable:
        {
          if (isFBlock) {
            cellsSpanned = 2;
            startRow = 6;
            colIndex = groupLeft;
          } else {
            if (groupLeft >= 2 && groupLeft <= 11) {
              cellsSpanned = 4;
              startRow = 4;
              colIndex = groupLeft + 12;
            } else if (groupLeft >= 12 && groupLeft < 18) {
              cellsSpanned = 6;
              startRow = 2;
              colIndex = groupLeft + 12;
            } else {
              if (groupLeft == 0) {
                cellsSpanned = 8;
              } else {
                cellsSpanned = 7;
              }
              startRow = 0;
              if (groupLeft < 2) {
                colIndex = 30 + groupLeft;
              } else {
                colIndex = 32;
              }
            }
          }
        }
        break;
    }
    double lineLength = cellsSpanned * cellSize + topExtension + 1;
    Axis lineAxis = Axis.vertical;
    Rect drawingSpace = TableGrid.getTableDrawingSpace(settings, containerSize);
    double lineOffsetX = drawingSpace.left + settings.leftLineExtension.value + colIndex * cellSize;
    double lineOffsetY = drawingSpace.top + startRow * cellSize;
    return _GridLine(
        lineDescription: this,
        key: widgetKey,
        axis: lineAxis,
        time: time,
        targetOffset: Offset(lineOffsetX, lineOffsetY),
        length: lineLength,
        lineStatus: lineStatus,
        containerSize: containerSize,
        statusAnimationfinishedHandler: onOffsetAnimationFinished);
  }

  @override
  String get description {
    if (!isFBlock) {
      return "group separator to the right of group $groupLeft";
    } else {
      return "group separator to the left of f-block column $groupLeft";
    }
  }

  @override
  bool isPresentInTableType(TableType tableType) {
    switch (tableType) {
      case TableType.StandardTable:
        {
          return !isFBlock;
        }
      case TableType.ExtendedTable:
        {
          return true;
        }
      case TableType.LeftStepTable:
        {
          return true;
        }
      case TableType.CompactTable:
        {
          return !isFBlock && (groupLeft < 2 || groupLeft >= 12);
        }
      case TableType.PBlock:
        {
          return !isFBlock && groupLeft >= 12;
        }
      case TableType.DBlock:
        {
          return !isFBlock && groupLeft >= 2 && groupLeft <= 12;
        }
    }
  }

  @override
  int get hashCode {
    int fMultiplier = isFBlock ? 47 : 1;
    return fMultiplier * groupLeft * "groupSeparator".hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is _GroupSeparatorLine) {
      return groupLeft == other.groupLeft && isFBlock == other.isFBlock;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    return description;
  }
}

class _GridLine extends StatefulWidget {
  final Offset targetOffset;
  final Axis axis;
  final double length;
  final double time;
  final _GridLineStatusInTable lineStatus;
  final Size containerSize;
  final Function() statusAnimationfinishedHandler;
  Duration animationDelay = const Duration();
  _GridLineDescription? lineDescription;

  _GridLine(
      {Key? key,
      required this.axis,
      required this.time,
      required this.targetOffset,
      required this.length,
      required this.lineStatus,
      required this.containerSize,
      required this.statusAnimationfinishedHandler,
      this.lineDescription})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GridLineState();
  }
}

class _GridLineState extends State<_GridLine> with TickerProviderStateMixin {
  late Size containerSize;
  late Offset startingOffset;
  late Offset currentOffset;
  late Offset targetOffset;
  late Offset theoreticalTargetOffset;
  late Axis axis;
  late double startingLength;
  late double currentLength;
  late double targetLength;
  late double theoreticalLength;
  late double time;
  late AnimationController lengthAnimationController;
  late CurvedAnimation lengthAnimationCurved;
  late _GridLineStatusInTable lineStatus;
  late AnimationController offsetAnimationController;
  late CurvedAnimation offsetAnimationCurved;
  late Tween<Offset> offsetTween;
  late Animation<Offset> offsetAnimation;
  late Function() _onStatusAnimationFinished;
  late Duration animationDelay;

  void _lengthAnimationHandler() {
    double currentAnimationValue = lengthAnimationCurved.value;
    double deltaLength = targetLength - startingLength;
    setState(() {
      currentLength = startingLength + currentAnimationValue * deltaLength;
    });
  }

  void _offsetAnimationHandler() {
    setState(() {
      currentOffset = offsetAnimation.value;
    });
  }

  @override
  void initState() {
    super.initState();
    animationDelay = widget.animationDelay;
    _onStatusAnimationFinished = widget.statusAnimationfinishedHandler;
    containerSize = widget.containerSize;
    //currentOffset = widget.targetOffset;
    axis = widget.axis;
    currentLength = widget.length;
    targetLength = currentLength;
    startingLength = currentLength;
    theoreticalLength = currentLength;
    time = widget.time;
    lineStatus = widget.lineStatus;
    lengthAnimationController = AnimationController(vsync: this, duration: _lengthAnimationDuration);
    lengthAnimationCurved = CurvedAnimation(parent: lengthAnimationController, curve: Curves.easeOutBack);
    lengthAnimationCurved.addListener(_lengthAnimationHandler);
    theoreticalTargetOffset = widget.targetOffset;
    switch (lineStatus) {
      case _GridLineStatusInTable.Left:
        {
          if (axis == Axis.horizontal) {
            currentOffset = Offset(containerSize.width + 1, widget.targetOffset.dy);
          } else {
            currentOffset = Offset(widget.targetOffset.dx, containerSize.height + 1);
          }
          startingOffset = currentOffset;
          targetOffset = currentOffset;
        }
        break;
      case _GridLineStatusInTable.Entering:
        {
          if (axis == Axis.horizontal) {
            currentOffset = Offset(-currentLength - 1, widget.targetOffset.dy);
          } else {
            currentOffset = Offset(widget.targetOffset.dx, -currentLength - 1);
          }
          startingOffset = currentOffset;
          targetOffset = widget.targetOffset;
        }
        break;
      case _GridLineStatusInTable.Leaving:
        {
          currentOffset = widget.targetOffset;
          startingOffset = currentOffset;
          if (axis == Axis.horizontal) {
            targetOffset = Offset(containerSize.width + 1, currentOffset.dy);
          } else {
            targetOffset = Offset(currentOffset.dx, containerSize.height + 1);
          }
        }
        break;
      default:
        {
          // in position. Rearranging in initState is ambiguous, as we don't know the starting position...
          currentOffset = widget.targetOffset;
          startingOffset = currentOffset;
          targetOffset = currentOffset;
        }
    }
    offsetAnimationController = AnimationController(vsync: this, duration: _offsetAnimationDuration);
    offsetAnimationCurved = CurvedAnimation(parent: offsetAnimationController, curve: Curves.easeInOut);
    offsetTween = Tween(begin: startingOffset, end: targetOffset);
    offsetAnimation = offsetAnimationCurved.drive(offsetTween);
    offsetAnimation.addListener(_offsetAnimationHandler);
    if (lineStatus == _GridLineStatusInTable.Entering || lineStatus == _GridLineStatusInTable.Leaving) {
      Future<void> delayed = Future.delayed(animationDelay, () {
        offsetAnimationController.forward(from: 0).then((value) => _onStatusAnimationFinished());
      });
      delayed.ignore();
    }
  }

  @override
  void dispose() {
    lengthAnimationCurved.removeListener(_lengthAnimationHandler);
    lengthAnimationCurved.dispose();
    lengthAnimationController.dispose();
    offsetAnimation.removeListener(_offsetAnimationHandler);
    offsetAnimationCurved.dispose();
    offsetAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_GridLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    animationDelay = widget.animationDelay;
    _onStatusAnimationFinished = widget.statusAnimationfinishedHandler;
    var oldContainerSize = containerSize;
    containerSize = widget.containerSize;
    axis = widget.axis;
    time = widget.time;
    if (theoreticalLength != widget.length) {
      // line size changed
      theoreticalLength = widget.length;
      _GridLineStatusInTable oldStatus = lineStatus;
      _GridLineStatusInTable newStatus = widget.lineStatus;
      if (oldStatus == newStatus) {
        if (lineStatus == _GridLineStatusInTable.Rearranging) {
          // length currently animating. update the animation
          targetLength = theoreticalLength;
          // leave current and starting length unchanged
          lengthAnimationController.forward(from: lengthAnimationController.value);
        } else {
          currentLength = theoreticalLength;
          startingLength = theoreticalLength;
          targetLength = theoreticalLength;
        }
      } else {
        if (oldStatus != _GridLineStatusInTable.Rearranging && newStatus == _GridLineStatusInTable.Rearranging) {
          startingLength = currentLength;
          targetLength = widget.length;
          Future delayed = Future.delayed(animationDelay, () {
            lengthAnimationController.forward(from: 0);
          });
          delayed.ignore();
        } else if (newStatus != _GridLineStatusInTable.Rearranging && newStatus != _GridLineStatusInTable.Leaving) {
          currentLength = widget.length;
          startingLength = currentLength;
          targetLength = currentLength;
        }
      }
    }
    if (theoreticalTargetOffset != widget.targetOffset || widget.lineStatus != lineStatus) {
      theoreticalTargetOffset = widget.targetOffset;
      _GridLineStatusInTable oldStatus = lineStatus;
      _GridLineStatusInTable newStatus = widget.lineStatus;
      if (oldStatus == newStatus) {
        // only the target ofset changed
        if (lineStatus == _GridLineStatusInTable.Entering ||
            lineStatus == _GridLineStatusInTable.Leaving ||
            lineStatus == _GridLineStatusInTable.Rearranging) {
          // targetOffset = theoreticalTargetOffset;
          // offsetTween.end = theoreticalTargetOffset;
          if (lineStatus == _GridLineStatusInTable.Entering) {
            if (axis == Axis.vertical) {
              //double relativeStartingOffset = startingOffset.dy / oldContainerSize.height;
              //startingOffset = Offset(theoreticalTargetOffset.dx, relativeStartingOffset * containerSize.height);
              startingOffset = Offset(theoreticalTargetOffset.dx, -currentLength - 1);
            } else {
              //double relativeStartingOffset = startingOffset.dx / oldContainerSize.width;
              //startingOffset = Offset(relativeStartingOffset * containerSize.width, theoreticalTargetOffset.dy);
              startingOffset = Offset(-currentLength - 1, theoreticalTargetOffset.dy);
            }
            offsetTween.begin = startingOffset;
            targetOffset = theoreticalTargetOffset;
            offsetTween.end = targetOffset;
            currentOffset = startingOffset + (targetOffset - startingOffset) * offsetAnimationCurved.value;
          } else if (lineStatus == _GridLineStatusInTable.Leaving) {
            if (axis == Axis.vertical) {
              double relativeStartingOffset = startingOffset.dy / oldContainerSize.height;
              startingOffset = Offset(theoreticalTargetOffset.dx, relativeStartingOffset * containerSize.height);
              targetOffset = Offset(theoreticalTargetOffset.dx, containerSize.height + 1);
            } else {
              double relativeStartingOffset = startingOffset.dx / oldContainerSize.width;
              startingOffset = Offset(relativeStartingOffset * containerSize.width, theoreticalTargetOffset.dy);
              targetOffset = Offset(containerSize.width + 1, theoreticalTargetOffset.dy);
            }
            offsetTween.begin = startingOffset;
            offsetTween.end = targetOffset;
            currentOffset = startingOffset + (targetOffset - startingOffset) * offsetAnimationCurved.value;
          } else {
            //rearranging
            double relativeStartingOffsetX = startingOffset.dx / oldContainerSize.width;
            double relativeStartingOffsetY = startingOffset.dy / oldContainerSize.height;
            startingOffset =
                Offset(relativeStartingOffsetX * containerSize.width, relativeStartingOffsetY * containerSize.height);
            targetOffset = theoreticalTargetOffset;
            offsetTween.begin = startingOffset;
            offsetTween.end = targetOffset;
            currentOffset = startingOffset + (targetOffset - startingOffset) * offsetAnimationCurved.value;
          }
        } else {
          if (lineStatus == _GridLineStatusInTable.InPosition) {
            targetOffset = theoreticalTargetOffset;
            currentOffset = theoreticalTargetOffset;
            startingOffset = theoreticalTargetOffset;
          } else {
            // left
            if (axis == Axis.horizontal) {
              currentOffset = Offset(containerSize.width + 1, widget.targetOffset.dy);
            } else {
              currentOffset = Offset(widget.targetOffset.dx, containerSize.height + 1);
            }
            targetOffset = currentOffset;
            startingOffset = currentOffset;
          }
        }
      } else {
        // both line status and position changed
        // (if the status changes, the position must change by definition)
        lineStatus = widget.lineStatus;
        switch (lineStatus) {
          case _GridLineStatusInTable.InPosition:
            {
              currentOffset = widget.targetOffset;
              targetOffset = currentOffset;
              startingOffset = currentOffset;
            }
            break;
          case _GridLineStatusInTable.Rearranging:
            {
              startingOffset = currentOffset;
              targetOffset = widget.targetOffset;
              offsetTween.begin = startingOffset;
              offsetTween.end = targetOffset;
              offsetAnimationController.value = 0;
              Future delayed = Future.delayed(animationDelay, () {
                offsetAnimationController.forward(from: 0).then((value) => _onStatusAnimationFinished());
              });
              delayed.ignore();
            }
            break;
          case _GridLineStatusInTable.Entering:
            {
              if (axis == Axis.horizontal) {
                currentOffset = Offset(-currentLength - 1, widget.targetOffset.dy);
              } else {
                currentOffset = Offset(widget.targetOffset.dx, -currentLength - 1);
              }
              startingOffset = currentOffset;
              targetOffset = widget.targetOffset;
              offsetTween.begin = startingOffset;
              offsetTween.end = targetOffset;
              offsetAnimationController.value = 0;
              Future delayed = Future.delayed(animationDelay, () {
                offsetAnimationController.forward(from: 0).then((value) => _onStatusAnimationFinished());
              });
              delayed.ignore();
            }
            break;
          case _GridLineStatusInTable.Leaving:
            {
              startingOffset = currentOffset;
              if (axis == Axis.horizontal) {
                targetOffset = Offset(containerSize.width + 1, currentOffset.dy);
              } else {
                targetOffset = Offset(currentOffset.dx, containerSize.height + 1);
              }
              offsetTween.begin = startingOffset;
              offsetTween.end = targetOffset;
              offsetAnimationController.value = 0;
              Future delayed = Future.delayed(animationDelay, () {
                offsetAnimationController.forward(from: 0).then((value) => _onStatusAnimationFinished());
              });
              delayed.ignore();
            }
            break;
          case _GridLineStatusInTable.Left:
            {
              if (axis == Axis.horizontal) {
                currentOffset = Offset(containerSize.width + 1, widget.targetOffset.dy);
              } else {
                currentOffset = Offset(widget.targetOffset.dx, containerSize.height + 1);
              }
              targetOffset = currentOffset;
              startingOffset = currentOffset;
            }
            break;
        }
      }
    }
  }

  double get _lineWidth {
    return 1;
  }

  Duration get _lengthAnimationDuration {
    return const Duration(milliseconds: 1200);
  }

  Duration get _offsetAnimationDuration {
    return const Duration(milliseconds: 800);
  }

  @override
  Widget build(BuildContext context) {
    Size lineSize = Size(currentLength, _lineWidth);
    if (axis == Axis.vertical) {
      lineSize = Size(_lineWidth, currentLength);
    }
    return LayoutBuilder(
      builder: (ctx, constraints) {
        var customPaintSize = constraints.biggest;
        return CustomPaint(
          size: customPaintSize,
          painter: _VertexPainter(
            time: time,
            globalOffset: currentOffset,
            lineSize: lineSize,
          ),
          willChange: true,
        );
      },
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (widget.lineDescription != null) {
      return widget.lineDescription!.toString();
    } else {
      return super.toString(minLevel: minLevel);
    }
  }
}

enum _GridLineStatusInTable {
  /// Was outside the screen, now entering
  Entering,

  /// Exiting the screen
  Leaving,

  /// Outside the screen, may later enter
  Left,

  /// At its final position in the table
  InPosition,

  /// Moving within the table, not entering or leaving
  Rearranging
}

class _VertexPainter extends CustomPainter {
  double time;
  Offset globalOffset;
  Size lineSize;

  double get cellSize {
    return 1;
  }

  _VertexPainter({required this.time, required this.globalOffset, required this.lineSize});

  Float32List _createTriangles(Size size) {
    int numCols = size.width ~/ cellSize;
    int numRows = size.height ~/ cellSize;
    double xStep = cellSize;
    double yStep = cellSize;
    Float32List triangles = Float32List(numCols * numRows * 12);
    int x = 0;
    int i = 0;
    while (x < numCols) {
      double leftX = x * xStep;
      double rightX = leftX + xStep;
      leftX += globalOffset.dx;
      rightX += globalOffset.dx;
      int y = 0;
      while (y < numRows) {
        double topY = y * yStep;
        double bottomY = topY + yStep;
        topY += globalOffset.dy;
        bottomY += globalOffset.dy;
        triangles[i] = leftX;
        i++;
        triangles[i] = topY;
        i++;
        triangles[i] = rightX;
        i++;
        triangles[i] = topY;
        i++;
        triangles[i] = leftX;
        i++;
        triangles[i] = bottomY;
        i++;
        triangles[i] = rightX;
        i++;
        triangles[i] = topY;
        i++;
        triangles[i] = rightX;
        i++;
        triangles[i] = bottomY;
        i++;
        triangles[i] = leftX;
        i++;
        triangles[i] = bottomY;
        i++;
        y++;
      }
      x++;
    }
    return triangles;
  }

  Float32List _createTextureCoords(Size size) {
    int numCols = size.width ~/ cellSize;
    int numRows = size.height ~/ cellSize;
    double xStep = cellSize;
    double yStep = cellSize;
    Float32List triangles = Float32List(numCols * numRows * 12);
    int x = 0;
    int i = 0;
    while (x < numCols) {
      double leftX = x * xStep;
      double rightX = leftX + xStep;
      leftX += globalOffset.dx;
      rightX += globalOffset.dx;

      int y = 0;
      while (y < numRows) {
        double topY = y * yStep;
        double bottomY = topY + yStep;
        topY += globalOffset.dy;
        bottomY += globalOffset.dy;

        // double leftXM = leftX + 30 * sin(time) * sin(topY / 30);
        // double rightXM = rightX + 7 * cos(rightX / 170) * sin(bottomY / 7);
        // double topYM = topY + 15 * sin(leftX / 37);
        // double bottomYM = bottomY + 15 * sin(leftX / 37);
        double leftXM = leftX + 30 * sin(time) * sin(topY / 30);
        double rightXM = rightX + 7 * cos(rightX / 170) * sin(bottomY / 7);
        double topYM = topY + 50 * sin(leftX / 77) * cos(topY / 133);
        double bottomYM = bottomY + 50 * sin(leftX / 77) * cos(topY / 133);

        triangles[i] = leftXM;
        i++;
        triangles[i] = topYM;
        i++;
        triangles[i] = rightXM;
        i++;
        triangles[i] = topYM;
        i++;
        triangles[i] = leftXM;
        i++;
        triangles[i] = bottomYM;
        i++;
        triangles[i] = rightXM;
        i++;
        triangles[i] = topYM;
        i++;
        triangles[i] = rightXM;
        i++;
        triangles[i] = bottomYM;
        i++;
        triangles[i] = leftXM;
        i++;
        triangles[i] = bottomYM;
        i++;
        y++;
      }
      x++;
    }
    return triangles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    ui.Vertices? vertices;
    double lineWidth = lineSize.width;
    double lineHeight = lineSize.height;
    if (lineWidth < 0) {
      lineWidth = 0;
    }
    if (lineHeight < 0) {
      lineHeight = 0;
    }
    lineSize = Size(lineWidth, lineHeight);
    if (!kIsWeb) {
      vertices = ui.Vertices.raw(VertexMode.triangles, _createTriangles(lineSize),
          textureCoordinates: _createTextureCoords(lineSize));
    }
    double gradientAngle = time / 3;
    //double gradientAngle = pi / 4;
    Alignment gradientEnd = Alignment(sin(gradientAngle), cos(gradientAngle));
    //gradientEnd = Alignment(gradientEnd.x / size.width, gradientEnd.y / size.width);
    //gradientEnd *= 1100;

    var gradient = LinearGradient(
      colors: [
        Colors.red.shade200,
        Colors.yellow,
        Colors.purple.shade300,
        Colors.grey.shade300,
        Colors.blue.shade100,
        Colors.red.shade200
      ],
      begin: const Alignment(-0.2, -0.2),
      end: gradientEnd,
      tileMode: TileMode.repeated,
    );
    var rect = Rect.fromLTRB(0, 0, max(size.width, size.height), max(size.width, size.height));
    if (!kIsWeb) {
      var paint = Paint()
        ..style = ui.PaintingStyle.fill
        ..shader = gradient.createShader(rect);
      canvas.drawVertices(vertices!, BlendMode.src, paint);
    } else {
      // significant performance improvement. Drop the gradient distortion on web, it is too resource-intensive
      var paint = Paint()
        ..style = ui.PaintingStyle.stroke
        ..shader = gradient.createShader(rect);
      Offset lineEnd;
      if (lineSize.width > lineSize.height) {
        lineEnd = Offset(globalOffset.dx + lineSize.width - 1, globalOffset.dy);
      } else {
        lineEnd = Offset(globalOffset.dx, globalOffset.dy + lineSize.height - 1);
      }
      canvas.drawLine(globalOffset, lineEnd, paint);
    }
  }

  @override
  bool shouldRepaint(_VertexPainter oldDelegate) {
    return true;
  }
}

class _GridColRowLabel extends StatefulWidget {
  final Offset offset;
  final Color color;
  final _LabelContent labelContent;
  final Axis axis;
  final bool showing;
  final TableType tableType;
  final Size containerSize;
  Duration animationDelay = const Duration();

  _GridColRowLabel({
    Key? key,
    required this.labelContent,
    required this.axis,
    required this.color,
    required this.offset,
    required this.showing,
    required this.tableType,
    required this.containerSize,
  }) : super(key: key);

  @override
  _GridColRowLabelState createState() {
    return _GridColRowLabelState();
  }
}

class _GridColRowLabelState extends State<_GridColRowLabel> with SingleTickerProviderStateMixin {
  late Offset offset;
  late Offset targetOffset;
  late Color color;
  late _LabelContent labelContent;
  late _LabelContent targetLabelContent;
  late double startingOpacity;
  late double currentOpacity;
  late double targetOpacity;
  late Axis axis;
  late AnimationController opacityController;
  late CurvedAnimation opacityCurved;
  late bool showing;
  late Duration animationDelay;
  late TableType tableType;
  late Size containerSize;

  Duration get fadeTransitionDuration {
    return const Duration(milliseconds: 700);
  }

  void _opacityChangeHandler() {
    setState(() {
      double deltaOpacity = opacityCurved.value * (targetOpacity - startingOpacity);
      currentOpacity = startingOpacity + deltaOpacity;
    });
  }

  @override
  void initState() {
    super.initState();
    containerSize = widget.containerSize;
    tableType = widget.tableType;
    animationDelay = widget.animationDelay;
    showing = widget.showing;
    offset = widget.offset;
    targetOffset = offset;
    color = widget.color;
    labelContent = widget.labelContent;
    targetLabelContent = labelContent;
    axis = widget.axis;
    startingOpacity = 0;
    currentOpacity = 0;
    targetOpacity = showing ? 1 : 0;
    opacityController = AnimationController(vsync: this, duration: fadeTransitionDuration);
    opacityCurved = CurvedAnimation(parent: opacityController, curve: Curves.easeInOut);
    opacityCurved.addListener(_opacityChangeHandler);
    if (showing) {
      Future delayed = Future.delayed(animationDelay, () {
        opacityController.forward(from: 0);
      });
      delayed.ignore();
    }
  }

  @override
  void didUpdateWidget(covariant _GridColRowLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    animationDelay = widget.animationDelay;
    var oldShowing = showing;
    showing = widget.showing;
    var oldTableType = tableType;
    tableType = widget.tableType;
    color = widget.color;
    axis = widget.axis;
    targetOffset = widget.offset;
    var oldContainerSize = containerSize;
    containerSize = widget.containerSize;
    if (oldTableType != tableType || (oldShowing != showing && showing)) {
      startingOpacity = currentOpacity;
      targetOpacity = 0;
      opacityController.forward(from: 0).then((value) {
        //labelContent = widget.labelContent;
        offset = targetOffset;
        startingOpacity = currentOpacity;
        targetOpacity = showing ? 1 : 0;
        Future delayed = Future.delayed(animationDelay, () {
          opacityController.forward(from: 0);
        });
        delayed.ignore();
      });
    }
    if (offset != widget.offset) {
      if (!opacityController.isAnimating) {
        offset = widget.offset;
      } else {
        double relativePosX = offset.dx / oldContainerSize.width;
        double relativePosY = offset.dy / oldContainerSize.height;
        offset = Offset(relativePosX * containerSize.width, relativePosY * containerSize.height);
      }
    }
    if (labelContent != widget.labelContent) {
      if (!opacityController.isAnimating) {
        labelContent = widget.labelContent;
      }
    }
    if (oldShowing != showing && !showing) {
      if (!opacityController.isAnimating) {
        targetOpacity = 0;
        startingOpacity = currentOpacity;
        opacityController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    opacityCurved.removeListener(_opacityChangeHandler);
    opacityCurved.dispose();
    opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);
      Size customPaintSize = constraints.biggest;
      return CustomPaint(
        size: customPaintSize,
        painter: _GridColRowLabelPainter(
          axis: axis,
          color: color,
          labelContent: labelContent,
          offset: offset,
          opacity: currentOpacity,
        ),
      );
    });
  }
}

abstract class _GridColRowDefinition {
  String get description;
  bool get isElectronConfigurationLabel;
  bool isPresentInGameConfiguration(GameSettings configuration);
  _GridColRowLabel createWidget(GameSettings configuration, double cellSize, Size containerSize, Color color);
}

class _GroupElectronConfigurationLabelDefinition implements _GridColRowDefinition {
  final int groupNumber;
  final String block;

  _GroupElectronConfigurationLabelDefinition({required this.groupNumber, required this.block});

  double get _maxFontSize {
    return 24;
  }

  @override
  _GridColRowLabel createWidget(GameSettings configuration, double cellSize, Size containerSize, Color color) {
    double fontSize = min(cellSize / 3.2, _maxFontSize);
    int numElectrons;
    if (block == "f" || block == "s") {
      numElectrons = groupNumber;
    } else {
      if (block == "d") {
        numElectrons = groupNumber - 2;
      } else {
        //p-block
        numElectrons = groupNumber - 12;
      }
    }
    _LabelContent labelContent = _LabelContent(
        mainString: block,
        fontFamily: "Parisienne",
        superscript: numElectrons.toString(),
        mainFontSize: fontSize,
        superscriptHorizontalOffset: 0.5,
        superscriptVerticalOffset: 0);
    bool showing = isPresentInGameConfiguration(configuration);
    Key widgetKey = ObjectKey(this);
    Axis axis = Axis.vertical;
    int cellsX;
    int cellsY;
    switch (configuration.tableType.value) {
      case TableType.StandardTable:
        {
          cellsX = groupNumber;
          if (groupNumber == 1 || groupNumber == 18) {
            cellsY = 0;
          } else if (groupNumber == 2 || groupNumber >= 13) {
            cellsY = 1;
          } else {
            cellsY = 3;
          }
        }
        break;
      case TableType.CompactTable:
        {
          if (groupNumber <= 2) {
            cellsX = groupNumber;
          } else {
            cellsX = groupNumber - 10;
          }
          if (groupNumber == 1 || groupNumber == 18) {
            cellsY = 0;
          } else {
            cellsY = 1;
          }
        }
        break;
      case TableType.PBlock:
        {
          cellsX = groupNumber - 12;
          if (groupNumber == 18) {
            cellsY = 0;
          } else {
            cellsY = 1;
          }
        }
        break;
      case TableType.DBlock:
        {
          cellsX = groupNumber - 2;
          cellsY = 0;
        }
        break;
      case TableType.ExtendedTable:
        {
          if (block != "f") {
            if (groupNumber <= 2) {
              cellsX = groupNumber;
            } else {
              cellsX = groupNumber + 14;
            }
            if (groupNumber == 1 || groupNumber == 18) {
              cellsY = 0;
            } else if (groupNumber == 2 || groupNumber >= 13) {
              cellsY = 1;
            } else {
              cellsY = 3;
            }
          } else {
            cellsY = 5;
            cellsX = groupNumber + 2;
          }
        }
        break;
      case TableType.LeftStepTable:
        {
          if (block != "f") {
            if (groupNumber >= 3 && groupNumber <= 12) {
              cellsX = groupNumber - 2 + 14;
              cellsY = 4;
            } else if (groupNumber >= 13) {
              cellsX = groupNumber - 2 + 14;
              cellsY = 2;
            } else {
              cellsX = 14 + 10 + 6 + groupNumber;
              cellsY = 0;
            }
          } else {
            cellsY = 6;
            cellsX = groupNumber;
          }
        }
        break;
    }
    Rect drawingSpace = TableGrid.getTableDrawingSpace(configuration, containerSize);
    double labelOffsetX =
        drawingSpace.left + configuration.leftLineExtension.value + (cellsX - 1) * cellSize + cellSize / 2;
    double labelOffsetY = drawingSpace.top + configuration.topLineExtension.value + cellsY * cellSize;
    Offset labelOffset = Offset(labelOffsetX, labelOffsetY);
    return _GridColRowLabel(
      key: widgetKey,
      labelContent: labelContent,
      axis: axis,
      color: color,
      offset: labelOffset,
      showing: showing,
      tableType: configuration.tableType.value,
      containerSize: containerSize,
    );
  }

  @override
  String get description => "electron configuration label for group $groupNumber";

  @override
  bool get isElectronConfigurationLabel => true;

  @override
  bool isPresentInGameConfiguration(GameSettings configuration) {
    if (!configuration.showPeriodAndGroupLabels.value) {
      return false;
    }
    if (!configuration.showElectronConfigurationGroups.value) {
      if (!configuration.showFBlockGroups.value) {
        return false;
      } else {
        TableType tableType = configuration.tableType.value;
        return block == "f" && (tableType == TableType.ExtendedTable || tableType == TableType.LeftStepTable);
      }
    } else {
      switch (configuration.tableType.value) {
        case TableType.StandardTable:
          {
            return block != "f";
          }
        case TableType.DBlock:
          {
            return block != "f" && (groupNumber >= 3 && groupNumber <= 12);
          }
        case TableType.PBlock:
          {
            return block != "f" && groupNumber >= 13;
          }
        case TableType.CompactTable:
          {
            return block != "f" && (groupNumber <= 2 || groupNumber >= 13);
          }
        case TableType.ExtendedTable:
          {
            return true;
          }
        case TableType.LeftStepTable:
          {
            return true;
          }
      }
    }
  }

  @override
  int get hashCode {
    return groupNumber * block.hashCode * "groupElectronConfigurationLabel".hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is _GroupElectronConfigurationLabelDefinition) {
      return groupNumber == other.groupNumber && block == other.block;
    } else {
      return false;
    }
  }
}

class _GroupNumberLabelDefinition implements _GridColRowDefinition {
  final int groupNumber;

  _GroupNumberLabelDefinition({required this.groupNumber});

  double get _maxFontSize {
    return 14;
  }

  @override
  _GridColRowLabel createWidget(GameSettings configuration, double cellSize, Size containerSize, Color color) {
    double fontSize = min(cellSize / 5, _maxFontSize);
    _LabelContent labelContent = _LabelContent(
        mainString: groupNumber.toString(),
        fontFamily: "Noto",
        superscript: null,
        mainFontSize: fontSize,
        superscriptHorizontalOffset: 0,
        superscriptVerticalOffset: 0);
    bool showing = isPresentInGameConfiguration(configuration);
    Key widgetKey = ObjectKey(this);
    Axis axis = Axis.vertical;
    int cellsX;
    int cellsY;
    switch (configuration.tableType.value) {
      case TableType.StandardTable:
        {
          cellsX = groupNumber;
          if (groupNumber == 1 || groupNumber == 18) {
            cellsY = 0;
          } else if (groupNumber == 2 || groupNumber >= 13) {
            cellsY = 1;
          } else {
            cellsY = 3;
          }
        }
        break;
      case TableType.CompactTable:
        {
          if (groupNumber <= 2) {
            cellsX = groupNumber;
          } else {
            cellsX = groupNumber - 10;
          }
          if (groupNumber == 1 || groupNumber == 18) {
            cellsY = 0;
          } else {
            cellsY = 1;
          }
        }
        break;
      case TableType.PBlock:
        {
          cellsX = groupNumber - 12;
          if (groupNumber == 18) {
            cellsY = 0;
          } else {
            cellsY = 1;
          }
        }
        break;
      case TableType.DBlock:
        {
          cellsX = groupNumber - 2;
          cellsY = 0;
        }
        break;
      case TableType.ExtendedTable:
        {
          if (groupNumber <= 2) {
            cellsX = groupNumber;
          } else {
            cellsX = groupNumber + 14;
          }
          if (groupNumber == 1 || groupNumber == 18) {
            cellsY = 0;
          } else if (groupNumber == 2 || groupNumber >= 13) {
            cellsY = 1;
          } else {
            cellsY = 3;
          }
        }
        break;
      case TableType.LeftStepTable:
        {
          if (groupNumber >= 3 && groupNumber <= 12) {
            cellsX = groupNumber - 2 + 14;
            cellsY = 4;
          } else if (groupNumber >= 13) {
            cellsX = groupNumber - 2 + 14;
            cellsY = 2;
          } else {
            cellsX = 14 + 10 + 6 + groupNumber;
            cellsY = 0;
          }
        }
        break;
    }
    Rect drawingSpace = TableGrid.getTableDrawingSpace(configuration, containerSize);
    double labelOffsetX =
        drawingSpace.left + configuration.leftLineExtension.value + (cellsX - 1) * cellSize + cellSize / 2;
    double labelOffsetY = drawingSpace.top + configuration.topLineExtension.value + cellsY * cellSize - fontSize;
    Offset labelOffset = Offset(labelOffsetX, labelOffsetY);
    return _GridColRowLabel(
      key: widgetKey,
      labelContent: labelContent,
      axis: axis,
      color: color,
      offset: labelOffset,
      showing: showing,
      tableType: configuration.tableType.value,
      containerSize: containerSize,
    );
  }

  @override
  String get description => "regular label for group $groupNumber";

  @override
  bool get isElectronConfigurationLabel => false;

  @override
  bool isPresentInGameConfiguration(GameSettings configuration) {
    if (!configuration.showPeriodAndGroupLabels.value) {
      return false;
    }
    if (configuration.showElectronConfigurationGroups.value) {
      return false;
    }
    switch (configuration.tableType.value) {
      case TableType.StandardTable:
        {
          return true;
        }
      case TableType.CompactTable:
        {
          return groupNumber <= 2 || groupNumber >= 13;
        }
      case TableType.PBlock:
        {
          return groupNumber >= 13;
        }
      case TableType.DBlock:
        {
          return groupNumber >= 3 && groupNumber <= 12;
        }
      case TableType.ExtendedTable:
        {
          return true;
        }
      case TableType.LeftStepTable:
        {
          return true;
        }
    }
  }

  @override
  int get hashCode {
    return groupNumber * "groupNumberLabelDefinition".hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is _GroupNumberLabelDefinition) {
      return groupNumber == other.groupNumber;
    } else {
      return false;
    }
  }
}

class _PeriodLabelDefinition implements _GridColRowDefinition {
  final int period;

  _PeriodLabelDefinition({required this.period});

  double get _maxFontSize {
    return 14;
  }

  @override
  _GridColRowLabel createWidget(GameSettings configuration, double cellSize, Size containerSize, Color color) {
    double fontSize = min(cellSize / 5, _maxFontSize);
    _LabelContent labelContent = _LabelContent(
        mainString: period.toString(),
        fontFamily: "Noto",
        superscript: null,
        mainFontSize: fontSize,
        superscriptHorizontalOffset: 0,
        superscriptVerticalOffset: 0);
    bool showing = isPresentInGameConfiguration(configuration);
    Key widgetKey = ObjectKey(this);
    Axis axis = Axis.horizontal;
    _RegularPeriodSeparatorLine lineDefinition = _RegularPeriodSeparatorLine(periodBelow: period);
    var lineWidget = lineDefinition.createWidget(0, cellSize, configuration, containerSize, () {},
        statusOverride: _GridLineStatusInTable.InPosition);
    Offset lineoffset = lineWidget.targetOffset;
    double labelOffsetY = lineoffset.dy + cellSize / 2;
    double labelOffsetX = lineoffset.dx + configuration.leftLineExtension.value - fontSize;
    if (configuration.tableType.value == TableType.LeftStepTable) {
      labelOffsetX += fontSize / 2.5;
    }
    Offset labelOffset = Offset(labelOffsetX, labelOffsetY);
    return _GridColRowLabel(
      key: widgetKey,
      labelContent: labelContent,
      axis: axis,
      color: color,
      offset: labelOffset,
      showing: showing,
      tableType: configuration.tableType.value,
      containerSize: containerSize,
    );
  }

  @override
  String get description => "label for period $period";

  @override
  bool get isElectronConfigurationLabel => false;

  @override
  bool isPresentInGameConfiguration(GameSettings configuration) {
    if (!configuration.showPeriodAndGroupLabels.value) {
      return false;
    }
    switch (configuration.tableType.value) {
      case TableType.StandardTable:
        {
          return period <= 7;
        }
      case TableType.CompactTable:
        {
          return period <= 7;
        }
      case TableType.ExtendedTable:
        {
          return period <= 7;
        }
      case TableType.PBlock:
        {
          return period <= 7;
        }
      case TableType.DBlock:
        {
          return period >= 4 && period <= 7;
        }
      case TableType.LeftStepTable:
        {
          return period <= 8;
        }
    }
  }

  @override
  int get hashCode => period.hashCode * "periodLabelDefinition".hashCode;

  @override
  bool operator ==(Object other) {
    if (other is _PeriodLabelDefinition) {
      return period == other.period;
    } else {
      return false;
    }
  }
}

class _LabelContent {
  final String mainString;
  final String? superscript;
  final String fontFamily;
  final double mainFontSize;

  /// multiplier of letter width
  final double superscriptHorizontalOffset;

  /// multiplier of letter height
  final double superscriptVerticalOffset;

  _LabelContent(
      {required this.mainString,
      required this.fontFamily,
      required this.superscript,
      required this.mainFontSize,
      required this.superscriptHorizontalOffset,
      required this.superscriptVerticalOffset});

  @override
  int get hashCode {
    int code = mainString.hashCode * fontFamily.hashCode * mainFontSize.hashCode;
    if (superscript != null) {
      code *= superscript.hashCode * superscriptHorizontalOffset.hashCode * superscriptVerticalOffset.hashCode;
    }
    return code;
  }

  @override
  bool operator ==(Object other) {
    if (other is _LabelContent) {
      bool mainEqual = mainString == other.mainString &&
          superscript == other.superscript &&
          fontFamily == other.fontFamily &&
          mainFontSize == other.mainFontSize;
      if (superscript == null) {
        return mainEqual;
      } else {
        return mainEqual &&
            superscript == other.superscript &&
            superscriptHorizontalOffset == other.superscriptHorizontalOffset &&
            superscriptVerticalOffset == other.superscriptVerticalOffset;
      }
    } else {
      return false;
    }
  }
}

class _GridColRowLabelPainter extends CustomPainter {
  /// Vertical if group label, horizontal if period label
  final Axis axis;
  final _LabelContent labelContent;
  final double opacity;
  final Offset offset;
  final Color color;

  double get superscriptFontZize {
    return labelContent.mainFontSize / 3 * 2;
  }

  double get paragraphWidth {
    return 100;
  }

  _GridColRowLabelPainter(
      {required this.axis,
      required this.labelContent,
      required this.opacity,
      required this.offset,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    ui.ParagraphStyle mainParagraphStyle = ui.ParagraphStyle(
      fontFamily: labelContent.fontFamily,
      fontSize: labelContent.mainFontSize,
    );
    ui.ParagraphBuilder mainParagraphBuilder = ui.ParagraphBuilder(mainParagraphStyle);
    mainParagraphBuilder.pushStyle(ui.TextStyle(color: color.withOpacity(opacity)));
    mainParagraphBuilder.addText(labelContent.mainString);
    ui.Paragraph mainParagraph = mainParagraphBuilder.build();
    mainParagraph.layout(ui.ParagraphConstraints(width: paragraphWidth));
    double totalWidth = mainParagraph.longestLine;
    double letterwidth = totalWidth / labelContent.mainString.length;
    double letterHeight = mainParagraph.height;
    ui.Paragraph? superscriptParagraph;
    double superscriptWidth = 0;
    if (labelContent.superscript != null) {
      totalWidth += letterwidth * labelContent.superscriptHorizontalOffset;
      ui.ParagraphStyle superscriptParagraphStyle = ui.ParagraphStyle(
        fontFamily: labelContent.fontFamily,
        fontSize: superscriptFontZize,
      );
      ui.ParagraphBuilder superscriptParagraphBuilder = ui.ParagraphBuilder(superscriptParagraphStyle);
      superscriptParagraphBuilder.pushStyle(ui.TextStyle(color: color.withOpacity(opacity)));
      superscriptParagraphBuilder.addText(labelContent.superscript!);
      superscriptParagraph = superscriptParagraphBuilder.build();
      superscriptParagraph.layout(ui.ParagraphConstraints(width: paragraphWidth));
      superscriptWidth = superscriptParagraph.longestLine;
      totalWidth += superscriptWidth;
    }
    Offset mainTextRelativeOffset;
    Offset superscriptRelativeOffset;
    if (axis == Axis.horizontal) {
      double relativeMainX = -totalWidth;
      double relativeMainY = -letterHeight / 2;
      double relativeSuperX = -superscriptWidth;
      double relativeSuperY = -letterHeight / 2 + letterHeight * labelContent.superscriptVerticalOffset;
      mainTextRelativeOffset = Offset(relativeMainX, relativeMainY);
      superscriptRelativeOffset = Offset(relativeSuperX, relativeSuperY);
    } else {
      double relativeMainX = -totalWidth / 2;
      double relativeMainY = -letterHeight;
      double relativeSuperX = totalWidth / 2 - superscriptWidth;
      double relativeSuperY = -letterHeight + letterHeight * labelContent.superscriptVerticalOffset;
      mainTextRelativeOffset = Offset(relativeMainX, relativeMainY);
      superscriptRelativeOffset = Offset(relativeSuperX, relativeSuperY);
    }
    canvas.drawParagraph(mainParagraph, offset + mainTextRelativeOffset);
    if (superscriptParagraph != null) {
      canvas.drawParagraph(superscriptParagraph, offset + superscriptRelativeOffset);
    }
  }

  @override
  bool shouldRepaint(_GridColRowLabelPainter oldDelegate) {
    return axis != oldDelegate.axis ||
        labelContent != oldDelegate.labelContent ||
        opacity != oldDelegate.opacity ||
        offset != oldDelegate.offset ||
        color != oldDelegate.color;
  }
}

class OutlineTableIcon extends StatelessWidget {
  final bool adaptiveTable;
  final TableType? tableType;
  static const double _iconPadding = 4;

  const OutlineTableIcon({Key? key, required this.adaptiveTable, required this.tableType}) : super(key: key);

  List<Widget> _createStackChildren(Size containerSize) {
    if (adaptiveTable) {
      return _createAdaptiveTableIconLines(containerSize);
    } else {
      switch (tableType!) {
        case TableType.DBlock:
          {
            return _createDBlockTableIconLines(containerSize);
          }
        case TableType.CompactTable:
          {
            return _createCompactTableIconLines(containerSize);
          }
        case TableType.ExtendedTable:
          {
            return _createExtendedTableIconLines(containerSize);
          }
        case TableType.LeftStepTable:
          {
            return _createLeftStepTableIconLines(containerSize);
          }
        case TableType.PBlock:
          {
            return _createPBlockTableIconLines(containerSize);
          }
        case TableType.StandardTable:
          {
            return _createStandardTableIconLines(containerSize);
          }
      }
    }
  }

  List<Widget> _createAdaptiveTableIconLines(Size containerSize) {
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    _GridLine l1 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: bottomLeft,
      length: hLength + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: topLeft,
      length: vLength + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: topLeft,
      length: hLength / 3 + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: bottomRight - Offset(0, vLength / 3),
      length: vLength / 3 + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l5 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: topLeft + Offset(hLength / 3, 0),
      length: vLength + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l6 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: bottomLeft - Offset(0, vLength / 3),
      length: hLength + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    return [l1, l2, l3, l4, l5, l6];
  }

  List<Widget> _createDBlockTableIconLines(Size containerSize) {
    int cellsW = 10;
    int cellsH = 4;
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    double cellSizeX = hLength / cellsW;
    double cellSizeY = vLength / cellsH;
    double cellSize = min(cellSizeX, cellSizeY);
    double requieredWidth = cellSize * cellsW;
    double requieredHeight = cellSize * cellsH;
    double startX = (hLength - requieredWidth) / 2;
    double startY = (vLength - requieredHeight) / 2;
    _GridLine l1 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellsW * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellsH * cellSize),
      length: cellsW * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellsW * cellSize, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    return [l1, l2, l3, l4];
  }

  List<Widget> _createCompactTableIconLines(Size containerSize) {
    int cellsW = 8;
    int cellsH = 7;
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    double cellSizeX = hLength / cellsW;
    double cellSizeY = vLength / cellsH;
    double cellSize = min(cellSizeX, cellSizeY);
    double requieredWidth = cellSize * cellsW;
    double requieredHeight = cellSize * cellsH;
    double startX = (hLength - requieredWidth) / 2;
    double startY = (vLength - requieredHeight) / 2;
    _GridLine l1 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellsH * cellSize),
      length: cellsW * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellsW * cellSize, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l5 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l6 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l7 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l8 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + cellSize, startY + cellSize),
      length: (cellsW - 2) * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    return [l1, l2, l3, l4, l5, l6, l7, l8];
  }

  List<Widget> _createPBlockTableIconLines(Size containerSize) {
    int cellsW = 6;
    int cellsH = 7;
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    double cellSizeX = hLength / cellsW;
    double cellSizeY = vLength / cellsH;
    double cellSize = min(cellSizeX, cellSizeY);
    double requieredWidth = cellSize * cellsW;
    double requieredHeight = cellSize * cellsH;
    double startX = (hLength - requieredWidth) / 2;
    double startY = (vLength - requieredHeight) / 2;
    _GridLine l1 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellSize),
      length: (cellsH - 1) * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellsH * cellSize),
      length: cellsW * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellsW * cellSize, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellSize),
      length: (cellsW - 1) * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l5 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l6 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    return [l1, l2, l3, l4, l5, l6];
  }

  List<Widget> _createStandardTableIconLines(Size containerSize) {
    int cellsW = 18;
    int cellsH = 7;
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    double cellSizeX = hLength / cellsW;
    double cellSizeY = vLength / cellsH;
    double cellSize = min(cellSizeX, cellSizeY);
    double requieredWidth = cellSize * cellsW;
    double requieredHeight = cellSize * cellsH;
    double startX = (hLength - requieredWidth) / 2;
    double startY = (vLength - requieredHeight) / 2;
    _GridLine l1 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellsH * cellSize),
      length: cellsW * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW * cellSize), startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l5 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l6 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l7 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l8 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + cellSize, startY + cellSize),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l9 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + 12 * cellSize, startY + cellSize),
      length: 5 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l10 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + 2 * cellSize, startY + cellSize),
      length: 2 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l11 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + 12 * cellSize, startY + cellSize),
      length: 2 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l12 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + 2 * cellSize, startY + 3 * cellSize),
      length: 10 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    return [l1, l2, l3, l4, l5, l6, l7, l8, l9, l10, l11, l12];
  }

  List<Widget> _createExtendedTableIconLines(Size containerSize) {
    int cellsW = 32;
    int cellsH = 7;
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    double cellSizeX = hLength / cellsW;
    double cellSizeY = vLength / cellsH;
    double cellSize = min(cellSizeX, cellSizeY);
    double requieredWidth = cellSize * cellsW;
    double requieredHeight = cellSize * cellsH;
    double startX = (hLength - requieredWidth) / 2;
    double startY = (vLength - requieredHeight) / 2;
    _GridLine l1 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellsH * cellSize),
      length: cellsW * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellsW * cellSize, startY),
      length: cellsH * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l5 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l6 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l7 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 1) * cellSize, startY),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l8 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + cellSize, startY + cellSize),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l9 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 6) * cellSize, startY + cellSize),
      length: 5 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l10 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + 2 * cellSize, startY + cellSize),
      length: 4 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l11 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 6) * cellSize, startY + cellSize),
      length: 2 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l12 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + 2 * cellSize, startY + 5 * cellSize),
      length: 14 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l13 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + 16 * cellSize, startY + 3 * cellSize),
      length: 10 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l14 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + 16 * cellSize, startY + 3 * cellSize),
      length: 2 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    return [l1, l2, l3, l4, l5, l6, l7, l8, l9, l10, l11, l12, l13, l14];
  }

  List<Widget> _createLeftStepTableIconLines(Size containerSize) {
    int cellsW = 32;
    int cellsH = 8;
    Random random = Random();
    Offset topLeft = const Offset(_iconPadding, _iconPadding);
    //Offset topRight = Offset(containerSize.width - _iconPadding, _iconPadding);
    Offset bottomLeft = Offset(_iconPadding, containerSize.height - _iconPadding);
    Offset bottomRight = Offset(containerSize.width - _iconPadding, containerSize.height - _iconPadding);
    double lineTime = random.nextDouble() * 1000;
    double hLength = (bottomRight - bottomLeft).distance;
    double vLength = (bottomLeft - topLeft).distance;
    double cellSizeX = hLength / cellsW;
    double cellSizeY = vLength / cellsH;
    double cellSize = min(cellSizeX, cellSizeY);
    double requieredWidth = cellSize * cellsW;
    double requieredHeight = cellSize * cellsH;
    double startX = (hLength - requieredWidth) / 2;
    double startY = (vLength - requieredHeight) / 2;
    double cx = startX;
    double cy = startY + (cellsH - 2) * cellSize;
    List<Widget> lines = [];
    for (int i in [14, 10, 6, 2]) {
      _GridLine downLine = _GridLine(
        axis: Axis.vertical,
        time: lineTime,
        targetOffset: Offset(cx, cy),
        length: 2 * cellSize + 1,
        lineStatus: _GridLineStatusInTable.InPosition,
        containerSize: containerSize,
        statusAnimationfinishedHandler: () {},
      );
      _GridLine hLine = _GridLine(
        axis: Axis.horizontal,
        time: lineTime,
        targetOffset: Offset(cx, cy),
        length: i * cellSize + 1,
        lineStatus: _GridLineStatusInTable.InPosition,
        containerSize: containerSize,
        statusAnimationfinishedHandler: () {},
      );
      lines.add(downLine);
      lines.add(hLine);
      cx += i * cellSize;
      cy -= 2 * cellSize;
    }
    _GridLine l1 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX, startY + cellsH * cellSize),
      length: (cellsW - 2) * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l2 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + cellsW * cellSize, startY),
      length: (cellsH - 1) * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l3 = _GridLine(
      axis: Axis.horizontal,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 2) * cellSize, startY + (cellsH - 1) * cellSize),
      length: 2 * cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    _GridLine l4 = _GridLine(
      axis: Axis.vertical,
      time: lineTime,
      targetOffset: Offset(startX + (cellsW - 2) * cellSize, startY + (cellsH - 1) * cellSize),
      length: cellSize + 1,
      lineStatus: _GridLineStatusInTable.InPosition,
      containerSize: containerSize,
      statusAnimationfinishedHandler: () {},
    );
    lines.addAll([l1, l2, l3, l4]);
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight);
      Size containerSize = constraints.biggest;
      List<Widget> stackChildren = _createStackChildren(containerSize);
      return Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.passthrough,
        children: stackChildren,
      );
    });
  }
}
