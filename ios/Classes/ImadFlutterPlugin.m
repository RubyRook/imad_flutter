#import "ImadFlutterPlugin.h"
#if __has_include(<imad_flutter/imad_flutter-Swift.h>)
#import <imad_flutter/imad_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#endif

#import "IMAdSDKFlutterView.h"

@implementation ImadFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
	IMAdSDKFlutterViewFactory* viewFactory = [[IMAdSDKFlutterViewFactory alloc] initWithMessenger:registrar.messenger];
	[registrar registerViewFactory:viewFactory withId:@"com.appsploration.imadsdk/flutter"];
}
@end
