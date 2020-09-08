#import "DarwinAudioSession.h"
#import <AVFoundation/AVFoundation.h>

// TODO disable for macOS.
static NSMutableArray<DarwinAudioSession *> *sessions = nil;

@implementation DarwinAudioSession {
    NSObject<FlutterPluginRegistrar>* _registrar;
    FlutterMethodChannel *_channel;
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    if (!sessions) {
        sessions = [[NSMutableArray alloc] init];
    }
    [sessions addObject:self];
    _registrar = registrar;
    _channel = [FlutterMethodChannel
        methodChannelWithName:@"com.ryanheise.av_audio_session"
              binaryMessenger:[registrar messenger]];
    __weak __typeof__(self) weakSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        [weakSelf handleMethodCall:call result:result];
    }];
    [AVAudioSession sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    return self;
}

- (FlutterMethodChannel *)channel {
    return _channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray* args = (NSArray*)call.arguments;
    if ([@"getCategory" isEqualToString:call.method]) {
        [self getCategory:args result:result];
    } else if ([@"setCategory" isEqualToString:call.method]) {
        [self setCategory:args result:result];
    } else if ([@"getAvailableCategories" isEqualToString:call.method]) {
        [self getAvailableCategories:args result:result];
    } else if ([@"getCategoryOptions" isEqualToString:call.method]) {
        [self getCategoryOptions:args result:result];
    } else if ([@"getMode" isEqualToString:call.method]) {
        [self getMode:args result:result];
    } else if ([@"setMode" isEqualToString:call.method]) {
        [self setMode:args result:result];
    } else if ([@"getAvailableModes" isEqualToString:call.method]) {
        [self getAvailableModes:args result:result];
    } else if ([@"getRouteSharingPolicy" isEqualToString:call.method]) {
        [self getRouteSharingPolicy:args result:result];
    } else if ([@"setActive" isEqualToString:call.method]) {
        [self setActive:args result:result];
    } else if ([@"getRecordPermission" isEqualToString:call.method]) {
        [self getRecordPermission:args result:result];
    } else if ([@"requestRecordPermission" isEqualToString:call.method]) {
        [self requestRecordPermission:args result:result];
    } else if ([@"isOtherAudioPlaying" isEqualToString:call.method]) {
        [self isOtherAudioPlaying:args result:result];
    } else if ([@"getSecondaryAudioShouldBeSilencedHint" isEqualToString:call.method]) {
        [self getSecondaryAudioShouldBeSilencedHint:args result:result];
    } else if ([@"getAllowHapticsAndSystemSoundsDuringRecording" isEqualToString:call.method]) {
        [self getAllowHapticsAndSystemSoundsDuringRecording:args result:result];
    } else if ([@"setAllowHapticsAndSystemSoundsDuringRecording" isEqualToString:call.method]) {
        [self setAllowHapticsAndSystemSoundsDuringRecording:args result:result];
    } else if ([@"getPromptStyle" isEqualToString:call.method]) {
        [self getPromptStyle:args result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)getCategory:(NSArray *)args result:(FlutterResult)result {
    AVAudioSessionCategory category = [[AVAudioSession sharedInstance] category];
    result([self categoryToFlutter:category]);
}

- (void)setCategory:(NSArray *)args result:(FlutterResult)result {
    NSNumber *categoryIndex = (NSNumber *)args[0];
    NSNumber *options = (NSNumber *)args[1];
    NSNumber *modeIndex = (NSNumber *)args[2];
    NSNumber *policyIndex = (NSNumber *)args[3];
    NSError *error = nil;
    BOOL status;
    AVAudioSessionCategory category = [self flutterToCategory:categoryIndex];
    if (!category) category = AVAudioSessionCategorySoloAmbient;
    NSString *mode = [self flutterToMode:modeIndex];
    if (!mode) mode = AVAudioSessionModeDefault;
    if (options == (id)[NSNull null]) options = @(0);
    if (policyIndex == (id)[NSNull null]) {
        // Set the category, mode and options depending on the available API
        if (@available(iOS 10.0, *)) {
            status = [[AVAudioSession sharedInstance] setCategory:category mode:mode options:options.integerValue error:&error];
        } else {
            status = [[AVAudioSession sharedInstance] setCategory:category withOptions:options.integerValue error:&error];
            if (!error) {
                status = status && [[AVAudioSession sharedInstance] setMode:mode error:&error];
            }
        }
    } else {
        // Set the category, mode, options and policy depending on the available API
        if (@available(iOS 11.0, *)) {
            AVAudioSessionRouteSharingPolicy policy = [self flutterToPolicy:policyIndex];
            status = [[AVAudioSession sharedInstance] setCategory:category mode:mode routeSharingPolicy:policy options:options.integerValue error:&error];
        } else if (@available(iOS 10.0, *)) {
            status = [[AVAudioSession sharedInstance] setCategory:category mode:mode options:options.integerValue error:&error];
        } else {
            status = [[AVAudioSession sharedInstance] setCategory:category withOptions:options.integerValue error:&error];
            if (!error) {
                status = status && [[AVAudioSession sharedInstance] setMode:mode error:&error];
            }
        }
    }
    if (error) {
        [self sendError:error result:result];
    } else {
        result(@(status));
    }
}

- (void)getAvailableCategories:(NSArray *)args result:(FlutterResult)result {
    if (@available(iOS 9.0, *)) {
        NSArray *categories = [[AVAudioSession sharedInstance] availableCategories];
        NSMutableArray *flutterCategories = [NSMutableArray new];
        for (int i = 0; i < categories.count; i++) {
            [flutterCategories addObject:[self categoryToFlutter:categories[i]]];
        }
        result(flutterCategories);
    } else {
        result(@[]);
    }
}

- (void)getCategoryOptions:(NSArray *)args result:(FlutterResult)result {
    AVAudioSessionCategoryOptions options = [[AVAudioSession sharedInstance] categoryOptions];
    result(@((int)options));
}

- (void)getMode:(NSArray *)args result:(FlutterResult)result {
    AVAudioSessionMode mode = [[AVAudioSession sharedInstance] mode];
    result([self modeToFlutter:mode]);
}

- (void)setMode:(NSArray *)args result:(FlutterResult)result {
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setMode:[self flutterToMode:args[0]] error:&error];
    if (error) {
        [self sendError:error result:result];
    } else {
        result(nil);
    }
}

- (void)getAvailableModes:(NSArray *)args result:(FlutterResult)result {
    if (@available(iOS 9.0, *)) {
        NSArray *modes = [[AVAudioSession sharedInstance] availableModes];
        NSMutableArray *flutterModes = [NSMutableArray new];
        for (int i = 0; i < modes.count; i++) {
            [flutterModes addObject:[self modeToFlutter:modes[i]]];
        }
        result(flutterModes);
    } else {
        result(@[]);
    }
}

- (void)getRouteSharingPolicy:(NSArray *)args result:(FlutterResult)result {
    if (@available(iOS 11.0, *)) {
        AVAudioSessionRouteSharingPolicy policy = [[AVAudioSession sharedInstance] routeSharingPolicy];
        result([self policyToFlutter:policy]);
    } else {
        result(nil);
    }
}

- (void)setActive:(NSArray *)args result:(FlutterResult)result {
    NSError *error = nil;
    BOOL active = [args[0] boolValue];
    BOOL status;
    if (args[1] != (id)[NSNull null]) {
        status = [[AVAudioSession sharedInstance] setActive:active withOptions:[args[1] integerValue] error:&error];
    } else {
        status = [[AVAudioSession sharedInstance] setActive:active error:&error];
    }
    if (error) {
        [self sendError:error result:result];
    } else {
        result(@(status));
    }
}

- (void)getRecordPermission:(NSArray *)args result:(FlutterResult)result {
    result([self recordPermissionToFlutter:[[AVAudioSession sharedInstance] recordPermission]]);
}

- (void)requestRecordPermission:(NSArray *)args result:(FlutterResult)result {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        result(@(granted));
    }];
}

- (void)isOtherAudioPlaying:(NSArray *)args result:(FlutterResult)result {
    result(@([[AVAudioSession sharedInstance] isOtherAudioPlaying]));
}

- (void)getSecondaryAudioShouldBeSilencedHint:(NSArray *)args result:(FlutterResult)result {
    result(@([[AVAudioSession sharedInstance] secondaryAudioShouldBeSilencedHint]));
}

- (void)getAllowHapticsAndSystemSoundsDuringRecording:(NSArray *)args result:(FlutterResult)result {
    if (@available(iOS 13.0, *)) {
        result(@([[AVAudioSession sharedInstance] allowHapticsAndSystemSoundsDuringRecording]));
    } else {
        result(@(NO));
    }
}

- (void)setAllowHapticsAndSystemSoundsDuringRecording:(NSArray *)args result:(FlutterResult)result {
    if (@available(iOS 13.0, *)) {
        NSError *error = nil;
        result(@([[AVAudioSession sharedInstance] setAllowHapticsAndSystemSoundsDuringRecording:[args[0] boolValue] error:&error]));
        if (error) {
            [self sendError:error result:result];
        } else {
            result(nil);
        }
    } else {
        result(nil);
    }
}

- (void)getPromptStyle:(NSArray *)args result:(FlutterResult)result {
    if (@available(iOS 13.0, *)) {
        result([self promptStyleToFlutter:[[AVAudioSession sharedInstance] promptStyle]]);
    } else {
        result(nil);
    }
}

- (AVAudioSessionCategory)flutterToCategory:(NSNumber *)categoryIndex {
    AVAudioSessionCategory category = nil;
    if (categoryIndex != (id)[NSNull null]) {
        switch (categoryIndex.integerValue) {
            case 0: category = AVAudioSessionCategoryAmbient; break;
            case 1: category = AVAudioSessionCategorySoloAmbient; break;
            case 2: category = AVAudioSessionCategoryPlayback; break;
            case 3: category = AVAudioSessionCategoryRecord; break;
            case 4: category = AVAudioSessionCategoryPlayAndRecord; break;
            case 5: category = AVAudioSessionCategoryMultiRoute; break;
        }
    }
    return category;
}

- (NSObject *)categoryToFlutter:(AVAudioSessionCategory)category {
    if (category == AVAudioSessionCategoryAmbient) return @(0);
    else if (category == AVAudioSessionCategorySoloAmbient) return @(1);
    else if (category == AVAudioSessionCategoryPlayback) return @(2);
    else if (category == AVAudioSessionCategoryRecord) return @(3);
    else if (category == AVAudioSessionCategoryPlayAndRecord) return @(4);
    else return @(5);
}

- (NSString *)flutterToMode:(NSNumber *)modeIndex {
    AVAudioSessionMode mode = nil;
    if (modeIndex != (id)[NSNull null]) {
        switch (modeIndex.integerValue) {
            case 0: mode = AVAudioSessionModeDefault; break;
            case 1: mode = AVAudioSessionModeGameChat; break;
            case 2: mode = AVAudioSessionModeMeasurement; break;
            case 3: mode = AVAudioSessionModeMoviePlayback; break;
            case 4:
                if (@available(iOS 9.0, *)) {
                    mode = AVAudioSessionModeSpokenAudio;
                } else {
                    mode = AVAudioSessionModeDefault;
                }
                break;
            case 5: mode = AVAudioSessionModeVideoChat; break;
            case 6: mode = AVAudioSessionModeVideoRecording; break;
            case 7: mode = AVAudioSessionModeVoiceChat; break;
            case 8:
                if (@available(iOS 12.0, *)) {
                    mode = AVAudioSessionModeVoicePrompt;
                } else {
                    mode = AVAudioSessionModeDefault;
                }
                break;
        }
    }
    return mode;
}

- (NSObject *)modeToFlutter:(NSString *)mode {
    if (@available(iOS 9.0, *)) {
        if (mode == AVAudioSessionModeSpokenAudio) return @(4);
        if (@available(iOS 12.0, *)) {
            if (mode == AVAudioSessionModeVoicePrompt) return @(8);
        }
    }
    if (mode == AVAudioSessionModeDefault) return @(0);
    else if (mode == AVAudioSessionModeGameChat) return @(1);
    else if (mode == AVAudioSessionModeMeasurement) return @(2);
    else if (mode == AVAudioSessionModeMoviePlayback) return @(3);
    else if (mode == AVAudioSessionModeVideoChat) return @(5);
    else if (mode == AVAudioSessionModeVideoRecording) return @(6);
    else if (mode == AVAudioSessionModeVoiceChat) return @(7);
    else return @(0);
}

- (NSUInteger)flutterToPolicy:(NSNumber *)policyIndex {
    NSUInteger policy = 0;
    if (@available(iOS 11.0, *)) {
        if (policyIndex != (id)[NSNull null]) {
            switch (policyIndex.integerValue) {
                case 0: policy = AVAudioSessionRouteSharingPolicyDefault; break;
                case 1:
                    if (@available(iOS 13.0, *)) {
                        policy = AVAudioSessionRouteSharingPolicyLongFormAudio;
                    } else {
                        policy = AVAudioSessionRouteSharingPolicyDefault;
                    }
                    break;
                case 2:
                    if (@available(iOS 13.0, *)) {
                        policy = AVAudioSessionRouteSharingPolicyLongFormVideo;
                    } else {
                        policy = AVAudioSessionRouteSharingPolicyDefault;
                    }
                    break;
                case 3: policy = AVAudioSessionRouteSharingPolicyIndependent; break;
            }
        }
    }
    return policy;
}

- (NSObject *)policyToFlutter:(NSUInteger)policy {
    if (@available(iOS 11.0, *)) {
        if (@available(iOS 13.0, *)) {
            if (policy == AVAudioSessionRouteSharingPolicyLongFormAudio) return @(1);
            else if (policy == AVAudioSessionRouteSharingPolicyLongFormVideo) return @(2);
        }
        if (policy == AVAudioSessionRouteSharingPolicyDefault) return @(0);
        else return @(3);
    } else {
        return [NSNull null];
    }
}

- (AVAudioSessionRecordPermission)flutterToRecordPermission:(NSNumber *)recordPermissionIndex {
    AVAudioSessionRecordPermission permission = AVAudioSessionRecordPermissionUndetermined;
    if (recordPermissionIndex != (id)[NSNull null]) {
        switch (recordPermissionIndex.integerValue) {
            case 0: permission = AVAudioSessionRecordPermissionUndetermined; break;
            case 1: permission = AVAudioSessionRecordPermissionDenied; break;
            case 2: permission = AVAudioSessionRecordPermissionGranted; break;
        }
    }
    return permission;
}

- (NSObject *)recordPermissionToFlutter:(AVAudioSessionRecordPermission)recordPermission {
    if (recordPermission == AVAudioSessionRecordPermissionUndetermined) return @(0);
    else if (recordPermission == AVAudioSessionRecordPermissionDenied) return @(1);
    else if (recordPermission == AVAudioSessionRecordPermissionGranted) return @(2);
    else return @(0);
}

- (NSObject *)promptStyleToFlutter:(AVAudioSessionPromptStyle)promptStyle {
    if (promptStyle == AVAudioSessionPromptStyleNone) return @(0);
    else if (promptStyle == AVAudioSessionPromptStyleShort) return @(1);
    else if (promptStyle == AVAudioSessionPromptStyleNormal) return @(2);
    else return @(0);
}


- (void) sendError:(NSError *)error result:(FlutterResult)result {
    FlutterError *flutterError = [FlutterError errorWithCode:[NSString stringWithFormat:@"%d", (int)error.code]
                                                        message:error.localizedDescription
                                                        details:nil];
    result(flutterError);
}

- (void) audioInterrupt:(NSNotification*)notification {
    NSNumber *interruptionType = (NSNumber*)[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey];
    NSLog(@"audioInterrupt");
    switch ([interruptionType integerValue]) {
        case AVAudioSessionInterruptionTypeBegan:
        {
            [self invokeMethod:@"onInterruptionEvent" arguments:@[@(0), @(0)]];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded:
        {
            if ([(NSNumber*)[notification.userInfo valueForKey:AVAudioSessionInterruptionOptionKey] intValue] == AVAudioSessionInterruptionOptionShouldResume) {
                [self invokeMethod:@"onInterruptionEvent" arguments:@[@(1), @(1)]];
            } else {
                [self invokeMethod:@"onInterruptionEvent" arguments:@[@(1), @(0)]];
            }
            break;
        }
        default:
            break;
    }
}

- (void) invokeMethod:(NSString *)method arguments:(id _Nullable)arguments {
    for (int i = 0; i < sessions.count; i++) {
        [sessions[i].channel invokeMethod:method arguments:arguments];
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [sessions removeObject:self];
}

@end
