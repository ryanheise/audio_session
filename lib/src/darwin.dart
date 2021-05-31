import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class AVAudioSession {
  static final MethodChannel _channel =
      const MethodChannel('com.ryanheise.av_audio_session');
  static AVAudioSession? _instance;

  final _interruptionNotificationSubject =
      PublishSubject<AVAudioSessionInterruptionNotification>();
  final _routeChangeSubject = PublishSubject<AVAudioSessionRouteChange>();
  final _silenceSecondaryAudioHintSubject =
      PublishSubject<AVAudioSessionSilenceSecondaryAudioHintType>();
  final _mediaServicesWereLostSubject = PublishSubject<void>();
  final _mediaServicesWereResetSubject = PublishSubject<void>();

  factory AVAudioSession() {
    if (kIsWeb || !Platform.isIOS) {
      throw Exception('AVAudioSession is supported only on iOS');
    }
    return _instance ??= AVAudioSession._();
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
            wasSuspended: args[2],
          ));
          break;
        case 'onRouteChange':
          AVAudioSessionRouteChange routeChange = AVAudioSessionRouteChange(
              reason: AVAudioSessionRouteChangeReason.values[args[0]]);
          _routeChangeSubject.add(routeChange);
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

  Stream<AVAudioSessionRouteChange> get routeChangeStream =>
      _routeChangeSubject.stream;

  Stream<AVAudioSessionSilenceSecondaryAudioHintType>
      get silenceSecondaryAudioHintStream =>
          _silenceSecondaryAudioHintSubject.stream;

  Stream<void> get mediaServicesWereLostStream =>
      _mediaServicesWereLostSubject.stream;

  Stream<void> get mediaServicesWereResetStream =>
      _mediaServicesWereResetSubject.stream;

  Future<AVAudioSessionCategory> get category async {
    final index = (await (_channel.invokeMethod<int>('getCategory')))!;
    return AVAudioSessionCategory.values[index];
  }

  Future<void> setCategory(
    AVAudioSessionCategory? category, [
    AVAudioSessionCategoryOptions? options,
    AVAudioSessionMode? mode,
    AVAudioSessionRouteSharingPolicy? policy,
  ]) =>
      _channel.invokeMethod('setCategory',
          [category?.index, options?.value, mode?.index, policy?.index]);

  Future<List<AVAudioSessionCategory>> get availableCategories async =>
      (await _channel.invokeMethod<List<dynamic>>('getAvailableCategories'))!
          .cast<int>()
          .map((index) => AVAudioSessionCategory.values[index])
          .toList();

  Future<AVAudioSessionCategoryOptions> get categoryOptions async {
    final value = (await (_channel.invokeMethod<int>('getCategoryOptions')))!;
    return AVAudioSessionCategoryOptions(value);
  }

  Future<AVAudioSessionMode> get mode async {
    final index = (await (_channel.invokeMethod<int>('getMode')))!;
    return AVAudioSessionMode.values[index];
  }

  Future<void> setMode(AVAudioSessionMode mode) =>
      _channel.invokeMethod('setMode', [mode.index]);

  Future<List<AVAudioSessionMode>> get availableModes async => (await _channel
          .invokeMethod<List<AVAudioSessionMode>>('getAvailableModes'))!
      .map((index) => AVAudioSessionMode.values[index as int])
      .toList();

  Future<AVAudioSessionRouteSharingPolicy?> get routeSharingPolicy async {
    // TODO: Use this code without the '?' once a Dart bug is fixed.
    // (similar instances occur elsewhere)
    //final index = await _channel.invokeMethod<int>('getRouteSharingPolicy');
    final index = await _channel.invokeMethod<int?>('getRouteSharingPolicy');
    return index == null
        ? null
        : AVAudioSessionRouteSharingPolicy.values[index];
  }

  Future<bool> setActive(bool active,
          {AVAudioSessionSetActiveOptions? avOptions}) async =>
      (await _channel
          .invokeMethod<bool>('setActive', [active, avOptions?.value]))!;

  Future<AVAudioSessionRecordPermission> get recordPermission async {
    final index = (await (_channel.invokeMethod<int>('getRecordPermission')))!;
    return AVAudioSessionRecordPermission.values[index];
  }

  Future<bool> requestRecordPermission() async =>
      (await _channel.invokeMethod<bool>('requestRecordPermission'))!;

  Future<bool> get isOtherAudioPlaying async =>
      (await _channel.invokeMethod<bool>('isOtherAudioPlaying'))!;

  Future<bool> get secondaryAudioShouldBeSilencedHint async => (await _channel
      .invokeMethod<bool>('getSecondaryAudioShouldBeSilencedHint'))!;

  Future<bool> get allowHapticsAndSystemSoundsDuringRecording async =>
      (await _channel.invokeMethod<bool>(
          'getAllowHapticsAndSystemSoundsDuringRecording'))!;

  Future<void> setAllowHapticsAndSystemSoundsDuringRecording(bool allow) =>
      _channel.invokeMethod(
          "setAllowHapticsAndSystemSoundsDuringRecording", [allow]);

  Future<AVAudioSessionPromptStyle?> get promptStyle async {
    // TODO: Use this code without the '?' once a Dart bug is fixed.
    // (similar instances occur elsewhere)
    //final index = await _channel.invokeMethod<int>('getPromptStyle');
    final index = await _channel.invokeMethod<int?>('getPromptStyle');
    return index == null ? null : AVAudioSessionPromptStyle.values[index];
  }

  Future<AVAudioSessionRouteDescription> get currentRoute async {
    return AVAudioSessionRouteDescription._fromMap(_channel,
        (await _channel.invokeMapMethod<String, dynamic>('getCurrentRoute'))!);
  }

  Future<List<AVAudioSessionPortDescription>> get availableInputs async {
    return (await _channel.invokeListMethod<dynamic>('availableInputs'))!
        .map((dynamic raw) =>
            AVAudioSessionPortDescription._fromMap(_channel, raw))
        .toList();
  }

  //Future<AVAudioSessionPortDescription> get preferredInput {
  //  return null;
  //}

  Future<void> setPreferredInput(AVAudioSessionPortDescription input) =>
      _channel.invokeMethod('setPreferredInput', [input._toMap()]);

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

  Future<void> overrideOutputAudioPort(
          AVAudioSessionPortOverride portOverride) =>
      _channel.invokeMethod('overrideOutputAudioPort', [portOverride.index]);

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

  Future<Duration> get inputLatency async {
    return Duration(
        microseconds: (await _channel.invokeMethod<int>('inputLatency'))!);
  }

  Future<Duration> get outputLatency async {
    return Duration(
        microseconds: (await _channel.invokeMethod<int>('outputLatency'))!);
  }

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

  /// This will be `null` prior to iOS 10.3.
  final bool? wasSuspended;

  AVAudioSessionInterruptionNotification({
    required this.type,
    required this.options,
    required this.wasSuspended,
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

class AVAudioSessionRouteChange {
  final AVAudioSessionRouteChangeReason reason;
  // add everything else later
  // AVAudioSessionRouteDescription? previousRoute;
  // NOTE: Maybe the Flutter side can just cache the previous
  // route without needing to send it over the platform
  // channel on a notification.

  AVAudioSessionRouteChange({required this.reason});
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
enum AVAudioSessionSilenceSecondaryAudioHintType { end, begin }

class AVAudioSessionRouteDescription {
  final List<AVAudioSessionPortDescription> inputs;
  final List<AVAudioSessionPortDescription> outputs;

  AVAudioSessionRouteDescription({required this.inputs, required this.outputs});
  static AVAudioSessionRouteDescription _fromMap(
          MethodChannel channel, Map<String, dynamic> map) =>
      AVAudioSessionRouteDescription(
        inputs: (map['inputs'] as List<dynamic>)
            .map((raw) => AVAudioSessionPortDescription._fromMap(channel, raw))
            .toList(),
        outputs: (map['outputs'] as List<dynamic>)
            .map((raw) => AVAudioSessionPortDescription._fromMap(channel, raw))
            .toList(),
      );
}

class AVAudioSessionPortDescription {
  MethodChannel _channel;
  // TODO: https://developer.apple.com/documentation/avfoundation/avaudiosessionportdescription?language=objc
  final String portName;
  final AVAudioSessionPort portType;
  final List<AVAudioSessionChannelDescription> channels;
  final String uid;
  final bool hasHardwareVoiceCallProcessing;
  final List<AVAudioSessionDataSourceDescription>? dataSources;
  final AVAudioSessionDataSourceDescription? selectedDataSource;
  AVAudioSessionDataSourceDescription? _preferredDataSource;

  AVAudioSessionPortDescription({
    required MethodChannel channel,
    required this.portName,
    required this.portType,
    required this.channels,
    required this.uid,
    required this.hasHardwareVoiceCallProcessing,
    required this.dataSources,
    required this.selectedDataSource,
    required AVAudioSessionDataSourceDescription? preferredDataSource,
  })  : _channel = channel,
        _preferredDataSource = preferredDataSource;

  AVAudioSessionDataSourceDescription? get preferredDataSource =>
      _preferredDataSource;

  //Future<bool> setPreferredDataSource(
  //    AVAudioSessionDataSourceDescription dataSource) async {
  //  final success = await _channel
  //      ?.invokeMethod('setPreferredDataSource', [portName, dataSource]);
  //  if (success) {
  //    _preferredDataSource = dataSource;
  //  }
  //  return success;
  //}

  static AVAudioSessionPortDescription _fromMap(
          MethodChannel channel, Map<String, dynamic> map) =>
      AVAudioSessionPortDescription(
        channel: channel,
        portName: map['portName'],
        portType: AVAudioSessionPort.values[map['portType']],
        channels: [],
        uid: map['uid'],
        hasHardwareVoiceCallProcessing: map['hasHardwareVoiceCallProcessing'],
        dataSources: (map['dataSources'] as List<dynamic>?)
            ?.map((raw) =>
                AVAudioSessionDataSourceDescription._fromMap(channel, raw))
            .toList(),
        selectedDataSource: map['selectedDataSource'] == null
            ? null
            : AVAudioSessionDataSourceDescription._fromMap(
                channel, map['selectedDataSource']),
        preferredDataSource: map['preferredDataSource'] == null
            ? null
            : AVAudioSessionDataSourceDescription._fromMap(
                channel, map['preferredDataSource']),
      );

  Map<String, dynamic> _toMap() => {
        'portName': portName,
        'portType': portType.index,
        'channels': channels.map((channel) => channel._toMap()).toList(),
        'uid': uid,
        'hasHardwareVoiceCallProcessing': hasHardwareVoiceCallProcessing,
        'dataSources': dataSources?.map((source) => source._toMap())?.toList(),
        'selectedDataSource': selectedDataSource?._toMap(),
        'preferredDataSource': preferredDataSource?._toMap(),
      };
}

enum AVAudioSessionPort {
  builtInMic,
  headsetMic,
  lineIn,
  airPlay,
  bluetoothA2dp,
  bluetoothLe,
  builtInReceiver,
  builtInSpeaker,
  hdmi,
  headphones,
  lineOut,
  avb,
  bluetoothHfp,
  displayPort,
  carAudio,
  fireWire,
  pci,
  thunderbolt,
  usbAudio,
  virtual,
}

class AVAudioSessionChannelDescription {
  final String name;
  final int number;
  final String owningPortUid;
  final int label;

  AVAudioSessionChannelDescription(
    this.name,
    this.number,
    this.owningPortUid,
    this.label,
  );

  Map<String, dynamic> _toMap() => {
        'name': name,
        'number': number,
        'owningPortUid': owningPortUid,
        'label': label,
      };
}

class AVAudioSessionDataSourceDescription {
  // TODO: https://developer.apple.com/documentation/avfoundation/avaudiosessiondatasourcedescription?language=objc
  final MethodChannel _channel;
  final int id;
  final String name;
  final AVAudioSessionLocation? location;
  final AVAudioSessionOrientation? orientation;
  final AVAudioSessionPolarPattern? selectedPolarPattern;
  final List<AVAudioSessionPolarPattern>? supportedPolarPatterns;
  final AVAudioSessionPolarPattern? _preferredPolarPattern;

  AVAudioSessionDataSourceDescription({
    required MethodChannel channel,
    required this.id,
    required this.name,
    required this.location,
    required this.orientation,
    required this.selectedPolarPattern,
    required this.supportedPolarPatterns,
    required AVAudioSessionPolarPattern? preferredPolarPattern,
  })  : _channel = channel,
        _preferredPolarPattern = preferredPolarPattern;

  AVAudioSessionPolarPattern? get preferredPolarPattern =>
      _preferredPolarPattern;

  //Future<bool> setPreferredPolarPattern(
  //    AVAudioSessionPolarPattern pattern) async {
  //  final success = await _channel
  //      ?.invokeMethod('setPreferredPolarPattern', [name, pattern.index]);
  //  if (success) {
  //    _preferredPolarPattern = pattern;
  //  }
  //  return success;
  //}

  static AVAudioSessionDataSourceDescription _fromMap(
          MethodChannel channel, Map<String, dynamic> map) =>
      AVAudioSessionDataSourceDescription(
        channel: channel,
        id: map['id'],
        name: map['name'],
        location: map['location'] == null
            ? null
            : AVAudioSessionLocation.values[map['location']],
        orientation: map['orientation'] == null
            ? null
            : AVAudioSessionOrientation.values[map['orientation']],
        selectedPolarPattern: map['selectedPolarPattern'] == null
            ? null
            : AVAudioSessionPolarPattern.values[map['selectedPolarPattern']],
        supportedPolarPatterns:
            (map['supportedPolarPatterns'] as List<dynamic>?)
                ?.map((index) => AVAudioSessionPolarPattern.values[index])
                .toList(),
        preferredPolarPattern: map['preferredPolarPattern'] == null
            ? null
            : AVAudioSessionPolarPattern.values[map['preferredPolarPattern']],
      );

  Map<String, dynamic> _toMap() => {
        'id': id,
        'name': name,
        'location': location?.index,
        'orientation': orientation?.index,
        'selectedPolarPattern': selectedPolarPattern?.index,
        'supportedPolarPatterns':
            supportedPolarPatterns?.map((pattern) => pattern.index).toList(),
        'preferredPolarPattern': preferredPolarPattern?.index,
      };
}

enum AVAudioSessionLocation { lower, upper }

enum AVAudioSessionOrientation { top, bottom, front, back, left, right }

enum AVAudioSessionPolarPattern {
  stereo,
  cardioid,
  subcardioid,
  omnidirectional,
}

enum AVAudioSessionPortOverride { none, speaker }

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
