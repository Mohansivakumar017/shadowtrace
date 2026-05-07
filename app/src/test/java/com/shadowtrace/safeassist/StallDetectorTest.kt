package com.shadowtrace.safeassist

import android.location.Location
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class StallDetectorTest {
    @Test
    fun doesNotStallWhenMoving() {
        val detector = StallDetector(minimumMovementMeters = 10f, stallThresholdMs = 60_000)

        detector.onLocationUpdate(location(12.0, 77.0), 0)
        val stalled = detector.onLocationUpdate(location(12.001, 77.001), 70_000)

        assertFalse(stalled)
    }

    @Test
    fun stallsWhenNoMovementPastThreshold() {
        val detector = StallDetector(minimumMovementMeters = 50f, stallThresholdMs = 60_000)

        detector.onLocationUpdate(location(12.0, 77.0), 0)
        val stalled = detector.onLocationUpdate(location(12.0, 77.0), 61_000)

        assertTrue(stalled)
    }

    private fun location(lat: Double, lon: Double): Location {
        return Location("test").apply {
            latitude = lat
            longitude = lon
        }
    }
}
