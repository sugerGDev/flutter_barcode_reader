package de.mintware.barcode_scan

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.*
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import de.mintware.barcode_scan.scanner.StorageResult
import de.mintware.barcode_scan.scanner.StorageScannerView
import de.mintware.barcodescan.R
import java.lang.RuntimeException


class StorageScannerActivity : Activity(), StorageScannerView.ResultHandler {

    var scannerView: StorageScannerView? = null
    private var operationType: Int = 0

    companion object {
        val REQUEST_TAKE_PHOTO_CAMERA_PERMISSION = 100
        val TOGGLE_FLASH = 200

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        operationType = intent?.getIntExtra("operationType", 0) ?: 0
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        scannerView = StorageScannerView(this)
        scannerView?.setAutoFocus(true)
        // this paramter will make your HUAWEI phone works great!
        scannerView?.setAspectTolerance(0.5f)
        setContentView(scannerView)
    }


//    override fun onCreateOptionsMenu(menu: Menu): Boolean {
//        if (scannerView.flash) {
//            val item = menu.add(0,
//                    TOGGLE_FLASH, 0, "关闭闪光灯")
//            item.setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS)
//        } else {
//            val item = menu.add(0,
//                    TOGGLE_FLASH, 0, "开启闪光灯")
//            item.setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS)
//        }
//        return super.onCreateOptionsMenu(menu)
//    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == TOGGLE_FLASH) {
            scannerView?.flash = !(scannerView?.flash ?: false)
            this.invalidateOptionsMenu()
            return true
        }
        return super.onOptionsItemSelected(item)
    }

    override fun onResume() {
        super.onResume()
        scannerView?.setResultHandler(this)
        // start camera immediately if permission is already given
        if (!requestCameraAccessIfNecessary()) {
            scannerView?.startCamera()
        }
    }

    override fun onPause() {
        super.onPause()
        scannerView?.stopCamera()
    }

    override fun handleResult(result: StorageResult?) {
        when (result?.operationType) {
            StorageResult.OPERATION_TYPE_SCANNER -> {
                val intent = Intent()
                intent.putExtra("SCAN_RESULT", result)
                setResult(Activity.RESULT_OK, intent)
                finish()
            }
        }

    }

    override fun getFrontView(): ViewGroup {
        val storageOperationView = layoutInflater.inflate(R.layout.layout_storage_operation, scannerView, false) as ViewGroup
        initFrontView(storageOperationView)
        return storageOperationView
    }

    fun initFrontView(frontView: ViewGroup) {
        val tvFlashlight = frontView.findViewById<TextView>(R.id.tvFlashlight)
        val tvInput = frontView.findViewById<View>(R.id.tvInput)
        val flBottom = frontView.findViewById<FrameLayout>(R.id.flBottom)
        try {
            if (scannerView?.flash == true) {
                tvFlashlight.isSelected = true
                tvFlashlight.text = "轻触关灯"
            } else {
                tvFlashlight.isSelected = false
                tvFlashlight.text = "轻触照亮"
            }
        } catch (e: RuntimeException) {

        }

        tvFlashlight.setOnClickListener {
            clickFlashlight(tvFlashlight)
        }

        frontView.findViewById<View>(R.id.ivBack).setOnClickListener {
            finish()
        }

        tvInput.setOnClickListener {
            val intent = Intent()
            intent.putExtra("SCAN_RESULT", StorageResult("", StorageResult.OPERATION_TYPE_INPUT))
            setResult(RESULT_OK, intent)
            finish()
        }

    }

    fun clickFlashlight(tvFlashlight: TextView) {
        scannerView?.flash = !(scannerView?.flash ?: false)
        if (scannerView?.flash == true) {
            tvFlashlight.isSelected = true
            tvFlashlight.text = "轻触关灯"
        } else {
            tvFlashlight.isSelected = false
            tvFlashlight.text = "轻触照亮"
        }
    }

    fun finishWithError(errorCode: String) {
        val intent = Intent()
        intent.putExtra("ERROR_CODE", errorCode)
        setResult(Activity.RESULT_CANCELED, intent)
        finish()
    }

    private fun requestCameraAccessIfNecessary(): Boolean {
        val array = arrayOf(Manifest.permission.CAMERA)
        if (ContextCompat
                        .checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {

            ActivityCompat.requestPermissions(this, array,
                    REQUEST_TAKE_PHOTO_CAMERA_PERMISSION)
            return true
        }
        return false
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        when (requestCode) {
            REQUEST_TAKE_PHOTO_CAMERA_PERMISSION -> {
                if (PermissionUtil.verifyPermissions(grantResults)) {
                    scannerView?.startCamera()
                } else {
                    finishWithError("PERMISSION_NOT_GRANTED")
                }
            }
            else -> {
                super.onRequestPermissionsResult(requestCode, permissions, grantResults)
            }
        }
    }
}

