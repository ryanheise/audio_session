package com.ryanheise.audio_session;

import android.content.Context;
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
	private static List<AndroidAudioManager> instances = new ArrayList<>();

	private Context applicationContext;
	private BinaryMessenger messenger;
	private MethodChannel channel;
	private AudioManager audioManager;

	public AndroidAudioManager(Context applicationContext, BinaryMessenger messenger) {
		this.applicationContext = applicationContext;
		this.messenger = messenger;
		channel = new MethodChannel(messenger, "com.ryanheise.android_audio_manager");
		channel.setMethodCallHandler(this);
		audioManager = (AudioManager)applicationContext.getSystemService(Context.AUDIO_SERVICE);
		instances.add(this);
	}

	@Override
	public void onMethodCall(final MethodCall call, final Result result) {
		List<?> args = (List<?>)call.arguments;
		switch (call.method) {
		case "requestAudioFocus": {
			Map<?, ?> request = (Map<?, ?>)args.get(0);
			AudioFocusRequestCompat.Builder builder = new AudioFocusRequestCompat.Builder((Integer)request.get("gainType"));
			builder.setOnAudioFocusChangeListener(focusChange -> {
				invokeMethod("onAudioFocusChanged", focusChange);
			});
			if (request.get("audioAttributes") != null) {
				builder.setAudioAttributes(decodeAudioAttributes((Map<?, ?>)request.get("audioAttributes")));
			}
			if (request.get("willPauseWhenDucked") != null) {
				builder.setWillPauseWhenDucked((Boolean)request.get("willPauseWhenDucked"));
			}
			int status = AudioManagerCompat.requestAudioFocus(audioManager, builder.build());
			result.success(status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
			break;
		}
		default: {
			result.notImplemented();
			break;
		}
		}
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

	public void dispose() {
		channel.setMethodCallHandler(null);
		instances.remove(this);
	}

	private void invokeMethod(String method, Object... args) {
		for (AndroidAudioManager instance : instances) {
			ArrayList<Object> list = new ArrayList<Object>(Arrays.asList(args));
			instance.channel.invokeMethod(method, list);
		}
	}
}
