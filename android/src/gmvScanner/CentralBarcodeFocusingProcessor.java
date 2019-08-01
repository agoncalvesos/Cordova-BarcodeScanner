package com.dealrinc.gmvScanner;

import android.util.SparseArray;

import com.dealrinc.gmvScanner.ui.camera.CameraSourcePreview;
import com.google.android.gms.vision.Detector;
import com.google.android.gms.vision.FocusingProcessor;
import com.google.android.gms.vision.Tracker;
import com.google.android.gms.vision.barcode.Barcode;

public class CentralBarcodeFocusingProcessor extends FocusingProcessor<Barcode> {
    CameraSourcePreview mPreview;

    public CentralBarcodeFocusingProcessor(Detector<Barcode> detector, Tracker<Barcode> tracker, CameraSourcePreview mPreview) {
        super(detector, tracker);
        this.mPreview = mPreview;
    }

    @Override
    public int selectFocus(Detector.Detections<Barcode> detections) {

        SparseArray<Barcode> barcodes = detections.getDetectedItems();
        int id = -1;

        for (int i = 0; i < barcodes.size(); ++i) {
            int tempId = barcodes.keyAt(i);
            Barcode barcode = barcodes.get(tempId);


            if (mPreview.getRect().contains(barcode.getBoundingBox())){
                return tempId;
            }
        }
        return id;
    }
}