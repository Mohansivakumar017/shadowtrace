package com.example.shadowtrace_app.ui.map

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import org.maplibre.android.MapLibre
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style

@Composable
fun MapScreen() {
    AndroidView(
        factory = { context ->
            MapView(context).apply {
                getMapAsync { map ->
                    val styleUrl = "https://maps.geo.us-east-1.amazonaws.com/maps/v0/maps/shadowtrace-map/style-descriptor?key=YOUR_AWS_LOCATION_API_KEY"
                    map.setStyle(Style.Builder().fromUri(styleUrl))
                }
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}
