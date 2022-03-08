import 'package:flutter/foundation.dart';

import 'FullscreenManager.dart';

FullscreenManager getManager() => StandardFullscreenManager();

class StandardFullscreenManager implements FullscreenManager {
  @override
  bool get isAvailable => false;

  @override
  ValueNotifier<bool> get isFullscreen => throw UnimplementedError();
}
