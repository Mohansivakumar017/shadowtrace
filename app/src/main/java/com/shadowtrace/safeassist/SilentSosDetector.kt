package com.shadowtrace.safeassist

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.app.NotificationManager
import android.app.NotificationChannel
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.net.URL
import org.json.JSONObject
import java.nio.charset.StandardCharsets

class SilentSosDetector(private val context: Context) : BroadcastReceiver() {
    companion object {
        private const val RAPID_PRESS_THRESHOLD = 3000 // 3 seconds
        private const val PRESS_COUNT_THRESHOLD = 5
        private const val NOTIFICATION_ID = 1002
        private const val CHANNEL_ID = "shadowtrace_silent_sos"
    }

    private var pressCount = 0
    private var lastPressTime: Long = 0
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_SCREEN_OFF || intent?.action == Intent.ACTION_SCREEN_ON) {
            handlePowerButtonPress()
        }
    }

    private fun handlePowerButtonPress() {
        val currentTime = System.currentTimeMillis()

        if (currentTime - lastPressTime > RAPID_PRESS_THRESHOLD) {
            pressCount = 1
        } else {
            pressCount++
        }

        lastPressTime = currentTime

        if (pressCount >= PRESS_COUNT_THRESHOLD) {
            triggerSilentSOS()
            pressCount = 0
        }
    }

    private fun triggerSilentSOS() {
        scope.launch {
            try {
                sendSOSRequest()
                showConfirmationNotification()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private suspend fun sendSOSRequest() {
        withContext(Dispatchers.IO) {
            try {
                val url = URL("https://YOUR_API_ENDPOINT/sos")
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")

                val jsonPayload = JSONObject()
                jsonPayload.put("triggerMethod", "silent_sos")

                connection.outputStream.write(jsonPayload.toString().toByteArray(StandardCharsets.UTF_8))
                connection.responseCode
                connection.disconnect()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun showConfirmationNotification() {
        createNotificationChannel()

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("SOS Triggered")
            .setContentText("Silent SOS activated. Guardians are being notified.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setAutoCancel(true)
            .build()

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Silent SOS",
            NotificationManager.IMPORTANCE_MAX
        )
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    fun register() {
        val filter = IntentFilter()
        filter.addAction(Intent.ACTION_SCREEN_OFF)
        filter.addAction(Intent.ACTION_SCREEN_ON)
        context.registerReceiver(this, filter)
    }

    fun unregister() {
        try {
            context.unregisterReceiver(this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun destroy() {
        scope.cancel()
        unregister()
    }
}
