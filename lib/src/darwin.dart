import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class AVAudioSession {
  static final MethodChannel _channel =
      const MethodChannel('com.ryanheise.av_audio_session');
  static AVAudioSession _instance;

  final _interruptionNotificationSubject =
      PublishSubject<AVAudioSessionInterruptionNotification>();
  final _becomingNoisyEventSubject = PublishSubject<void>();
  final _routeChangeSubject = PublishSubject<AVAudioSessionRouteChange>();
  final _silenceSecondaryAudioHintSubject =
      PublishSubject<AVAudioSessionSilenceSecondaryAudioHintType>();
  final _mediaServicesWereLostSubject = PublishSubject<void>();
  final _mediaServicesWereResetSubject = PublishSubject<void>();

  factory AVAudioSession() {
    if (_instance == null) _instance = AVAudioSession._();
    return _instance;
  }

  AVAudioSession._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      final List args = call.arguments;
      switch (call.method) {
        case 'onInterruptionEvent':
          _interruptionNotificationSubject
              .add(AVAudioSessionInterruptionNotification(
            type: AVAudioSessionInterruptionType.values[args[0]],
            options: AVAudioSessionInterruptionOptions(args[1]),
          ));
          break;
        case 'onRouteChange':
          AVAudioSessionRouteChange routeChange = AVAudioSessionRouteChange(
              AVAudioSessionRouteChangeReason.values[args[0]], args[1]);
          _routeChangeSubject.add(routeChange);
          if (routeChange.shouldInterrupt) {
            _becomingNoisyEventSubject.add(null);
          }
          break;
        case 'onSilenceSecondaryAudioHint':
          _silenceSecondaryAudioHintSubject
              .add(AVAudioSessionSilenceSecondaryAudioHintType.values[args[0]]);
          break;
        case 'onMediaServicesWereLost':
          _mediaServicesWereLostSubject.add(null);
          break;
        case 'onMediaServicesWereReset':
          _mediaServicesWereResetSubject.add(null);
          break;
      }
    });
  }

  Stream<AVAudioSessionInterruptionNotification>
      get interruptionNotificationStream =>
          _interruptionNotificationSubject.stream;

  Stream<void> get becomingNoisyEventStream =>
      _becomingNoisyEventSubject.stream;

  Stream<AVAudioSessionRouteChange> get routeChangeReasonStream =>
      _routeChangeSubject.stream;

  Stream<AVAudioSessionSilenceSecondaryAudioHintType>
      get silenceSecondaryAudioHintStream =>
          _silenceSecondaryAudioHintSubject.stream;

  Stream<void> get mediaServicesWereLostStream =>
      _mediaServicesWereLostSubject.stream;

  Stream<void> get mediaServicesWereResetStream =>
      _mediaServicesWereResetSubject.stream;

  Future<AVAudioSessionCategory> get category async {
    final int index = await _channel.invokeMethod('getCategory');
    return index == null ? null : AVAudioSessionCategory.values[index];
  }

  Future<void> setCategory(
    AVAudioSessionCategory category, [
    AVAudioSessionCategoryOptions options,
    AVAudioSessionMode mode,
    AVAudioSessionRouteSharingPolicy policy,
  ]) =>
      _channel.invokeMethod('setCategory',
          [category?.index, options?.value, mode?.index, policy?.index]);

  Future<List<AVAudioSessionCategory>> get availableCategories async =>
      ((await _channel.invokeMethod('getAvailableCategories')) as List<dynamic>)
          ?.map((index) => AVAudioSessionCategory.values[index as int])
          ?.toList();

  Future<AVAudioSessionCategoryOptions> get categoryOptions async {
    final int value = await _channel.invokeMethod('getCategoryOptions');
    return value == null ? null : AVAudioSessionCategoryOptions(value);
  }

  Future<AVAudioSessionMode> get mode async {
    final int index = await _channel.invokeMethod('getMode');
    return index == null ? null : AVAudioSessionMode.values[index];
  }

  Future<void> setMode(AVAudioSessionMode mode) =>
      _channel.invokeMethod('setMode', [mode.index]);

  Future<List<AVAudioSessionMode>> get availableModes async =>
      ((await _channel.invokeMethod('getAvailableModes')) as List<dynamic>)
          ?.map((index) => AVAudioSessionMode.values[index as int])
          ?.toList();

  Future<AVAudioSessionRouteSharingPolicy> get routeSharingPolicy async {
    final int index = await _channel.invokeMethod('getRouteSharingPolicy');
    return index == null
        ? null
        : AVAudioSessionRouteSharingPolicy.values[index];
  }

  Future<bool> setActive(bool active,
          {AVAudioSessionSetActiveOptions avOptions}) =>
      _channel.invokeMethod('setActive', [active, avOptions?.value]);

  Future<AVAudioSessionRecordPermission> get recordPermission async {
    final int index = await _channel.invokeMethod('getRecordPermission');
    return index == null ? null : AVAudioSessionRecordPermission.values[index];
  }

  Future<bool> requestRecordPermission() =>
      _channel.invokeMethod('requestRecordPermission');

  Future<bool> get isOtherAudioPlaying =>
      _channel.invokeMethod('isOtherAudioPlaying');

  Future<bool> get secondaryAudioShouldBeSilencedHint =>
      _channel.invokeMethod('getSecondaryAudioShouldBeSilencedHint');

  Future<bool> get allowHapticsAndSystemSoundsDuringRecording =>
      _channel.invokeMethod('getAllowHapticsAndSystemSoundsDuringRecording');

  Future<void> setAllowHapticsAndSystemSoundsDuringRecording(bool allow) =>
      _channel.invokeMethod(
          "setAllowHapticsAndSystemSoundsDuringRecording", [allow]);

  Future<AVAudioSessionPromptStyle> get promptStyle async {
    int index = await _channel.invokeMethod('getPromptStyle');
    return index == null ? null : AVAudioSessionPromptStyle.values[index];
  }

  //Future<AVAudioSessionRouteDescription> get currentRoute async {
  //  return null;
  //}

  //Future<List<AVAudioSessionPortDescription>> get availableInputs async {
  //  return null;
  //}

  //Future<AVAudioSessionPortDescription> get preferredInput {
  //  return null;
  //}

  //Future<void> setPreferredInput(AVAudioSessionPortDescription input) async {}

  //Future<AVAudioSessionDataSourceDescription> get inputDataSource async {
  //  return null;
  //}

  //Future<List<AVAudioSessionDataSourceDescription>> get inputDataSources async {
  //  return null;
  //}

  //Future<void> setInputDataSource(
  //    AVAudioSessionDataSourceDescription input) async {}

  //Future<List<AVAudioSessionDataSourceDescription>>
  //    get outputDataSources async {
  //  return null;
  //}

  //Future<AVAudioSessionDataSourceDescription> get outputDataSource async {
  //  return null;
  //}

  //Future<void> setOutputDataSource(
  //    AVAudioSessionDataSourceDescription output) async {}

  //Future<void> overrideOutputAudioPort(
  //    AVAudioSessionPortOverride portOverride) async {}

  //Future<AVPreparePlaybackRouteResult>
  //    prepareRouteSelectionForPlayback() async {
  //  return null;
  //}

  //Future<AVAudioStereoOrientation> get inputOrientation async {
  //  return null;
  //}

  //Future<AVAudioStereoOrientation> get preferredInputOrientation async {
  //  return null;
  //}

  //Future<void> setPreferredInputOrientation(
  //    AVAudioStereoOrientation orientation) async {}

  //Future<int> get inputNumberOfChannels async {
  //  return 1;
  //}

  //Future<int> get maximumInputNumberOfChannels async {
  //  return 2;
  //}

  //Future<int> get preferredInputNumberOfChannels async {
  //  return 1;
  //}

  //Future<void> setPreferredInputNumberOfChannels(int count) async {}

  //Future<int> get outputNumberOfChannels async {
  //  return 2;
  //}

  //Future<int> get maximumOutputNumberOfChannels async {
  //  return 2;
  //}

  //Future<int> get preferredOutputNumberOfChannels async {
  //  return 2;
  //}

  //Future<void> setPreferredOutputNumberOfChannels(int count) async {}

  //Future<double> get inputGain async {
  //  // TODO: key/value observing
  //  return 0.5;
  //}

  //Future<bool> get inputGainSettable async {
  //  return false;
  //}

  //Future<void> setInputGame(double gain) async {}

  //Future<double> get outputVolume async {
  //  return 1.0;
  //}

  //Future<double> get sampleRate async {
  //  return 48000.0;
  //}

  //Future<double> get preferredSampleRate async {
  //  return 48000.0;
  //}

  //Future<void> setPreferredSampleRate(double rate) async {}

  //Future<Duration> get inputLatency async {
  //  return Duration.zero;
  //}

  //Future<Duration> get outputLatency async {
  //  return Duration.zero;
  //}

  //Future<Duration> get ioBufferDuration async {
  //  return Duration.zero;
  //}

  //Future<Duration> get preferredIoBufferDuration async {
  //  return Duration.zero;
  //}

  //Future<void> setPreferredIoBufferDuration(Duration duration) async {}

  //Future<bool> setAggregatedIoPreference(AVAudioSessionIOType type) async {
  //  return true;
  //}

}

/// The categories for [AVAudioSession].
enum AVAudioSessionCategory {
  ambient,
  soloAmbient,
  playback,
  record,
  playAndRecord,
  multiRoute,
}

/// The category options for [AVAudioSession].
class AVAudioSessionCategoryOptions {
  static const AVAudioSessionCategoryOptions none =
      const AVAudioSessionCategoryOptions(0);
  static const AVAudioSessionCategoryOptions mixWithOthers =
      const AVAudioSessionCategoryOptions(0x1);
  static const AVAudioSessionCategoryOptions duckOthers =
      const AVAudioSessionCategoryOptions(0x2);
  static const AVAudioSessionCategoryOptions
      interruptSpokenAudioAndMixWithOthers =
      const AVAudioSessionCategoryOptions(0x11);
  static const AVAudioSessionCategoryOptions allowBluetooth =
      const AVAudioSessionCategoryOptions(0x4);
  static const AVAudioSessionCategoryOptions allowBluetoothA2dp =
      const AVAudioSessionCategoryOptions(0x20);
  static const AVAudioSessionCategoryOptions allowAirPlay =
      const AVAudioSessionCategoryOptions(0x40);
  static const AVAudioSessionCategoryOptions defaultToSpeaker =
      const AVAudioSessionCategoryOptions(0x8);

  final int value;

  const AVAudioSessionCategoryOptions(this.value);

  AVAudioSessionCategoryOptions operator |(
          AVAudioSessionCategoryOptions option) =>
      AVAudioSessionCategoryOptions(value | option.value);

  AVAudioSessionCategoryOptions operator &(
          AVAudioSessionCategoryOptions option) =>
      AVAudioSessionCategoryOptions(value & option.value);

  bool contains(AVAudioSessionInterruptionOptions options) =>
      options.value & value == options.value;

  @override
  bool operator ==(Object option) =>
      option is AVAudioSessionCategoryOptions && value == option.value;

  int get hashCode => value.hashCode;
}

/// The modes for [AVAudioSession].
enum AVAudioSessionMode {
  defaultMode,
  gameChat,
  measurement,
  moviePlayback,
  spokenAudio,
  videoChat,
  videoRecording,
  voiceChat,
  voicePrompt,
}

/// The route sharing policies for [AVAudioSession].
enum AVAudioSessionRouteSharingPolicy {
  defaultPolicy,
  longFormAudio,
  longFormVideo,
  independent,
}

/// The options for [AVAudioSession.setActive].
class AVAudioSessionSetActiveOptions {
  static const AVAudioSessionSetActiveOptions none =
      const AVAudioSessionSetActiveOptions(0);
  static const AVAudioSessionSetActiveOptions notifyOthersOnDeactivation =
      const AVAudioSessionSetActiveOptions(1);

  final int value;

  const AVAudioSessionSetActiveOptions(this.value);

  AVAudioSessionSetActiveOptions operator |(
          AVAudioSessionSetActiveOptions option) =>
      AVAudioSessionSetActiveOptions(value | option.value);

  AVAudioSessionSetActiveOptions operator &(
          AVAudioSessionSetActiveOptions option) =>
      AVAudioSessionSetActiveOptions(value & option.value);

  bool contains(AVAudioSessionInterruptionOptions options) =>
      options.value & value == options.value;

  @override
  bool operator ==(Object option) =>
      option is AVAudioSessionSetActiveOptions && value == option.value;

  int get hashCode => value.hashCode;
}

/// The permissions for [AVAudioSession].
enum AVAudioSessionRecordPermission { undetermined, denied, granted }

/// The prompt styles for [AVAudioSession].
enum AVAudioSessionPromptStyle { none, short, normal }

/// Details of an interruption in [AVAudioSession].
class AVAudioSessionInterruptionNotification {
  final AVAudioSessionInterruptionType type;
  final AVAudioSessionInterruptionOptions options;

  AVAudioSessionInterruptionNotification({
    @required this.type,
    @required this.options,
  });
}

/// The interruption types for [AVAudioSessionInterruptionNotification].
enum AVAudioSessionInterruptionType { began, ended }

/// The interruption options for [AVAudioSessionInterruptionNotification].
class AVAudioSessionInterruptionOptions {
  static const AVAudioSessionInterruptionOptions none =
      const AVAudioSessionInterruptionOptions(0);
  static const AVAudioSessionInterruptionOptions shouldResume =
      const AVAudioSessionInterruptionOptions(1);

  final int value;

  const AVAudioSessionInterruptionOptions(this.value);

  AVAudioSessionInterruptionOptions operator |(
          AVAudioSessionInterruptionOptions option) =>
      AVAudioSessionInterruptionOptions(value | option.value);

  AVAudioSessionInterruptionOptions operator &(
          AVAudioSessionInterruptionOptions option) =>
      AVAudioSessionInterruptionOptions(value & option.value);

  bool contains(AVAudioSessionInterruptionOptions options) =>
      options.value & value == options.value;

  @override
  bool operator ==(Object option) =>
      option is AVAudioSessionInterruptionOptions && value == option.value;

  int get hashCode => value.hashCode;
}

/// Temporary class to encapsulate the [AVAudioSessionRouteChangeReason] and
/// a boolean to indicate if a previous route dropped had headphones port.
/// Not according to documentation.
class AVAudioSessionRouteChange {
  final AVAudioSessionRouteChangeReason routeChangeReason;
  final int _shouldInterrupt;

  const AVAudioSessionRouteChange(
      this.routeChangeReason, this._shouldInterrupt);

  bool intToBool(int a) => a == 0 ? false : true;

  bool get shouldInterrupt => intToBool(_shouldInterrupt);
}

/// The route change reasons for [AVAudioSession].
enum AVAudioSessionRouteChangeReason {
  unknown,
  newDeviceAvailable,
  oldDeviceUnavailable,
  categoryChange,
  override,
  wakeFromSleep,
  noSuitableRouteForCategory,
  routeConfigurationChange,
}

/// The interruption types for [AVAudioSessionSilenceSecondaryAudioHint].
enum AVAudioSessionSilenceSecondaryAudioHintType { began, end }

//class AVAudioSessionRouteDescription {
//  final List<AVAudioSessionPortDescription> inputs;
//  final List<AVAudioSessionPortDescription> outputs;
//
//  AVAudioSessionRouteDescription(this.inputs, this.outputs);
//}
//
//class AVAudioSessionPortDescription {
//  MethodChannel _channel;
//  // TODO: https://developer.apple.com/documentation/avfoundation/avaudiosessionportdescription?language=objc
//  final String portName;
//  final AVAudioSessionPort portType;
//  final List<AVAudioSessionChannelDescription> channels;
//  final String uid;
//  final bool hasHardwareVoiceCallProcessing;
//  final List<AVAudioSessionDataSourceDescription> dataSources;
//  final AVAudioSessionDataSourceDescription selectedDataSource;
//  AVAudioSessionDataSourceDescription _preferredDataSource;
//
//  AVAudioSessionPortDescription(
//    this._channel,
//    this.portName,
//    this.portType,
//    this.channels,
//    this.uid,
//    this.hasHardwareVoiceCallProcessing,
//    this.dataSources,
//    this.selectedDataSource,
//    this._preferredDataSource,
//  );
//
//  AVAudioSessionDataSourceDescription get preferredDataSource =>
//      _preferredDataSource;
//
//  Future<bool> setPreferredDataSource(
//      AVAudioSessionDataSourceDescription dataSource) async {
//    final success = await _channel
//        ?.invokeMethod('setPreferredDataSource', [portName, dataSource]);
//    if (success) {
//      _preferredDataSource = dataSource;
//    }
//    return success;
//  }
//}
//
//enum AVAudioSessionPort {
//  builtInMic,
//  headsetMic,
//  lineIn,
//  airPlay,
//  bluetoothA2DP,
//  bluetoothLE,
//  builtInReceiver,
//  builtInSpeaker,
//  hDMI,
//  headphones,
//  lineOut,
//  aVB,
//  bluetoothHFP,
//  displayPort,
//  carAudio,
//  fireWire,
//  pCI,
//  thunderbolt,
//  uSBAudio,
//  virtual,
//}
//
//class AVAudioSessionChannelDescription {
//  final String name;
//  final int number;
//  final String owningPortUid;
//  final int label;
//
//  AVAudioSessionChannelDescription(
//    this.name,
//    this.number,
//    this.owningPortUid,
//    this.label,
//  );
//}
//
//class AVAudioSessionDataSourceDescription {
//  // TODO: https://developer.apple.com/documentation/avfoundation/avaudiosessiondatasourcedescription?language=objc
//  final MethodChannel _channel;
//  final num id;
//  final String name;
//  final AVAudioSessionLocation location;
//  final AVAudioSessionOrientation orientation;
//  final AVAudioSessionPolarPattern selectedPolarPattern;
//  final List<AVAudioSessionPolarPattern> supportedPolarPatterns;
//  AVAudioSessionPolarPattern _preferredPolarPattern;
//
//  AVAudioSessionDataSourceDescription(
//    this._channel,
//    this.id,
//    this.name,
//    this.location,
//    this.orientation,
//    this.selectedPolarPattern,
//    this.supportedPolarPatterns,
//    this._preferredPolarPattern,
//  );
//
//  AVAudioSessionPolarPattern get preferredPolarPattern =>
//      _preferredPolarPattern;
//
//  Future<bool> setPreferredPolarPattern(
//      AVAudioSessionPolarPattern pattern) async {
//    final success = await _channel
//        ?.invokeMethod('setPreferredPolarPattern', [name, pattern.index]);
//    if (success) {
//      _preferredPolarPattern = pattern;
//    }
//    return success;
//  }
//}
//
//enum AVAudioSessionLocation { lower, upper }
//
//enum AVAudioSessionOrientation { top, bottom, front, back, left, right }
//
//enum AVAudioSessionPolarPattern {
//  stereo,
//  cardioid,
//  subcardioid,
//  omnidirectional,
//}
//
//enum AVAudioSessionPortOverride { none, speaker }
//
//class AVPreparePlaybackRouteResult {
//  final bool shouldStartPlayback;
//  final AVAudioSessionRouteSelection routeSelection;
//
//  AVPreparePlaybackRouteResult(this.shouldStartPlayback, this.routeSelection);
//}
//
//enum AVAudioSessionRouteSelection { none, local, externalSelection }
//
//enum AVAudioStereoOrientation {
//  none,
//  portrait,
//  portraitUpsideDown,
//  landscapeLeft,
//  landscapeRight,
//}
//
//enum AVAudioSessionIOType { notSpecified, aggregated }
