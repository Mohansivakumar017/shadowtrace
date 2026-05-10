package com.example.shadowtrace_app.ui.home

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.shadowtrace_app.service.ShadowTraceService
import com.example.shadowtrace_app.ui.theme.*
import com.example.shadowtrace_app.ui.sos.*

@Composable
fun HomeScreen(navController: NavController, viewModel: SOSViewModel = hiltViewModel()) {
    val sosState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    var isMonitoring by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CyberDark)
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Column {
            Text("9:41", color = Color.White, fontSize = 12.sp)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Text("DASHBOARD", color = GrayText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            DashboardHeader()
            
            Spacer(modifier = Modifier.height(24.dp))
            
            GreetingCard(name = "Saida")
            
            Spacer(modifier = Modifier.height(16.dp))
            
            StatusGrid()
            
            Spacer(modifier = Modifier.height(32.dp))
            
            PrimaryActionButtons(navController)
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun DashboardHeader() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(64.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(Brush.verticalGradient(listOf(NeonBlue, NeonCyan))),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color.White, modifier = Modifier.size(32.dp))
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column {
            Text("Home Dashboard", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
            Text("Trip status, safety score, alerts, and quick actions.", color = GrayText, fontSize = 14.sp)
        }
    }
}

@Composable
fun GreetingCard(name: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = SurfaceDark),
        shape = RoundedCornerShape(24.dp)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text("GREETING", color = GrayText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Text("Hi $name", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
            Text("Travel monitoring and emergency protection are active.", color = GrayText, fontSize = 14.sp)
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                StatusTag("Live share on", SuccessGreen)
                StatusTag("Voice SOS ready", SuccessGreen)
            }
            Spacer(modifier = Modifier.height(8.dp))
            StatusTag("3 contacts", NeonBlue)
        }
    }
}

@Composable
fun StatusTag(label: String, color: Color) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.1f))
            .border(1.dp, color.copy(alpha = 0.2f), CircleShape)
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(label, color = Color.White, fontSize = 12.sp)
    }
}

@Composable
fun StatusGrid() {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatusCard(Modifier.weight(1f), "TRIP", "Bangalore \u2192 Mysore", isLarge = true)
            StatusCard(Modifier.weight(1f), "SAFETY", "88 / 100", isLarge = true)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatusCard(Modifier.weight(1f), "ALERTS", "3")
            StatusCard(Modifier.weight(1f), "MODE", "Armed")
        }
    }
}

@Composable
fun StatusCard(modifier: Modifier, label: String, value: String, isLarge: Boolean = false) {
    Card(
        modifier = modifier.height(if (isLarge) 120.dp else 100.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceDark),
        shape = RoundedCornerShape(24.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(label, color = GrayText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            Text(value, color = Color.White, fontSize = if (isLarge) 20.sp else 18.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun PrimaryActionButtons(navController: NavController) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MainButton("Plan Safe Travel", Brush.linearGradient(listOf(NeonBlue, NeonCyan))) {
            navController.navigate("planner")
        }
        MainButton("Launch Live Monitoring", Brush.linearGradient(listOf(SurfaceDark, SurfaceDark))) {
            navController.navigate("map")
        }
        MainButton("Review Safety Alerts", Brush.linearGradient(listOf(SurfaceDark, SurfaceDark))) {
            navController.navigate("alerts")
        }
    }
}

@Composable
fun MainButton(label: String, brush: Brush, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(64.dp),
        shape = RoundedCornerShape(24.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent),
        contentPadding = PaddingValues()
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(brush),
            contentAlignment = Alignment.Center
        ) {
            Text(label, color = if (brush == Brush.linearGradient(listOf(SurfaceDark, SurfaceDark))) Color.White else Color.Black, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        }
    }
}
