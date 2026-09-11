package pk.darazindaconnect.app

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.CellInfo
import android.telephony.CellInfoLte
import android.telephony.CellInfoNr
import android.telephony.CellInfoWcdma
import android.telephony.CellInfoGsm
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes real, OS-reported cellular telephony data to Dart. Every
 * value returned is either an actual reading from [TelephonyManager] /
 * [CellInfo], or `null` when the platform does not expose it (mapped to
 * "Not available on this device" in the UI) — nothing here is ever
 * fabricated or estimated beyond what Android itself reports.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "pk.darazindaconnect.app/telephony"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTelephonyInfo" -> result.success(getTelephonyInfo())
                    else -> result.notImplemented()
                }
            }
    }

    @SuppressLint("MissingPermission")
    private fun getTelephonyInfo(): Map<String, Any?> {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            ?: return emptyMap()

        val hasPhoneStatePermission = ActivityCompat.checkSelfPermission(
            this,
            android.Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

        val operatorName: String? = tm.networkOperatorName?.takeIf { it.isNotBlank() }
        val simCountryIso: String? = tm.simCountryIso?.takeIf { it.isNotBlank() }
        val networkType: String = networkTypeToString(
            if (hasPhoneStatePermission) tm.dataNetworkType else TelephonyManager.NETWORK_TYPE_UNKNOWN
        )

        var signalDbm: Int? = null
        var signalAsu: Int? = null

        val hasLocationPermission = ActivityCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (hasLocationPermission && hasPhoneStatePermission) {
            try {
                val cellInfoList: List<CellInfo>? = tm.allCellInfo
                val registered = cellInfoList?.firstOrNull { it.isRegistered }
                registered?.let { cell ->
                    when (cell) {
                        is CellInfoLte -> {
                            signalDbm = cell.cellSignalStrength.dbm
                            signalAsu = cell.cellSignalStrength.asuLevel
                        }
                        is CellInfoWcdma -> {
                            signalDbm = cell.cellSignalStrength.dbm
                            signalAsu = cell.cellSignalStrength.asuLevel
                        }
                        is CellInfoGsm -> {
                            signalDbm = cell.cellSignalStrength.dbm
                            signalAsu = cell.cellSignalStrength.asuLevel
                        }
                        else -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                                cell is CellInfoNr
                            ) {
                                signalDbm = cell.cellSignalStrength.dbm
                                signalAsu = cell.cellSignalStrength.asuLevel
                            }
                        }
                    }
                }
            } catch (e: SecurityException) {
                // Permission revoked mid-call; leave signal values null.
            }
        }

        return mapOf(
            "operatorName" to operatorName,
            "networkType" to networkType,
            "simCountryIso" to simCountryIso,
            "signalDbm" to signalDbm,
            "signalAsu" to signalAsu,
            "hasPhoneStatePermission" to hasPhoneStatePermission,
            "hasLocationPermission" to hasLocationPermission,
        )
    }

    private fun networkTypeToString(type: Int): String = when (type) {
        TelephonyManager.NETWORK_TYPE_NR -> "5G"
        TelephonyManager.NETWORK_TYPE_LTE -> "4G (LTE)"
        TelephonyManager.NETWORK_TYPE_HSPA,
        TelephonyManager.NETWORK_TYPE_HSPAP,
        TelephonyManager.NETWORK_TYPE_UMTS,
        TelephonyManager.NETWORK_TYPE_EVDO_0,
        TelephonyManager.NETWORK_TYPE_EVDO_A,
        TelephonyManager.NETWORK_TYPE_EVDO_B -> "3G"
        TelephonyManager.NETWORK_TYPE_GPRS,
        TelephonyManager.NETWORK_TYPE_EDGE,
        TelephonyManager.NETWORK_TYPE_CDMA,
        TelephonyManager.NETWORK_TYPE_1xRTT -> "2G"
        else -> "Unknown"
    }
}
