import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/ElementSquare.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class ElementInfoDialog {
  static void showElementInfoDialog(ChemicalElement element, BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) {
          GameSettings detailsDisplaySettings =
              GameSettings(initialPuzzle: SlidePuzzle.fromTableType(TableType.PBlock));
          detailsDisplaySettings.showAtomicMasses.value = true;
          detailsDisplaySettings.showAtomicNumbers.value = true;
          detailsDisplaySettings.showRadiationEffects.value = false;
          List<Widget> titleRowWidgets = [
            ConstrainedBox(
              constraints: BoxConstraints.tight(
                const Size(120, 120),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child:
                    ElementSquare(gameTheme: detailsDisplaySettings, chemicalElement: element, rotation: 0, opacity: 1),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  element.fullName,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          ];
          if (element.radioactivity > 0) {
            titleRowWidgets.add(
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "☢",
                  style: TextStyle(color: Colors.amber, fontSize: 36),
                ),
              ),
            );
          }
          // String blockString = element.block;
          // String periodString = element.period.toString();
          // String groupString;
          // if (element.group != null) {
          //   groupString = element.group.toString();
          // } else {
          //   groupString = "-";
          // }
          Widget mainDialogContent = DefaultTextStyle(
            style: TextStyle(color: Colors.grey.shade200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: titleRowWidgets,
                ),
                // _DetailCard(
                //   icon: RotatedBox(
                //     quarterTurns: 1,
                //     child: Icon(
                //       Icons.view_column_rounded,
                //       size: 80,
                //       color: Colors.grey.shade200,
                //     ),
                //   ),
                //   title: periodString,
                //   subtitle: "Period",
                // ),
                // _DetailCard(
                //   icon: Icon(
                //     Icons.view_column_rounded,
                //     size: 80,
                //     color: Colors.grey.shade200,
                //   ),
                //   title: groupString,
                //   subtitle: "Group",
                // ),
                // _DetailCard(
                //   icon: Icon(
                //     Icons.table_chart,
                //     size: 80,
                //     color: Colors.grey.shade200,
                //   ),
                //   title: blockString,
                //   subtitle: "Block",
                // ),
                _DetailCard(
                  icon: Icon(
                    Icons.radar,
                    size: 80,
                    color: Colors.grey.shade200,
                  ),
                  //title: getECString(element),
                  titleWidget: _ElectronConfigurationLabel(
                    element: element,
                    mainFontSize: 26,
                  ),
                  subtitle: "Electron configuration",
                ),
              ],
            ),
          );
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              "Element info",
              style: TextStyle(color: Colors.grey.shade200),
            ),
            content: mainDialogContent,
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text("close"))
            ],
          );
        });
  }

  static String getECString(ChemicalElement element) {
    ElectronConfiguration elementEC = element.electronConfiguration.realConfiguration();
    ChemicalElement? nobleGasCore = element.electronConfiguration.getNobleGasCore(ChemicalElements.getElements());
    String ecString = "";
    if (nobleGasCore != null) {
      ecString = "[" + nobleGasCore.symbol + "] ";
    }
    List<FilledOrbital> lastOrbitals;
    if (nobleGasCore == null) {
      lastOrbitals = elementEC.orbitals;
    } else {
      lastOrbitals = elementEC.orbitals.sublist(nobleGasCore.electronConfiguration.orbitals.length);
    }
    String fullElementECString = elementEC.toString();
    List<String> fullElementECParts = fullElementECString.split(" ");
    List<String> lastParts = fullElementECParts.sublist(fullElementECParts.length - lastOrbitals.length - 1);
    for (var part in lastParts) {
      ecString += part + " ";
    }
    return ecString;
  }
}

class _DetailCard extends StatelessWidget {
  final Widget icon;
  final String? title;
  final Widget? titleWidget;
  final String subtitle;
  const _DetailCard({Key? key, required this.icon, this.title, required this.subtitle, this.titleWidget})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    assert(title != null || titleWidget != null);
    Widget? mainWidget = titleWidget;
    if (titleWidget == null) {
      mainWidget = Text(
        title!,
        style: TextStyle(fontSize: 26, color: Colors.grey.shade200),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: Card(
        color: Colors.grey.shade900,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: ListTile(
            leading: icon,
            title: mainWidget,
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade200),
            ),
          ),
        ),
      ),
    );
  }
}

class _ElectronConfigurationLabel extends StatelessWidget {
  final double mainFontSize;
  final ChemicalElement element;

  const _ElectronConfigurationLabel({Key? key, required this.mainFontSize, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double requiredWidth = ElementInfoDialog.getECString(element).length * mainFontSize / 2.5;
    return Semantics(
      child: CustomPaint(
        willChange: false,
        foregroundPainter: _ElectronConfigurationPainter(element: element, mainFontSize: mainFontSize),
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: requiredWidth, height: mainFontSize * 1.2),
        ),
      ),
      label: element.electronConfiguration.realConfiguration().toString(),
    );
  }
}

class _ElectronConfigurationPainter extends CustomPainter {
  final double mainFontSize;
  final ChemicalElement element;

  _ElectronConfigurationPainter({required this.mainFontSize, required this.element}) : super();

  @override
  void paint(Canvas canvas, Size size) {
    ui.ParagraphStyle mainParagraphStyle = ui.ParagraphStyle(fontSize: mainFontSize);
    ui.ParagraphStyle superscriptParagraphStyle = ui.ParagraphStyle(fontSize: mainFontSize / 2);
    double spaceSize = mainFontSize / 3;
    Color textColor = Colors.grey.shade200;
    double spaceUsed = 0;
    ElectronConfiguration elementEC = element.electronConfiguration.realConfiguration();
    ChemicalElement? nobleGasCore = element.electronConfiguration.getNobleGasCore(ChemicalElements.getElements());
    if (nobleGasCore != null) {
      String coreString = "[" + nobleGasCore.symbol + "]";
      ui.ParagraphBuilder coreStringBuilder = ui.ParagraphBuilder(mainParagraphStyle);
      coreStringBuilder.pushStyle(ui.TextStyle(color: textColor));
      coreStringBuilder.addText(coreString);
      var coreParagraph = coreStringBuilder.build();
      coreParagraph.layout(const ui.ParagraphConstraints(width: 150));
      spaceUsed += coreParagraph.longestLine + spaceSize;
      canvas.drawParagraph(coreParagraph, Offset.zero);
    }
    List<FilledOrbital> lastOrbitals;
    if (nobleGasCore == null) {
      lastOrbitals = elementEC.orbitals;
    } else {
      lastOrbitals = elementEC.orbitals.sublist(nobleGasCore.electronConfiguration.orbitals.length);
    }
    String fullElementECString = elementEC.toString();
    List<String> fullElementECParts = fullElementECString.split(" ");
    List<String> lastParts = fullElementECParts.sublist(fullElementECParts.length - lastOrbitals.length - 1);
    for (var part in lastParts) {
      if (part.isEmpty) {
        continue;
      }
      String layerTypePart = part.substring(0, 2);
      String superscriptPart = part.substring(2);
      ui.ParagraphBuilder layerTypeParagraphBuilder = ui.ParagraphBuilder(mainParagraphStyle);
      layerTypeParagraphBuilder.pushStyle(ui.TextStyle(color: textColor));
      layerTypeParagraphBuilder.addText(layerTypePart);
      var layerTypeParagraph = layerTypeParagraphBuilder.build();
      layerTypeParagraph.layout(const ui.ParagraphConstraints(width: 150));
      canvas.drawParagraph(layerTypeParagraph, Offset(spaceUsed, 0));
      spaceUsed += layerTypeParagraph.longestLine;
      ui.ParagraphBuilder superscriptBuilder = ui.ParagraphBuilder(superscriptParagraphStyle);
      superscriptBuilder.pushStyle(ui.TextStyle(color: textColor));
      superscriptBuilder.addText(superscriptPart);
      var superscriptParagraph = superscriptBuilder.build();
      superscriptParagraph.layout(const ui.ParagraphConstraints(width: 150));
      canvas.drawParagraph(superscriptParagraph, Offset(spaceUsed, 0));
      spaceUsed += superscriptParagraph.longestLine + spaceSize;
      // ui.ParagraphBuilder spaceBuilder = ui.ParagraphBuilder(mainParagraphStyle);
      // spaceBuilder.pushStyle(ui.TextStyle(color: textColor));
      // spaceBuilder.addText(" ");
      // var spaceParagraph = spaceBuilder.build();
      // spaceParagraph.layout(const ui.ParagraphConstraints(width: 150));
      // canvas.drawParagraph(spaceParagraph, Offset(spaceUsed, 0));
      // spaceUsed += spaceParagraph.longestLine;
    }
  }

  @override
  bool shouldRepaint(_ElectronConfigurationPainter oldDelegate) {
    return mainFontSize != oldDelegate.mainFontSize || element != oldDelegate.element;
  }
}
