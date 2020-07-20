package de.mintware.barcode_scan

import android.app.Activity
import android.content.Intent
import de.mintware.barcode_scan.scanner.StorageResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

class BarcodeScanPlugin() : MethodCallHandler, PluginRegistry.ActivityResultListener, FlutterPlugin, ActivityAware {

    private var result: Result? = null
    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    constructor(activity: Activity?) : this() {
        this.activity = activity
    }

    companion object {
        const val OPERATION_TYPE_NONE = 0
        const val OPERATION_TYPE_INPUT = 1
        const val OPERATION_TYPE_HISTORY = 2
        const val OPERATION_TYPE_ALL = 3

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "de.mintware.barcode_scan")
            if (registrar.activity() != null) {
                val plugin = BarcodeScanPlugin(registrar.activity())
                channel.setMethodCallHandler(plugin)
                registrar.addActivityResultListener(plugin)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "scan") {
            this.result = result
            val operationType = call.argument<Int>("button_key")
            showBarcodeView(operationType)
        } else {
            result.notImplemented()
        }
    }

    private fun showBarcodeView(operationType: Int?) {
        activity?.let {
            val intent = Intent(it, StorageScannerActivity::class.java)
            intent.putExtra("operationType", operationType)
            it.startActivityForResult(intent, 100)
        }
    }

    override fun onActivityResult(code: Int, resultCode: Int, data: Intent?): Boolean {
        if (code == 100) {
            if (resultCode == Activity.RESULT_OK) {
                val barcode = data?.getParcelableExtra<StorageResult>("SCAN_RESULT")
                barcode?.let {
                    when (it.operationType) {
                        StorageResult.OPERATION_TYPE_SCANNER -> {
                            this.result?.success(barcode.code)
                        }
                        StorageResult.OPERATION_TYPE_INPUT -> {
                            this.result?.success("input_key")
                        }
                        StorageResult.OPERATION_TYPE_HISTORY -> {
                            this.result?.success("history_key")
                        }
                        else -> {

                        }
                    }
                }
            } else {
                val errorCode = data?.getStringExtra("ERROR_CODE")
                this.result?.error(errorCode, null, null)
            }
            return true
        }
        return false
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "de.mintware.barcode_scan")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val plugin = BarcodeScanPlugin(binding.activity)
        channel?.setMethodCallHandler(plugin)
        binding.addActivityResultListener(plugin)
    }

    override fun onDetachedFromActivity() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

}
