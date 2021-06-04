#import <Flutter/Flutter.h>

#ifndef MICROPHONE_ENABLED
    #define MICROPHONE_ENABLED=1
#endif

@interface DarwinAudioSession : NSObject

@property (readonly, nonatomic) FlutterMethodChannel *channel;

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar;

@end
