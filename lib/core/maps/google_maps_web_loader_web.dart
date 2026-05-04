import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Future<bool> ensureGoogleMapsJsLoaded() async {
  if (isGoogleMapsJsReady) {
    return true;
  }

  final JSAny? loader = web.window.getProperty('hextLoadGoogleMaps'.toJS);
  if (loader == null || loader.isUndefinedOrNull) {
    return isGoogleMapsJsReady;
  }

  try {
    web.window.callMethod('hextLoadGoogleMaps'.toJS);
    for (int attempt = 0; attempt < 80; attempt += 1) {
      if (isGoogleMapsJsReady) {
        return true;
      }
      if (googleMapsJsLoadError != null) {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return isGoogleMapsJsReady;
  } catch (_) {
    return false;
  }
}

bool get isGoogleMapsJsReady {
  final JSAny? readyFn = web.window.getProperty('hextIsGoogleMapsFullyReady'.toJS);
  if (readyFn != null && !readyFn.isUndefinedOrNull) {
    final JSAny? result = web.window.callMethod('hextIsGoogleMapsFullyReady'.toJS);
    if (result != null && !result.isUndefinedOrNull) {
      return result.dartify() == true;
    }
  }

  final JSAny? google = web.window.getProperty('google'.toJS);
  if (google != null && !google.isUndefinedOrNull) {
    final JSAny? maps = (google as JSObject).getProperty('maps'.toJS);
    if (maps != null && !maps.isUndefinedOrNull) {
      final JSObject mapsObject = maps as JSObject;
      if (!mapsObject.hasProperty('Map'.toJS).toDart) {
        return false;
      }
      if (!mapsObject.hasProperty('MapTypeId'.toJS).toDart) {
        return false;
      }
      final JSAny? mapTypeId = mapsObject.getProperty('MapTypeId'.toJS);
      if (mapTypeId == null || mapTypeId.isUndefinedOrNull) {
        return false;
      }
      return (mapTypeId as JSObject).hasProperty('ROADMAP'.toJS).toDart;
    }
  }

  final JSAny? state = web.window.getProperty('__hextGoogleMapsState'.toJS);
  if (state != null && !state.isUndefinedOrNull) {
    return (state as JSObject).getProperty('loaded'.toJS).dartify() == true;
  }

  return false;
}

String? get googleMapsJsLoadError {
  final JSAny? state = web.window.getProperty('__hextGoogleMapsState'.toJS);
  if (state == null || state.isUndefinedOrNull) {
    return null;
  }
  final Object? error = (state as JSObject)
      .getProperty('error'.toJS)
      .dartify();
  return error?.toString();
}