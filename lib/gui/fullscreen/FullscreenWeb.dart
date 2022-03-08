import 'package:flutter/material.dart';
import 'package:js/js.dart';

import 'FullscreenManager.dart';

WebFullscreenManager _manager = WebFullscreenManager();
bool _setCallback = false;
FullscreenManager getManager() {
  if (!_setCallback) {
    _setCallback = true;
    _notify_flutter_fullscreen = allowInterop((isFullscreen) {
      _manager.fullscreenNotifier.value = isFullscreen;
    });
  }
  return _manager;
}

@JS("window.setFullscreenValue")
external void setFullscreenValue(bool fullscreenValue);

@JS("window.getFullscreenValue")
external bool getFullscreenValue();

@JS("notify_flutter_fullscreen")
external set _notify_flutter_fullscreen(void function(bool));

class WebFullscreenManager implements FullscreenManager {
  final ValueNotifier<bool> fullscreenNotifier;

  WebFullscreenManager() : fullscreenNotifier = ValueNotifier(false) {
    fullscreenNotifier.value = getFullscreenValue();
    fullscreenNotifier.addListener(() {
      setFullscreenValue(fullscreenNotifier.value);
    });
  }

  @override
  bool get isAvailable => true;

  @override
  ValueNotifier<bool> get isFullscreen => fullscreenNotifier;
}
