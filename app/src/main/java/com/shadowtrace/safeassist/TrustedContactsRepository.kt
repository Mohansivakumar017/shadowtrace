package com.shadowtrace.safeassist

import android.content.Context
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class TrustedContactsRepository(context: Context) {
    private val prefs = context.getSharedPreferences("safeassist_prefs", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    fun loadContacts(): List<TrustedContact> {
        val raw = prefs.getString(KEY_CONTACTS, null) ?: return emptyList()
        return runCatching { json.decodeFromString<List<TrustedContact>>(raw) }.getOrDefault(emptyList())
    }

    fun saveContacts(contacts: List<TrustedContact>) {
        prefs.edit().putString(KEY_CONTACTS, json.encodeToString(contacts)).apply()
    }

    companion object {
        private const val KEY_CONTACTS = "trusted_contacts"
    }
}
