package com.shadowtrace.safeassist

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.content.ContextCompat

class AlertDispatcher(private val context: Context) {
    fun dispatchEmergencyAlert(contacts: List<TrustedContact>, message: String) {
        if (contacts.isEmpty()) return
        if (!hasSmsPermission()) return

        val smsManager = SmsManager.getDefault()
        contacts.forEach { contact ->
            runCatching { smsManager.sendTextMessage(contact.phoneNumber, null, message, null, null) }
        }
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }
}
