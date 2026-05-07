package com.shadowtrace.safeassist

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class SafetyForegroundService : Service() {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val stallDetector = StallDetector()
    private lateinit var alertDispatcher: AlertDispatcher
    private lateinit var contactsRepository: TrustedContactsRepository

    private var promptIssuedAt: Long? = null

    private val callback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return
            handleLocation(location)
        }
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        alertDispatcher = AlertDispatcher(this)
        contactsRepository = TrustedContactsRepository(this)
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, baseNotification("Safety monitoring active"))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTracking()
                stopSelf()
            }
            else -> startTracking()
        }
        return START_STICKY
    }

    private fun startTracking() {
        val request = LocationRequest.Builder(30_000L)
            .setMinUpdateDistanceMeters(10f)
            .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
            .build()

        runCatching {
            fusedLocationClient.requestLocationUpdates(request, callback, mainLooper)
        }
    }

    private fun stopTracking() {
        stallDetector.reset()
        promptIssuedAt = null
        fusedLocationClient.removeLocationUpdates(callback)
    }

    private fun handleLocation(location: Location) {
        val now = System.currentTimeMillis()
        val isStalled = stallDetector.onLocationUpdate(location, now)

        sendStatusBroadcast(
            status = if (isStalled) TripStatus.STALLED else TripStatus.ACTIVE,
            location = "${location.latitude}, ${location.longitude}",
            promptPending = promptIssuedAt != null
        )

        if (isStalled && promptIssuedAt == null) {
            promptIssuedAt = now
            sendStatusBroadcast(
                status = TripStatus.STALLED,
                location = "${location.latitude}, ${location.longitude}",
                promptPending = true
            )
            updateForegroundNotification("No movement detected. Confirm safety in app.")
            return
        }

        val promptStart = promptIssuedAt ?: return
        if (now - promptStart >= ESCALATION_DELAY_MS) {
            val contacts = contactsRepository.loadContacts()
            alertDispatcher.dispatchEmergencyAlert(
                contacts,
                "Emergency alert from SafeAssist: prolonged inactivity detected at ${location.latitude}, ${location.longitude}."
            )
            promptIssuedAt = null
            sendStatusBroadcast(
                status = TripStatus.ESCALATED,
                location = "${location.latitude}, ${location.longitude}",
                promptPending = false
            )
            updateForegroundNotification("Emergency alert escalated to trusted contacts")
        }
    }

    private fun sendStatusBroadcast(status: TripStatus, location: String, promptPending: Boolean) {
        val intent = Intent(ACTION_STATUS)
            .putExtra(EXTRA_STATUS, status.name)
            .putExtra(EXTRA_LOCATION, location)
            .putExtra(EXTRA_PROMPT_PENDING, promptPending)
        sendBroadcast(intent)
    }

    private fun baseNotification(content: String): Notification {
        val stopIntent = Intent(this, SafetyForegroundService::class.java).apply { action = ACTION_STOP }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPending = PendingIntent.getActivity(
            this,
            1,
            openIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SafeAssist")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(openPending)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateForegroundNotification(content: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, baseNotification(content))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(CHANNEL_ID, "Safety monitoring", NotificationManager.IMPORTANCE_DEFAULT)
        manager.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val CHANNEL_ID = "safeassist_monitor"
        private const val NOTIFICATION_ID = 1001
        private const val ESCALATION_DELAY_MS = 60_000L

        const val ACTION_STOP = "com.shadowtrace.safeassist.ACTION_STOP"
        const val ACTION_STATUS = "com.shadowtrace.safeassist.ACTION_STATUS"
        const val EXTRA_STATUS = "extra_status"
        const val EXTRA_LOCATION = "extra_location"
        const val EXTRA_PROMPT_PENDING = "extra_prompt_pending"
    }
}
