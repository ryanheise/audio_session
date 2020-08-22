# audio_session

This plugin configures your app's audio category and settings on Android and iOS. This is essential to:

* Communicate to the operating system what type of audio your app intends to play.
* Specify how your app interacts with other audio apps on the device.
* Centralise the configuration of system audio settings so that different audio plugins within your app do not overwrite each other's settings (see Section "Managing multiple audio plugins").

The audio_session plugin interfaces with `AudioManager` on Android and `AVAudioSession` on iOS.

## For app developers

Configure your audio session on app initialisation:

```dart
// Obtain the AudioSession singleton (from any FlutterEngine)
final session = await AudioSession.instance;
// Configure your app for playing music:
await session.configure(AudioSessionConfiguration.music());
// Or, configure your app for playing podcasts/audiobooks:
await session.configure(AudioSessionConfiguration.speech());
// Or, use a custom configuration:
await session.configure(AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
  avAudioSessionMode: AVAudioSessionMode.spokenAudio,
  avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
  avSetActiveOptions: AVAudioSessionSetActiveOptions.none,
  androidAudioAttributes: const AndroidAudioAttributes(
    contentType: AndroidAudioContentType.speech,
    flags: AndroidAudioFlags.none,
    usage: AndroidAudioUsage.voiceCommunication,
  ),
  androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  androidWillPauseWhenDucked: true,
));
```

Observe audio interruptions:

```dart
session.interruptionEventStream.listen((event) {
  if (event.begin) {
    switch (event.type) {
      case AudioInterruptionType.duck:
        // Another app started playing audio and we should duck.
        break;
      case AudioInterruptionType.pause:
      case AudioInterruptionType.unknown:
        // Another app started playing audio and we should pause.
        break;
    }
  } else {
    switch (event.type) {
      case AudioInterruptionType.duck:
        // The interruption ended and we should unduck.
        break;
      case AudioInterruptionType.pause:
        // The interruption ended and we should resume.
      case AudioInterruptionType.unknown:
        // The interruption ended but we should not resume.
        break;
    }
  }
});
```

## For plugin authors

When the plugin is about to play or record audio:

```dart
final session = await AudioSession.instance;
// If the app didn't already configure the session
if (!session.isConfigured) {
  // Set an appropriate default configuration
  await session.configure(...);
}
// Activate the audio session
await session.setActive(true);
// Now play or record audio
```

A convenience method for the above:

```dart
// Ensure the audio session is ready to play or record
await AudioSession.ensurePrepared();
// Now play or record audio
```

## Managing multiple audio plugins

The Flutter plugin ecosystem contains a rich set of open source plugins for playing audio, recording audio, playing text to speech, etc. However, using these plugins within the same app can often lead to conflicts where one plugin will overwrite the system audio settings written by another plugin. For example, An audio recorder plugin may set the iOS audio session category to `record` while an audio player plugin may overwrite this and set it to `playback`. In reality, the ideal choice of category (i.e. `playAndRecord`) is outside the concern of either plugin. Similarly, an audio recorder plugin may configure the ducking behaviour on Android so that audio should not be ducked, while an audio player plugin may configure your app so that audio can be ducked. Whichever plugin loads second will overwrite the settings of the first, where in reality, the ideal behaviour of audio focus is outside the concern of either plugin.

Rather than place this concern into the individual audio plugins, you can use audio_session to configure your app-wide audio settings in one place during your app's initialisation.
