# audio_session

This plugin configures the iOS audio session category and Android audio attributes for your app, and manages your app's audio focus, mixing and ducking behaviour. This is essential to:

* Communicate to the operating system what type of audio your app intends to play.
* Specify how your app interacts with other audio apps on the device.
* Centralise the configuration of app-wide system audio settings among different audio plugins (see Section "Managing multiple audio plugins").

The audio_session plugin interfaces with `AudioManager` on Android and `AVAudioSession` on iOS.

## Managing multiple audio plugins

If your app uses multiple audio plugins (e.g. text-to-speech, audio player, audio recorder, speech recognition), you may experience an issue where one plugin will overwrite the system audio settings written by another plugin. For example, An audio recorder plugin may set the iOS audio session category to `record` while an audio player plugin may overwrite this and set it to `playback`. In reality, the ideal choice of category (i.e. `playAndRecord`) is outside the concern of either plugin.

Similarly, an audio recorder plugin may configure the ducking behaviour on Android so that audio should not be ducked, while an audio player plugin may configure your app so that audio can be ducked. Whichever plugin loads second will overwrite the settings of the first, where in reality, the ideal behaviour of audio focus is outside the concern of either plugin.

audio_session lets you remove this concern from the individual audio plugins and configure your app-wide settings globally. 

## For app developers

Obtain the AudioSession singleton from any `FlutterEngine`:

```dart
final session = await AudioSession.instance;
```

Configure your app for playing music:

```dart
await session.configure(AudioSessionConfiguration.music());
```

Configure your app for playing podcasts/audiobooks:

```dart
// Configure your app for playing podcasts/audiobooks:
await session.configure(AudioSessionConfiguration.speech());
```

Use a custom configuration:

```dart
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

Observe unplugged headphones:

```dart
session.becomingNoisyEventStream.listen((_) {
  // The user unplugged the headphones, so we should pause or lower the volume.
});
```

## For plugin authors

When the plugin is about to play or record audio:

```dart
// Activate the audio session.
if (await session.setActive(true)) {
  // Now play or record audio
} else {
  // The request was denied and the app should not play audio
  // e.g. a phonecall is in progress.
}
```

If a plugin can handle audio interruptions, it is preferable to provide an option to turn this feature on or off. e.g.:

```dart
player = AudioPlayer(handleInterruptions: false);
```

Note that iOS and Android have fundamentally different ways to set the audio attributes and categories: for iOS it is app-wide, while for Android it is per player or audio track. As such, `audioSession.configure()` can and does set the app-wide configuration on iOS immediately, while on Android these app-wide settings are stored within audio_session and can be obtained by individual audio plugins via a Stream. The following code shows how a player plugin can listen for changes to the Android AudioAttributes and apply them:

```dart
audioSession.configurationStream
    .map((conf) => conf?.androidAudioAttributes)
    .distinct()
    .listen((attributes) {
  // apply the attributes to this Android audio track
  _channel.invokeMethod("setAudioAttributes", attributes.toJson());
});
```

`configurationStream` will always emit the latest configuration as the first event upon subscribing, and so the above code will handle both the initial configuration choice and subsequent changes to it throughout the life of the app.
