import 'package:flutter/services.dart';

abstract class IMAdMethodChannelCallback {
  void onIMAdAdLoaded(String zoneId);
  void onIMAdAdLoadFailed(String zoneId, String errorDescription);
  void onIMAdAdClicked(String zoneId);
  void onIMAdAdExpanded(String zoneId);
  void onIMAdAdCloseExpanded(String zoneId);
  void onIMAdAdUnloaded(String zoneId);
  void onIMAdViewSizeChanged(num width, num height);
}

class IMAdMethodChannel {
  final MethodChannel _channel;
  final IMAdMethodChannelCallback _callback;

  IMAdMethodChannel(int id, this._callback)
      : _channel = MethodChannel("com.appsploration.imadsdk/flutter_$id") {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  Future<bool?> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "updateSize":
        final num width = call.arguments['width'];
        final num height = call.arguments['height'];
        _callback.onIMAdViewSizeChanged(width, height);
        return null;
      case "adReady":
        final String zoneId = call.arguments['zoneId'];
        _callback.onIMAdAdLoaded(zoneId);
        return null;
      case "adFailed":
        final String zoneId = call.arguments['zoneId'];
        final String errorDescription = call.arguments['description'];
        _callback.onIMAdAdLoadFailed(zoneId, errorDescription);
        return null;
      case "adExpanded":
        final String zoneId = call.arguments['zoneId'];
        _callback.onIMAdAdExpanded(zoneId);
        return null;
      case "adCloseExpanded":
        final String zoneId = call.arguments['zoneId'];
        _callback.onIMAdAdCloseExpanded(zoneId);
        return null;
      case "adUnloaded":
        final String zoneId = call.arguments['zoneId'];
        _callback.onIMAdAdUnloaded(zoneId);
        return null;
      case "adClicked":
        final String zoneId = call.arguments['zoneId'];
        _callback.onIMAdAdClicked(zoneId);
        return null;
    }

    return null;
  }
}
