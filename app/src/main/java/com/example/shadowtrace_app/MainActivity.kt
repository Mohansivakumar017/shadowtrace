package com.example.shadowtrace_app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.shadowtrace_app.ui.auth.LoginScreen
import com.example.shadowtrace_app.ui.auth.RoleSelectionScreen
import com.example.shadowtrace_app.ui.auth.SignupScreen
import com.example.shadowtrace_app.ui.home.HomeScreen
import com.example.shadowtrace_app.ui.home.GuardianHomeScreen
import com.example.shadowtrace_app.ui.map.MapScreen
import com.example.shadowtrace_app.ui.theme.ShadowTraceTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ShadowTraceTheme {
                MainNavigation()
            }
        }
    }
}

@Composable
fun MainNavigation() {
    val navController = rememberNavController()
    
    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "login",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("login") { LoginScreen(navController) }
            composable("signup") { SignupScreen(navController) }
            composable("role_selection") { RoleSelectionScreen(navController) }
            composable("home") { HomeScreen(navController) }
            composable("guardian_home") { GuardianHomeScreen(navController) }
            composable("map") { MapScreen() }
        }
    }
}
