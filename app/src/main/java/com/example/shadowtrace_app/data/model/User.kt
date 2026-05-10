package com.example.shadowtrace_app.data.model

data class User(
    val uid: String = "",
    val name: String = "",
    val email: String = "",
    val phone: String = "",
    val guardianPhone: String = "",
    val role: String = "USER" // USER or GUARDIAN
)
