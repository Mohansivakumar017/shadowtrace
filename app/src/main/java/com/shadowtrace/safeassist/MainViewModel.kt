package com.shadowtrace.safeassist

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {
    private val contactsRepository = TrustedContactsRepository(application)
    private val alertDispatcher = AlertDispatcher(application)

    private val _uiState = MutableStateFlow(UiState(contacts = contactsRepository.loadContacts()))
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val statusName = intent?.getStringExtra(SafetyForegroundService.EXTRA_STATUS) ?: return
            val status = TripStatus.valueOf(statusName)
            val location = intent.getStringExtra(SafetyForegroundService.EXTRA_LOCATION) ?: "No location yet"
            val prompt = intent.getBooleanExtra(SafetyForegroundService.EXTRA_PROMPT_PENDING, false)

            _uiState.value = _uiState.value.copy(
                status = status,
                lastKnownLocation = location,
                safetyPromptPending = prompt
            )
        }
    }

    init {
        application.registerReceiver(
            statusReceiver,
            IntentFilter(SafetyForegroundService.ACTION_STATUS),
            Context.RECEIVER_NOT_EXPORTED
        )
    }

    fun addContact(name: String, phone: String) {
        if (name.isBlank() || phone.isBlank()) return
        val updated = (_uiState.value.contacts + TrustedContact(name.trim(), phone.trim())).distinctBy { it.phoneNumber }
        contactsRepository.saveContacts(updated)
        _uiState.value = _uiState.value.copy(contacts = updated)
    }

    fun removeContact(phone: String) {
        val updated = _uiState.value.contacts.filterNot { it.phoneNumber == phone }
        contactsRepository.saveContacts(updated)
        _uiState.value = _uiState.value.copy(contacts = updated)
    }

    fun startTrip() {
        val app = getApplication<Application>()
        val intent = Intent(app, SafetyForegroundService::class.java)
        ContextCompat.startForegroundService(app, intent)
        _uiState.value = _uiState.value.copy(status = TripStatus.ACTIVE)
    }

    fun stopTrip() {
        val app = getApplication<Application>()
        val intent = Intent(app, SafetyForegroundService::class.java).apply {
            action = SafetyForegroundService.ACTION_STOP
        }
        app.startService(intent)
        _uiState.value = _uiState.value.copy(status = TripStatus.IDLE, safetyPromptPending = false)
    }

    fun confirmSafety() {
        _uiState.value = _uiState.value.copy(status = TripStatus.ACTIVE, safetyPromptPending = false)
    }

    fun triggerEmergency() {
        viewModelScope.launch {
            val message = "Manual emergency triggered from SafeAssist. Last known location: ${_uiState.value.lastKnownLocation}"
            alertDispatcher.dispatchEmergencyAlert(_uiState.value.contacts, message)
            _uiState.value = _uiState.value.copy(status = TripStatus.ESCALATED, safetyPromptPending = false)
        }
    }

    override fun onCleared() {
        getApplication<Application>().unregisterReceiver(statusReceiver)
        super.onCleared()
    }
}
