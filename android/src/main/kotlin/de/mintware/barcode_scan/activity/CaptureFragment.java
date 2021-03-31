package de.mintware.barcode_scan.activity;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.graphics.Bitmap;
import android.hardware.Camera;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.Vibrator;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.Result;

import org.jetbrains.annotations.NotNull;

import java.io.IOException;
import java.util.Vector;

import de.mintware.barcode_scan.camera.CameraManager;
import de.mintware.barcode_scan.decoding.CaptureActivityHandler;
import de.mintware.barcode_scan.decoding.InactivityTimer;
import de.mintware.barcode_scan.view.ViewfinderView;
import de.mintware.barcodescan.R;

/**
 * 自定义实现的扫描Fragment
 */
public class CaptureFragment extends Fragment implements SurfaceHolder.Callback {

    private CaptureActivityHandler handler;
    private ViewfinderView viewfinderView;
    private boolean hasSurface;
    private Vector<BarcodeFormat> decodeFormats;
    private String characterSet;
    private InactivityTimer inactivityTimer;
    private MediaPlayer mediaPlayer;
    private boolean playBeep;
    private static final float BEEP_VOLUME = 0.10f;
    private boolean vibrate;
    private SurfaceHolder surfaceHolder;
    private CodeUtils.AnalyzeCallback analyzeCallback;
    @SuppressWarnings("deprecation")
    private Camera camera;
    private IScanResultCallback mScanResultCallback;

    @SuppressWarnings("ConstantConditions")
    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        CameraManager.init(getActivity().getApplication());
        this.analyzeCallback = new CodeUtils.AnalyzeCallback() {
            @Override
            public void onAnalyzeSuccess(Bitmap mBitmap, String result, BarcodeFormat mBarcodeFormat) {
                if (!TextUtils.isEmpty(result)) {
                    if (mBarcodeFormat == BarcodeFormat.CODE_39
                            || mBarcodeFormat == BarcodeFormat.CODE_128
                            || mBarcodeFormat == BarcodeFormat.CODE_93
                            || mBarcodeFormat == BarcodeFormat.EAN_8
                            || mBarcodeFormat == BarcodeFormat.EAN_13
                            || mBarcodeFormat == BarcodeFormat.ITF
                            || mBarcodeFormat == BarcodeFormat.UPC_A
                            || mBarcodeFormat == BarcodeFormat.UPC_E
                            || mBarcodeFormat == BarcodeFormat.QR_CODE
                    ) {
                        if (mScanResultCallback != null) {
                            mScanResultCallback.onSuccess(result);
                        }
                    }
                } else {
                    if (mScanResultCallback != null) {
                        mScanResultCallback.onFailure();
                    }
                    restartPreviewAndDecode();
                }
            }

            @Override
            public void onAnalyzeFailed() {
                if (mScanResultCallback != null) {
                    mScanResultCallback.onFailure();
                }
                restartPreviewAndDecode();
            }
        };
        hasSurface = false;
        inactivityTimer = new InactivityTimer(this.getActivity());
    }

    @Nullable
    @Override
    public View onCreateView(@NotNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {

        Bundle bundle = getArguments();
        View view = null;
        if (bundle != null) {
            int layoutId = bundle.getInt(CodeUtils.LAYOUT_ID);
            if (layoutId != -1) {
                view = inflater.inflate(layoutId, null);
            }
        }

        if (view == null) {
            view = inflater.inflate(R.layout.fragment_capture, container, false);
        }

        viewfinderView = view.findViewById(R.id.viewfinder_view);
        viewfinderView.setOnFlashClickListener(new ViewfinderView.OnFlashClickListener() {
            @Override
            public void onFlashClick(boolean isOn) {
                CodeUtils.isLightEnable(isOn);
            }
        });
        SurfaceView surfaceView = view.findViewById(R.id.preview_view);
        surfaceHolder = surfaceView.getHolder();

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        resume();
    }


    @SuppressWarnings({"deprecation", "ConstantConditions"})
    public void resume() {
        if (hasSurface) {
            initCamera(surfaceHolder);
        } else {
            if (surfaceHolder != null) {
                surfaceHolder.addCallback(this);
                surfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
            }
        }
        decodeFormats = null;
        characterSet = null;

        playBeep = true;
        AudioManager audioService = (AudioManager) getActivity().getSystemService(Context.AUDIO_SERVICE);
        if (audioService.getRingerMode() != AudioManager.RINGER_MODE_NORMAL) {
            playBeep = false;
        }
        initBeepSound();
        vibrate = true;
    }

    @Override
    public void onPause() {
        super.onPause();
        pause();
    }


    public void pause() {
        if (handler != null) {
            handler.quitSynchronously();
            handler = null;
        }
        CameraManager.get().closeDriver();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        inactivityTimer.shutdown();
    }


    private void restartPreviewAndDecode() {
        if (null != handler) {
            Message restartMessage = handler.obtainMessage();
            restartMessage.what = R.id.restart_preview;
            handler.sendMessageDelayed(restartMessage, 1000);
        }
    }


    /**
     * Handler scan result
     *
     * @param result  结果
     * @param barcode 图片
     */
    public void handleDecode(Result result, Bitmap barcode) {
        inactivityTimer.onActivity();
        playBeepSoundAndVibrate();

        if (result == null || TextUtils.isEmpty(result.getText())) {
            if (analyzeCallback != null) {
                analyzeCallback.onAnalyzeFailed();
            }
        } else {
            if (analyzeCallback != null) {
                analyzeCallback.onAnalyzeSuccess(barcode, result.getText(), result.getBarcodeFormat());
            }
        }
    }

    private void initCamera(SurfaceHolder surfaceHolder) {
        try {
            CameraManager.get().openDriver(surfaceHolder);
            camera = CameraManager.get().getCamera();
        } catch (Exception e) {
            if (callBack != null) {
                callBack.callBack(e);
            }
            return;
        }
        if (callBack != null) {
            callBack.callBack(null);
        }
        if (handler == null) {
            handler = new CaptureActivityHandler(this, decodeFormats, characterSet, viewfinderView);
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width,
                               int height) {

    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        if (!hasSurface) {
            hasSurface = true;
            initCamera(holder);
        }

    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        hasSurface = false;
        if (camera != null) {
            if (CameraManager.get().isPreviewing()) {
                if (!CameraManager.get().isUseOneShotPreviewCallback()) {
                    camera.setPreviewCallback(null);
                }
                try {
                    camera.stopPreview();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                CameraManager.get().getPreviewCallback().setHandler(null, 0);
                CameraManager.get().getAutoFocusCallback().setHandler(null, 0);
                CameraManager.get().setPreviewing(false);
            }
        }
    }

    public Handler getHandler() {
        return handler;
    }

    public void drawViewfinder() {
        viewfinderView.drawViewfinder();

    }

    @SuppressWarnings("ConstantConditions")
    private void initBeepSound() {
        if (playBeep && mediaPlayer == null) {
            // The volume on STREAM_SYSTEM is not adjustable, and users found it
            // too loud,
            // so we now play on the music stream.
            getActivity().setVolumeControlStream(AudioManager.STREAM_MUSIC);
            mediaPlayer = new MediaPlayer();
            mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
            mediaPlayer.setOnCompletionListener(beepListener);

            AssetFileDescriptor file = getResources().openRawResourceFd(
                    R.raw.beep);
            try {
                mediaPlayer.setDataSource(file.getFileDescriptor(),
                        file.getStartOffset(), file.getLength());
                file.close();
                mediaPlayer.setVolume(BEEP_VOLUME, BEEP_VOLUME);
                mediaPlayer.prepare();
            } catch (IOException e) {
                mediaPlayer = null;
            }
        }
    }

    private static final long VIBRATE_DURATION = 200L;

    @SuppressWarnings("ConstantConditions")
    private void playBeepSoundAndVibrate() {
        if (playBeep && mediaPlayer != null) {
            mediaPlayer.start();
        }
        if (vibrate) {
            Vibrator vibrator = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);
            vibrator.vibrate(VIBRATE_DURATION);
        }
    }

    /**
     * When the beep has finished playing, rewind to queue up another one.
     */
    private final MediaPlayer.OnCompletionListener beepListener = new MediaPlayer.OnCompletionListener() {
        public void onCompletion(MediaPlayer mediaPlayer) {
            mediaPlayer.seekTo(0);
        }
    };

    @SuppressWarnings("unused")
    public CodeUtils.AnalyzeCallback getAnalyzeCallback() {
        return analyzeCallback;
    }

    public void setAnalyzeCallback(CodeUtils.AnalyzeCallback analyzeCallback) {
        this.analyzeCallback = analyzeCallback;
    }

    @Nullable
    CameraInitCallBack callBack;

    public void setScanResultCallback(IScanResultCallback mScanResultCallback) {
        this.mScanResultCallback = mScanResultCallback;
    }

    /**
     * Set callback for Camera check whether Camera init success or not.
     */
    public void setCameraInitCallBack(CameraInitCallBack callBack) {
        this.callBack = callBack;
    }

    public interface CameraInitCallBack {
        /**
         * Callback for Camera init result.
         *
         * @param e If is's null,means success.otherwise Camera init failed with the Exception.
         */
        void callBack(Exception e);
    }

    public interface IScanResultCallback {
        void onSuccess(String barCode);

        void onFailure();
    }

}
