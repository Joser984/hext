import 'google_maps_web_loader_stub.dart'
    if (dart.library.html) 'google_maps_web_loader_web.dart' as impl;

Future<bool> ensureGoogleMapsJsLoaded() => impl.ensureGoogleMapsJsLoaded();

bool get isGoogleMapsJsReady => impl.isGoogleMapsJsReady;

String? get googleMapsJsLoadError => impl.googleMapsJsLoadError;