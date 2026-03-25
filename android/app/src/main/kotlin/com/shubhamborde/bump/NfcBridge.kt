package com.shubhamborde.bump

import android.content.ComponentName
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge between the Flutter layer and the native NFC HCE service.
 *
 * Exposes a MethodChannel `com.shubhamborde.bump/nfc_hce` with methods:
 *   - `setVCard(String vcf)` — sets the vCard the HCE service will serve.
 *   - `setExchangeUri(String uri)` — sets a bump:// URI to serve.
 *   - `isHceSupported` — returns true if the device supports HCE.
 *   - `enableHce` — enables the HCE service component.
 *   - `disableHce` — disables the HCE service component.
 */
object NfcBridge {

    private const val CHANNEL = "com.shubhamborde.bump/nfc_hce"

    fun register(flutterEngine: FlutterEngine, activity: MainActivity) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setVCard" -> {
                        val vcf = call.argument<String>("vcf") ?: ""
                        CardEmulationService.setVCard(vcf)
                        result.success(true)
                    }
                    "setExchangeUri" -> {
                        val uri = call.argument<String>("uri") ?: ""
                        CardEmulationService.setExchangeUri(uri)
                        result.success(true)
                    }
                    "isHceSupported" -> {
                        val adapter = NfcAdapter.getDefaultAdapter(activity)
                        val supported = adapter != null &&
                                activity.packageManager.hasSystemFeature(
                                    PackageManager.FEATURE_NFC_HOST_CARD_EMULATION
                                )
                        result.success(supported)
                    }
                    "enableHce" -> {
                        activity.packageManager.setComponentEnabledSetting(
                            ComponentName(activity, CardEmulationService::class.java),
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                            PackageManager.DONT_KILL_APP
                        )
                        // Make our service the preferred one for the NDEF AID
                        val adapter = NfcAdapter.getDefaultAdapter(activity)
                        if (adapter != null) {
                            val ce = CardEmulation.getInstance(adapter)
                            ce.setPreferredService(
                                activity,
                                ComponentName(activity, CardEmulationService::class.java)
                            )
                        }
                        result.success(true)
                    }
                    "disableHce" -> {
                        val adapter = NfcAdapter.getDefaultAdapter(activity)
                        if (adapter != null) {
                            val ce = CardEmulation.getInstance(adapter)
                            ce.unsetPreferredService(activity)
                        }
                        activity.packageManager.setComponentEnabledSetting(
                            ComponentName(activity, CardEmulationService::class.java),
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                            PackageManager.DONT_KILL_APP
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
