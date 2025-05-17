import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:audio_session_example/audio_switcher.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _player = ja.AudioPlayer(
    // Handle audio_session events ourselves for the purpose of this demo.
    handleInterruptions: false,
    androidApplyAudioAttributes: false,
    handleAudioSessionActivation: false,
  );

  @override
  void initState() {
    super.initState();
    AudioSession.instance.then((audioSession) async {
      // This line configures the app's audio session, indicating to the OS the
      // type of audio we intend to play. Using the "speech" recipe rather than
      // "music" since we are playing a podcast.
      await audioSession.configure(AudioSessionConfiguration.speech());
      // Listen to audio interruptions and pause or duck as appropriate.
      _handleInterruptions(audioSession);
      // Use another plugin to load audio to play.
      await _player.setUrl(
          "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3");
    });
  }

  void _handleInterruptions(AudioSession audioSession) {
    // just_audio can handle interruptions for us, but we have disabled that in
    // order to demonstrate manual configuration.
    bool playInterrupted = false;
    audioSession.becomingNoisyEventStream.listen((_) {
      debugPrint('PAUSE');
      _player.pause();
    });
    _player.playingStream.listen((playing) {
      playInterrupted = false;
      if (playing) {
        audioSession.setActive(true);
      }
    });
    audioSession.interruptionEventStream.listen((event) {
      debugPrint('interruption begin: ${event.begin}');
      debugPrint('interruption type: ${event.type}');
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            if (audioSession.androidAudioAttributes!.usage ==
                AndroidAudioUsage.game) {
              _player.setVolume(_player.volume / 2);
            }
            playInterrupted = false;
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_player.playing) {
              _player.pause();
              playInterrupted = true;
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(min(1.0, _player.volume * 2));
            playInterrupted = false;
            break;
          case AudioInterruptionType.pause:
            if (playInterrupted) _player.play();
            playInterrupted = false;
            break;
          case AudioInterruptionType.unknown:
            playInterrupted = false;
            break;
        }
      }
    });
    audioSession.devicesChangedEventStream.listen((event) {
      debugPrint('Devices added: ${event.devicesAdded}');
      debugPrint('Devices removed: ${event.devicesRemoved}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('audio_session example'),
        ),
        body: SafeArea(
          child: FutureBuilder<AudioSession>(
            future: AudioSession.instance,
            builder: (context, snapshot) {
              final session = snapshot.data;
              if (session == null) return SizedBox();
              return StreamBuilder<Set<AudioDevice>>(
                stream: session.devicesStream,
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? {};
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: StreamBuilder<ja.PlayerState>(
                            stream: _player.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              if (playerState?.processingState !=
                                  ja.ProcessingState.ready) {
                                return Container(
                                  margin: EdgeInsets.all(8.0),
                                  width: 64.0,
                                  height: 64.0,
                                  child: CircularProgressIndicator(),
                                );
                              } else if (playerState?.playing == true) {
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.pause),
                                  iconSize: 64.0,
                                  onPressed: _player.pause,
                                );
                              } else {
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.play_arrow),
                                  iconSize: 64.0,
                                  onPressed: _player.play,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      AudioSwitcher(session: session),
                      Text("Input devices",
                          style: Theme.of(context).textTheme.titleLarge),
                      for (var device
                          in devices.where((device) => device.isInput))
                        Text('${device.name} (${device.type.name})'),
                      SizedBox(height: 16),
                      Text("Output devices",
                          style: Theme.of(context).textTheme.titleLarge),
                      for (var device
                          in devices.where((device) => device.isOutput))
                        Text('${device.name} (${device.type.name})'),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
