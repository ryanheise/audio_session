#import "AudioSessionPlugin.h"
#import "DarwinAudioSession.h"

static NSObject *configuration = nil;
static NSMutableArray<AudioSessionPlugin *> *instances = nil;

@implementation AudioSessionPlugin {
    DarwinAudioSession *_darwinAudioSession;
    FlutterMethodChannel *_channel;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (!instances) {
        instances = [[NSMutableArray alloc] init];
    }
    AudioSessionPlugin *instance = [[AudioSessionPlugin alloc] initWithRegistrar:registrar];

	_darwinAudioSession = [[DarwinAudioSession alloc] initWithRegistrar:registrar];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
	_channel = [FlutterMethodChannel
		methodChannelWithName:@"com.ryanheise.audio_session"
              binaryMessenger:[registrar messenger]];
	[registrar addMethodCallDelegate:instance channel:_channel];
    [instances addObject:self];
    return self;
}

- (FlutterMethodChannel *)channel {
    return _channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray* args = (NSArray*)call.arguments;
	if ([@"setConfiguration" isEqualToString:call.method]) {
        configuration = args[0];
        for (int i = 0; i < instances.count; i++) {
            [instances[i].channel invokeMethod:@"onConfigurationChanged" arguments:@[configuration]];
        }
		result(nil);
	} else if ([@"getConfiguration" isEqualToString:call.method]) {
        result(configuration);
	} else {
		result(FlutterMethodNotImplemented);
	}
}

- (void) dealloc {
    [instances removeObject:self];
}

@end
