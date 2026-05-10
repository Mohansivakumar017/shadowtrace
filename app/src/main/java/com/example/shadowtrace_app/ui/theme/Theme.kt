package com.example.shadowtrace_app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = NeonBlue,
    secondary = NeonCyan,
    background = CyberDark,
    surface = SurfaceDark,
    error = EmergencyRed,
    onPrimary = Color.Black,
    onBackground = LightText,
    onSurface = LightText
)

@Composable
fun ShadowTraceTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        content = content
    )
}
