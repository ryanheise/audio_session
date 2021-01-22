package com.ryanheise.audio_session;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import androidx.media.AudioAttributesCompat;
import androidx.media.AudioFocusRequestCompat;
import androidx.media.AudioManagerCompat;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

public class AndroidAudioManager implements MethodCallHandler {
    // TODO: synchronize access
    private static Singleton singleton;

    private BinaryMessenger messenger;
    private MethodChannel channel;

    public AndroidAudioManager(Context applicationContext, BinaryMessenger messenger) {
        if (singleton == null)
            singleton = new Singleton(applicationContext);
        this.messenger = messenger;
        channel = new MethodChannel(messenger, "com.ryanheise.android_audio_manager");
        singleton.add(this);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        List<?> args = (List<?>)call.arguments;
        switch (call.method) {
        case "requestAudioFocus": {
            result.success(singleton.requestAudioFocus(args));
            break;
        }
        case "abandonAudioFocus": {
            result.success(singleton.abandonAudioFocus());
            break;
        }
        default: {
            result.notImplemented();
            break;
        }
        }
    }

    public void dispose() {
        channel.setMethodCallHandler(null);
        singleton.remove(this);
        if (singleton.isEmpty()) {
            singleton.dispose();
            singleton = null;
        }
        channel = null;
        messenger = null;
    }

    /**
     * To emulate iOS's AVAudioSession, we maintain a single app-wide audio
     * focus request and noisy receiver at any one time which all isolates
     * share access to.
     */
    private static class Singleton {
        private List<AndroidAudioManager> instances = new ArrayList<>();
        private AudioFocusRequestCompat audioFocusRequest;
        private BroadcastReceiver noisyReceiver;
        private Context applicationContext;
        private AudioManager audioManager;

        public Singleton(Context applicationContext) {
            this.applicationContext = applicationContext;
            audioManager = (AudioManager)applicationContext.getSystemService(Context.AUDIO_SERVICE);
        }

        public void add(AndroidAudioManager manager) {
            instances.add(manager);
        }

        public void remove(AndroidAudioManager manager) {
            instances.remove(manager);
        }

        public boolean isEmpty() {
            return instances.size() == 0;
        }

        private boolean requestAudioFocus(List<?> args) {
            if (audioFocusRequest != null) {
                return true;
            }
            Map<?, ?> request = (Map<?, ?>)args.get(0);
            AudioFocusRequestCompat.Builder builder = new AudioFocusRequestCompat.Builder((Integer)request.get("gainType"));
            builder.setOnAudioFocusChangeListener(focusChange -> {
                if (focusChange == AudioManager.AUDIOFOCUS_LOSS) abandonAudioFocus();
                invokeMethod("onAudioFocusChanged", focusChange);
            });
            if (request.get("audioAttributes") != null) {
                builder.setAudioAttributes(decodeAudioAttributes((Map<?, ?>)request.get("audioAttributes")));
            }
            if (request.get("willPauseWhenDucked") != null) {
                builder.setWillPauseWhenDucked((Boolean)request.get("willPauseWhenDucked"));
            }
            audioFocusRequest = builder.build();
            int status = AudioManagerCompat.requestAudioFocus(audioManager, audioFocusRequest);
            boolean success = status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
            if (success) {
                registerNoisyReceiver();
            }
            return success;
        }

        private boolean abandonAudioFocus() {
            if (applicationContext == null) return false;
            unregisterNoisyReceiver();
            if (audioFocusRequest == null) {
                return true;
            } else {
                int status = AudioManagerCompat.abandonAudioFocusRequest(audioManager, audioFocusRequest);
                audioFocusRequest = null;
                return status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
            }
        }

        private void registerNoisyReceiver() {
            if (noisyReceiver != null) return;
            noisyReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction())) {
                        invokeMethod("onBecomingNoisy");
                    }
                }
            };
            applicationContext.registerReceiver(noisyReceiver, new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY));
        }

        private void unregisterNoisyReceiver() {
            if (noisyReceiver == null || applicationContext == null) return;
            applicationContext.unregisterReceiver(noisyReceiver);
            noisyReceiver = null;
        }

        private AudioAttributesCompat decodeAudioAttributes(Map<?, ?> attributes) {
            AudioAttributesCompat.Builder builder = new AudioAttributesCompat.Builder();
            if (attributes.get("contentType") != null) {
                builder.setContentType((Integer)attributes.get("contentType"));
            }
            if (attributes.get("flags") != null) {
                builder.setFlags((Integer)attributes.get("flags"));
            }
            if (attributes.get("usage") != null) {
                builder.setUsage((Integer)attributes.get("usage"));
            }
            return builder.build();
        }

        private void invokeMethod(String method, Object... args) {
            for (AndroidAudioManager instance : instances) {
                ArrayList<Object> list = new ArrayList<Object>(Arrays.asList(args));
                instance.channel.invokeMethod(method, list);
            }
        }

        public void dispose() {
            abandonAudioFocus();
            applicationContext = null;
            audioManager = null;
        }
    }
}
