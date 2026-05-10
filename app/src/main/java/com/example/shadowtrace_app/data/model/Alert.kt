package com.example.shadowtrace_app.data.model

import com.google.gson.annotations.SerializedName

data class AlertRequest(
    val userId: String,
    val guardianPhone: String,
    val latitude: Double,
    val longitude: Double,
    val alertType: String = "SOS"
)

data class AlertResponse(
    @SerializedName("alertId") val alertId: String,
    @SerializedName("message") val message: String? = null
)

data class RespondRequest(
    val alertId: String,
    val response: String // ACCEPTED, REJECTED, SAFE_NOW
)
