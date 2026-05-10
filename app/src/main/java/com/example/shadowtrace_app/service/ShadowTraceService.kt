package com.example.shadowtrace_app.service

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import com.example.shadowtrace_app.R
import com.example.shadowtrace_app.data.repository.AlertRepository
import com.example.shadowtrace_app.data.repository.AuthRepository
import com.example.shadowtrace_app.util.AlertSoundPlayer
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import javax.inject.Inject

@AndroidEntryPoint
class ShadowTraceService : Service() {

    @Inject lateinit var authRepository: AuthRepository
    @Inject lateinit var alertRepository: AlertRepository
    @Inject lateinit var soundPlayer: AlertSoundPlayer

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var lastLocation: Location? = null
    
    private var timerHandler = Handler(Looper.getMainLooper())
    private var startTime = 0L

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        startForeground(1, createNotification("Safety Watch Active"))
        requestLocationUpdates()
        startEscalationTimer()
    }

    private fun startEscalationTimer() {
        startTime = SystemClock.elapsedRealtime()
        timerHandler.postDelayed(object : Runnable {
            override fun run() {
                val elapsed = SystemClock.elapsedRealtime() - startTime
                checkSafetyIntervals(elapsed)
                timerHandler.postDelayed(this, 10000) // Check every 10s
            }
        }, 10000)
    }

    private fun checkSafetyIntervals(elapsed: Long) {
        when {
            elapsed >= 120000 -> { // 2 Minutes - CRITICAL ESCALATION
                triggerAutomaticSOS("CRITICAL: No movement for 2 mins")
                timerHandler.removeCallbacksAndMessages(null)
            }
            elapsed >= 60000 -> { // 1 Minute - Warning
                updateNotification("WARNING: Inactivity detected for 1 min.")
                playTickSound()
            }
            elapsed >= 30000 -> { // 30 Seconds - Alert
                updateNotification("Status: Standing still for 30s.")
            }
        }
    }

    private fun playTickSound() {
        // Subtle alert sound for user
        soundPlayer.playAlert()
        Handler(Looper.getMainLooper()).postDelayed({ soundPlayer.stopAlert() }, 2000)
    }

    private fun triggerAutomaticSOS(reason: String) {
        serviceScope.launch {
            val user = authRepository.getCurrentUser()
            val details = user?.let { authRepository.getUserDetails(it.uid) }
            details?.let {
                alertRepository.triggerAlert(
                    it.uid, it.guardianPhone, 
                    lastLocation?.latitude ?: 0.0, 
                    lastLocation?.longitude ?: 0.0
                )
                Log.d("ShadowTrace", "Auto SOS Sent: $reason")
            }
        }
    }

    private fun requestLocationUpdates() {
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000).build()
        try {
            fusedLocationClient.requestLocationUpdates(request, object : LocationCallback() {
                override fun onLocationResult(result: LocationResult) {
                    val loc = result.lastLocation
                    if (loc != null) {
                        if (lastLocation != null) {
                    if (loc.distanceTo(lastLocation!!) > 5) {
                        startTime = SystemClock.elapsedRealtime()
                    }
                    // Share live tracking
                    serviceScope.launch {
                        val user = authRepository.getCurrentUser()
                        user?.let { alertRepository.shareLiveTracking(it.uid, loc.latitude, loc.longitude) }
                    }
                }
                lastLocation = loc
                    }
                }
            }, mainLooper)
        } catch (e: SecurityException) {}
    }

    private fun updateNotification(content: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(1, createNotification(content))
    }

    private fun createNotification(content: String): Notification {
        val channelId = "shadowtrace_channel"
        val channel = NotificationChannel(channelId, "Safety Service", NotificationManager.IMPORTANCE_HIGH)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("ShadowTrace Protocol")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }

    override fun onDestroy() {
        serviceScope.cancel()
        timerHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
