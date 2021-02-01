import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class AndroidAudioManager {
  static const MethodChannel _channel =
      const MethodChannel('com.ryanheise.android_audio_manager');
  static AndroidAudioManager? _instance;

  final _becomingNoisyEventSubject = PublishSubject<void>();
  AndroidOnAudioFocusChanged? _onAudioFocusChanged;

  factory AndroidAudioManager() {
    return _instance ??= AndroidAudioManager._();
  }

  AndroidAudioManager._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      final List args = call.arguments;
      switch (call.method) {
        case 'onAudioFocusChanged':
          if (_onAudioFocusChanged != null) {
            _onAudioFocusChanged!(AndroidAudioFocus.values[args[0]]!);
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
    return (await (_channel
        .invokeMethod<bool>('requestAudioFocus', [focusRequest.toJson()])))!;
  }

  Future<bool> abandonAudioFocus() async {
    return (await (_channel.invokeMethod<bool>('abandonAudioFocus')))!;
  }

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
          usage: AndroidAudioUsage.values[data['usage']]!,
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

  AndroidAudioFlags operator &(AndroidAudioFlags flag) =>
      AndroidAudioFlags(value & flag.value);

  bool contains(AndroidAudioFlags flags) => flags.value & value == flags.value;

  @override
  bool operator ==(Object flag) =>
      flag is AndroidAudioFlags && value == flag.value;

  int get hashCode => value.hashCode;
}

/// The content type options for [AndroidAudioAttributes].
enum AndroidAudioContentType { unknown, speech, music, movie, sonification }

/// The usage options for [AndroidAudioAttributes].
class AndroidAudioUsage {
  static const unknown = AndroidAudioUsage._(0);
  static const media = AndroidAudioUsage._(1);
  static const voiceCommunication = AndroidAudioUsage._(2);
  static const voiceCommunicationSignalling = AndroidAudioUsage._(3);
  static const alarm = AndroidAudioUsage._(4);
  static const notification = AndroidAudioUsage._(5);
  static const notificationRingtone = AndroidAudioUsage._(6);
  static const notificationCommunicationRequest = AndroidAudioUsage._(7);
  static const notificationCommunicationInstant = AndroidAudioUsage._(8);
  static const notificationCommunicationDelayed = AndroidAudioUsage._(9);
  static const notificationEvent = AndroidAudioUsage._(10);
  static const assistanceAccessibility = AndroidAudioUsage._(11);
  static const assistanceNavigationGuidance = AndroidAudioUsage._(12);
  static const assistanceSonification = AndroidAudioUsage._(13);
  static const game = AndroidAudioUsage._(14);
  static const assistant = AndroidAudioUsage._(16);
  static const values = {
    0: unknown,
    1: media,
    2: voiceCommunication,
    3: voiceCommunicationSignalling,
    4: alarm,
    5: notification,
    6: notificationRingtone,
    7: notificationCommunicationRequest,
    8: notificationCommunicationInstant,
    9: notificationCommunicationDelayed,
    10: notificationEvent,
    11: assistanceAccessibility,
    12: assistanceNavigationGuidance,
    13: assistanceSonification,
    14: game,
    16: assistant,
  };

  final int value;

  const AndroidAudioUsage._(this.value);

  @override
  bool operator ==(Object other) =>
      other is AndroidAudioUsage && value == other.value;

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
  final AndroidAudioAttributes? audioAttributes;
  final bool? willPauseWhenDucked;
  final AndroidOnAudioFocusChanged? onAudioFocusChanged;

  const AndroidAudioFocusRequest({
    required this.gainType,
    this.audioAttributes,
    this.willPauseWhenDucked,
    this.onAudioFocusChanged,
  });

  Map toJson() => {
        'gainType': gainType.index,
        'audioAttribute': audioAttributes?.toJson(),
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
