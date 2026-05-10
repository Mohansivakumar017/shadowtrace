package com.example.shadowtrace_app.ui.sos

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.shadowtrace_app.data.repository.AlertRepository
import com.example.shadowtrace_app.data.repository.AuthRepository
import com.example.shadowtrace_app.util.AlertSoundPlayer
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SOSViewModel @Inject constructor(
    private val alertRepository: AlertRepository,
    private val authRepository: AuthRepository,
    private val soundPlayer: AlertSoundPlayer
) : ViewModel() {

    private val _uiState = MutableStateFlow<SOSUiState>(SOSUiState.Idle)
    val uiState: StateFlow<SOSUiState> = _uiState

    fun triggerSOS(lat: Double, lng: Double) {
        // Trigger existing alarm immediately
        soundPlayer.playAlert()
        
        viewModelScope.launch {
            _uiState.value = SOSUiState.Loading
            try {
                val user = authRepository.getCurrentUser()
                val userDetails = user?.let { authRepository.getUserDetails(it.uid) }
                
                if (userDetails != null) {
                    alertRepository.triggerAlert(
                        userId = userDetails.uid,
                        guardianPhone = userDetails.guardianPhone,
                        lat = lat,
                        lng = lng
                    )
                    _uiState.value = SOSUiState.Triggered
                } else {
                    _uiState.value = SOSUiState.Error("Session missing credentials")
                }
            } catch (e: Exception) {
                _uiState.value = SOSUiState.Error(e.message ?: "Dispatch failed")
            }
        }
    }

    fun cancelAlert() {
        soundPlayer.stopAlert()
        _uiState.value = SOSUiState.Idle
    }
}

sealed class SOSUiState {
    object Idle : SOSUiState()
    object Loading : SOSUiState()
    object Triggered : SOSUiState()
    data class Error(val message: String) : SOSUiState()
}
