# audio_session

This plugin configures your app's audio category and configures how your app interacts with other audio apps.

Audio apps often have unique requirements. For example, when a navigator app voices driving instructions, a music player should duck its audio while a podcast player should pause its audio. Depending on which one of these three apps you are building, you will need to configure your app's audio settings and callbacks to appropriately handle these interactions.

This plugin can be used both by app developers, to initialise appropriate audio settings for their app, and by plugin authors, to provide easy access to low level features of iOS's AVAudioSession and Android's AudioManager in Dart.

Note: If your app uses a number of different audio plugins, e.g. any combination of audio recording, text to speech, background audio, audio playing, or speech recognition, it is possible that those plugins may internally overwrite each other's choice of global system audio settings, including the ones you set via this plugin. You may consider asking the developer of each audio plugin you use to provide an option to not overwrite these global settings and allow them be managed externally.

The following sections describe how audio_session can be used by both app developers and plugin authors.

## For app developers

An app should configure the audio session during app initialisation to indicate what type of audio it intends to play and how it should interact with other audio apps on the device. There are a number of preset recipe configurations available.

Configure your app for playing music:

```dart
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration.music());
```

Configure your app for playing podcasts/audiobooks:

```dart
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration.speech());
```

Or use a custom configuration:

```dart
final session = await AudioSession.instance;
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

Individual audio plugins that you use may provide an option to handle audio interruptions (e.g. phone calls, navigator instructions or notifications). If your app has specialised requirements, you may prefer to disable that option and implement it yourself by interfacing directly with the audio session.

Observe interruptions to the audio session:

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

This plugin provides easy access to the iOS AVAudioSession and Android AudioManager APIs from Dart, and provides a unified API to activate the audio session for both platforms:

```dart
// Activate the audio session before playing or recording audio.
if (await session.setActive(true)) {
  // Now play or record audio.
} else {
  // The request was denied and the app should not play audio
  // e.g. a phonecall is in progress.
}
```

On iOS this calls `AVAudioSession.setActive` and on Android this calls `AudioManager.requestAudioFocus`. In addition to calling the lower level APIs, it also registers callbacks and forwards events to Dart via the streams `AudioSession.interruptionEventStream` and `AudioSession.becomingNoisyEventStream`. This allows both plugins and apps to interface with a shared instance of the audio focus request and audio session without conflict.

If a plugin can handle audio interruptions (i.e. by listening to the `interruptionEventStream` and automatically pausing audio), it is preferable to provide an option to turn this feature on or off, since some apps may have specialised requirements. e.g.:

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

All numeric values encoded in `AndroidAudioAttributes.toJson()` correspond exactly to the Android platform constants.

`configurationStream` will always emit the latest configuration as the first event upon subscribing, and so the above code will handle both the initial configuration choice and subsequent changes to it throughout the life of the app.
