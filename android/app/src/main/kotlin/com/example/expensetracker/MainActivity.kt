package com.example.expensetracker

import android.Manifest
import android.content.pm.PackageManager
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import org.json.JSONArray
import org.json.JSONException
import java.util.ArrayDeque

class MainActivity : FlutterFragmentActivity() {
    private lateinit var smsChannel: MethodChannel
    private val pendingPermissionResults = ArrayDeque<MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        smsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        smsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSmsPermission" -> result.success(hasSmsPermission())
                "requestSmsPermission" -> requestSmsPermission(result)
                "readPendingSms" -> result.success(readPendingSms())
                "acknowledgePendingSms" -> {
                    val ids = call.arguments as? List<*> ?: emptyList<Any>()
                    acknowledgePendingSms(ids.filterIsInstance<String>())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasSmsPermission(): Boolean =
        checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (hasSmsPermission()) {
            result.success(true)
            return
        }

        val shouldRequestPermission = pendingPermissionResults.isEmpty()
        pendingPermissionResults.addLast(result)
        if (shouldRequestPermission) {
            requestPermissions(arrayOf(Manifest.permission.RECEIVE_SMS), SMS_PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SMS_PERMISSION_REQUEST_CODE) return

        if (pendingPermissionResults.isEmpty()) return

        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        while (pendingPermissionResults.isNotEmpty()) {
            pendingPermissionResults.removeFirst().success(granted)
        }
    }

    private fun readPendingSms(): List<Map<String, Any>> {
        val preferences = getSharedPreferences(IncomingSmsReceiver.STORAGE_NAME, MODE_PRIVATE)
        val pending = readPendingMessages(preferences)
        return buildList {
            for (index in 0 until pending.length()) {
                val message = pending.optJSONObject(index) ?: continue
                add(
                    mapOf(
                        "id" to message.optString("id"),
                        "sender" to message.optString("sender"),
                        "body" to message.optString("body"),
                        "receivedAt" to message.optLong("receivedAt"),
                    ),
                )
            }
        }
    }

    private fun acknowledgePendingSms(ids: List<String>) {
        if (ids.isEmpty()) return

        val preferences = getSharedPreferences(IncomingSmsReceiver.STORAGE_NAME, MODE_PRIVATE)
        val pending = readPendingMessages(preferences)
        val acknowledged = ids.toSet()
        val remaining = JSONArray()
        for (index in 0 until pending.length()) {
            val message = pending.optJSONObject(index) ?: continue
            if (!acknowledged.contains(message.optString("id"))) remaining.put(message)
        }
        preferences.edit().putString(IncomingSmsReceiver.PENDING_KEY, remaining.toString()).apply()
    }

    private fun readPendingMessages(preferences: android.content.SharedPreferences): JSONArray {
        return try {
            JSONArray(preferences.getString(IncomingSmsReceiver.PENDING_KEY, "[]") ?: "[]")
        } catch (_: JSONException) {
            // Reset corrupted data once, allowing subsequent reads and acknowledgements to proceed.
            JSONArray().also {
                preferences.edit().putString(IncomingSmsReceiver.PENDING_KEY, it.toString()).apply()
            }
        }
    }

    companion object {
        private const val CHANNEL_NAME = "expensetracker/sms"
        private const val SMS_PERMISSION_REQUEST_CODE = 4101
    }
}
