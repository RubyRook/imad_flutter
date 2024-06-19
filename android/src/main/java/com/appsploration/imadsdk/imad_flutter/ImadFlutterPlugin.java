package com.appsploration.imadsdk.imad_flutter;

import android.app.Activity;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;

/** ImadFlutterPlugin */
public class ImadFlutterPlugin implements FlutterPlugin, ActivityAware {
  public Activity activity;

  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "com.appsploration.imadsdk/flutter",
                    new IMAdSDKFlutterViewFactory(registrar.messenger(), registrar.view(), null));

  }

  //@Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    BinaryMessenger messenger = binding.getBinaryMessenger();
    binding
            .getPlatformViewRegistry()
            .registerViewFactory(
                    "com.appsploration.imadsdk/flutter", new IMAdSDKFlutterViewFactory(messenger, /*containerView=*/ null, this));
  }

  //@Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }

  //@Override
  public void onDetachedFromActivity() {
    this.activity = null;
  }


  //@Override
  public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
    this.activity = activityPluginBinding.getActivity();

  }

  //@Override
  public void onDetachedFromActivityForConfigChanges() {
    this.activity = null;
  }

  //@Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
    this.activity = activityPluginBinding.getActivity();
  }

}
