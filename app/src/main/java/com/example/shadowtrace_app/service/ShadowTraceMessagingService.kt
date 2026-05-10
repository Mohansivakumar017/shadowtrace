package com.example.shadowtrace_app.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.example.shadowtrace_app.MainActivity
import com.example.shadowtrace_app.util.AlertSoundPlayer
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class ShadowTraceMessagingService : FirebaseMessagingService() {

    @Inject lateinit var soundPlayer: AlertSoundPlayer

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        val type = remoteMessage.data["type"]
        if (type == "SOS") {
            // PLAY SIREN IMMEDIATELY ON GUARDIAN PHONE
            soundPlayer.playAlert()
            showHighPriorityNotification(remoteMessage.notification?.title ?: "CRITICAL SOS", remoteMessage.notification?.body ?: "Emergency alert received!")
        }
    }

    private fun showHighPriorityNotification(title: String, body: String) {
        val channelId = "critical_sos_channel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val channel = NotificationChannel(channelId, "Critical Alerts", NotificationManager.IMPORTANCE_HIGH).apply {
            setBypassDnd(true)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .build()

        manager.notify(100, notification)
    }
}
