package fr.michaelvilleneuve.customcrop;

import com.facebook.react.bridge.WritableMap;

import android.content.res.Resources;
import android.util.DisplayMetrics;
import android.util.Log;

import fr.michaelvilleneuve.helpers.AppConstant;
import fr.michaelvilleneuve.helpers.Quadrilateral;
import fr.michaelvilleneuve.helpers.ScannedDocument;
import fr.michaelvilleneuve.helpers.Utils;

import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

public class ImageProcessor {

  private static final String TAG = "l33t";
  private double colorGain = 1; // contrast
  private double colorBias = 10;

  public WritableMap processPicture(Mat img) {
    ScannedDocument doc = detectDocument(img);
    doc.release();
    img.release();
    return doc.pointsAsHash();
  }

    private ScannedDocument detectDocument(Mat img) {
       ScannedDocument scannedDocuments = new ScannedDocument(img);
        ArrayList<MatOfPoint> contours = findContours(img);

        scannedDocuments.originalSize = img.size();
        Quadrilateral quad = getQuadrilateral(contours, scannedDocuments.originalSize);

        double ratio = scannedDocuments.originalSize.height / AppConstant.RESIZED_IMAGE_HEIGHT;
        scannedDocuments.heightWithRatio = Double.valueOf(scannedDocuments.originalSize.width / ratio).intValue();
        scannedDocuments.widthWithRatio = Double.valueOf(scannedDocuments.originalSize.height / ratio).intValue();

        Mat doc;
        if (quad != null) {
            scannedDocuments.originalPoints = new Point[4];
            scannedDocuments.originalPoints[0] = new Point( quad.points[0].x, quad.points[0].y); // TopLeft
            scannedDocuments.originalPoints[1] = new Point( quad.points[1].x, quad.points[1].y); // TopRight
            scannedDocuments.originalPoints[2] = new Point( quad.points[2].x, quad.points[2].y); // BottomRight
            scannedDocuments.originalPoints[3] = new Point( quad.points[3].x, quad.points[3].y); // BottomLeft
            scannedDocuments.quadrilateral = quad;
            doc = fourPointTransform(img, scannedDocuments.originalPoints);
        } else {
            doc = new Mat(img.size(), CvType.CV_8UC4);
            img.copyTo(doc);
        }
        enhanceDocument(doc);
        return scannedDocuments.setProcessed(doc);
    }

    private Quadrilateral getQuadrilateral(ArrayList<MatOfPoint> contours, Size srcSize) {
        double ratio = srcSize.height / AppConstant.RESIZED_IMAGE_HEIGHT;
        int height = Double.valueOf(srcSize.height / ratio).intValue();
        int width = Double.valueOf(srcSize.width / ratio).intValue();
        Size size = new Size(width, height);

        for (MatOfPoint c : contours) {
            MatOfPoint2f c2f = new MatOfPoint2f(c.toArray());
            double peri = Imgproc.arcLength(c2f, true);
            MatOfPoint2f approx = new MatOfPoint2f();
            Imgproc.approxPolyDP(c2f, approx, 0.02 * peri, true);
            Point[] points = approx.toArray();
            Point[] foundPoints = sortPoints(points);
            if (insideArea(foundPoints, size)) {
                return new Quadrilateral(c, foundPoints);
            }
        }
        return null;
  }

  private void enhanceDocument(Mat src) {
      Imgproc.cvtColor(src, src, Imgproc.COLOR_RGBA2GRAY);
      src.convertTo(src, CvType.CV_8UC1, colorGain, colorBias);
  }

  private Point[] sortPoints(Point[] src) {
      ArrayList<Point> srcPoints = new ArrayList<>(Arrays.asList(src));
      Point[] result = { null, null, null, null };

      Comparator<Point> sumComparator = new Comparator<Point>() {
          @Override
          public int compare(Point lhs, Point rhs) {
              return Double.compare(lhs.y + lhs.x, rhs.y + rhs.x);
          }
      };

      Comparator<Point> diffComparator = new Comparator<Point>() {
          @Override
          public int compare(Point lhs, Point rhs) {
              return Double.compare(lhs.y - lhs.x, rhs.y - rhs.x);
          }
      };

      // top-left corner = minimal sum
      result[0] = Collections.min(srcPoints, sumComparator);

      // top-right corner = minimal difference
      result[1] = Collections.min(srcPoints, diffComparator);

      // bottom-right corner = maximal sum
      result[2] = Collections.max(srcPoints, sumComparator);

      // bottom-left corner = maximal difference
      result[3] = Collections.max(srcPoints, diffComparator);

      return result;
  }

    private boolean insideArea(Point[] rp, Size size) {
        int width = Double.valueOf(size.width).intValue();
        int height = Double.valueOf(size.height).intValue();

        int minimumSize = width / 5;

        boolean isANormalShape = rp[0].x != rp[1].x && rp[1].y != rp[0].y && rp[2].y != rp[3].y && rp[3].x != rp[2].x;
        boolean isBigEnough = ((rp[1].x - rp[0].x >= minimumSize) && (rp[2].x - rp[3].x >= minimumSize)
                && (rp[3].y - rp[0].y >= minimumSize) && (rp[2].y - rp[1].y >= minimumSize));

        double leftOffset = rp[0].x - rp[3].x;
        double rightOffset = rp[1].x - rp[2].x;
        double bottomOffset = rp[0].y - rp[1].y;
        double topOffset = rp[2].y - rp[3].y;

        boolean isAnActualRectangle = ((leftOffset <= minimumSize && leftOffset >= -minimumSize)
                && (rightOffset <= minimumSize && rightOffset >= -minimumSize)
                && (bottomOffset <= minimumSize && bottomOffset >= -minimumSize)
                && (topOffset <= minimumSize && topOffset >= -minimumSize));

        return isANormalShape && isAnActualRectangle && isBigEnough;
    }

    private Mat fourPointTransform(Mat src, Point[] pts) {
        double ratio = src.size().height / AppConstant.RESIZED_IMAGE_HEIGHT;
        Point tl = pts[0];
        Point tr = pts[1];
        Point br = pts[2];
        Point bl = pts[3];

        double widthA = Math.sqrt(Math.pow(br.x - bl.x, 2) + Math.pow(br.y - bl.y, 2));
        double widthB = Math.sqrt(Math.pow(tr.x - tl.x, 2) + Math.pow(tr.y - tl.y, 2));

        double dw = Math.max(widthA, widthB) * ratio;
        int maxWidth = Double.valueOf(dw).intValue();

        double heightA = Math.sqrt(Math.pow(tr.x - br.x, 2) + Math.pow(tr.y - br.y, 2));
        double heightB = Math.sqrt(Math.pow(tl.x - bl.x, 2) + Math.pow(tl.y - bl.y, 2));

        double dh = Math.max(heightA, heightB) * ratio  ;
        int maxHeight = Double.valueOf(dh).intValue();

        Mat doc = new Mat(maxHeight, maxWidth, CvType.CV_8UC4);

        Mat src_mat = new Mat(4, 1, CvType.CV_32FC2);
        Mat dst_mat = new Mat(4, 1, CvType.CV_32FC2);

        src_mat.put(0, 0, tl.x * ratio , tl.y * ratio, tr.x * ratio, tr.y * ratio, br.x * ratio, br.y * ratio, bl.x * ratio , bl.y * ratio);
        dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh);

        Mat m = Imgproc.getPerspectiveTransform(src_mat, dst_mat);

        Imgproc.warpPerspective(src, doc, m, doc.size());

        return doc;
    }

    private ArrayList<MatOfPoint> findContours(Mat src) {
        Mat grayImage;
        Mat cannedImage;
        Mat resizedImage;

        double ratio = src.size().height / AppConstant.RESIZED_IMAGE_HEIGHT;
        int height = Double.valueOf(src.size().height / ratio).intValue();
        int width = Double.valueOf(src.size().width / ratio).intValue();
        Size size = new Size(width, height);

        resizedImage = new Mat(size, CvType.CV_8UC4);
        grayImage = new Mat(size, CvType.CV_8UC4);
        cannedImage = new Mat(size, CvType.CV_8UC1);

        Imgproc.resize(src, resizedImage, size);
        Imgproc.cvtColor(resizedImage, grayImage, Imgproc.COLOR_RGB2HSV, 4);
        List <Mat> image = new ArrayList<>(3);
        Core.split(grayImage, image);
        Mat saturationChannel = image.get(1);
        Imgproc.GaussianBlur(saturationChannel, grayImage, new Size(5, 5), 0);
        Imgproc.threshold(grayImage, grayImage,0, 255, Imgproc.THRESH_BINARY_INV|Imgproc.THRESH_OTSU);
        Imgproc.erode(grayImage, grayImage, new Mat(new Size(5,5), CvType.CV_8UC1));
        Imgproc.Canny(grayImage, cannedImage, 80, 250, 3, false);

        ArrayList<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();

        Imgproc.findContours(cannedImage, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
        hierarchy.release();

        Collections.sort(contours, new Comparator<MatOfPoint>() {
            @Override
            public int compare(MatOfPoint lhs, MatOfPoint rhs) {
                return Double.compare(Imgproc.contourArea(rhs), Imgproc.contourArea(lhs));
            }
        });

        resizedImage.release();
        grayImage.release();
        cannedImage.release();

        return contours;
    }

}
