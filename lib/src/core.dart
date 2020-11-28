import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'android.dart';
import 'darwin.dart';

/// Manages a single audio session to be used across different audio plugins in
/// your app. [AudioSession] will configure your app by describing to the operating
/// system the nature of the audio that your app intends to play.
///
/// You obtain the singleton [instance] of this class, [configure] it during
/// your app's startup, and then use other plugins to play or record audio. An
/// app will typically not call [setActive] directly since individual audio
/// plugins will call this before they play or record audio.
class AudioSession {
  static const MethodChannel _channel =
      const MethodChannel('com.ryanheise.audio_session');
  static AudioSession? _instance;

  /// The singleton instance across all Flutter engines.
  static Future<AudioSession> get instance async {
    if (_instance == null) {
      _instance = AudioSession._();
      // TODO: Use this code without the '?' once a Dart bug is fixed.
      // (similar instances occur elsewhere)
      //Map? data = await _channel.invokeMethod<Map>('getConfiguration');
      Map? data = await _channel.invokeMethod<Map?>('getConfiguration');
      if (data != null) {
        _instance!._configuration = AudioSessionConfiguration.fromJson(data);
      }
    }
    return _instance!;
  }

  AndroidAudioManager? _androidAudioManager =
      !kIsWeb && Platform.isAndroid ? AndroidAudioManager() : null;
  AVAudioSession? _avAudioSession =
      !kIsWeb && Platform.isIOS ? AVAudioSession() : null;
  AudioSessionConfiguration? _configuration;
  final _configurationSubject = BehaviorSubject<AudioSessionConfiguration>();
  final _interruptionEventSubject = PublishSubject<AudioInterruptionEvent>();
  final _becomingNoisyEventSubject = PublishSubject<void>();

  AudioSession._() {
    _avAudioSession?.interruptionNotificationStream?.listen((notification) {
      switch (notification.type) {
        case AVAudioSessionInterruptionType.began:
          if (notification.wasSuspended != true) {
            _interruptionEventSubject.add(
                AudioInterruptionEvent(true, AudioInterruptionType.unknown));
          }
          break;
        case AVAudioSessionInterruptionType.ended:
          _interruptionEventSubject.add(AudioInterruptionEvent(
              false,
              notification.options
                      .contains(AVAudioSessionInterruptionOptions.shouldResume)
                  ? AudioInterruptionType.pause
                  : AudioInterruptionType.unknown));
          break;
      }
    });
    _avAudioSession?.routeChangeStream
        .where((routeChange) =>
            routeChange.reason ==
            AVAudioSessionRouteChangeReason.oldDeviceUnavailable)
        .listen((routeChange) => _becomingNoisyEventSubject.add(null));
    _androidAudioManager?.becomingNoisyEventStream
        .listen((event) => _becomingNoisyEventSubject.add(null));
    _channel.setMethodCallHandler((MethodCall call) async {
      final List? args = call.arguments;
      switch (call.method) {
        case 'onConfigurationChanged':
          _configurationSubject.add(
              _configuration = AudioSessionConfiguration.fromJson(args![0]));
          break;
      }
    });
  }

  /// The current configuration.
  AudioSessionConfiguration? get configuration => _configuration;

  /// A stream broadcasting the current configuration.
  Stream<AudioSessionConfiguration> get configurationStream =>
      _configurationSubject.stream;

  /// Whether the audio session is configured.
  bool get isConfigured => _configuration != null;

  /// The configured [AndroidAudioAttributes].
  AndroidAudioAttributes? get androidAudioAttributes =>
      _configuration?.androidAudioAttributes;

  /// The configured [AndroidAudioFocusGainType].
  AndroidAudioFocusGainType? get androidAudioFocusGainType =>
      _configuration?.androidAudioFocusGainType;

  /// A stream of [AudioInterruptionEvent]s.
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      _interruptionEventSubject.stream;

  /// A stream of events that occur when audio becomes noisy (e.g. due to
  /// unplugging the headphones).
  Stream<void> get becomingNoisyEventStream =>
      _becomingNoisyEventSubject.stream;

  /// Configures the audio session. It is useful to call this method during
  /// your app's initialisation before you start playing or recording any
  /// audio. However, you may also call this method afterwards to change the
  /// current configuration at any time.
  Future<void> configure(AudioSessionConfiguration configuration) async {
    assert(configuration != null);
    await _avAudioSession?.setCategory(
      configuration.avAudioSessionCategory,
      configuration.avAudioSessionCategoryOptions,
      configuration.avAudioSessionMode,
      configuration.avAudioSessionRouteSharingPolicy,
    );
    _configuration = configuration;
    await _channel.invokeMethod('setConfiguration', [configuration.toJson()]);
  }

  /// Activates or deactivates this audio session. Typically an audio plugin
  /// should call this method when it begins playing audio. If the audio
  /// session is not yet configured at the time this is called, the
  /// [fallbackConfiguration] will be set. If any of
  /// [avAudioSessionSetActiveOptions], [androidAudioFocusGainType],
  /// [androidAudioAttributesttributes] and [androidWillPauseWhenDucked] are
  /// speficied, they will override the configuration.
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    AndroidAudioAttributes? androidAudioAttributes,
    bool? androidWillPauseWhenDucked,
    AudioSessionConfiguration fallbackConfiguration =
        const AudioSessionConfiguration.music(),
  }) async {
    final configuration = _configuration ?? fallbackConfiguration;
    if (!isConfigured) {
      await configure(fallbackConfiguration);
    }
    if (!kIsWeb && Platform.isIOS) {
      return await _avAudioSession!.setActive(active,
          avOptions: avAudioSessionSetActiveOptions ??
              configuration.avAudioSessionSetActiveOptions);
    } else if (!kIsWeb && Platform.isAndroid) {
      if (active) {
        // Activate
        final pauseWhenDucked =
            configuration.androidWillPauseWhenDucked ?? false;
        var ducked = false;
        final success = await _androidAudioManager!
            .requestAudioFocus(AndroidAudioFocusRequest(
          gainType: androidAudioFocusGainType ??
              configuration.androidAudioFocusGainType,
          audioAttributes:
              androidAudioAttributes ?? configuration.androidAudioAttributes,
          willPauseWhenDucked: androidWillPauseWhenDucked ??
              configuration.androidWillPauseWhenDucked,
          onAudioFocusChanged: (focus) {
            print("core onAudioFocusChanged");
            switch (focus) {
              case AndroidAudioFocus.gain:
                _interruptionEventSubject.add(AudioInterruptionEvent(
                    false,
                    ducked
                        ? AudioInterruptionType.duck
                        : AudioInterruptionType.pause));
                ducked = false;
                break;
              case AndroidAudioFocus.loss:
                _interruptionEventSubject.add(AudioInterruptionEvent(
                    true, AudioInterruptionType.unknown));
                ducked = false;
                break;
              case AndroidAudioFocus.lossTransient:
                _interruptionEventSubject.add(
                    AudioInterruptionEvent(true, AudioInterruptionType.pause));
                ducked = false;
                break;
              case AndroidAudioFocus.lossTransientCanDuck:
                // We enforce the "will pause when ducked" configuration by
                // sending the app a pause event instead of a duck event.
                _interruptionEventSubject.add(AudioInterruptionEvent(
                    true,
                    pauseWhenDucked
                        ? AudioInterruptionType.pause
                        : AudioInterruptionType.duck));
                if (!pauseWhenDucked) ducked = true;
                break;
            }
          },
        ));
        return success;
      } else {
        // Deactivate
        final success = await _androidAudioManager!.abandonAudioFocus();
        return success;
      }
    }
    return true;
  }
}

/// A configuration for [AudioSession] describing what type of audio your app
/// intends to play, and how it interacts with other audio apps. You can either
/// create your own configuration or use the following recipes:
///
/// * [AudioSessionConfiguration.music]: Useful for music player apps.
/// * [AudioSessionConfiguration.speech]: Useful for podcast and audiobook
/// apps.
///
/// You can suggest additional recipes via the GitHub issues page.
class AudioSessionConfiguration {
  final AVAudioSessionCategory? avAudioSessionCategory;
  final AVAudioSessionCategoryOptions? avAudioSessionCategoryOptions;
  final AVAudioSessionMode? avAudioSessionMode;
  final AVAudioSessionRouteSharingPolicy? avAudioSessionRouteSharingPolicy;
  final AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions;
  final AndroidAudioAttributes? androidAudioAttributes;
  final AndroidAudioFocusGainType androidAudioFocusGainType;
  final bool? androidWillPauseWhenDucked;

  /// Creates an audio session configuration from scratch.
  ///
  /// Options prefixed with `av` correspond to classes in Apple's AVFoundation
  /// library and their values will be ignored on all platforms other than iOS.
  /// Only certain combinations of these configuration options are permitted,
  /// and you should consult [Apple's
  /// documentation](https://developer.apple.com/documentation/avfoundation/avaudiosession?language=objc)
  /// for further information.
  ///
  /// Options prefixed with `android` correspond to options in Android's SDK
  /// and their values are ignored on all platforms other than Android. Note
  /// that the underlying Android platform allows different audio players to
  /// use different audio attributes, and so the values supplied here act as
  /// hints on the type of configuration you would like audio plugins in your
  /// session to adopt by default.
  const AudioSessionConfiguration({
    this.avAudioSessionCategory,
    this.avAudioSessionCategoryOptions,
    this.avAudioSessionMode,
    this.avAudioSessionRouteSharingPolicy,
    this.avAudioSessionSetActiveOptions,
    this.androidAudioAttributes,
    this.androidAudioFocusGainType = AndroidAudioFocusGainType.gain,
    this.androidWillPauseWhenDucked,
  }) : assert(androidAudioFocusGainType != null);

  AudioSessionConfiguration.fromJson(Map data)
      : this(
          avAudioSessionCategory: data['avAudioSessionCategory'] == null
              ? null
              : AVAudioSessionCategory.values[data['avAudioSessionCategory']],
          avAudioSessionCategoryOptions:
              data['avAudioSessionCategoryOptions'] == null
                  ? null
                  : AVAudioSessionCategoryOptions(
                      data['avAudioSessionCategoryOptions']),
          avAudioSessionMode: data['avAudioSessionMode'] == null
              ? null
              : AVAudioSessionMode.values[data['avAudioSessionMode']],
          avAudioSessionRouteSharingPolicy:
              data['avAudioSessionRouteSharingPolicy'] == null
                  ? null
                  : AVAudioSessionRouteSharingPolicy
                      .values[data['avAudioSessionRouteSharingPolicy']],
          avAudioSessionSetActiveOptions:
              data['avAudioSessionSetActiveOptions'] == null
                  ? null
                  : AVAudioSessionSetActiveOptions(
                      data['avAudioSessionSetActiveOptions']),
          androidAudioAttributes: data['androidAudioAttributes'] == null
              ? null
              : AndroidAudioAttributes.fromJson(data['androidAudioAttributes']),
          androidAudioFocusGainType: AndroidAudioFocusGainType
              .values[data['androidAudioFocusGainType']]!,
          androidWillPauseWhenDucked: data['androidWillPauseWhenDucked'],
        );

  /// A recipe for creating an audio configuration for a music player.
  const AudioSessionConfiguration.music()
      : this(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        );

  /// A recipe for creating an audio configuration for an app that
  /// predominantly plays continuous speech such as a podcast or audiobook app.
  const AudioSessionConfiguration.speech()
      : this(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        );

  /// Creates a copy of this configuration with the given fields replaced by
  /// new values.
  AudioSessionConfiguration copyWith({
    AVAudioSessionCategory? avAudioSessionCategory,
    AVAudioSessionCategoryOptions? avAudioSessionCategoryOptions,
    AVAudioSessionMode? avAudioSessionMode,
    AVAudioSessionRouteSharingPolicy? avAudioSessionRouteSharingPolicy,
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioAttributes? androidAudioAttributes,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    bool? androidWillPauseWhenDucked,
  }) =>
      AudioSessionConfiguration(
        avAudioSessionCategory:
            avAudioSessionCategory ?? this.avAudioSessionCategory,
        avAudioSessionCategoryOptions:
            avAudioSessionCategoryOptions ?? this.avAudioSessionCategoryOptions,
        avAudioSessionMode: avAudioSessionMode ?? this.avAudioSessionMode,
        avAudioSessionRouteSharingPolicy: avAudioSessionRouteSharingPolicy ??
            this.avAudioSessionRouteSharingPolicy,
        avAudioSessionSetActiveOptions: avAudioSessionSetActiveOptions ??
            this.avAudioSessionSetActiveOptions,
        androidAudioAttributes:
            androidAudioAttributes ?? this.androidAudioAttributes,
        androidAudioFocusGainType:
            androidAudioFocusGainType ?? this.androidAudioFocusGainType,
        androidWillPauseWhenDucked:
            androidWillPauseWhenDucked ?? this.androidWillPauseWhenDucked,
      );

  // Converts this instance to JSON.
  Map toJson() => {
        'avAudioSessionCategory': avAudioSessionCategory?.index,
        'avAudioSessionCategoryOptions': avAudioSessionCategoryOptions?.value,
        'avAudioSessionMode': avAudioSessionMode?.index,
        'avAudioSessionRouteSharingPolicy':
            avAudioSessionRouteSharingPolicy?.index,
        'avAudioSessionSetActiveOptions': avAudioSessionSetActiveOptions?.value,
        'androidAudioAttributes': androidAudioAttributes?.toJson(),
        'androidAudioFocusGainType': androidAudioFocusGainType.index,
        'androidWillPauseWhenDucked': androidWillPauseWhenDucked,
      };
}

/// An audio interruption event.
class AudioInterruptionEvent {
  /// Whether the interruption is beginning or ending.
  final bool begin;

  /// The type of interruption.
  final AudioInterruptionType type;

  AudioInterruptionEvent(this.begin, this.type);
}

/// The type of audio interruption.
enum AudioInterruptionType {
  /// Audio should be paused during the interruption.
  pause,

  /// Audio should be ducked during the interruption.
  duck,

  /// Audio should be paused, possibly indefinitely.
  unknown
}
