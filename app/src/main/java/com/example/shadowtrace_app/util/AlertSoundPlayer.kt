package com.example.shadowtrace_app.util

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.util.Log
import com.example.shadowtrace_app.R
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlertSoundPlayer @Inject constructor(@ApplicationContext private val context: Context) {
    private var mediaPlayer: MediaPlayer? = null

    fun playAlert() {
        Log.d("AlertSoundPlayer", "playAlert() called")
        stopAlert()

        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

            val soundResId = R.raw.reality_siren
            mediaPlayer = MediaPlayer.create(context, soundResId)
            
            mediaPlayer?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                start()
            }
        } catch (e: Exception) {
            Log.e("AlertSoundPlayer", "Error in playAlert", e)
        }
    }

    fun stopAlert() {
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
        } finally {
            mediaPlayer = null
        }
    }
}
