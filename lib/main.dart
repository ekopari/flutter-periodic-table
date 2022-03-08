import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/gui/SlideGameUI.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Periodic table puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SlidePuzzleHome(),
    );
  }
}

class SlidePuzzleHome extends StatefulWidget {
  const SlidePuzzleHome({Key? key}) : super(key: key);

  @override
  State<SlidePuzzleHome> createState() => _SlidePuzzleHomeState();
}

class _SlidePuzzleHomeState extends State<SlidePuzzleHome> {
  bool firstRun = true;
  late GameSettings gameSettings;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (firstRun) {
        firstRun = false;
        SlidePuzzle defaultPuzzle = SlidePuzzle.fromTableType(TableType.StandardTable);
        gameSettings = GameSettings(initialPuzzle: defaultPuzzle);
        gameSettings.setAdaptiveTableType(constraints.maxWidth);
      }
      return Scaffold(
        body: SlideGameUI(settings: gameSettings),
      );
    });
  }
}
