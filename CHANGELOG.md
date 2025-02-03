## 0.1.25

* Fix SwiftPM support on macOS.

## 0.1.24

* Add support for SwiftPM.
* Define AVAudioSessionCategory constants using raw strings.

## 0.1.23

* Replace androidx.media2 by androidx.media.
* Bump Android minSdk from 16 to 19.
* Fix Android lints.

## 0.1.22

* Add prefersNoInterruptionsFromSystemAlerts (@AlexBacich).
* Add inputGain features to AVAudioSession (@Volsavr).
* Export Android broadcast receivers for SDK >= 33 (@techieasif).
* Fix dispatchMediaKeyEvent error (@yellowfisherz).
* Handle iOS exception in setActive (@lsslu).

## 0.1.21

* Fix compile error with JDK 21 (@bartekpacia).

## 0.1.20

* Support rxdart 0.28.x.

## 0.1.19

* Run setActive in a thread on iOS to avoid jank (@jointhejourney).
* Update minimum iOS version to 12.0.

## 0.1.18

* Fix parameter type in AVAudioSessionCategoryOptions.contains (@kainosk).
* Fix parameter type in AVAudioSessionSetActiveOptions.contains (@kainosk).

## 0.1.17

* Fix compile error with Android SDK 34.

## 0.1.16

* Use lowercase topics.

## 0.1.15

* AGP 8 compatibility (@josephcrowell).
* Update AGP to 7.3.0.
* Apply flutter_lints.

## 0.1.14

* Update minimum flutter version to 3.0.

## 0.1.13

* Fix compile error with older rxdart 0.26.*.

## 0.1.12

* Add AndroidAudioManager.scoAudioEventStream (@rwrz)
* Add AndroidAudioManager.currentScoAudioState (@rwrz)

## 0.1.11

* Fix iOS bug where devicesChangedEventStream was not firing.

## 0.1.10

* Add communication device methods for Android 31 (@towynlin).

## 0.1.9

* Fix iOS error when decoding portType.

## 0.1.8

* Fix bug in AndroidAudioManager.getMicrophones().

## 0.1.7

* Fix bug detecting added devices on iOS/macOS (@derekcoder).
* Fix bug decoding Android enums.
* Migrate to Flutter 3, Android 31

## 0.1.6+1

* Hide iOS/macOS logs.

## 0.1.6

* Update Android Gradle dependencies.
* Fix Android compiler warnings.
* Fix setBluetoothScoOn bug.

## 0.1.5

* Add more missing API level checks on Android.

## 0.1.4

* Add missing API level checks on Android.

## 0.1.3

* Mostly complete AndroidAudioManager API.
* Mostly complete AVAudioSession API.
* Unified Android/iOS API for device discovery.
* Option to remove iOS microphone code at compile time.

## 0.1.2

* Support rxdart 0.27.0.

## 0.1.1

* Fix iOS interruption notifications bug.
* Fix deprecated warnings on Android (@lhartman1).

## 0.1.0

* Support null safety.

## 0.0.11

* Fix Android NPE if focus lost after dispose.

## 0.0.10

* Support rxdart 0.25.0.
* Fix leaked context on Android.
* Remove compiler warnings on iOS.

## 0.0.9

* ARC fixes on iOS.
* Register notification observers once for all FlutterEngines on iOS.
* Add AVAudioSessionInterruptionNotification.wasSuspended.

## 0.0.8

* Support becomingNoisyEventStream on iOS (@snaeji).

## 0.0.7

* Fix bug in androidWillPauseWhenDucked.
* Improve documentation.

## 0.0.6

* Handle AVAudioSessionInterruptionTypeEnded correctly on iOS.

## 0.0.5

* Fix music() preset so that iOS notification can appear.

## 0.0.4

* Lower minSdkVersion to 16.

## 0.0.3

* Add bitwise operations to flags and options.
* Add AudioSessionConfiguration.copyWith.

## 0.0.2

* Lower min sdk to 1.12.13+hotfix.5
* Add override options to setActive.
* Remove close.

## 0.0.1

* Initial release.
