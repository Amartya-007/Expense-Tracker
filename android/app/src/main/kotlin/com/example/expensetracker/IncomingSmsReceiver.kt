package com.example.expensetracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.util.UUID

class IncomingSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        val grouped = messages.groupBy { it.originatingAddress.orEmpty() }
        val preferences = context.getSharedPreferences(STORAGE_NAME, Context.MODE_PRIVATE)
        val existing = try {
            JSONArray(preferences.getString(PENDING_KEY, "[]") ?: "[]")
        } catch (_: JSONException) {
            // Discard corrupt queued data so a malformed preference cannot crash SMS delivery.
            JSONArray().also { preferences.edit().putString(PENDING_KEY, it.toString()).apply() }
        }
        val knownIds = mutableSetOf<String>()
        for (index in 0 until existing.length()) {
            existing.optJSONObject(index)?.optString("id")?.let(knownIds::add)
        }

        grouped.forEach { (sender, parts) ->
            val body = parts.joinToString(separator = "") { it.messageBody.orEmpty() }
                .take(MAX_BODY_LENGTH)
            if (body.isBlank()) return@forEach

            val receivedAt = parts.maxOfOrNull { it.timestampMillis } ?: System.currentTimeMillis()
            val id = stableId(sender, receivedAt, body)
            if (knownIds.contains(id)) return@forEach

            existing.put(
                JSONObject()
                    .put("id", id)
                    .put("sender", sender)
                    .put("body", body)
                    .put("receivedAt", receivedAt),
            )
            knownIds.add(id)
        }

        val firstKeptIndex = (existing.length() - MAX_PENDING_MESSAGES).coerceAtLeast(0)
        val trimmed = JSONArray()
        for (index in firstKeptIndex until existing.length()) {
            existing.optJSONObject(index)?.let(trimmed::put)
        }
        preferences.edit().putString(PENDING_KEY, trimmed.toString()).apply()
    }

    private fun stableId(sender: String, timestamp: Long, body: String): String {
        val digest = try {
            MessageDigest.getInstance("SHA-256")
                .digest("$sender|$timestamp|$body".toByteArray())
        } catch (_: NoSuchAlgorithmException) {
            return UUID.randomUUID().toString()
        }
        return digest.joinToString(separator = "") { byte ->
            "%02x".format(byte.toInt() and 0xff)
        }
    }

    companion object {
        const val STORAGE_NAME = "sms_capture"
        const val PENDING_KEY = "pending_messages"
        private const val MAX_BODY_LENGTH = 4000
        private const val MAX_PENDING_MESSAGES = 100
    }
}
