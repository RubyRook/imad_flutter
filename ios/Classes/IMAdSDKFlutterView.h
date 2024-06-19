#import <Flutter/Flutter.h>
#import <IMAd/IMAd-Swift.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMAdSDKFlutterContainerController : NSObject <FlutterPlatformView, AdLoadCallback, AdEventCallback>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

- (UIView*)view;
@end

@interface IMAdSDKFlutterViewFactory : NSObject <FlutterPlatformViewFactory>
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end

/**
 * The WkWebView used for the plugin.
 *
 * This class overrides some methods in `WKWebView` to serve the needs for the plugin.
 */
@interface IMAdSDKFlutterContainerView : UIView
@end

NS_ASSUME_NONNULL_END
