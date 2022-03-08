import 'dart:ui';

class ChemicalElement {
  const ChemicalElement(
      {required this.atomicNumber,
      required this.symbol,
      required this.fullName,
      required this.atomicMass,
      this.isArtificial = false,
      this.radioactivity = 0,
      required this.emissionColor,
      required this.block,
      required this.group,
      required this.period,
      required this.electronConfiguration});

  /// 1 for hydrogen, 2 for helium, ...
  final int atomicNumber;

  /// The element's symbol in the periodic table (for example Na for sodium, Fe for iron, ...)
  final String symbol;

  /// The element's full name in the current language
  final String fullName;

  /// The element's standard atomic mass. `null` if unknown
  final double? atomicMass;

  /// `true` for elements not found in nature
  final bool isArtificial;

  /// Not a true physical measurement, used for display and animation.
  /// `0` means not radioactive (or extremely long-lived, like bismuth)
  final double radioactivity;

  /// Used for display
  final Color? emissionColor;

  /// s, p, d or f-block
  final String block;

  final ElectronConfiguration electronConfiguration;

  /// `null` for f-block elements, as these aren't assigned a group
  final int? group;
  final int period;

  @override
  bool operator ==(Object other) {
    if (other is ChemicalElement) {
      return atomicNumber == other.atomicNumber;
    } else {
      return false;
    }
  }

  int get hashCode {
    return atomicNumber;
  }

  @override
  String toString() {
    return symbol;
  }
}

const List<String> _symbols = [
  "H",
  "He",
  "Li",
  "Be",
  "B",
  "C",
  "N",
  "O",
  "F",
  "Ne",
  "Na",
  "Mg",
  "Al",
  "Si",
  "P",
  "S",
  "Cl",
  "Ar",
  "K",
  "Ca",
  "Sc",
  "Ti",
  "V",
  "Cr",
  "Mn",
  "Fe",
  "Co",
  "Ni",
  "Cu",
  "Zn",
  "Ga",
  "Ge",
  "As",
  "Se",
  "Br",
  "Kr",
  "Rb",
  "Sr",
  "Y",
  "Zr",
  "Nb",
  "Mo",
  "Tc",
  "Ru",
  "Rh",
  "Pd",
  "Ag",
  "Cd",
  "In",
  "Sn",
  "Sb",
  "Te",
  "I",
  "Xe",
  "Cs",
  "Ba",
  "La",
  "Ce",
  "Pr",
  "Nd",
  "Pm",
  "Sm",
  "Eu",
  "Gd",
  "Tb",
  "Dy",
  "Ho",
  "Er",
  "Tm",
  "Yb",
  "Lu",
  "Hf",
  "Ta",
  "W",
  "Re",
  "Os",
  "Ir",
  "Pt",
  "Au",
  "Hg",
  "Tl",
  "Pb",
  "Bi",
  "Po",
  "At",
  "Rn",
  "Fr",
  "Ra",
  "Ac",
  "Th",
  "Pa",
  "U",
  "Np",
  "Pu",
  "Am",
  "Cm",
  "Bk",
  "Cf",
  "Es",
  "Fm",
  "Md",
  "No",
  "Lr",
  "Rf",
  "Db",
  "Sg",
  "Bh",
  "Hs",
  "Mt",
  "Ds",
  "Rg",
  "Cn",
  "Nh",
  "Fl",
  "Mc",
  "Lv",
  "Ts",
  "Og",
];

const List<String> _elementNames = [
  "hydrogen",
  "helium",
  "lithium",
  "beryllium",
  "boron",
  "carbon",
  "nitrogen",
  "oxygen",
  "fluorine",
  "neon",
  "sodium",
  "magnesium",
  "aluminium",
  "silicon",
  "phosphorus",
  "sulfur",
  "chlorine",
  "argon",
  "potassium",
  "calcium",
  "scandium",
  "titanium",
  "vanadium",
  "chromium",
  "manganese",
  "iron",
  "cobalt",
  "nickel",
  "copper",
  "zinc",
  "gallium",
  "germanium",
  "arsenic",
  "selenium",
  "bromine",
  "krypton",
  "rubidium",
  "strontium",
  "yttrium",
  "zirconium",
  "niobium",
  "molybdenum",
  "technetium",
  "ruthenium",
  "rhodium",
  "palladium",
  "silver",
  "cadmium",
  "indium",
  "tin",
  "antimony",
  "tellurium",
  "iodine",
  "xenon",
  "caesium",
  "barium",
  "lanthanum",
  "cerium",
  "praseodymium",
  "neodymium",
  "promethium",
  "samarium",
  "europium",
  "gadolinium",
  "terbium",
  "dysprosium",
  "holmium",
  "erbium",
  "thulium",
  "ytterbium",
  "lutetium",
  "hafnium",
  "tantalum",
  "tungsten",
  "rhenium",
  "osmium",
  "iridium",
  "platinum",
  "gold",
  "mercury",
  "thallium",
  "lead",
  "bismuth",
  "polonium",
  "astatine",
  "radon",
  "francium",
  "radium",
  "actinium",
  "thorium",
  "protactinium",
  "uranium",
  "neptunium",
  "plutonium",
  "americium",
  "curium",
  "berkelium",
  "californium",
  "einsteinium",
  "fermium",
  "mendelevium",
  "nobelium",
  "lawrencium",
  "ruthefordium",
  "dubnium",
  "seaborgium",
  "bohrium",
  "hassium",
  "meitnerium",
  "darmstadtium",
  "roentgenium",
  "copernicium",
  "nihonium",
  "flerovium",
  "moscovium",
  "livermorium",
  "tennessine",
  "oganesson",
];

const List<double?> _atomicMasses = [
  1.00794, //H
  4.002602, //He
  6.941, //Li
  9.012182, //Be
  10.811, //B
  12.0107, //C
  14.0067, //N
  15.9994, //O
  18.9984, //F
  20.1797, //Ne
  22.9898, //Na
  24.305, //Mg
  26.9815, //Al
  28.0855, //Si
  30.9738, //P
  32.065, //S
  35.453, //Cl
  39.948, //Ar
  39.0983, //K
  40.078, //Ca
  44.9559, //Sc
  47.867, //Ti
  50.9415, //V
  51.9961, //Cr
  54.938, //Mn
  55.845, //Fe
  58.9332, //Co
  58.6934, //Ni
  63.546, //Cu
  65.38, //Zn
  69.723, //Ga
  72.64, //Ge
  74.9216, //As
  78.96, //Se
  79.904, //Br
  83.798, //Kr
  85.4678, //Rb
  87.62, //Sr
  88.9059, //Y
  91.224, //Zr
  92.9064, //Nb
  95.96, //Mo
  98, //Tc
  101.07, //Ru
  102.906, //Rh
  106.42, //Pd
  107.868, //Ag
  112.411, //Cd
  114.818, //In
  118.71, //Sn
  121.76, //Sb
  127.6, //Te
  126.904, //I
  131.293, //Xe
  132.905, //Cs
  137.327, //Ba
  138.905, //La
  140.116, //Ce
  140.908, //Pr
  144.242, //Nd
  145, //Pm
  150.36, //Sm
  151.964, //Eu
  157.25, //Gd
  158.925, //Tb
  162.5, //Dy
  164.93, //Ho
  167.259, //Er
  168.934, //Tm
  173.054, //Yb
  174.967, //Lu
  178.49, //Hf
  180.948, //Ta
  183.84, //W
  186.207, //Re
  190.23, //Os
  192.217, //Ir
  195.084, //Pt
  196.967, //Au
  200.59, //Hg
  204.383, //Tl
  207.2, //Pb
  208.98, //Bi
  209, //Po
  210, //At
  222, //Rn
  223, //Fr
  226, //Ra
  227, //Ac
  232.038, //Th
  231.036, //Pa
  238.029, //U
  237, //Np
  244, //Pu
  243, //Am
  247, //Cm
  247, //Bk
  251, //Cf
  252, //Es
  257, //Fm
  258, //Md
  259, //No
  262, //Lr
  265, //Rf
  268, //Db
  271, //Sg
  272, //Bh
  270, //Hs
  276, //Mt
  281, //Ds
  280, //Rg
  285, //Cn
  284, //Nh
  289, //Fl
  288, //Mc
  293, //Lv
  null, //Ts
  294, //Og
];

const Map<int, double> _radioactivities = {
  43: 200,
  61: 200,
  84: 1000,
  85: 1500,
  86: 500,
  87: 1500,
  88: 500,
  89: 500,
  90: 50,
  91: 500,
  92: 50,
  93: 200,
  94: 200,
  95: 500,
  96: 700,
  97: 900,
  98: 900,
  99: 1200,
  100: 1500,
};

const List<Color?> _emissionColors = [
  Color(0xffff4ad5), //H
  Color(0xffffac27), //He
  Color(0xffff1385), //Li
  Color(0xfffff3fd), //Be
  Color(0xff14ff76), //B
  Color(0xffffa617), //C
  Color(0xffff85d8), //N
  Color(0xffffc1e1), //O
  Color(0xffb3252c), //F
  Color(0xffff2c07), //Ne
  Color(0xfffff700), //Na
  Color(0xfff2fbff), //Mg
  Color(0xff4949ff), //Al
  Color(0xffe5ffe8), //Si
  Color(0xffb9fff0), //P
  Color(0xffe5ffe8), //S
  Color(0xff6dff6b), //Cl
  Color(0xffff33cf), //Ar
  Color(0xffff9cd4), //K
  Color(0xffff5825), //Ca
  Color(0xffff8f1e), //Sc
  Color(0xfff4f7ff), //Ti
  Color(0xffc9ff4a), //V
  Color(0xfff4f7ff), //Cr
  Color(0xffedff4b), //Mn
  Color(0xff54ff8d), //Fe
  Color(0xfff4f7ff), //Co
  Color(0xfff4f7ff), //Ni
  Color(0xff35ff75), //Cu
  Color(0xff4fffca), //Zn
  Color(0xffff4545), //Ga
  Color(0xff9e97ff), //Ge
  Color(0xff678aff), //As
  Color(0xff3776ff), //Se
  Color(0xffff4545), //Br
  Color(0xffddfff2), //Kr
  Color(0xffe96cff), //Rb
  Color(0xffff0e3a), //Sr
  Color(0xffff23a7), //Y
  Color(0xffff5770), //Zr
  Color(0xff5effbc), //Nb
  Color(0xffbfff2a), //Mo
  Color(0xff42ff9a), //Tc
  Color(0xff17fff0), //Ru
  Color(0xff08ff77), //Rh
  Color(0xff1ee1ff), //Pd
  Color(0xff34ffdd), //Ag
  Color(0xffff3b21), //Cd
  Color(0xff850bff), //In
  Color(0xffc2c2ff), //Sn
  Color(0xffd6ffd4), //Sb
  Color(0xffd6ffd4), //Te
  Color(0xffebffd4), //I
  Color(0xffe4f8ff), //Xe
  Color(0xffbe62ff), //Cs
  Color(0xffa3ff8a), //Ba
  Color(0xff8cffb0), //La
  Color(0xffffff27), //Ce
  Color(0xffe1ffd3), //Pr
  Color(0xffabffdf), //Nd
  Color(0xfffff589), //Pm
  Color(0xff40a6ff), //Sm
  Color(0xffd2d2ff), //Eu
  Color(0xff8bff10), //Gd
  Color(0xffeadbff), //Tb
  Color(0xfff2eeff), //Dy
  Color(0xffffe4b8), //Ho
  Color(0xffffe561), //Er
  Color(0xffe2ffc2), //Tm
  Color(0xffa9ffe7), //Yb
  Color(0xffd4ffdb), //Lu
  Color(0xfff0fffc), //Hf
  Color(0xff7b8dff), //Ta
  Color(0xff61ff93), //W
  Color(0xff60ff47), //Re
  Color(0xffaeffed), //Os
  Color(0xff7cff73), //Ir
  Color(0xffe8ff97), //Pt
  Color(0xffdeffa1), //Au
  Color(0xffdeffa1), //Hg
  Color(0xff44ff00), //Tl
  Color(0xffbdc7ff), //Pb
  Color(0xffb5fbff), //Bi
  Color(0xff79ffbc), //Po
  null, //At
  Color(0xff79ff50), //Rn
  null, //Fr
  Color(0xffff31c8), //Ra
  Color(0xffff9a41), //Ac
  Color(0xff7bffe5), //Th
  Color(0xffff2c2c), //Pa
  Color(0xff2cff1d), //U
  Color(0xffe2ff4e), //Np
  Color(0xffd9fff4), //Pu
  Color(0xff26ff59), //Am
  Color(0xffffa74e), //Cm
  Color(0xff10ff54), //Bk
  Color(0xff27f4ff), //Cf
  Color(0xff1567ff), //Es
];

class AtomicOrbital {
  const AtomicOrbital({required this.name, required this.length, required this.startingPeriod});
  final String name;
  final int length;
  final int startingPeriod;
}

class FilledOrbital extends AtomicOrbital {
  FilledOrbital(
      {required String name, required int length, required int startingPeriod, required this.currentElectrons})
      : super(name: name, length: length, startingPeriod: startingPeriod);
  final int currentElectrons;

  static FilledOrbital sOrbital(int numElectrons) {
    return FilledOrbital(
        name: _sOrbital.name,
        length: _sOrbital.length,
        startingPeriod: _sOrbital.startingPeriod,
        currentElectrons: numElectrons);
  }

  static FilledOrbital pOrbital(int numElectrons) {
    return FilledOrbital(
        name: _pOrbital.name,
        length: _pOrbital.length,
        startingPeriod: _pOrbital.startingPeriod,
        currentElectrons: numElectrons);
  }

  static FilledOrbital dOrbital(int numElectrons) {
    return FilledOrbital(
        name: _dOrbital.name,
        length: _dOrbital.length,
        startingPeriod: _dOrbital.startingPeriod,
        currentElectrons: numElectrons);
  }

  static FilledOrbital fOrbital(int numElectrons) {
    return FilledOrbital(
        name: _fOrbital.name,
        length: _fOrbital.length,
        startingPeriod: _fOrbital.startingPeriod,
        currentElectrons: numElectrons);
  }
}

const _sOrbital = AtomicOrbital(name: "s", length: 2, startingPeriod: 1);
const _pOrbital = AtomicOrbital(name: "p", length: 6, startingPeriod: 2);
const _dOrbital = AtomicOrbital(name: "d", length: 10, startingPeriod: 4);
const _fOrbital = AtomicOrbital(name: "f", length: 14, startingPeriod: 6);

const List<AtomicOrbital> _orbitals = [_sOrbital, _fOrbital, _dOrbital, _pOrbital];

class _TablePosition {
  _TablePosition({required this.block, required this.group, required this.period, required this.electronConfiguration});
  final String block;
  final int? group;
  final int period;
  final ElectronConfiguration electronConfiguration;
}

class ElectronConfiguration {
  ElectronConfiguration(
      {required this.orbitals, required this.period, required this.atomicNumber, required this.isDisplayOrder});
  static ElectronConfiguration hydrogen() {
    return ElectronConfiguration(
      orbitals: [FilledOrbital.sOrbital(1)],
      period: 1,
      atomicNumber: 1,
      isDisplayOrder: false,
    );
  }

  final int atomicNumber;
  final List<FilledOrbital> orbitals;
  final int period;
  final bool isDisplayOrder;

  /// Note: does not correctly compute exceptions to the rule, such as Cu, Mo, Ag, ...
  /// The exceptions are irrelevant for the element's position in the periodic table
  ElectronConfiguration next() {
    FilledOrbital lastOrbital = orbitals.last;
    if (lastOrbital.currentElectrons < lastOrbital.length) {
      FilledOrbital newLastOrbital = FilledOrbital(
          name: lastOrbital.name,
          length: lastOrbital.length,
          startingPeriod: lastOrbital.startingPeriod,
          currentElectrons: lastOrbital.currentElectrons + 1);
      List<FilledOrbital> newOrbitals = List.from(orbitals);
      newOrbitals[newOrbitals.length - 1] = newLastOrbital;
      return ElectronConfiguration(
          orbitals: newOrbitals, period: period, atomicNumber: atomicNumber + 1, isDisplayOrder: false);
    } else {
      int i = _orbitals.indexWhere((orbital) => orbital.name == lastOrbital.name);
      assert(i >= 0);
      i += 1;
      AtomicOrbital? nextOrbitalInPeriod;
      while (i < _orbitals.length) {
        AtomicOrbital orbital = _orbitals[i];
        if (orbital.startingPeriod <= period) {
          nextOrbitalInPeriod = orbital;
          break;
        }
        i++;
      }
      FilledOrbital newOrbital;
      int newPeriod;
      if (nextOrbitalInPeriod != null) {
        newOrbital = FilledOrbital(
            name: nextOrbitalInPeriod.name,
            length: nextOrbitalInPeriod.length,
            startingPeriod: nextOrbitalInPeriod.startingPeriod,
            currentElectrons: 1);
        newPeriod = period;
      } else {
        newPeriod = period + 1;
        newOrbital = FilledOrbital(name: "s", length: 2, startingPeriod: 1, currentElectrons: 1);
      }
      List<FilledOrbital> newOrbitals = List.from(orbitals);
      newOrbitals.add(newOrbital);
      return ElectronConfiguration(
          orbitals: newOrbitals, period: newPeriod, atomicNumber: atomicNumber + 1, isDisplayOrder: false);
    }
  }

  ChemicalElement? getNobleGasCore(List<ChemicalElement> allElements) {
    List<int> nobleGases = [2, 10, 18, 36, 54, 86, 118];
    int coreAtomicNumber = nobleGases.lastWhere((x) => x < atomicNumber, orElse: () => -1);
    if (coreAtomicNumber == -1) {
      return null;
    }
    return allElements[coreAtomicNumber - 1];
  }

  ElectronConfiguration realConfiguration() {
    List<int> exceptions = [24, 29, 41, 42, 44, 45, 46, 47, 57, 58, 64, 78, 79, 89, 90, 91, 92, 93, 96, 103];
    if (!exceptions.contains(atomicNumber)) {
      return this;
    } else {
      List<FilledOrbital> newOrbitals = List.from(_orbitalDisplayOrder);
      if (atomicNumber == 24) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(5);
      } else if (atomicNumber == 29) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(10);
      } else if (atomicNumber == 41) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(4);
      } else if (atomicNumber == 42) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(5);
      } else if (atomicNumber == 44) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(7);
      } else if (atomicNumber == 45) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(8);
      } else if (atomicNumber == 46) {
        newOrbitals.removeAt(newOrbitals.length - 1);
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.dOrbital(10);
      } else if (atomicNumber == 47) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(10);
      } else if (atomicNumber == 57) {
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(1);
      } else if (atomicNumber == 58) {
        newOrbitals.removeLast();
        newOrbitals.removeLast();
        newOrbitals.add(FilledOrbital.fOrbital(1));
        newOrbitals.add(FilledOrbital.dOrbital(1));
        newOrbitals.add(FilledOrbital.sOrbital(2));
      } else if (atomicNumber == 64) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.dOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.fOrbital(7);
        newOrbitals.add(FilledOrbital.sOrbital(2));
      } else if (atomicNumber == 78) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(9);
      } else if (atomicNumber == 79) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.sOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(10);
      } else if (atomicNumber == 89) {
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(1);
      } else if (atomicNumber == 90) {
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.dOrbital(2);
      } else if (atomicNumber == 91) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.dOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.fOrbital(2);
        newOrbitals.add(FilledOrbital.sOrbital(2));
      } else if (atomicNumber == 92) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.dOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.fOrbital(3);
        newOrbitals.add(FilledOrbital.sOrbital(2));
      } else if (atomicNumber == 93) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.dOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.fOrbital(4);
        newOrbitals.add(FilledOrbital.sOrbital(2));
      } else if (atomicNumber == 96) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.dOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.fOrbital(7);
        newOrbitals.add(FilledOrbital.sOrbital(2));
      } else if (atomicNumber == 103) {
        newOrbitals[newOrbitals.length - 1] = FilledOrbital.pOrbital(1);
        newOrbitals[newOrbitals.length - 2] = FilledOrbital.sOrbital(2);
      } else {
        throw AssertionError();
      }
      return ElectronConfiguration(
          orbitals: newOrbitals, period: period, atomicNumber: atomicNumber, isDisplayOrder: true);
    }
  }

  List<FilledOrbital> get _orbitalDisplayOrder {
    List<FilledOrbital> displayOrder = List.from(orbitals);
    int i = 0;
    while (i < displayOrder.length) {
      FilledOrbital currentOrbital = displayOrder[i];
      FilledOrbital? nextOrbital;
      if (displayOrder.length > i + 1) {
        nextOrbital = displayOrder[i + 1];
      }
      if (nextOrbital != null) {
        if (currentOrbital.name == "s" && (nextOrbital.name == "d" || nextOrbital.name == "f")) {
          int insertIndex = i + 1;
          while (displayOrder.length > insertIndex + 1 &&
              (displayOrder[insertIndex + 1].name == "d" || displayOrder[insertIndex + 1].name == "f")) {
            insertIndex++;
          }
          displayOrder.insert(insertIndex + 1, currentOrbital);
          displayOrder.removeAt(i);
        }
      }
      i++;
    }
    return displayOrder;
  }

  String _toSuperscript(String s) {
    Map<String, String> superscriptNumbers = {
      "0": "⁰",
      "1": "¹",
      "2": "²",
      "3": "³",
      "4": "⁴",
      "5": "⁵",
      "6": "⁶",
      "7": "⁷",
      "8": "⁸",
      "9": "⁹",
    };
    for (String normal in superscriptNumbers.keys) {
      s = s.replaceAll(normal, superscriptNumbers[normal]!);
    }
    return s;
  }

  @override
  String toString() {
    String ec = "";
    int sOrbitalsEncountered = 0;
    int pOrbitalsEncountered = 0;
    int dOrbitalsEncountered = 0;
    int fOrbitalsEncountered = 0;
    List<FilledOrbital> stringOrbitals;
    if (isDisplayOrder) {
      stringOrbitals = orbitals;
    } else {
      stringOrbitals = _orbitalDisplayOrder;
    }
    for (var orbital in stringOrbitals) {
      var orbitalType = orbital.name;
      int layer;
      if (orbitalType == "s") {
        layer = _sOrbital.startingPeriod + sOrbitalsEncountered;
        sOrbitalsEncountered++;
      } else if (orbitalType == "p") {
        layer = _pOrbital.startingPeriod + pOrbitalsEncountered;
        pOrbitalsEncountered++;
      } else if (orbitalType == "d") {
        layer = _dOrbital.startingPeriod + dOrbitalsEncountered - 1;
        dOrbitalsEncountered++;
      } else {
        layer = _fOrbital.startingPeriod + fOrbitalsEncountered - 2;
        fOrbitalsEncountered++;
      }
      ec += layer.toString() + orbitalType + orbital.currentElectrons.toString() + " ";
    }
    return ec;
  }
}

class ChemicalElements {
  static List<_TablePosition> _getGroupsAndPeriods({int maxAtomicNumber = 118}) {
    List<_TablePosition> positions = [];
    int atomicNumber = 1;
    ElectronConfiguration currentElectronConfiguration = ElectronConfiguration.hydrogen();
    while (atomicNumber <= maxAtomicNumber) {
      FilledOrbital lastOrbital = currentElectronConfiguration.orbitals.last;
      String block = lastOrbital.name;
      int period = currentElectronConfiguration.period;
      int? group;
      if (block != "f") {
        if (atomicNumber == 2) {
          // Helium is special...
          group = 18;
        } else {
          switch (lastOrbital.name) {
            case "s":
              {
                group = lastOrbital.currentElectrons;
              }
              break;
            case "d":
              {
                group = 2 + lastOrbital.currentElectrons;
              }
              break;
            case "p":
              {
                group = 12 + lastOrbital.currentElectrons;
              }
              break;
            default:
              {
                assert(false, "orbital not valid");
              }
              break;
          }
        }
      }
      positions.add(_TablePosition(
          block: block, group: group, period: period, electronConfiguration: currentElectronConfiguration));
      currentElectronConfiguration = currentElectronConfiguration.next();
      atomicNumber++;
    }
    return positions;
  }

  static List<ChemicalElement> getElements() {
    List<_TablePosition> tablePositions = _getGroupsAndPeriods();
    List<ChemicalElement> elements = [];
    int i = 0;
    while (i < _symbols.length) {
      int atomicNumber = i + 1;
      String symbol = _symbols[i];
      String fullName = _elementNames[i];
      double? atomicMass = _atomicMasses[i];
      bool isArtificial = false;
      if (atomicNumber == 43 || //Tc
          atomicNumber == 61 || //Pm
          (atomicNumber >= 84 && atomicNumber <= 89) || //Po-Ac
          atomicNumber >= 93) {
        isArtificial = true;
      }
      double radioactivity = 0;
      if (atomicNumber > 100) {
        radioactivity = 2000;
      }
      if (_radioactivities.containsKey(atomicNumber)) {
        radioactivity = _radioactivities[atomicNumber]!;
      }
      Color emissionColor = const Color(0xfff4f4f4);
      if (i < _emissionColors.length) {
        if (_emissionColors[i] != null) {
          emissionColor = _emissionColors[i]!;
        }
      }
      _TablePosition tablePosition = tablePositions[i];
      elements.add(ChemicalElement(
        atomicNumber: atomicNumber,
        symbol: symbol,
        fullName: fullName,
        atomicMass: atomicMass,
        emissionColor: emissionColor,
        block: tablePosition.block,
        group: tablePosition.group,
        period: tablePosition.period,
        isArtificial: isArtificial,
        radioactivity: radioactivity,
        electronConfiguration: tablePosition.electronConfiguration,
      ));
      i++;
    }
    return elements;
  }
}
