import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AudioSwitcher extends StatefulWidget {
  final AudioSession session;
  const AudioSwitcher({super.key, required this.session});

  @override
  State<AudioSwitcher> createState() => _AudioSwitcherState();
}

class _AudioSwitcherState extends State<AudioSwitcher> {
  Set<OutputAudioDevice> _outputs = {};
  OutputAudioDevice? _currentOutput;

  final _btTypes = [
    AndroidAudioDeviceType.bluetoothA2dp,
    AndroidAudioDeviceType.bluetoothSco,
  ];
  final _speakerTypes = [
    AndroidAudioDeviceType.builtInSpeaker,
    AndroidAudioDeviceType.builtInSpeakerSafe,
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _updateIosDevices();
    } else {
      _updateAndroidDevices();
    }
  }

  T? _firstWhereOrNull<T>(Iterable<T> iterable, bool Function(T element) test) {
    for (var element in iterable) {
      if (test(element)) return element;
    }
    return null;
  }

  String getOutputDeviceName(OutputAudioDevice device) {
    switch (device) {
      case Bluetooth _:
        return 'bluetooth (${device.label})';
      case Earpiece _:
        return 'telephony';
      case Speaker _:
        return 'speaker';
    }
  }

  Future<void> changeOutputDevice(OutputAudioDevice device) async {
    final session = widget.session;
    switch (device) {
      case Bluetooth _:
        session.switchToBluetooth();
        _currentOutput = Bluetooth(device.label);       
      case Earpiece _:
        session.switchToReceiver();
        _currentOutput = Earpiece();       
      case Speaker _:
        session.switchToSpeaker();        
         _currentOutput = Speaker();       
    }
    setState(() {});
  }

  IconData getOutputDeviceIcon(OutputAudioDevice device) {
    switch (device) {
      case Bluetooth _:
        return Icons.bluetooth_audio;
      case Earpiece _:
        return Icons.phone;
      case Speaker _:
        return Icons.speaker;
    }
  }

  Future<void> _updateIosDevices() async {
    final avAudioSession = !kIsWeb && Platform.isIOS ? AVAudioSession() : null;
    final currentRoute = await avAudioSession?.currentRoute;
    if (currentRoute != null) {
      _outputs.add(Speaker());
      final availableInputs = await avAudioSession!.availableInputs;
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
      final bluetoothDevice = _firstWhereOrNull(
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
    }
    setState(() {});
  }

  Future<void> _updateAndroidDevices() async {
    final androidAudioManager =
        !kIsWeb && Platform.isAndroid ? AndroidAudioManager() : null;
    final androidDevices = await androidAudioManager!.getDevices(
      AndroidGetAudioDevicesFlags.outputs,
    );
    final types = androidDevices.map((d) => d.type);
    final hasSpeakerPhone = types.any(_speakerTypes.contains);
    final hasEarpiece =
        types.any((t) => t == AndroidAudioDeviceType.builtInEarpiece);
    final blutoothDevice = _firstWhereOrNull(
      androidDevices,
      (d) => _btTypes.contains(d.type),
    );
    _outputs = {
      if (hasSpeakerPhone) Speaker(),
      if (blutoothDevice != null) Bluetooth(blutoothDevice.productName),
      if (hasEarpiece) Earpiece(),
    };
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentDevice = _currentOutput;
    final currentDeviceName =
        currentDevice != null ? getOutputDeviceName(currentDevice) : '';

    return Column(
      children: [
        Text("Switch devices: $currentDeviceName",
            style: Theme.of(context).textTheme.titleLarge),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var device in _outputs)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(getOutputDeviceName(device)),
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => changeOutputDevice(device),
                      icon: Icon(getOutputDeviceIcon(device)))
                ],
              ),
          ],
        )
      ],
    );
  }
}

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
