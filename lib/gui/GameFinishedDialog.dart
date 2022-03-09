import 'package:flutter/material.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

class GameFinishedDialog {
  static Future<GameFinishedDialogResult?> showGameFinishedDialog(SlidePuzzle completedPuzzle, BuildContext context) {
    return showDialog<GameFinishedDialogResult?>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade200,
            title: const Text("Puzzle solved!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Card(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 100),
                      child: ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          size: 80,
                        ),
                        title: Text(
                          _solveTimeString(completedPuzzle.timeSpentSolving!),
                          style: const TextStyle(fontSize: 26),
                        ),
                        subtitle: const Text(
                          "Solve time",
                          //style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 100),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.compare_arrows,
                          size: 80,
                        ),
                        title: Text(
                          completedPuzzle.moveCount.toString(),
                          style: const TextStyle(fontSize: 26),
                        ),
                        subtitle: const Text(
                          "Move count",
                          //style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 100),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.lightbulb_outline,
                          size: 80,
                        ),
                        title: Text(
                          _hintsUsedString(completedPuzzle.hintsUsed),
                          style: const TextStyle(fontSize: 26),
                        ),
                        subtitle: const Text(
                          "Hints used",
                          //style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, GameFinishedDialogResult.NewGame);
                },
                child: const Text("New game"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, GameFinishedDialogResult.Remain);
                },
                child: const Text("Cancel"),
              ),
            ],
          );
        });
  }

  static String _hintsUsedString(int hintsUsed) {
    if (hintsUsed > 0) {
      return hintsUsed.toString();
    } else {
      return "zero";
    }
  }

  static String _solveTimeString(Duration d) {
    int seconds = d.inSeconds;
    int minutes = seconds ~/ 60;
    seconds %= 60;
    String secondsString = seconds.toString();
    if (seconds < 10) {
      secondsString = "0" + secondsString;
    }
    if (minutes == 0) {
      return secondsString + " seconds";
    } else {
      return "$minutes:$secondsString";
    }
  }
}

enum GameFinishedDialogResult { Remain, NewGame }
