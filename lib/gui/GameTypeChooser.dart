import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/gui/TableGrid.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class GameTypeChooser extends StatelessWidget {
  final GameSettings settings;

  const GameTypeChooser({Key? key, required this.settings}) : super(key: key);

  static void showGameTypeChooser(BuildContext context, GameSettings settings) {
    NavigatorState navigator = Navigator.of(context);
    navigator.push(MaterialPageRoute(builder: (ctx) {
      return GameTypeChooser(
        settings: settings,
      );
    }));
  }

  /// null means adaptive
  void _tableTypeChosen(TableType? tt, double screenWidth, BuildContext context) {
    if (tt != null) {
      settings.tableType.value = tt;
      settings.puzzle.value = SlidePuzzle.fromTableType(tt);
    } else {
      // adaptive table type
      settings.setAdaptiveTableType(screenWidth);
    }
    settings.showRadiationEffects.value = false;
    settings.showAtomicNumbers.value = true;
    settings.showAtomicMasses.value = true;
    Navigator.of(context).pop();
  }

  Map<OutlineTableIcon, String> _gameTypes() {
    Map<OutlineTableIcon, String> gameTypes = {};
    OutlineTableIcon adaptiveGame = const OutlineTableIcon(adaptiveTable: true, tableType: null);
    gameTypes[adaptiveGame] = "Adaptive";
    OutlineTableIcon standardTable = const OutlineTableIcon(adaptiveTable: false, tableType: TableType.StandardTable);
    gameTypes[standardTable] = "Standard";
    OutlineTableIcon compactTable = const OutlineTableIcon(adaptiveTable: false, tableType: TableType.CompactTable);
    gameTypes[compactTable] = "Compact";
    OutlineTableIcon pBlockTable = const OutlineTableIcon(adaptiveTable: false, tableType: TableType.PBlock);
    gameTypes[pBlockTable] = "P-block";
    OutlineTableIcon dBlockTable = const OutlineTableIcon(adaptiveTable: false, tableType: TableType.DBlock);
    gameTypes[dBlockTable] = "D-block";
    OutlineTableIcon extendedTable = const OutlineTableIcon(adaptiveTable: false, tableType: TableType.ExtendedTable);
    gameTypes[extendedTable] = "Extended";
    OutlineTableIcon leftStepTable = const OutlineTableIcon(adaptiveTable: false, tableType: TableType.LeftStepTable);
    gameTypes[leftStepTable] = "Left-step";
    return gameTypes;
  }

  Color _getButtonColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.focused) ||
        states.contains(MaterialState.hovered) ||
        states.contains(MaterialState.pressed)) {
      return Colors.grey.shade800;
    } else {
      return Colors.black;
    }
  }

  List<Widget> _createGameTypeButtons(double cellWidth, double screenWidth, BuildContext context) {
    var gameTypes = _gameTypes();
    List<Widget> buttons = [];
    for (var outline in gameTypes.keys) {
      String buttonText = gameTypes[outline]!;
      TableType? tableType = outline.tableType;
      buttons.add(
        TextButton(
          onPressed: () {
            _tableTypeChosen(tableType, screenWidth, context);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(_getButtonColor),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: cellWidth / 2.5, maxWidth: cellWidth / 2.5),
                  child: outline,
                ),
                Text(
                  buttonText,
                  style: TextStyle(color: Colors.white, fontSize: cellWidth / 16),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      assert(constraints.hasBoundedWidth);
      double screenWidth = constraints.maxWidth;
      int numColumns;
      if (screenWidth <= 600) {
        numColumns = 1;
      } else if (screenWidth <= 992) {
        numColumns = 2;
      } else {
        numColumns = 3;
      }
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120),
                child: const Center(
                  child: Text(
                    "Choose table type",
                    style: TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: numColumns,
                padding: const EdgeInsets.all(15),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                primary: false,
                children: _createGameTypeButtons(screenWidth / numColumns, screenWidth, ctx),
              ),
            ],
          ),
        ),
      );
    });
  }
}
