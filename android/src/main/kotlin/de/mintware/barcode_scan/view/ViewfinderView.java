/*
 * Copyright (C) 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package de.mintware.barcode_scan.view;

import android.content.Context;
import android.content.res.Resources;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.Drawable;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.MotionEvent;
import android.view.View;

import androidx.annotation.StringRes;

import com.google.zxing.ResultPoint;

import java.util.Collection;
import java.util.HashSet;

import de.mintware.barcode_scan.DisplayUtil;
import de.mintware.barcode_scan.camera.CameraManager;
import de.mintware.barcodescan.R;

/**
 * 自定义组件实现,扫描功能
 */
public final class ViewfinderView extends View {

    private static final long ANIMATION_DELAY = 30L;
    private static final int OPAQUE = 0xFF;
    /**
     * 字体大小
     */
    private static final int TEXT_SIZE = 13;

    /**
     * 字体距离扫描框下面的距离
     */
    private static final int TEXT_PADDING_TOP = 30;

    /**
     * 手机的屏幕密度
     */
    private float density;
    private final Paint paint;
    private Bitmap resultBitmap;
    private final int maskColor;
    private final int resultColor;
    private final int resultPointColor;
    private int textColor;
    private String text;
    private Collection<ResultPoint> possibleResultPoints;
    private Collection<ResultPoint> lastPossibleResultPoints;
    private Paint textPaint;
    private Rect textRect;
    private String flashClickText = "轻触照亮";
    private RectF flashLightRect;
    private Bitmap flasLightBitmap;
    private Bitmap flasLightBitmapOn;

    private OnFlashClickListener onFlashClickListener;
    private boolean isOn = false;

    public ViewfinderView(Context context) {
        this(context, null);
    }

    public ViewfinderView(Context context, AttributeSet attrs) {
        this(context, attrs, -1);

    }

    public ViewfinderView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        paint = new Paint();
        Resources resources = getResources();
        maskColor = resources.getColor(R.color.viewfinder_mask);
        resultColor = resources.getColor(R.color.result_view);
        resultPointColor = resources.getColor(R.color.possible_result_points);
        possibleResultPoints = new HashSet<>(5);
        density = context.getResources().getDisplayMetrics().density;
        scanLight = BitmapFactory.decodeResource(resources,
                R.drawable.scan_light);

        initInnerRect(context, attrs);
    }

    /**
     * 初始化内部框的大小
     *
     * @param context
     * @param attrs
     */
    private void initInnerRect(Context context, AttributeSet attrs) {
        TypedArray ta = context.obtainStyledAttributes(attrs, R.styleable.ViewfinderView);

        // 扫描框距离顶部
        float innerMarginTop = ta.getDimension(R.styleable.ViewfinderView_inner_margintop, -1);
        if (innerMarginTop != -1) {
            CameraManager.FRAME_MARGINTOP = (int) innerMarginTop;
        }

        int defaultScanWidth = DisplayUtil.screenWidthPx / 2;

        // 扫描框的宽度
        CameraManager.FRAME_WIDTH = (int) ta.getDimension(R.styleable.ViewfinderView_inner_width, defaultScanWidth);

        // 扫描框的高度
        CameraManager.FRAME_HEIGHT = (int) ta.getDimension(R.styleable.ViewfinderView_inner_height, defaultScanWidth);

        // 屏幕小于 450 扫描框设为 200dp
        if (CameraManager.FRAME_WIDTH <= 450) {
            CameraManager.FRAME_WIDTH = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 230f, getResources().getDisplayMetrics());
            CameraManager.FRAME_HEIGHT = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 230f, getResources().getDisplayMetrics());
        }


        // 扫描框边角颜色
        innercornercolor = ta.getColor(R.styleable.ViewfinderView_inner_corner_color, Color.parseColor("#45DDDD"));
        // 扫描框边角长度
        innercornerlength = (int) ta.getDimension(R.styleable.ViewfinderView_inner_corner_length, 65);
        // 扫描框边角宽度
        innercornerwidth = (int) ta.getDimension(R.styleable.ViewfinderView_inner_corner_width, 15);

        textColor = ta.getColor(R.styleable.ViewfinderView_inner_text_color, Color.parseColor("#45DDDD"));

        text = ta.getString(R.styleable.ViewfinderView_inner_text);

        // 扫描bitmap
        Drawable drawable = ta.getDrawable(R.styleable.ViewfinderView_inner_scan_bitmap);
        if (drawable != null) {
        }

        // 扫描控件
        scanLight = BitmapFactory.decodeResource(getResources(), ta.getResourceId(R.styleable.ViewfinderView_inner_scan_bitmap, R.drawable.scan_img_line));
        // 扫描速度
        SCAN_VELOCITY = ta.getInt(R.styleable.ViewfinderView_inner_scan_speed, 5);

        isCircle = ta.getBoolean(R.styleable.ViewfinderView_inner_scan_iscircle, true);

        textPaint = new TextPaint(Paint.ANTI_ALIAS_FLAG);
        textPaint.setTextSize(11 * density);
        textPaint.setColor(Color.WHITE);
        textPaint.setTextAlign(Paint.Align.CENTER);
        textRect = new Rect();
        textPaint.getTextBounds(flashClickText, 0, flashClickText.length() - 1, textRect);

        Resources resources = getResources();
        flasLightBitmap = BitmapFactory.decodeResource(resources, R.drawable.scan_flashlight);
        flasLightBitmapOn = BitmapFactory.decodeResource(resources, R.drawable.scan_flashlight_on);


        ta.recycle();
    }

    @Override
    public void onDraw(Canvas canvas) {
        Rect frame = CameraManager.get().getFramingRect();
        if (frame == null) {
            return;
        }
        int width = canvas.getWidth();
        int height = canvas.getHeight();

        // Draw the exterior (i.e. outside the framing rect) darkened
        paint.setColor(resultBitmap != null ? resultColor : maskColor);
        canvas.drawRect(0, 0, width, frame.top, paint);
        canvas.drawRect(0, frame.top, frame.left, frame.bottom + 1, paint);
        canvas.drawRect(frame.right + 1, frame.top, width, frame.bottom + 1, paint);
        canvas.drawRect(0, frame.bottom + 1, width, height, paint);

        if (resultBitmap != null) {
            // Draw the opaque result bitmap over the scanning rectangle
            paint.setAlpha(OPAQUE);
            canvas.drawBitmap(resultBitmap, frame.left, frame.top, paint);
        } else {

            drawFrameBounds(canvas, frame);

            drawFlashLight(canvas, frame.bottom, frame.left + (frame.right - frame.left) / 2);

            drawScanLight(canvas, frame);

//            drawText(canvas, frame);

            Collection<ResultPoint> currentPossible = possibleResultPoints;
            Collection<ResultPoint> currentLast = lastPossibleResultPoints;
            if (currentPossible.isEmpty()) {
                lastPossibleResultPoints = null;
            } else {
                possibleResultPoints = new HashSet<ResultPoint>(5);
                lastPossibleResultPoints = currentPossible;
                paint.setAlpha(OPAQUE);
                paint.setColor(resultPointColor);

                if (isCircle) {
                    for (ResultPoint point : currentPossible) {
                        canvas.drawCircle(frame.left + point.getX(), frame.top + point.getY(), 6.0f, paint);
                    }
                }
            }
            if (currentLast != null) {
                paint.setAlpha(OPAQUE / 2);
                paint.setColor(resultPointColor);

                if (isCircle) {
                    for (ResultPoint point : currentLast) {
                        canvas.drawCircle(frame.left + point.getX(), frame.top + point.getY(), 3.0f, paint);
                    }
                }
            }

            postInvalidateDelayed(ANIMATION_DELAY, frame.left, frame.top, frame.right, frame.bottom);
        }
    }

    private void drawFlashLight(Canvas canvas, float bottom, float center) {
        textPaint.setColor(Color.WHITE);
        textPaint.setTextSize(11 * density);
        flashLightRect = new RectF(center - 10 * density, bottom - 45 * density - textRect.height(), center + 10 * density, bottom - 15 * density - textRect.height());
        if (isOn) {
            canvas.drawBitmap(flasLightBitmapOn, null, flashLightRect, textPaint);
            textPaint.setColor(Color.parseColor("#10bdc9"));
        } else {
            canvas.drawBitmap(flasLightBitmap, null, flashLightRect, textPaint);
            textPaint.setColor(Color.parseColor("#cccccc"));
        }
        canvas.drawText(flashClickText, center, bottom - 10 * density, textPaint);
        if (!TextUtils.isEmpty(text)) {
            textPaint.setTextSize(13 * density);
            canvas.drawText(text, center, bottom + 20 * density, textPaint);
        }
    }


    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (onFlashClickListener != null && event.getAction() == MotionEvent.ACTION_DOWN) {
            if (textRect != null && flashLightRect != null) {
                float left = Math.min(flashLightRect.centerX() - textRect.centerX(), flashLightRect.left);
                float top = flashLightRect.top;
                float right = Math.max(flashLightRect.centerX() + textRect.centerX(), flashLightRect.right);
                float bottom = flashLightRect.bottom + textRect.height() + 5 * density;
                float x = event.getX();
                float y = event.getY();

                if (x > left && x < right && y > top && y < bottom) {
                    isOn = !isOn;
                    onFlashClickListener.onFlashClick(isOn);
                    return true;
                }

            }
        }
        return super.onTouchEvent(event);
    }

    private void drawText(Canvas canvas, Rect frame) {
        if (!TextUtils.isEmpty(text)) {
            TextPaint textPaint = new TextPaint(Paint.ANTI_ALIAS_FLAG);
            textPaint.setDither(true);
            textPaint.setColor(textColor);
//            textPaint.setTypeface(Typeface.create("System", Typeface.BOLD));
            textPaint.setTextSize(TEXT_SIZE * density);

            StaticLayout layout = new StaticLayout(text, textPaint, frame.width() - TEXT_PADDING_TOP, Layout.Alignment.ALIGN_CENTER, 1.0F, 0.0F, true);
            canvas.translate(frame.left + TEXT_PADDING_TOP, (float) (frame.bottom + (float) TEXT_PADDING_TOP * density));
            layout.draw(canvas);
        }
    }

    // 扫描线移动的y
    private int scanLineTop;
    // 扫描线移动速度
    private int SCAN_VELOCITY;
    // 扫描线
    private Bitmap scanLight;
    // 是否展示小圆点
    private boolean isCircle;

    /**
     * 绘制移动扫描线
     *
     * @param canvas
     * @param frame
     */
    private void drawScanLight(Canvas canvas, Rect frame) {

        if (scanLineTop == 0) {
            scanLineTop = frame.top;
        }

        if (scanLineTop >= frame.bottom - 30) {
            scanLineTop = frame.top;
        } else {
            scanLineTop += SCAN_VELOCITY;
        }
        Rect scanRect = new Rect(frame.left, scanLineTop, frame.right,
                scanLineTop + 30);
        canvas.drawBitmap(scanLight, null, scanRect, paint);
    }


    // 扫描框边角颜色
    private int innercornercolor;
    // 扫描框边角长度
    private int innercornerlength;
    // 扫描框边角宽度
    private int innercornerwidth;

    /**
     * 绘制取景框边框
     *
     * @param canvas
     * @param frame
     */
    private void drawFrameBounds(Canvas canvas, Rect frame) {

        /*paint.setColor(Color.WHITE);
        paint.setStrokeWidth(2);
        paint.setStyle(Paint.Style.STROKE);

        canvas.drawRect(frame, paint);*/

        paint.setColor(innercornercolor);
        paint.setStyle(Paint.Style.FILL);

        int corWidth = innercornerwidth;
        int corLength = innercornerlength;

        // 左上角
        canvas.drawRect(frame.left, frame.top, frame.left + corWidth, frame.top
                + corLength, paint);
        canvas.drawRect(frame.left, frame.top, frame.left
                + corLength, frame.top + corWidth, paint);
        // 右上角
        canvas.drawRect(frame.right - corWidth, frame.top, frame.right,
                frame.top + corLength, paint);
        canvas.drawRect(frame.right - corLength, frame.top,
                frame.right, frame.top + corWidth, paint);
        // 左下角
        canvas.drawRect(frame.left, frame.bottom - corLength,
                frame.left + corWidth, frame.bottom, paint);
        canvas.drawRect(frame.left, frame.bottom - corWidth, frame.left
                + corLength, frame.bottom, paint);
        // 右下角
        canvas.drawRect(frame.right - corWidth, frame.bottom - corLength,
                frame.right, frame.bottom, paint);
        canvas.drawRect(frame.right - corLength, frame.bottom - corWidth,
                frame.right, frame.bottom, paint);


    }

    public void setInnerText(@StringRes int strRes) {
        text = getContext().getResources().getString(strRes);
        invalidate();
    }


    public void drawViewfinder() {
        resultBitmap = null;
        invalidate();
    }

    public void addPossibleResultPoint(ResultPoint point) {
        possibleResultPoints.add(point);
    }


    /**
     * 根据手机的分辨率从 dp 的单位 转成为 px(像素)
     */
    public static int dip2px(Context context, float dpValue) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dpValue * scale + 0.5f);
    }

    public void setFlashStatusClose() {
        isOn = false;
    }

    public void setOnFlashClickListener(OnFlashClickListener onFlashClickListener) {
        this.onFlashClickListener = onFlashClickListener;
    }

    public interface OnFlashClickListener {
        void onFlashClick(boolean isOn);
    }

}
