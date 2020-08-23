import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class AndroidAudioManager {
  static const MethodChannel _channel =
      const MethodChannel('com.ryanheise.android_audio_manager');
  static AndroidAudioManager _instance;

  final _becomingNoisyEventSubject = PublishSubject<void>();
  AndroidOnAudioFocusChanged _onAudioFocusChanged;

  factory AndroidAudioManager() {
    if (_instance == null) _instance = AndroidAudioManager._();
    return _instance;
  }

  AndroidAudioManager._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      final List args = call.arguments;
      switch (call.method) {
        case 'onAudioFocusChanged':
          if (_onAudioFocusChanged != null) {
            _onAudioFocusChanged(AndroidAudioFocus.values[args[0]]);
          }
          break;
        case 'onBecomingNoisy':
          _becomingNoisyEventSubject.add(null);
          break;
      }
    });
  }

  Stream<void> get becomingNoisyEventStream =>
      _becomingNoisyEventSubject.stream;

  Future<bool> requestAudioFocus(AndroidAudioFocusRequest focusRequest) async {
    _onAudioFocusChanged = focusRequest.onAudioFocusChanged;
    return await _channel
        .invokeMethod('requestAudioFocus', [focusRequest.toJson()]);
  }

  Future<bool> abandonAudioFocus() =>
      _channel.invokeMethod('abandonAudioFocus');

  void close() {
    _becomingNoisyEventSubject.close();
  }
}

/// Describes to the Android platform what kind of audio you intend to play.
class AndroidAudioAttributes {
  /// What type of audio you intend to play.
  final AndroidAudioContentType contentType;

  /// How the playback is to be affected.
  final AndroidAudioFlags flags;

  /// Why you intend to play the audio.
  final AndroidAudioUsage usage;

  const AndroidAudioAttributes({
    this.contentType = AndroidAudioContentType.unknown,
    this.flags = AndroidAudioFlags.none,
    this.usage = AndroidAudioUsage.unknown,
  });

  AndroidAudioAttributes.fromJson(Map data)
      : this(
          contentType: AndroidAudioContentType.values[data['contentType']],
          flags: AndroidAudioFlags(data['flags']),
          usage: AndroidAudioUsage(data['usage']),
        );

  Map toJson() => {
        'contentType': contentType.index,
        'flags': flags.value,
        'usage': usage.value,
      };

  @override
  bool operator ==(Object other) =>
      other is AndroidAudioAttributes &&
      contentType == other.contentType &&
      flags == other.flags &&
      usage == other.usage;

  int get hashCode =>
      '${contentType.index}-${flags.value}-${usage.value}'.hashCode;
}

/// The audio flags for [AndroidAudioAttributes].
class AndroidAudioFlags {
  static const AndroidAudioFlags none = AndroidAudioFlags(0);
  static const AndroidAudioFlags audibilityEnforced = AndroidAudioFlags(1 << 0);

  final int value;

  const AndroidAudioFlags(this.value);

  AndroidAudioFlags operator |(AndroidAudioFlags flag) =>
      AndroidAudioFlags(value | flag.value);

  @override
  bool operator ==(Object flag) =>
      flag is AndroidAudioFlags && value == flag.value;

  int get hashCode => value.hashCode;
}

/// The content type options for [AndroidAudioAttributes].
enum AndroidAudioContentType { unknown, speech, music, movie, sonification }

/// The usage options for [AndroidAudioAttributes].
class AndroidAudioUsage {
  static const unknown = AndroidAudioUsage(0);
  static const media = AndroidAudioUsage(1);
  static const voiceCommunication = AndroidAudioUsage(2);
  static const voiceCommunicationSignalling = AndroidAudioUsage(3);
  static const alarm = AndroidAudioUsage(4);
  static const notification = AndroidAudioUsage(5);
  static const notificationRingtone = AndroidAudioUsage(6);
  static const notificationCommunicationRequest = AndroidAudioUsage(7);
  static const notificationCommunicationInstant = AndroidAudioUsage(8);
  static const notificationCommunicationDelayed = AndroidAudioUsage(9);
  static const notificationEvent = AndroidAudioUsage(10);
  static const assistanceAccessibility = AndroidAudioUsage(11);
  static const assistanceNavigationGuidance = AndroidAudioUsage(12);
  static const assistanceSonification = AndroidAudioUsage(13);
  static const game = AndroidAudioUsage(14);
  static const assistant = AndroidAudioUsage(16);

  final int value;

  const AndroidAudioUsage(this.value);

  @override
  bool operator ==(Object other) =>
      other is AndroidAudioFlags && value == other.value;

  int get hashCode => value.hashCode;
}

class AndroidAudioFocusGainType {
  static const gain = AndroidAudioFocusGainType._(1);
  static const gainTransient = AndroidAudioFocusGainType._(2);
  static const gainTransientMayDuck = AndroidAudioFocusGainType._(3);
  static const gainTransientExclusive = AndroidAudioFocusGainType._(4);
  static const values = {
    1: gain,
    2: gainTransient,
    3: gainTransientMayDuck,
    4: gainTransientExclusive,
  };

  final int index;

  const AndroidAudioFocusGainType._(this.index);
}

class AndroidAudioFocusRequest {
  final AndroidAudioFocusGainType gainType;
  final AndroidAudioAttributes audioAttributes;
  final bool willPauseWhenDucked;
  final AndroidOnAudioFocusChanged onAudioFocusChanged;

  const AndroidAudioFocusRequest({
    @required this.gainType,
    this.audioAttributes,
    this.willPauseWhenDucked,
    this.onAudioFocusChanged,
  }) : assert(gainType != null);

  Map toJson() => {
        'gainType': gainType.index,
        'audioAttribute': audioAttributes.toJson(),
        'willPauseWhenDucked': willPauseWhenDucked,
      };
}

typedef AndroidOnAudioFocusChanged = void Function(AndroidAudioFocus focus);

class AndroidAudioFocus {
  static const gain = AndroidAudioFocus._(1);
  static const loss = AndroidAudioFocus._(-1);
  static const lossTransient = AndroidAudioFocus._(-2);
  static const lossTransientCanDuck = AndroidAudioFocus._(-3);
  static const values = {
    1: gain,
    -1: loss,
    -2: lossTransient,
    -3: lossTransientCanDuck,
  };

  final int index;

  const AndroidAudioFocus._(this.index);
}
