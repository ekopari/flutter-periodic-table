//import "FullscreenStub.dart";
import 'package:flutter/material.dart';

import "FullscreenStub.dart" if (dart.library.js) "FullscreenWeb.dart" if (dart.library.io) "FullscreenStandard.dart";

abstract class FullscreenManager {
  bool get isAvailable;
  ValueNotifier<bool> get isFullscreen;
}

FullscreenManager getFullscreenManager() {
  return getManager();
}
