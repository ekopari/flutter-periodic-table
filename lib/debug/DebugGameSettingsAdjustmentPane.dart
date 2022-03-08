import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class DebugGameSettingsAdjustmentPane extends StatefulWidget {
  final GameSettings gameSettings;
  final SlidePuzzle puzzle;
  DebugGameSettingsAdjustmentPane({Key? key, required this.gameSettings, required this.puzzle}) : super(key: key);

  @override
  State<DebugGameSettingsAdjustmentPane> createState() {
    return _DebugGameSettingsAdjustmentPaneState();
  }
}

class _DebugGameSettingsAdjustmentPaneState extends State<DebugGameSettingsAdjustmentPane> {
  late GameSettings gameSettings;
  late SlidePuzzle puzzle;

  void _updateSettings() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    gameSettings = widget.gameSettings;
    puzzle = widget.puzzle;
    gameSettings.showRadiationEffects.addListener(_updateSettings);
    gameSettings.showAtomicNumbers.addListener(_updateSettings);
    gameSettings.showAtomicMasses.addListener(_updateSettings);
    gameSettings.backgroundColor.addListener(_updateSettings);
    gameSettings.tableType.addListener(_updateSettings);
    gameSettings.showPeriodAndGroupLabels.addListener(_updateSettings);
    gameSettings.showFBlockGroups.addListener(_updateSettings);
    gameSettings.showElectronConfigurationGroups.addListener(_updateSettings);
  }

  @override
  void didUpdateWidget(covariant DebugGameSettingsAdjustmentPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    gameSettings.showRadiationEffects.removeListener(_updateSettings);
    gameSettings.showAtomicNumbers.removeListener(_updateSettings);
    gameSettings.showAtomicMasses.removeListener(_updateSettings);
    gameSettings.backgroundColor.removeListener(_updateSettings);
    gameSettings.tableType.removeListener(_updateSettings);
    gameSettings.showPeriodAndGroupLabels.removeListener(_updateSettings);
    gameSettings.showFBlockGroups.removeListener(_updateSettings);
    gameSettings.showElectronConfigurationGroups.removeListener(_updateSettings);
    gameSettings = widget.gameSettings;
    gameSettings.showRadiationEffects.addListener(_updateSettings);
    gameSettings.showAtomicNumbers.addListener(_updateSettings);
    gameSettings.showAtomicMasses.addListener(_updateSettings);
    gameSettings.backgroundColor.addListener(_updateSettings);
    gameSettings.tableType.addListener(_updateSettings);
    gameSettings.showPeriodAndGroupLabels.addListener(_updateSettings);
    gameSettings.showFBlockGroups.addListener(_updateSettings);
    gameSettings.showElectronConfigurationGroups.addListener(_updateSettings);
  }

  @override
  void dispose() {
    gameSettings.showRadiationEffects.removeListener(_updateSettings);
    gameSettings.showAtomicNumbers.removeListener(_updateSettings);
    gameSettings.showAtomicMasses.removeListener(_updateSettings);
    gameSettings.backgroundColor.removeListener(_updateSettings);
    gameSettings.tableType.removeListener(_updateSettings);
    gameSettings.showPeriodAndGroupLabels.removeListener(_updateSettings);
    gameSettings.showFBlockGroups.removeListener(_updateSettings);
    gameSettings.showElectronConfigurationGroups.removeListener(_updateSettings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var container = Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Radiation effects"),
              Checkbox(
                  value: gameSettings.showRadiationEffects.value,
                  onChanged: (value) {
                    gameSettings.showRadiationEffects.value = value!;
                  }),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Show atomic numbers"),
              Checkbox(
                  value: gameSettings.showAtomicNumbers.value,
                  onChanged: (value) {
                    gameSettings.showAtomicNumbers.value = value!;
                  }),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Show atomic masses"),
              Checkbox(
                  value: gameSettings.showAtomicMasses.value,
                  onChanged: (value) {
                    gameSettings.showAtomicMasses.value = value!;
                  }),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Table type"),
              DropdownButton<TableType>(
                  value: gameSettings.tableType.value,
                  items: [
                    TableType.StandardTable,
                    TableType.CompactTable,
                    TableType.ExtendedTable,
                    TableType.LeftStepTable,
                    TableType.PBlock,
                    TableType.DBlock
                  ].map((e) {
                    return DropdownMenuItem<TableType>(
                      child: Text(e.toString()),
                      value: e,
                    );
                  }).toList(),
                  onChanged: (value) {
                    gameSettings.tableType.value = value!;
                  }),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Background color"),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("black"),
                      Radio<Color>(
                        value: Colors.black,
                        groupValue: gameSettings.backgroundColor.value,
                        onChanged: (value) {
                          gameSettings.backgroundColor.value = value!;
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("red"),
                      Radio<Color>(
                        value: Colors.red.shade900,
                        groupValue: gameSettings.backgroundColor.value,
                        onChanged: (value) {
                          gameSettings.backgroundColor.value = value!;
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("blue"),
                      Radio<Color>(
                        value: Colors.blue.shade900,
                        groupValue: gameSettings.backgroundColor.value,
                        onChanged: (value) {
                          gameSettings.backgroundColor.value = value!;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Show group/period numbers"),
              Checkbox(
                  value: gameSettings.showPeriodAndGroupLabels.value,
                  onChanged: (value) {
                    gameSettings.showPeriodAndGroupLabels.value = value!;
                  }),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Show F-block groups"),
              Checkbox(
                  value: gameSettings.showFBlockGroups.value,
                  onChanged: (value) {
                    gameSettings.showFBlockGroups.value = value!;
                  }),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Show electron configuration groups"),
              Checkbox(
                  value: gameSettings.showElectronConfigurationGroups.value,
                  onChanged: (value) {
                    gameSettings.showElectronConfigurationGroups.value = value!;
                  }),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              ChemicalElement lastElement = puzzle.elements.last;
              puzzle.removeElement(lastElement);
            },
            child: const Text("remove last element"),
          ),
          ElevatedButton(
            onPressed: () {
              for (var period in puzzle.periods) {
                String ps = "";
                for (var cell in period) {
                  if (cell == null) {
                    ps += "  ,";
                  } else {
                    if (cell.content == null) {
                      ps += "[],";
                    } else {
                      String symbol = cell.content!.symbol;
                      if (symbol.length == 1) {
                        symbol += " ";
                      }
                      ps += symbol + ",";
                    }
                  }
                }
                print(ps);
              }
            },
            child: const Text("print puzzle cells"),
          ),
          ElevatedButton(
            onPressed: () {
              puzzle.shuffle();
            },
            child: const Text("shuffle"),
          ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: container,
      ),
    );
  }
}
