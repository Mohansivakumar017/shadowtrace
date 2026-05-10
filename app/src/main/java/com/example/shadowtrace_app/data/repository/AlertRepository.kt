package com.example.shadowtrace_app.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.example.shadowtrace_app.data.model.AlertRequest
import com.example.shadowtrace_app.data.model.RespondRequest
import com.example.shadowtrace_app.data.remote.AlertApiService
import com.google.firebase.firestore.DocumentSnapshot
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlertRepository @Inject constructor(
    private val api: AlertApiService,
    private val firestore: FirebaseFirestore
) {
    suspend fun triggerAlert(userId: String, guardianPhone: String, lat: Double, lng: Double) {
        val request = AlertRequest(userId, guardianPhone, lat, lng)
        api.triggerAlert(request)
    }

    suspend fun shareLiveTracking(userId: String, lat: Double, lng: Double) {
        val data = mapOf(
            "lat" to lat,
            "lng" to lng,
            "timestamp" to System.currentTimeMillis()
        )
        firestore.collection("live_tracking").document(userId).set(data).await()
    }

    fun getLiveLocation(userId: String): Flow<DocumentSnapshot> = callbackFlow {
        val listener = firestore.collection("live_tracking").document(userId)
            .addSnapshotListener { snapshot, _ ->
                if (snapshot != null) trySend(snapshot)
            }
        awaitClose { listener.remove() }
    }

    suspend fun respondToAlert(alertId: String, response: String) {
        val request = RespondRequest(alertId, response)
        api.respondToAlert(request)
    }
}
