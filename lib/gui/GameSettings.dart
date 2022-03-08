import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class GameSettings {
  final ValueNotifier<Color> _backgroundColor;
  final ValueNotifier<bool> _showAtomicNumbers;
  final ValueNotifier<bool> _showAtomicMasses;
  final ValueNotifier<bool> _showRadiationEffects;

  final ValueNotifier<SlidePuzzle> _puzzzle;
  final ValueNotifier<TableType> _tableType;
  final ValueNotifier<double> _minimumTablePadding;
  final ValueNotifier<double> _topLineExtension;
  final ValueNotifier<double> _leftLineExtension;
  final ValueNotifier<bool> _showPeriodAndGroupLabels;
  final ValueNotifier<bool> _showFBlockGroups;
  final ValueNotifier<bool> _showElectronConfigurationGroups;

  GameSettings({required SlidePuzzle initialPuzzle})
      : _backgroundColor = ValueNotifier(Colors.black),
        _showAtomicNumbers = ValueNotifier(true),
        _showAtomicMasses = ValueNotifier(true),
        _showRadiationEffects = ValueNotifier(false),
        _tableType = ValueNotifier(TableType.StandardTable),
        _minimumTablePadding = ValueNotifier(20),
        _topLineExtension = ValueNotifier(15),
        _leftLineExtension = ValueNotifier(15),
        _showPeriodAndGroupLabels = ValueNotifier(true),
        _showFBlockGroups = ValueNotifier(true),
        _showElectronConfigurationGroups = ValueNotifier(false),
        _puzzzle = ValueNotifier(initialPuzzle);

  ValueNotifier<Color> get backgroundColor {
    return _backgroundColor;
  }

  ValueNotifier<bool> get showAtomicNumbers {
    return _showAtomicNumbers;
  }

  ValueNotifier<bool> get showAtomicMasses {
    return _showAtomicMasses;
  }

  ValueNotifier<bool> get showRadiationEffects {
    return _showRadiationEffects;
  }

  ValueNotifier<SlidePuzzle> get puzzle {
    return _puzzzle;
  }

  ValueNotifier<TableType> get tableType {
    return _tableType;
  }

  ValueNotifier<double> get minimumTablePadding {
    return _minimumTablePadding;
  }

  ValueNotifier<double> get topLineExtension {
    return _topLineExtension;
  }

  ValueNotifier<double> get leftLineExtension {
    return _leftLineExtension;
  }

  ValueNotifier<bool> get showPeriodAndGroupLabels {
    return _showPeriodAndGroupLabels;
  }

  ValueNotifier<bool> get showFBlockGroups {
    return _showFBlockGroups;
  }

  ValueNotifier<bool> get showElectronConfigurationGroups {
    return _showElectronConfigurationGroups;
  }

  /// number of cells
  int get tableWidth {
    switch (_tableType.value) {
      case (TableType.StandardTable):
        {
          return 18;
        }
      case (TableType.CompactTable):
        {
          return 8;
        }
      case (TableType.PBlock):
        {
          return 6;
        }
      case (TableType.DBlock):
        {
          return 10;
        }
      case (TableType.LeftStepTable):
        {
          return 18 + 14;
        }
      case (TableType.ExtendedTable):
        {
          return 18 + 14;
        }
      default:
        {
          throw AssertionError();
        }
    }
  }

  /// number of cells
  int get tableHeight {
    if (tableType.value != TableType.DBlock) {
      return 7;
    } else {
      return 4;
    }
  }

  void setAdaptiveTableType(double screenWidth) {
    if (screenWidth <= 600) {
      tableType.value = TableType.PBlock;
    } else if (screenWidth <= 992) {
      tableType.value = TableType.CompactTable;
    } else {
      tableType.value = TableType.StandardTable;
    }
    puzzle.value = SlidePuzzle.fromTableType(tableType.value);
  }
}

enum TableType {
  /// P-block only (groups 13-18), includes Helium due to its position in group 18
  PBlock,

  /// D-block only (transition metals)
  DBlock,

  /// Standard periodic table, without f-block
  StandardTable,

  /// Extended table with f-block to the right of the s-block
  ExtendedTable,

  /// S-block plus p-block, no f-block or d-block
  CompactTable,

  /// Shows blocks in the order f-d-p-s, left-to-right
  LeftStepTable,
}
