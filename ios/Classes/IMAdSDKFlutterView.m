#import "IMAdSDKFlutterView.h"
#import <WebKit/WebKit.h>

@protocol IMAdSDKContainerViewResizeCallback <NSObject>

- (void) sdkRequestedViewResize;

@end

@implementation IMAdSDKFlutterViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  IMAdSDKFlutterContainerController* imadSdkFlutterContainerController = [[IMAdSDKFlutterContainerController alloc] initWithFrame:frame
                                                                         viewIdentifier:viewId
                                                                              arguments:args
                                                                        binaryMessenger:_messenger];
  return imadSdkFlutterContainerController;
}

@end

@interface IMAdSDKFlutterContainerView()
@property (weak, nonatomic) id<IMAdSDKContainerViewResizeCallback> resizeCallback;
@property (weak, nonatomic) WKWebView *webview;
@end

@implementation IMAdSDKFlutterContainerView {
    CGSize previousSize;
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
}

- (void) setResizeCallback:(id<IMAdSDKContainerViewResizeCallback>)resizeCallback {
    _resizeCallback = resizeCallback;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.webview == nil) {
        NSArray *webviews = [self getWebSubview:self];
        if (webviews.count < 1) {
            return;
        }
        self.webview = [webviews objectAtIndex:0];
        previousSize = CGSizeZero;
    }

    if (!CGSizeEqualToSize(previousSize, self.webview.frame.size) && self.resizeCallback) {
        [self.resizeCallback sdkRequestedViewResize];
        previousSize = self.webview.frame.size;
    }
    
    if (self.subviews.count > 0) {
        // the ad container view will shrink to 0 height after close expand
        [self.subviews objectAtIndex:0].frame = self.webview.frame;
    }
}

- (NSArray *) getWebSubview:(UIView *)parentView {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(UIView *aView in parentView.subviews){
        if([aView isKindOfClass:[WKWebView class]]){
            [result addObject:aView];
        }
        else {
            NSArray *subResult = [self getWebSubview:aView];
            result = [[result arrayByAddingObjectsFromArray:subResult] mutableCopy];
        }
    }
    
    return result;
}

@end

@interface IMAdSDKFlutterContainerController() <IMAdSDKContainerViewResizeCallback>

@end

@implementation IMAdSDKFlutterContainerController {
  IMAdSDKFlutterContainerView* _adContainerView;
  int64_t _viewId;
  FlutterMethodChannel* _channel;
  id _args;
  bool _loaded;
    EngageAd* _engageAd;
    CGSize previousSize;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if (self = [super init]) {
  	_loaded = false;
    _viewId = viewId;

    NSString* channelName = [NSString stringWithFormat:@"com.appsploration.imadsdk/flutter_%lld", viewId];
    _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
      _args = args;
    
    _adContainerView = [[IMAdSDKFlutterContainerView alloc] initWithFrame:frame];
      _adContainerView.opaque = false;
      [_adContainerView setResizeCallback:self];
    EngageAdConfiguration *config = nil;
    
    if (args[@"availableRect"]) {
    	CGRect availableRect = [self getAvailableRectFrom: args[@"availableRect"]];
        config = [[EngageAdConfiguration alloc] initWithAvailableArea:availableRect expansionCallback:nil];
    }
    NSString *premiumZoneId = nil;
    if (args[@"premiumZoneId"]) {
    	premiumZoneId = args[@"premiumZoneId"];
    }
    
    [self loadAdsWithPublisherId:[args objectForKey:@"publisherId"] zoneId:[args objectForKey:@"zoneId"] premiumZoneId:premiumZoneId config:config];
  }
  return self;
}

- (CGRect) getAvailableRectFrom: (id) argParam {
	CGFloat width = fabsf([[argParam objectForKey:@"right"] floatValue] - [[argParam objectForKey:@"left"] floatValue]);
	CGFloat height = fabsf([[argParam objectForKey:@"bottom"] floatValue] - [[argParam objectForKey:@"top"] floatValue]);
	return CGRectMake([[argParam objectForKey:@"top"] floatValue], [[argParam objectForKey:@"left"] floatValue], width, height);
}

- (void) loadAdsWithPublisherId: (NSString *) publisherId zoneId:(NSString *) zoneId premiumZoneId:(NSString *) premiumZoneId config: (EngageAdConfiguration *) config {
	if (_loaded) {
		return;
	}
	
	_loaded = true;
	
	IMAd* imad = nil;
	
	if ([@"ClickTagMode.externalBrowser" isEqualToString: _args[@"clickTagMode"]]) {
		imad = [[IMAd alloc] initIMAdSDKWithConfiguration: [[SdkConfiguration alloc] initWithClickTagMode:ClickTagModeExternalBrowser]];
	}
	else {
		imad = [[IMAd alloc] initIMAdSDK];
	}
	
    IMAdEngage* engageAd = [[IMAdEngage alloc] initIMAdEngageWithImadSDK:imad publisherId:publisherId];
    [engageAd setPremiumZoneWithPremiumZoneId:premiumZoneId];
    UIViewController* vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [engageAd loadWithZoneId:zoneId adLoadCallback:self adEventCallback:self viewController:vc config:config];
}


- (void)dealloc {
    [_engageAd destroy];
    _engageAd = nil;
}

- (UIView*)view {
  return _adContainerView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"updateSettings"]) {
    
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void) updateSize:(CGSize)size {
    
    [_channel invokeMethod:@"updateSize" arguments:@{@"width" : @(size.width), @"height" : @(size.height)}];
}

#pragma mark AdLoadCallback

- (void)adReadyWithAdUnit:(AdUnit * _Nonnull)adUnit
{
    // Add it to the window subview
    _engageAd = (EngageAd *) adUnit;
    [_adContainerView addSubview:[_engageAd getAdView]];
    NSString *zoneId = [_engageAd getZoneId];
    
    [self updateSizeForAd:_engageAd];
    [_channel invokeMethod:@"adReady" arguments:@{@"zoneId" : zoneId}];
}

- (void)adFailedWithZoneId:(NSString * _Nonnull)zoneId error:(NSError * _Nonnull)error {
    
    [_channel invokeMethod:@"adReady" arguments:@{@"adFailed" : zoneId, @"description": error.localizedDescription}];
}

#pragma mark AdEventCallback

- (void)adDidExpandWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
    [self updateSizeForAd:engageAd];
    [_channel invokeMethod:@"adExpanded" arguments:@{@"zoneId" : [engageAd getZoneId] }];
}

- (void) updateSizeForAd:(EngageAd *) engageAd {
    UIView *containerView = [engageAd getAdView];
    NSArray *webviews = [self getWebSubview:containerView];
    WKWebView *webview = [webviews objectAtIndex:0];
    CGRect frame = webview.frame;
    CGRect containerFrame = containerView.frame;
    
    CGSize size = frame.size;
    NSLog(@"update size called (current): %f, %f", previousSize.width, previousSize.height);
    NSLog(@"update size called (new): %f, %f", size.width, size.height);
    if (!CGSizeEqualToSize(previousSize, size)) {
        previousSize = size;
        
        [self updateSize:size];
        
        containerFrame = CGRectMake(0, 0, size.width, size.height);
        containerView.frame = containerFrame;
    }
}

- (NSArray *) getWebSubview:(UIView *)parentView {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(UIView *aView in parentView.subviews){
        if([aView isKindOfClass:[WKWebView class]]){
            [result addObject:aView];
        }
        else {
            NSArray *subResult = [self getWebSubview:aView];
            result = [[result arrayByAddingObjectsFromArray:subResult] mutableCopy];
        }
    }
    
    return result;
}

- (void)adDidCancelExpandWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
}

- (void)adWasClickedWithEngageAd:(EngageAd *)engageAd {
    
    [_channel invokeMethod:@"adClicked" arguments:@{@"zoneId" : [engageAd getZoneId] }];
}

- (void)adDidCloseExpandedWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
    [_channel invokeMethod:@"adCloseExpanded" arguments:@{@"zoneId" : [engageAd getZoneId] }];
    
    [self updateSizeForAd:engageAd];
}

- (void)adActionWillBeginWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
}

- (void)adActionDidEndWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
}

- (void)adActionWillLeaveApplicationWithEngageAd:(EngageAd * )engageAd
{
    
}

- (void)adDidBeginPreviewWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
}

- (void)adDidEndPreviewWithEngageAd:(EngageAd * _Nonnull)engageAd
{
    
}

- (void)adDidUnloadWithEngageAd:(EngageAd * _Nonnull)engageAd {
    
    [_channel invokeMethod:@"adUnloaded" arguments:@{@"zoneId" : [engageAd getZoneId] }];
}


#pragma mark IMAdSDKContainerViewResizeCallback

- (void)sdkRequestedViewResize {
    if (_engageAd == nil)
        return;
    
    [self updateSizeForAd:_engageAd];
}

@end
