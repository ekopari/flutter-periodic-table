import 'dart:math';

import 'package:periodic_table_puzzle/gui/GameSettings.dart';
import 'package:periodic_table_puzzle/models/ChemicalElement.dart';
import 'package:periodic_table_puzzle/models/puzzle/SlidePuzzle.dart';

abstract class GameHint {
  bool isApplicable(GameSettings settings, SlidePuzzle puzzle);
  void applyHint(GameSettings settings, SlidePuzzle puzzle);
  static List<GameHint> allHints() {
    List<GameHint> hints = [
      RadioactivityHint(),
      AtomicMassHint(),
      AtomicNumberHint(),
      ElementEjectionHint(),
    ];
    return hints;
  }
}

class RadioactivityHint implements GameHint {
  @override
  void applyHint(GameSettings settings, SlidePuzzle puzzle) {
    settings.showRadiationEffects.value = true;
  }

  @override
  bool isApplicable(GameSettings settings, SlidePuzzle puzzle) {
    return settings.showRadiationEffects.value == false;
  }
}

class AtomicMassHint implements GameHint {
  @override
  void applyHint(GameSettings settings, SlidePuzzle puzzle) {
    settings.showAtomicMasses.value = true;
  }

  @override
  bool isApplicable(GameSettings settings, SlidePuzzle puzzle) {
    return settings.showAtomicMasses.value == false;
  }
}

class AtomicNumberHint implements GameHint {
  @override
  void applyHint(GameSettings settings, SlidePuzzle puzzle) {
    settings.showAtomicNumbers.value = true;
  }

  @override
  bool isApplicable(GameSettings settings, SlidePuzzle puzzle) {
    return settings.showAtomicNumbers.value == false;
  }
}

class ElementEjectionHint implements GameHint {
  final Random random = Random();
  @override
  void applyHint(GameSettings settings, SlidePuzzle puzzle) {
    ChemicalElement toRemove = puzzle.elements[random.nextInt(puzzle.elements.length)];
    puzzle.removeElement(toRemove);
  }

  @override
  bool isApplicable(GameSettings settings, SlidePuzzle puzzle) {
    return puzzle.elements.length > 1;
  }
}
