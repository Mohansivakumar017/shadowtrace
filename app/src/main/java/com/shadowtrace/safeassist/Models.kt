package com.shadowtrace.safeassist

import kotlinx.serialization.Serializable

@Serializable
data class TrustedContact(
    val name: String,
    val phoneNumber: String
)

enum class TripStatus {
    IDLE,
    ACTIVE,
    STALLED,
    ESCALATED
}

data class UiState(
    val contacts: List<TrustedContact> = emptyList(),
    val status: TripStatus = TripStatus.IDLE,
    val lastKnownLocation: String = "No location yet",
    val safetyPromptPending: Boolean = false
)
