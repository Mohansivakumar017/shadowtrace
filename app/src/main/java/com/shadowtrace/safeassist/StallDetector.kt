package com.shadowtrace.safeassist

import android.location.Location

class StallDetector(
    private val minimumMovementMeters: Float = 25f,
    private val stallThresholdMs: Long = 120_000L
) {
    private var lastMovementLocation: Location? = null
    private var lastMovementTimeMs: Long = 0L

    fun onLocationUpdate(location: Location, currentTimeMs: Long): Boolean {
        val previous = lastMovementLocation
        if (previous == null) {
            lastMovementLocation = location
            lastMovementTimeMs = currentTimeMs
            return false
        }

        if (location.distanceTo(previous) >= minimumMovementMeters) {
            lastMovementLocation = location
            lastMovementTimeMs = currentTimeMs
            return false
        }

        return (currentTimeMs - lastMovementTimeMs) >= stallThresholdMs
    }

    fun reset() {
        lastMovementLocation = null
        lastMovementTimeMs = 0L
    }
}
