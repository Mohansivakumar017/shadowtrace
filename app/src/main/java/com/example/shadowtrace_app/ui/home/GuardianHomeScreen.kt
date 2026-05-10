package com.example.shadowtrace_app.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.example.shadowtrace_app.ui.theme.CyberDark
import com.example.shadowtrace_app.ui.theme.NeonBlue

import androidx.hilt.navigation.compose.hiltViewModel
import com.example.shadowtrace_app.ui.sos.SOSViewModel

@Composable
fun GuardianHomeScreen(navController: NavController, viewModel: SOSViewModel = hiltViewModel()) {
    // We could use a specific GuardianViewModel, but SOSViewModel has access to AlertRepository
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(CyberDark)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("GUARDIAN CONSOLE", color = NeonBlue, fontSize = 24.sp, fontWeight = FontWeight.Black)
        Spacer(modifier = Modifier.height(32.dp))
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color.White.copy(alpha = 0.05f))
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text("PROTECTED USER: AGENT_001", color = Color.White, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                Text("Status: Moving Normally", color = Color.Green, fontSize = 12.sp)
                
                Spacer(modifier = Modifier.height(24.dp))
                
                Button(
                    onClick = { navController.navigate("map") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = NeonBlue)
                ) {
                    Text("OPEN LIVE TRACKING", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text("INCOMING ALERTS", color = Color.Gray, fontSize = 12.sp)
        // List of alerts would go here
    }
}
