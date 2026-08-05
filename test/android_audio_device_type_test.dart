import 'package:audio_session/src/android.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ryanheise.android_audio_manager');
  int? rawType;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'getDevices') {
        throw UnsupportedError('Unexpected method: ${call.method}');
      }
      return <Map<String, Object?>>[_audioDevice(rawType)];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('decodes Android audio device types by raw platform value', () async {
    const cases = <(int?, AndroidAudioDeviceType)>[
      (26, AndroidAudioDeviceType.bleHeadset),
      (27, AndroidAudioDeviceType.bleSpeaker),
      (28, AndroidAudioDeviceType.echoReference),
      (29, AndroidAudioDeviceType.hdmiEarc),
      (30, AndroidAudioDeviceType.bleBroadcast),
      (31, AndroidAudioDeviceType.dockAnalog),
      (32, AndroidAudioDeviceType.multichannelGroup),
      (33, AndroidAudioDeviceType.bleHearingAid),
      (34, AndroidAudioDeviceType.bleCentral),
      (35, AndroidAudioDeviceType.bleCentralBroadcast),
      (-1, AndroidAudioDeviceType.unknown),
      (36, AndroidAudioDeviceType.unknown),
      (null, AndroidAudioDeviceType.unknown),
    ];

    for (final (platformValue, expectedType) in cases) {
      rawType = platformValue;

      final devices = await AndroidAudioManager().getDevices(
        AndroidGetAudioDevicesFlags.outputs,
      );

      expect(
        devices.single.type,
        expectedType,
        reason: 'raw platform value $platformValue',
      );
    }
  });

  test('sends the raw device type value when querying stream volume', () async {
    MethodCall? platformCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      platformCall = call;
      return 0.0;
    });

    await AndroidAudioManager().getStreamVolumeDb(
      AndroidStreamType.music,
      7,
      AndroidAudioDeviceType.hdmiEarc,
    );

    expect(platformCall?.method, 'getStreamVolumeDb');
    expect(platformCall?.arguments,
        <Object>[AndroidStreamType.music.index, 7, 29]);
  });
}

Map<String, Object?> _audioDevice(int? type) => <String, Object?>{
      'id': 1,
      'productName': 'Test audio device',
      'address': '',
      'isSource': false,
      'isSink': true,
      'sampleRates': <int>[48000],
      'channelMasks': <int>[],
      'channelIndexMasks': <int>[],
      'channelCounts': <int>[2],
      'encodings': <int>[],
      'type': type,
    };
