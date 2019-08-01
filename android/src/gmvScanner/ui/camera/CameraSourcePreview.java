/*
 * Copyright (C) The Android Open Source Project
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
package com.dealrinc.gmvScanner.ui.camera;

import android.Manifest;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.hardware.Camera;
import android.support.annotation.RequiresPermission;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.view.View;
import android.widget.Button;

import com.google.android.gms.common.images.Size;

import java.io.IOException;

public class CameraSourcePreview extends ViewGroup {
    private static final String TAG = "CameraSourcePreview";
    private Context mContext;
    private SurfaceView mSurfaceView;
    private View mViewFinderView;
    private Button mTorchButton;
    private boolean mStartRequested;
    private boolean mSurfaceAvailable;
    private CameraSource mCameraSource;

    public double ViewFinderWidth = .5;
    public double ViewFinderHeight = .8;

    private GraphicOverlay mOverlay;

    public CameraSourcePreview(Context context, AttributeSet attrs) {
        super(context, attrs);
        mContext = context;
        mStartRequested = false;
        mSurfaceAvailable = false;

        mSurfaceView = new SurfaceView(context);
        mSurfaceView.getHolder().addCallback(new SurfaceCallback());
        addView(mSurfaceView);

        mViewFinderView = new View(mContext);
        mViewFinderView.setBackgroundResource(getResources().getIdentifier("rounded_rectangle", "drawable", mContext.getPackageName()));
        addView(mViewFinderView);

        mTorchButton = new Button(mContext);
        mTorchButton.setMaxWidth(50);
        mTorchButton.setRotation(90);

        mTorchButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                try {
                    mCameraSource.setFlashMode(mCameraSource.getFlashMode() == Camera.Parameters.FLASH_MODE_OFF ? Camera.Parameters.FLASH_MODE_TORCH :Camera.Parameters.FLASH_MODE_OFF);
                    mTorchButton.setBackgroundResource(getResources().getIdentifier(mCameraSource.getFlashMode() ==  Camera.Parameters.FLASH_MODE_TORCH ? "torch_active" : "torch_inactive", "drawable", mContext.getPackageName()));
                } catch(Exception e) {

                }
            }
        });
        addView(mTorchButton);
    }

    public int dpToPx(int dp) {
        float density = mContext.getResources()
                .getDisplayMetrics()
                .density;
        return Math.round((float) dp * density);
    }

    @RequiresPermission(Manifest.permission.CAMERA)
    public void start(CameraSource cameraSource) throws IOException, SecurityException {
        if (cameraSource == null) {
            stop();
        }

        mCameraSource = cameraSource;

        if (mCameraSource.getFlashMode() == Camera.Parameters.FLASH_MODE_TORCH){
            mTorchButton.setBackgroundResource(getResources().getIdentifier("torch_active", "drawable", mContext.getPackageName()));
        } else {
            mTorchButton.setBackgroundResource(getResources().getIdentifier("torch_inactive", "drawable", mContext.getPackageName()));
        }

        if (mCameraSource != null) {
            mStartRequested = true;
            startIfReady();
        }
    }

    @RequiresPermission(Manifest.permission.CAMERA)
    public void start(CameraSource cameraSource, GraphicOverlay overlay) throws IOException, SecurityException {
        mOverlay = overlay;
        start(cameraSource);
    }

    public void stop() {
        if (mCameraSource != null) {
            mCameraSource.stop();
        }
    }

    public void release() {
        if (mCameraSource != null) {
            mCameraSource.release();
            mCameraSource = null;
        }
    }

    @RequiresPermission(Manifest.permission.CAMERA)
    private void startIfReady() throws IOException, SecurityException {
        if (mStartRequested && mSurfaceAvailable) {
            mCameraSource.start(mSurfaceView.getHolder());
            if (mOverlay != null) {
                Size size = mCameraSource.getPreviewSize();
                int min = Math.min(size.getWidth(), size.getHeight());
                int max = Math.max(size.getWidth(), size.getHeight());
                if (isPortraitMode()) {
                    // Swap width and height sizes when in portrait, since it will be rotated by
                    // 90 degrees
                    mOverlay.setCameraInfo(min, max, mCameraSource.getCameraFacing());
                } else {
                    mOverlay.setCameraInfo(max, min, mCameraSource.getCameraFacing());
                }
                mOverlay.clear();
            }
            mStartRequested = false;
        }
    }

    private class SurfaceCallback implements SurfaceHolder.Callback {
        @Override
        public void surfaceCreated(SurfaceHolder surface) {
            mSurfaceAvailable = true;
            try {
                startIfReady();
            } catch (SecurityException se) {
                Log.e(TAG,"Do not have permission to start the camera", se);
            } catch (IOException e) {
                Log.e(TAG, "Could not start camera source.", e);
            }
        }

        @Override
        public void surfaceDestroyed(SurfaceHolder surface) {
            mSurfaceAvailable = false;
        }

        @Override
        public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        }
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        int width = 320;
        int height = 240;
        if (mCameraSource != null) {
            Size size = mCameraSource.getPreviewSize();
            if (size != null) {
                width = size.getWidth();
                height = size.getHeight();
            }
        }

        // Swap width and height sizes when in portrait, since it will be rotated 90 degrees
        if (isPortraitMode()) {
            int tmp = width;
            //noinspection SuspiciousNameCombination
            width = height;
            height = tmp;
        }

        final int layoutWidth = right - left;
        final int layoutHeight = bottom - top;

        // Computes height and width for potentially doing fit width.

        int childHeight = layoutHeight;
        int childWidth = (int)(((float) layoutHeight / (float) height) * width);
        int leftOffset = ((int)((float) layoutHeight / (float) height) * width - childWidth) / 2;
        int topOffset = 0;


        if (childHeight > layoutHeight) {
            childWidth = layoutWidth;
            childHeight = (int)(((float) layoutWidth / (float) width) * height);

            leftOffset = 0;
            topOffset = ((int)((float) layoutWidth / (float) width) * height - childHeight) / 2;
        }

        mSurfaceView.layout(leftOffset, topOffset, childWidth, childHeight);


        int actualWidth = (int) (layoutWidth*ViewFinderWidth);
        int actualHeight = (int) (layoutHeight*ViewFinderHeight);

        mViewFinderView.layout(layoutWidth/2 - actualWidth/2,layoutHeight/2 - actualHeight/2, layoutWidth/2 + actualWidth/2, layoutHeight/2 + actualHeight/2);

        int buttonSize = dpToPx(45);
        int margin = 30;

        int torchLeft = layoutWidth - buttonSize - margin;
        int torchTop = layoutHeight - buttonSize - margin;
        mTorchButton.layout(torchLeft, torchTop, torchLeft + buttonSize, torchTop +  buttonSize);

        try {
            startIfReady();
        } catch (SecurityException se) {
            Log.e(TAG,"Do not have permission to start the camera", se);
        } catch (IOException e) {
            Log.e(TAG, "Could not start camera source.", e);
        }
    }

    private boolean isPortraitMode() {
        int orientation = mContext.getResources().getConfiguration().orientation;
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            return false;
        }
        if (orientation == Configuration.ORIENTATION_PORTRAIT) {
            return true;
        }

        Log.d(TAG, "isPortraitMode returning false by default");
        return false;
    }

    public Rect getRect(){
        int[] l = new int[2];
        mViewFinderView.getLocationOnScreen(l);
        Rect rect = new Rect(l[0], l[1], l[0] + mViewFinderView.getWidth(), l[1] + mViewFinderView.getHeight());
        return rect;
    }

}
