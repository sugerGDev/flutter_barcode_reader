@file:Suppress("PrivatePropertyName")

package de.mintware.barcode_scan.activity

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.text.TextUtils
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.yanzhenjie.permission.AndPermission
import com.yanzhenjie.permission.runtime.Permission
import de.mintware.barcode_scan.scanner.StorageResult
import de.mintware.barcodescan.R
import kotlinx.android.synthetic.main.activity_scan.*


class ScanActivity : AppCompatActivity() {

    private val REQUEST_CODE_PERMISSION = 1003
    private val REQUEST_CODE_INPUT = 1004
//    override var isStatusBarLight: Boolean = true
//    override var isFloatDragger: Boolean = false
//    override fun getContentLayoutResId(): Int = R.layout.activity_scan

//    private var _dialog: CameraPreviewTipDialog? = null

    private lateinit var _captureFragment: CaptureFragment
    private var isRequest = false
    private var from = -1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_scan)

        if (Build.VERSION.SDK_INT >= 21) {
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.statusBarColor = resources.getColor(R.color.color2)
        }

//        if (null != intent) {
//            from = intent.getIntExtra(SCAN_FORM_TYPE, -1)
//        }

//        if (from == CommonRepository.CONFIG_TYPE_STOREIN || from == CommonRepository.CONFIG_TYPE_QUALITY_CONTROL) {
        tvHistory.visibility = View.VISIBLE
//        }

        initCaptureFragment()

        initClick()
    }

    private fun initClick() {
        tvInput.setOnClickListener {
            val intent = Intent()
            intent.putExtra("SCAN_RESULT", StorageResult("", StorageResult.OPERATION_TYPE_INPUT))
            setResult(RESULT_OK, intent)
            finish()
        }

        tvHistory.setOnClickListener {
            val intent = Intent()
            intent.putExtra("SCAN_RESULT", StorageResult("", StorageResult.OPERATION_TYPE_HISTORY))
            setResult(RESULT_OK, intent)
            finish()
        }

        tvBack.setOnClickListener { finish() }
    }

    private fun initCaptureFragment() {
        _captureFragment = CaptureFragment()
        _captureFragment.setScanResultCallback(object : CaptureFragment.IScanResultCallback {
            override fun onSuccess(barCode: String?) {
                if (barCode != null) {
                    setScanResult(barCode)
                }
            }

            override fun onFailure() {
                Toast.makeText(this@ScanActivity, "扫描失败", Toast.LENGTH_SHORT)
            }

        })
        CodeUtils.setFragmentArgs(
                _captureFragment,
                R.layout.layout_scan_view,
                R.string.suplus_scan_tip
        )
        _captureFragment.setCameraInitCallBack { e ->
            if (e != null) {
                if (isRequest) {
                    val permission = arrayListOf(Permission.CAMERA)
                    if (AndPermission.hasAlwaysDeniedPermission(this, permission)) {
                        showSettingDialog(this, permission)
                        return@setCameraInitCallBack
                    }
                    finish()
                } else {
                    requestPermission()
                    isRequest = true
                }
            }
        }
        supportFragmentManager.beginTransaction()
                .replace(R.id.fl_my_container, _captureFragment)
                .commit()
    }

    @Suppress("unused")
    private fun showCameraPreviewDialog() {
//        val builder = CameraPreviewTipDialog.CameraPreviewTipDialogBuilder(this)
//        _dialog = builder.build()
//        _dialog?.setOnDismissListener { finish() }
//        _dialog?.show()
    }


    @Suppress("SENSELESS_COMPARISON")
    private fun requestPermission() {
        if (!AndPermission.hasPermissions(this, Permission.Group.CAMERA)) {
            AndPermission.with(this)
                    .runtime()
                    .permission(Permission.Group.CAMERA)
                    .onGranted {
                        if (_captureFragment != null) {
                            _captureFragment.pause()
                            _captureFragment.resume()
                        }
                    }
                    .onDenied {
                    }.start()
        }
    }


    /**
     * 显示设置对话框
     */
    private fun showSettingDialog(context: Context, permissions: List<String>) {
        val permissionNames = Permission.transformText(context, permissions)
        val message =
                context.getString(
                        R.string.message_permission_always_failed,
                        TextUtils.join("\n", permissionNames)
                )
        AlertDialog.Builder(context)
                .setCancelable(false)
                .setTitle("提示")
                .setMessage(message)
                .setPositiveButton("设置") { _, _ ->
                    setPermission(context)
                    finish()
                }
                .setNegativeButton("取消") { dialog, _ ->
                    dialog.dismiss()
                    finish()
                }
                .show()
    }


    /**
     * 设置权限
     */
    private fun setPermission(context: Context) {
        AndPermission.with(context)
                .runtime()
                .setting()
                .start(REQUEST_CODE_PERMISSION)
    }


    private fun setScanResult(result: String) {
        val intent = Intent()
        intent.putExtra("SCAN_RESULT", StorageResult(result, StorageResult.OPERATION_TYPE_SCANNER))
        setResult(Activity.RESULT_OK, intent)
        finish()
    }


//    private fun setInputResult(storeProduct: StoreProduct) {
//        val intent = Intent()
//        intent.putExtra(ARouterConstants.SCAN_RESULT, storeProduct)
//        intent.putExtra(ARouterConstants.SCAN_TYPE, ARouterConstants.SCAN_TYPE_INPUT)
//        setResult(Activity.RESULT_OK, intent)
//        finish()
//    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PERMISSION) {
            finish()
        } //else if (requestCode == REQUEST_CODE_INPUT) {
//            if (Activity.RESULT_OK == resultCode && null != data) {
//                val storeProduct =
//                    data.getParcelableExtra<StoreProduct>(ScanInputActivity.EXTRA_RESULT)
//                if (null != storeProduct) {
////                    setInputResult(storeProduct)
//                }
//            }
//        }
    }

}
