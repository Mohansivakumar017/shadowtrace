package com.shadowtrace.safeassist

import android.location.Location
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.Mockito.mock

class StallDetectorTest {
    @Test
    fun doesNotStallWhenMoving() {
        val detector = StallDetector(
            minimumMovementMeters = 10f,
            stallThresholdMs = 60_000,
            distanceCalculator = { _, _ -> 15f }
        )

        detector.onLocationUpdate(mock(Location::class.java), 0)
        val stalled = detector.onLocationUpdate(mock(Location::class.java), 70_000)

        assertFalse(stalled)
    }

    @Test
    fun stallsWhenNoMovementPastThreshold() {
        val detector = StallDetector(
            minimumMovementMeters = 50f,
            stallThresholdMs = 60_000,
            distanceCalculator = { _, _ -> 10f }
        )

        detector.onLocationUpdate(mock(Location::class.java), 0)
        val stalled = detector.onLocationUpdate(mock(Location::class.java), 61_000)

        assertTrue(stalled)
    }
}
