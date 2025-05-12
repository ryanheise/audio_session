import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../audio_session.dart';
import 'util.dart';

sealed class OutputAudioDevice {}

@immutable
class Speaker extends OutputAudioDevice {
  @override
  bool operator ==(Object other) => other is Speaker;

  @override
  int get hashCode => 'speaker'.hashCode;
}

@immutable
class Earpiece extends OutputAudioDevice {
  @override
  bool operator ==(Object other) => other is Earpiece;

  @override
  int get hashCode => 'earpiece'.hashCode;
}

@immutable
class Bluetooth extends OutputAudioDevice {
  Bluetooth(this.label);
  final String label;
  @override
  bool operator ==(Object other) => other is Bluetooth;

  @override
  int get hashCode => 'bluetooth'.hashCode;
}

typedef ChangedOutputsCallback = void Function(
  List<OutputAudioDevice> devices,
);
typedef ChangedCurrentOutputCallback = void Function(
  OutputAudioDevice device,
);

class AudioOutputsManager {
  AudioOutputsManager({
    AndroidAudioManager? androidAudioManager,
    AVAudioSession? avAudioSession,
  })  : _androidAudioManager = androidAudioManager,
        _avAudioSession = avAudioSession;

  final AndroidAudioManager? _androidAudioManager; 
  final AVAudioSession?
      _avAudioSession; 

  Set<OutputAudioDevice> _outputs = {};
  OutputAudioDevice? _currentOutput;

  Iterable<AndroidAudioDeviceType> _availableAndroidDeviceTypes = [];

  StreamSubscription<AVAudioSessionRouteChange>? _iosRrouteChangeSubscription;

  ChangedCurrentOutputCallback? _onChangedCurrentOutput;
  ChangedOutputsCallback? _onChangedOutputs;

  final _btTypes = [
    AndroidAudioDeviceType.bluetoothA2dp,
    AndroidAudioDeviceType.bluetoothSco,
  ];
  final _speakerTypes = [
    AndroidAudioDeviceType.builtInSpeaker,
    AndroidAudioDeviceType.builtInSpeakerSafe,
  ];

  Future<void> init({
    ChangedOutputsCallback? onChangedOutputs,
    ChangedCurrentOutputCallback? onChangedCurrentOutput,
  }) async {
    _onChangedCurrentOutput = onChangedCurrentOutput;
    _onChangedOutputs = onChangedOutputs;

    if (Platform.isIOS) {
      await _updateIosDevices();
    } else {
      await _updateAndroidDevices();
    }
    _iosRrouteChangeSubscription =
        _avAudioSession?.routeChangeStream.listen((event) async {
      await _updateIosDevices();
    });
    _androidAudioManager
        ?.setAudioDevicesAddedListener(_androidDevicesAddedListener);
    _androidAudioManager
        ?.setAudioDevicesRemovedListener(_androidDevicesRemovedListener);
  }

  Future<void> dispose() async {
    await _iosRrouteChangeSubscription?.cancel();
    _androidAudioManager?.setAudioDevicesAddedListener((_) {});
    _androidAudioManager?.setAudioDevicesRemovedListener((_) {});
    _availableAndroidDeviceTypes = [];
    _outputs = {};
    _currentOutput = null;
  }

  Future<void> switchToHeadphones() async {
    if (_androidAudioManager != null) {
      await _androidAudioManager
          .setMode(AndroidAudioHardwareMode.inCommunication);
      await _androidAudioManager.stopBluetoothSco();
      await _androidAudioManager.setBluetoothScoOn(false);
      await _androidAudioManager.setSpeakerphoneOn(false);
    } else if (_avAudioSession != null) {
      return _switchToAnyIosPortIn({AVAudioSessionPort.headsetMic});
    }
  }

  Future<void> switchToSpeaker() async {
    if (_androidAudioManager != null) {
      await _androidAudioManager.setMode(AndroidAudioHardwareMode.inCommunication);
      await _androidAudioManager.stopBluetoothSco();
      await _androidAudioManager.setBluetoothScoOn(false);
      await _androidAudioManager.setSpeakerphoneOn(true);
      _currentOutput = Speaker();
      _onChangedCurrentOutput?.call(_currentOutput!);
    } else if (_avAudioSession != null) {
      await _avAudioSession
          .overrideOutputAudioPort(AVAudioSessionPortOverride.speaker);
    }
  }

  Future<void> switchToReceiver() async {
    if (_androidAudioManager != null) {
      await _androidAudioManager
          .setMode(AndroidAudioHardwareMode.inCommunication);
      await _androidAudioManager.stopBluetoothSco();
      await _androidAudioManager.setBluetoothScoOn(false);
      await _androidAudioManager.setSpeakerphoneOn(false);
      _currentOutput = Earpiece();
      _onChangedCurrentOutput?.call(_currentOutput!);
    } else if (_avAudioSession != null) {
      await _avAudioSession
          .overrideOutputAudioPort(AVAudioSessionPortOverride.none);
      return _switchToAnyIosPortIn({AVAudioSessionPort.builtInMic});
    }
  }

  Future<void> switchToBluetooth() async {
    if (_androidAudioManager != null) {
      await _androidAudioManager
          .setMode(AndroidAudioHardwareMode.inCommunication);
      await _androidAudioManager.startBluetoothSco();
      await _androidAudioManager.setBluetoothScoOn(true);
      _currentOutput = firstWhereOrNull(_outputs, (o) => o is Bluetooth);
      if (_currentOutput != null) {
        _onChangedCurrentOutput?.call(_currentOutput!);
      }
    } else if (_avAudioSession != null) {
      return _switchToAnyIosPortIn({
        AVAudioSessionPort.bluetoothLe,
        AVAudioSessionPort.bluetoothHfp,
        AVAudioSessionPort.bluetoothA2dp,
      });
    }
  }

  Future<void> _switchToAnyIosPortIn(Set<AVAudioSessionPort> ports) async {
    for (final input in await _avAudioSession!.availableInputs) {
      if (ports.contains(input.portType)) {
        await _avAudioSession.setPreferredInput(input);
      }
    }
  }

  Future<void> _androidDevicesAddedListener(
    List<AndroidAudioDeviceInfo> devices,
  ) async {
    for (final device in devices) {
      if (_speakerTypes.contains(device.type)) {
        _outputs.add(Speaker());
      } else if (_btTypes.contains(device.type)) {
        _outputs.add(Bluetooth(device.productName));
      } else if (device.type == AndroidAudioDeviceType.builtInEarpiece) {
        _outputs.add(Earpiece());
      }
    }
    _onChangedOutputs?.call(_outputs.toList());
    unawaited(_updateAndroidActiveDevice());
  }

  Future<void> _androidDevicesRemovedListener(
    List<AndroidAudioDeviceInfo> devices,
  ) async {
    for (final device in devices) {
      if (_btTypes.contains(device.type)) {
        _outputs.removeWhere((o) => o is Bluetooth);
      } else if (_speakerTypes.contains(device.type)) {
        _outputs.removeWhere((o) => o is Speaker);
      } else if (device.type == AndroidAudioDeviceType.builtInEarpiece) {
        _outputs.removeWhere((o) => o is Earpiece);
      }
    }
    _onChangedOutputs?.call(_outputs.toList());
    unawaited(_updateAndroidActiveDevice());
  }

  Future<void> _updateIosDevices() async {
    final currentRoute = await _avAudioSession?.currentRoute;
    if (currentRoute != null) {
      _outputs.add(Speaker());
      final availableInputs = await _avAudioSession!.availableInputs;
      final currentOutputs = currentRoute.outputs;
      final currentOutput = currentOutputs.first;
      final bluetoothTypes = {
        AVAudioSessionPort.bluetoothLe,
        AVAudioSessionPort.bluetoothHfp,
        AVAudioSessionPort.bluetoothA2dp,
      };
      if (currentOutput.portType == AVAudioSessionPort.builtInReceiver) {
        _currentOutput = Earpiece();
      } else if (bluetoothTypes.contains(currentOutput.portType)) {
        _currentOutput = Bluetooth(currentOutput.portName);
      } else if (currentOutput.portType == AVAudioSessionPort.builtInSpeaker) {
        _currentOutput = Speaker();
      }
      final inputTypes = availableInputs.map((i) => i.portType);
      final hasBuiltIn = inputTypes.contains(AVAudioSessionPort.builtInMic);
      final bluetoothDevice = firstWhereOrNull(
        availableInputs,
        (i) => bluetoothTypes.contains(i.portType),
      );
      var btDevice =
          bluetoothDevice != null ? Bluetooth(bluetoothDevice.portName) : null;
      if (btDevice == null && _currentOutput is Bluetooth) {
        btDevice = _currentOutput! as Bluetooth;
      }
      _outputs = {
        Speaker(),
        if (btDevice != null) btDevice,
        if (hasBuiltIn) Earpiece(),
      };
      _onChangedOutputs?.call(_outputs.toList());
      if (_currentOutput != null) {
        _onChangedCurrentOutput?.call(_currentOutput!);
      }
    }
  }

  Future<void> _updateAndroidDevices() async {
    final androidDevices = await _androidAudioManager!.getDevices(
      AndroidGetAudioDevicesFlags.outputs,
    );
    final types = androidDevices.map((d) => d.type);
    _availableAndroidDeviceTypes = types;
    final hasSpeakerPhone = types.any(_speakerTypes.contains);
    final hasEarpiece =
        types.any((t) => t == AndroidAudioDeviceType.builtInEarpiece);
    final blutoothDevice = firstWhereOrNull(
      androidDevices,
      (d) => _btTypes.contains(d.type),
    );
    _outputs = {
      if (hasSpeakerPhone) Speaker(),
      if (blutoothDevice != null) Bluetooth(blutoothDevice.productName),
      if (hasEarpiece) Earpiece(),
    };
    _onChangedOutputs?.call(_outputs.toList());
    unawaited(_updateAndroidActiveDevice());
  }

  Future<void> _updateAndroidActiveDevice() async {
    final activeDevice = await _androidAudioManager?.getCommunicationDevice();
    if (activeDevice == null) {
      return;
    }
    final hasEarpiece = _availableAndroidDeviceTypes
        .any((t) => t == AndroidAudioDeviceType.builtInEarpiece);
    if (_btTypes.contains(activeDevice.type)) {
      _currentOutput = Bluetooth(activeDevice.productName);
    } else if (_speakerTypes.contains(activeDevice.type)) {
      _currentOutput = Speaker();
    } else if (hasEarpiece) {
      _currentOutput = Earpiece();
    }
    if (_currentOutput != null) {
      _onChangedCurrentOutput?.call(_currentOutput!);
    }
  }
}
