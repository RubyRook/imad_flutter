package com.appsploration.imadsdk.imad_flutter;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class IMAdSDKFlutterViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;
    private final View containerView;
    private final ImadFlutterPlugin plugin;

    IMAdSDKFlutterViewFactory(BinaryMessenger messenger, View containerView, ImadFlutterPlugin plugin) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.containerView = containerView;
        this.plugin = plugin;
    }

    @NonNull
    @SuppressWarnings("unchecked")
    //@Override
    public PlatformView create(Context context, int id, Object args) {
        Map<String, Object> params = (Map<String, Object>) args;
        return new IMAdSDKFlutterContainerView(context, messenger, id, params, containerView, this.plugin);
    }
}