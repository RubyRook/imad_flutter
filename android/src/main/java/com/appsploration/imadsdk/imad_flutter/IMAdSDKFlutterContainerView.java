package com.appsploration.imadsdk.imad_flutter;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.Resources;
import android.graphics.RectF;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.webkit.WebView;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.appsploration.imadsdk.core.ad.AdUnit;
import com.appsploration.imadsdk.core.sdk.IMAdSdk;
import com.appsploration.imadsdk.core.sdk.IMAdSdkBuilder;
import com.appsploration.imadsdk.core.sdk.SdkConfiguration;
import com.appsploration.imadsdk.core.task.AdExecutor;
import com.appsploration.imadsdk.engage.EngageAdConfiguration;
import com.appsploration.imadsdk.engage.IMAdEngage;
import com.appsploration.imadsdk.engage.ad.EngageAd;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class IMAdSDKFlutterContainerView implements PlatformView, MethodChannel.MethodCallHandler, AdExecutor.AdLoadCallback, IMAdEngage.AdEventCallback {
    private final FrameLayout imadView;
    private final MethodChannel methodChannel;
    private boolean loaded = false;
    private EngageAd engageAd;
    private final Map<String, Object> params;
    private AdViewSizeObserver sizeObserver;

    IMAdSDKFlutterContainerView(
            final Context context,
            BinaryMessenger messenger,
            int id,
            Map<String, Object> params,
            View containerView,
            ImadFlutterPlugin plugin) {

        imadView = new FrameLayout(context);
        imadView.setForegroundGravity(Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        methodChannel = new MethodChannel(messenger, "com.appsploration.imadsdk/flutter_" + id);
        this.params = params;
        EngageAdConfiguration config = null;

        if (params.containsKey("availableRect")) {
            RectF r = getAvailableRect((Map<String, Object>) params.get("availableRect"));
            config = new EngageAdConfiguration.Builder().setAvailableArea(r).build();
        }

        String premiumZoneId = null;
        if (params.containsKey("premiumZoneId")) {
            premiumZoneId = (String) params.get("premiumZoneId");
        }

        loadAd(context, (String) params.get("publisherId"), (String) params.get("zoneId"), premiumZoneId, config);
    }

    private RectF getAvailableRect(@NonNull Map<String, Object> rectParam) {
        double top = (double) rectParam.get("top");
        double right = (double) rectParam.get("right");
        double left = (double) rectParam.get("left");
        double bottom = (double) rectParam.get("bottom");

        RectF r = new RectF();
        Resources resources = imadView.getContext().getResources();
        r.top = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, (float) top, resources.getDisplayMetrics());
        r.right = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, (float) right, resources.getDisplayMetrics());
        r.left = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, (float) left, resources.getDisplayMetrics());
        r.bottom = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, (float) bottom, resources.getDisplayMetrics());

        return r;
    }

    //@Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {

    }

    public static Activity getActivity(Context context) {
        while (context instanceof ContextWrapper) {
            if (context instanceof Activity) {
                return (Activity) context;
            }
            context = ((ContextWrapper) context).getBaseContext();
        }
        return null;
    }

    private void loadAd(Context context, String publisherId, String zoneId, String premiumZoneId, EngageAdConfiguration config) {
        if (loaded)
            return;
        loaded = true;
        SdkConfiguration.Builder sdkConfigurationBuilder = new SdkConfiguration.Builder();

        if ("ClickTagMode.externalBrowser".equals(params.get("clickTagMode"))) {
            sdkConfigurationBuilder.setClickTagMode(SdkConfiguration.CLICK_TAG_MODE_EXTERNAL_BROWSER);
        }

        IMAdSdk sdk = new IMAdSdkBuilder(context, sdkConfigurationBuilder.build()).build();
        IMAdEngage engage = IMAdEngage.with(sdk, publisherId);
        engage.setPremiumZone(premiumZoneId);
        Activity activity = getActivity(context);
        engage.load(activity, zoneId, null, this, this, config);
    }

    //@Override
    public View getView() {
        return imadView;
    }

    //@Override
    public void onFlutterViewAttached(@NonNull View flutterView) {
        EngageAdConfiguration config = null;

        if (params.containsKey("availableRect")) {
            RectF r = getAvailableRect((Map<String, Object>) params.get("availableRect"));
            config = new EngageAdConfiguration.Builder().setAvailableArea(r).build();
        }

        String premiumZoneId = null;
        if (params.containsKey("premiumZoneId")) {
            premiumZoneId = (String) params.get("premiumZoneId");
        }

        loadAd(flutterView.getContext(), (String) params.get("publisherId"), (String) params.get("zoneId"), premiumZoneId, config);
    }

    //@Override
    public void onFlutterViewDetached() {

    }

    //@Override
    public void dispose() {
        sizeObserver = null;
        engageAd.destroy();
        engageAd = null;
    }

    //@Override
    public void onInputConnectionLocked() {

    }

    //@Override
    public void onInputConnectionUnlocked() {

    }

    //@Override
    public void adReady(AdUnit adUnit) {

        engageAd = (EngageAd) adUnit;
        WebView webView = getViewsByType(engageAd.getView(), WebView.class).get(0);
        sizeObserver = new AdViewSizeObserver(webView, methodChannel);
        webView.getViewTreeObserver().addOnGlobalLayoutListener(sizeObserver);
        
        FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        layoutParams.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
        engageAd.getView().setForegroundGravity(Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        imadView.addView(engageAd.getView(), layoutParams);
        engageAd.show();

        Map<String, Object> args = new HashMap<>();
        args.put("zoneId", engageAd.getZoneId());
        sendMethodChannelMessage(methodChannel, "adReady", args);
    }

    //@Override
    public void adFailed(String s, Exception e) {
        Map<String, Object> args = new HashMap<>();
        args.put("zoneId", params.get("zoneId"));
        args.put("description", e.getMessage());

        sendMethodChannelMessage(methodChannel, "adFailed", args);
    }

    //@Override
    public void adDidBeginPreview(EngageAd engageAd) {

    }

    //@Override
    public void adDidEndPreview(EngageAd engageAd) {

    }

    //@Override
    public void adDidExpand(EngageAd engageAd) {
        Map<String, Object> args = new HashMap<>();
        args.put("zoneId", engageAd.getZoneId());
        sendMethodChannelMessage(methodChannel, "adExpanded", args);
    }

    //@Override
    public void adDidCancelExpand(EngageAd engageAd) {

    }

    //@Override
    public void adDidCloseExpanded(EngageAd engageAd) {
        Map<String, Object> args = new HashMap<>();
        args.put("zoneId", engageAd.getZoneId());
        sendMethodChannelMessage(methodChannel, "adCloseExpanded", args);
    }

    //@Override
    public void adActionWillBegin(EngageAd engageAd) {

    }

    //@Override
    public void adActionDidEnd(EngageAd engageAd) {

    }

    //@Override
    public void adActionWillLeaveApplication(EngageAd engageAd) {

    }

    //@Override
    public void adDidUnload(EngageAd engageAd) {
        imadView.removeAllViews();
        Map<String, Object> args = new HashMap<>();
        args.put("zoneId", engageAd.getZoneId());
        sendMethodChannelMessage(methodChannel, "adUnloaded", args);
    }

    //@Override
    public void adWasClicked(EngageAd engageAd) {
        Map<String, Object> args = new HashMap<>();

        args.put("zoneId", engageAd.getZoneId());
        sendMethodChannelMessage(methodChannel, "adClicked", args);
    }


    private static <T extends View> ArrayList<T> getViewsByType(ViewGroup root, Class<T> tClass) {
        final ArrayList<T> result = new ArrayList<>();
        int childCount = root.getChildCount();

        for (int i = 0; i < childCount; i++)
        {
            final View child = root.getChildAt(i);

            if (child instanceof ViewGroup)
                result.addAll(getViewsByType((ViewGroup) child, tClass));

            if (tClass.isInstance(child))
                result.add(tClass.cast(child));
        }

        return result;
    }

    private static void sendMethodChannelMessage(final MethodChannel methodChannel, final String method, final Map<String, Object> args) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                methodChannel.invokeMethod(method, args);
            }
        });
    }

    private static class AdViewSizeObserver implements ViewTreeObserver.OnGlobalLayoutListener {
        private double previousWidth = 1;
        private double previousHeight = 1;
        private final WebView webView;
        private final MethodChannel methodChannel;

        public AdViewSizeObserver(WebView webView, MethodChannel methodChannel) {
            this.webView = webView;
            this.methodChannel = methodChannel;
        }

        @Override
        public void onGlobalLayout() {
            View adView = webView;
            if (adView.getMeasuredHeight() < 1 || adView.getMeasuredWidth() < 1) {
                return;
            }
            double width = adView.getMeasuredWidth();
            double height = adView.getMeasuredHeight();
            if (width != previousWidth || height != previousHeight) {

                float widthInDp = 0;
                float heightInDp = 0;
                widthInDp = (float) width / (adView.getContext().getResources().getDisplayMetrics().densityDpi / 160f);
                heightInDp = (float) height / (adView.getContext().getResources().getDisplayMetrics().densityDpi / 160f);

                Map<String, Object> args = new HashMap<>();
                args.put("width", widthInDp);
                args.put("height", heightInDp);
                sendMethodChannelMessage(methodChannel, "updateSize", args);

            }

            previousHeight = height;
            previousWidth = width;
        }
    }
}
