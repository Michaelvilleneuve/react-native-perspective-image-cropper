package fr.michaelvilleneuve.helpers;

import android.util.Log;

import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.core.Size;

/**
 * Created by allgood on 05/03/16.
 */
public class ScannedDocument {

    public Mat original;
    public Mat processed;
    public Quadrilateral quadrilateral;
    public Size originalSize;

    public Point[] originalPoints;

    public int heightWithRatio;
    public int widthWithRatio;

    public ScannedDocument(Mat original) {
        this.original = original;
    }

    public Mat getProcessed() {
        return processed;
    }

    public ScannedDocument setProcessed(Mat processed) {
        this.processed = processed;
        return this;
    }

    public WritableMap pointsAsHash() {
        if (this.originalPoints == null) {
            return null;
        }

        WritableMap rectangleCoordinates = new WritableNativeMap();
    
        double ratio = this.originalSize.height / AppConstant.RESIZED_IMAGE_HEIGHT;
        double xRatio = ratio;
        double yRatio =  ratio;

        WritableMap topLeft = new WritableNativeMap();
        topLeft.putDouble("x", this.originalPoints[0].x * xRatio );
        topLeft.putDouble("y", (this.originalPoints[0].y * yRatio));

        WritableMap topRight = new WritableNativeMap();
        topRight.putDouble("x", this.originalPoints[1].x * xRatio);
        topRight.putDouble("y", (this.originalPoints[1].y * yRatio));

        WritableMap bottomRight = new WritableNativeMap();
        bottomRight.putDouble("x", this.originalPoints[2].x * xRatio);
        bottomRight.putDouble("y",  (this.originalPoints[2].y * yRatio));

        WritableMap bottomLeft = new WritableNativeMap();
        bottomLeft.putDouble("x", this.originalPoints[3].x * xRatio);
        bottomLeft.putDouble("y", (this.originalPoints[3].y * yRatio));

        rectangleCoordinates.putMap("topLeft", topLeft);
        rectangleCoordinates.putMap("topRight", topRight);
        rectangleCoordinates.putMap("bottomRight", bottomRight);
        rectangleCoordinates.putMap("bottomLeft", bottomLeft);

        return rectangleCoordinates;
    }

    public void release() {
        if (processed != null) {
            processed.release();
        }
        if (original != null) {
            original.release();
        }

        if (quadrilateral != null && quadrilateral.contour != null) {
            quadrilateral.contour.release();
        }
    }
}
