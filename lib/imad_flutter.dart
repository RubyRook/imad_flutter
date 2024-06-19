import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:imad_flutter/imad_method_channel.dart';

typedef IMAdAdLoaded = void Function(String zoneId);
typedef IMAdAdLoadFailed = void Function(String zoneId, String errorDescription);
typedef IMAdAdClicked = void Function(String zoneId);
typedef IMAdAdExpanded = void Function(String zoneId);
typedef IMAdAdCloseExpanded = void Function(String zoneId);
typedef IMAdAdUnloaded = void Function(String zoneId);

enum ClickTagMode {
  inApp,
  externalBrowser,
}

class IMAdView extends StatefulWidget {
  final String publisherId;
  final String zoneId;
  final String? premiumZoneId;
  final IMAdAdLoaded? adLoaded;
  final IMAdAdLoadFailed? adLoadFailed;
  final IMAdAdClicked? adClicked;
  final IMAdAdExpanded? adExpanded;
  final IMAdAdCloseExpanded? adCloseExpanded;
  final IMAdAdUnloaded? adUnloaded;
  final Rect? availableRect;
  final ClickTagMode clickTagMode;
  /// if true: hold on ads, vertical scroll not work
  final bool eagerGestureRecognizer;

  const IMAdView({
    Key? key,
    required this.publisherId,
    required this.zoneId,
    this.premiumZoneId,
    this.adLoaded,
    this.adLoadFailed,
    this.adClicked,
    this.adExpanded,
    this.adCloseExpanded,
    this.adUnloaded,
    this.availableRect,
    this.clickTagMode = ClickTagMode.inApp,
    this.eagerGestureRecognizer = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IMAdViewState();
  }
}

class _IMAdViewState extends State<IMAdView> {
  final Completer<IMAdMethodChannel> _methodChannel =
      Completer<IMAdMethodChannel>();
  late _IMAdMethodCallbackWrapper _callbackWrapper;
  Size _containerSize = const Size(1, 1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _containerSize.width,
      height: _containerSize.height,
      child: defaultTargetPlatform == TargetPlatform.android
          ? PlatformViewLink(
              viewType: 'com.appsploration.imadsdk/flutter',
              surfaceFactory: (
                BuildContext context,
                PlatformViewController controller,
              ) {
                if (Platform.isAndroid) {
                  return AndroidViewSurface(
                    controller: controller as AndroidViewController,
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      if(widget.eagerGestureRecognizer) Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer(),),
                    },
                  );
                } else {
                  return PlatformViewSurface(
                    controller: controller,
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    gestureRecognizers: const <Factory<
                        OneSequenceGestureRecognizer>>{},
                  );
                }
              },
              onCreatePlatformView: (PlatformViewCreationParams params) {
                return PlatformViewsService.initSurfaceAndroidView(
                  id: params.id,
                  viewType: 'com.appsploration.imadsdk/flutter',
                  layoutDirection: TextDirection.rtl,
                  creationParams: getParams(),
                  creationParamsCodec: const StandardMessageCodec(),
                )
                  ..addOnPlatformViewCreatedListener(
                      params.onPlatformViewCreated)
                  ..addOnPlatformViewCreatedListener((int id) {
                    _callbackWrapper =
                        _IMAdMethodCallbackWrapper(widget, (Size size) {
                      setState(() {
                        _containerSize = size;
                      });
                    });
                    IMAdMethodChannel adMethodChannel =
                        IMAdMethodChannel(id, _callbackWrapper);
                    _methodChannel.complete(adMethodChannel);
                  })
                  ..create();
              },
            )
          : UiKitView(
              viewType: "com.appsploration.imadsdk/flutter",
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                if(widget.eagerGestureRecognizer) Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer(),),
              },
              layoutDirection: TextDirection.rtl,
              creationParams: getParams(),
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: (int id) {
                _callbackWrapper =
                    _IMAdMethodCallbackWrapper(widget, (Size size) {
                  setState(() {
                    _containerSize = size;
                  });
                });
                IMAdMethodChannel adMethodChannel =
                    IMAdMethodChannel(id, _callbackWrapper);
                _methodChannel.complete(adMethodChannel);
              },
            ),
    );
  }

  dynamic getParams() {
    Map<String, dynamic> params = {
      "zoneId": widget.zoneId,
      "publisherId": widget.publisherId,
      "clickTagMode": widget.clickTagMode.toString(),
    };
    if (widget.availableRect != null) {
      params['availableRect'] = {
        'top': widget.availableRect?.top,
        'bottom': widget.availableRect?.bottom,
        'left': widget.availableRect?.left,
        'right': widget.availableRect?.right,
      };
    }

    if (widget.premiumZoneId != null) {
      params['premiumZoneId'] = widget.premiumZoneId;
    }

    return params;
  }
}

class _IMAdMethodCallbackWrapper extends IMAdMethodChannelCallback {
  final IMAdView _widget;
  final Function(Size) _onSizeChange;

  _IMAdMethodCallbackWrapper(this._widget, this._onSizeChange);

  @override
  void onIMAdAdClicked(String zoneId) {
    if (_widget.adClicked != null) {
      _widget.adClicked!(zoneId);
    }
  }

  @override
  void onIMAdAdCloseExpanded(String zoneId) {
    if (_widget.adCloseExpanded != null) {
      _widget.adCloseExpanded!(zoneId);
    }
  }

  @override
  void onIMAdAdExpanded(String zoneId) {
    if (_widget.adExpanded != null) {
      _widget.adExpanded!(zoneId);
    }
  }

  @override
  void onIMAdAdLoadFailed(String zoneId, String errorDescription) {
    if (_widget.adLoadFailed != null) {
      _widget.adLoadFailed!(zoneId, errorDescription);
    }
  }

  @override
  void onIMAdAdLoaded(String zoneId) {
    if (_widget.adLoaded != null) {
      _widget.adLoaded!(zoneId);
    }
  }

  @override
  void onIMAdAdUnloaded(String zoneId) {
    if (_widget.adUnloaded != null) {
      _widget.adUnloaded!(zoneId);
    }
    onIMAdViewSizeChanged(0, 0);
  }

  @override
  void onIMAdViewSizeChanged(num width, num height) {
    // TODO: implement onIMAdViewSizeChanged

    _onSizeChange(Size(width.toDouble(), height.toDouble()));
    }
}
