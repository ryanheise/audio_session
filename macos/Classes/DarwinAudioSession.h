#import <FlutterMacOS/FlutterMacOS.h>

@interface AudioPlayer : NSObject<FlutterStreamHandler>

@property (readonly, nonatomic) FlutterMethodChannel *channel;

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar;

@end
