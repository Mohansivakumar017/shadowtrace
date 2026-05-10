package com.shadowtrace.safeassist

import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Binder
import android.os.IBinder
import android.os.PowerManager
import android.app.NotificationManager
import android.app.NotificationChannel
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.net.URL
import java.nio.charset.StandardCharsets
import org.json.JSONObject

class DeadZoneTimerService : Service() {
    companion object {
        private const val DEAD_ZONE_THRESHOLD_SECONDS = 300
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "shadowtrace_dead_zone"
    }

    private val binder = LocalBinder()
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private var countdownJob: Job? = null
    private var lastHeartbeatTime = System.currentTimeMillis()
    private var tripId: String? = null

    inner class LocalBinder : Binder() {
        fun getService(): DeadZoneTimerService = this@DeadZoneTimerService
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        tripId = intent?.getStringExtra("tripId")
        lastHeartbeatTime = System.currentTimeMillis()
        startCountdown()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder = binder

    private fun startCountdown() {
        countdownJob?.cancel()
        countdownJob = scope.launch {
            while (isActive) {
                delay(1000)
                val elapsedSeconds = (System.currentTimeMillis() - lastHeartbeatTime) / 1000

                if (elapsedSeconds == 60L) {
                    showWarningNotification()
                }

                if (elapsedSeconds >= DEAD_ZONE_THRESHOLD_SECONDS) {
                    handleDeadZoneTimeout()
                    break
                }
            }
        }
    }

    fun onHeartbeatReceived() {
        lastHeartbeatTime = System.currentTimeMillis()
        startCountdown()
    }

    private fun showWarningNotification() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Dead Zone Warning")
            .setContentText("No signal detected. Automatic SOS in 4 minutes.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun handleDeadZoneTimeout() {
        scope.launch {
            try {
                if (tripId != null) {
                    triggerSOSAlert()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private suspend fun triggerSOSAlert() {
        withContext(Dispatchers.IO) {
            try {
                val url = URL("https://YOUR_API_ENDPOINT/sos")
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")

                val jsonPayload = JSONObject()
                jsonPayload.put("tripId", tripId)
                jsonPayload.put("reason", "dead_zone_timeout")

                connection.outputStream.write(jsonPayload.toString().toByteArray(StandardCharsets.UTF_8))
                connection.responseCode
                connection.disconnect()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Dead Zone Timer",
            NotificationManager.IMPORTANCE_HIGH
        )
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        countdownJob?.cancel()
        scope.cancel()
        super.onDestroy()
    }
}
