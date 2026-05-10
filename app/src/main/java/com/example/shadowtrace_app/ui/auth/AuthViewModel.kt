package com.example.shadowtrace_app.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.shadowtrace_app.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val repository: AuthRepository
) : ViewModel() {

    private val _authState = MutableStateFlow<AuthResult>(AuthResult.Idle)
    val authState: StateFlow<AuthResult> = _authState

    fun login(email: String, pass: String) {
        viewModelScope.launch {
            _authState.value = AuthResult.Loading
            try {
                repository.login(email, pass)
                _authState.value = AuthResult.Success
            } catch (e: Exception) {
                _authState.value = AuthResult.Error(e.message ?: "Login failed")
            }
        }
    }

    fun signup(name: String, email: String, pass: String, phone: String, guardianPhone: String) {
        viewModelScope.launch {
            _authState.value = AuthResult.Loading
            try {
                repository.signup(name, email, pass, phone, guardianPhone)
                _authState.value = AuthResult.Success
            } catch (e: Exception) {
                _authState.value = AuthResult.Error(e.message ?: "Signup failed")
            }
        }
    }
}

sealed class AuthResult {
    object Idle : AuthResult()
    object Loading : AuthResult()
    object Success : AuthResult()
    data class Error(val message: String) : AuthResult()
}
