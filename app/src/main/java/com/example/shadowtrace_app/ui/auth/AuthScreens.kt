package com.example.shadowtrace_app.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.shadowtrace_app.ui.theme.*

@Composable
fun LoginScreen(navController: NavController, viewModel: AuthViewModel = hiltViewModel()) {
    val state by viewModel.authState.collectAsState()
    var isLogin by remember { mutableStateOf(true) }
    
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CyberDark)
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Column(horizontalAlignment = Alignment.Start) {
            Text("9:41", color = Color.White, fontSize = 12.sp)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Text("AUTH", color = GrayText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
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
                    Text("Login / Signup", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    Text("One screen with login/signup toggle and clear trust cues.", color = GrayText, fontSize = 14.sp)
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Description Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = SurfaceDark),
                shape = RoundedCornerShape(24.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        "ShadowTrace keeps journeys visible, monitored, and easy to escalate.",
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TagChip("Live tracking")
                        TagChip("Voice SOS")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    TagChip("Trusted contacts")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Mode Selection Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = SurfaceDark),
                shape = RoundedCornerShape(24.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("MODE", color = GrayText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    Text(
                        if (isLogin) "Welcome back" else "Create Account",
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ModeButton("Login", isLogin) { isLogin = true }
                        ModeButton("Signup", !isLogin) { isLogin = false }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Fields Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = SurfaceDark),
                shape = RoundedCornerShape(24.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("FIELDS", color = GrayText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    
                    if (!isLogin) {
                        AuthTextField("Name", name) { name = it }
                    }
                    AuthTextField("Email", email) { email = it }
                    AuthTextField("Password", password, isPassword = true) { password = it }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Button(
                onClick = {
                    if (isLogin) viewModel.login(email, password)
                    else viewModel.signup(name, email, password, "", "") // Simplified for now
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(64.dp),
                shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(containerColor = NeonBlue)
            ) {
                if (state is AuthResult.Loading) {
                    CircularProgressIndicator(color = Color.Black, modifier = Modifier.size(24.dp))
                } else {
                    Text("Continue", color = Color.Black, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }

    LaunchedEffect(state) {
        if (state is AuthResult.Success) {
            navController.navigate("role_selection") {
                popUpTo("login") { inclusive = true }
            }
        }
    }
}

@Composable
fun TagChip(label: String) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.1f))
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(label, color = Color.White, fontSize = 12.sp)
    }
}

@Composable
fun ModeButton(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(if (selected) Color.White.copy(alpha = 0.1f) else Color.Transparent)
            .border(1.dp, if (selected) Color.White.copy(alpha = 0.2f) else Color.Transparent, CircleShape)
            .clickable { onClick() }
            .padding(horizontal = 20.dp, vertical = 8.dp)
    ) {
        Text(label, color = if (selected) Color.White else GrayText, fontSize = 14.sp)
    }
}

@Composable
fun AuthTextField(label: String, value: String, isPassword: Boolean = false, onValueChange: (String) -> Unit) {
    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        Text(label, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
        TextField(
            value = value,
            onValueChange = onValueChange,
            visualTransformation = if (isPassword) PasswordVisualTransformation() else VisualTransformation.None,
            modifier = Modifier.fillMaxWidth(),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                cursorColor = NeonBlue,
                focusedTextColor = Color.White,
                unfocusedTextColor = Color.White
            )
        )
    }
}

@Composable
fun RoleSelectionScreen(navController: NavController, viewModel: AuthViewModel = hiltViewModel()) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CyberDark),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(24.dp)) {
            Text("IDENTIFY ROLE", fontSize = 24.sp, fontWeight = FontWeight.Black, color = NeonBlue, letterSpacing = 2.sp)
            Spacer(modifier = Modifier.height(16.dp))
            Text("Select your access level within the ShadowTrace network.", color = GrayText, fontSize = 14.sp, textAlign = TextAlign.Center)
            
            Spacer(modifier = Modifier.height(48.dp))
            
            RoleCard("PROTECTED USER", "Active monitoring & emergency escalation for your journeys.", NeonBlue) {
                navController.navigate("home")
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            RoleCard("GUARDIAN PROTECTOR", "Receive alerts and monitor live tracking for authorized operatives.", NeonCyan) {
                navController.navigate("guardian_home")
            }
        }
    }
}

@Composable
fun RoleCard(title: String, desc: String, color: Color, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = SurfaceDark),
        shape = RoundedCornerShape(24.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.2f))
    ) {
        Column(modifier = Modifier.padding(24.dp)) {
            Text(title, color = color, fontSize = 18.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
            Spacer(modifier = Modifier.height(8.dp))
            Text(desc, color = GrayText, fontSize = 14.sp)
        }
    }
}

// Fixed imports and missing components
import androidx.compose.foundation.clickable
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
