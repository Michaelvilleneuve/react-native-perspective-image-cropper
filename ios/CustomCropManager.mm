#import "CustomCropManager.h"
#import <React/RCTLog.h>

@implementation CustomCropManager
{
  CGFloat _imageDedectionConfidence;
  NSTimer *_borderDetectTimeKeeper;
  BOOL _borderDetectFrame;
  CIRectangleFeature *_borderDetectLastRectangleFeature;
  CGRect _borderDetectLastRectangleBounds;
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(crop:(NSDictionary *)points imageUri:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [[imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByRemovingPercentEncoding];
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *ciImage = [CIImage imageWithContentsOfURL:fileURL];
    ciImage = [ciImage imageByApplyingOrientation:kCGImagePropertyOrientationRightMirrored];
    
    CGPoint newLeft = CGPointMake([points[@"topLeft"][@"x"] floatValue], [points[@"topLeft"][@"y"] floatValue]);
    CGPoint newRight = CGPointMake([points[@"topRight"][@"x"] floatValue], [points[@"topRight"][@"y"] floatValue]);
    CGPoint newBottomLeft = CGPointMake([points[@"bottomLeft"][@"x"] floatValue], [points[@"bottomLeft"][@"y"] floatValue]);
    CGPoint newBottomRight = CGPointMake([points[@"bottomRight"][@"x"] floatValue], [points[@"bottomRight"][@"y"] floatValue]);
    
    NSMutableDictionary *rectangleCoordinates = [[NSMutableDictionary alloc] init];
    
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:newLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:newRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:newBottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:newBottomRight];
    
    ciImage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgimage];
    NSData *imageToEncode = UIImageJPEGRepresentation(image, 0.8);
    callback(@[[NSNull null], @{@"image": [imageToEncode base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]}]);
}

- (CGPoint)cartesianForPoint:(CGPoint)point {
    return CGPointMake(point.x, point.y);
}


RCT_EXPORT_METHOD(findDocument:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *detectionImage = [CIImage imageWithContentsOfURL:fileURL];
    detectionImage = [detectionImage imageByApplyingOrientation:kCGImagePropertyOrientationRight];

    self->_borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:detectionImage] image:detectionImage];
    self->_borderDetectLastRectangleBounds = detectionImage.extent;

    if (self->_borderDetectLastRectangleFeature) {
      NSDictionary *rectangleCoordinates = [self computeRectangle:self->_borderDetectLastRectangleFeature forImage: detectionImage];
    callback(@[[NSNull null], rectangleCoordinates]);
    } else {
        callback(@[@{@"error": @"No rectangle found"}, [NSNull null]]);
    }
}


// MARK: Rectangle Detection

/*!
 Gets a rectangle detector that can be used to plug an image into and find the rectangles from
 */
- (CIDetector *)highAccuracyRectangleDetector
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorReturnSubFeatures: @(YES) }];
    });
    return detector;
}

/*!
 Finds the best fitting rectangle from the list of rectangles found in the image
 */
- (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles image:(CIImage *)image
{
  if (![rectangles count]) return nil;

  float halfPerimiterValue = 0;

  CIRectangleFeature *biggestRectangle = [rectangles firstObject];

  for (CIRectangleFeature *rect in rectangles) {
    CGPoint p1 = rect.topLeft;
    CGPoint p2 = rect.topRight;
    CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);

    CGPoint p3 = rect.topLeft;
    CGPoint p4 = rect.bottomLeft;
    CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);

    CGFloat currentHalfPerimiterValue = height + width;

    if (halfPerimiterValue < currentHalfPerimiterValue) {
      halfPerimiterValue = currentHalfPerimiterValue;
      biggestRectangle = rect;
    }
  }

  return biggestRectangle;
}

/*!
 Maps the coordinates to the correct orientation.  This maybe can be cleaned up and removed if the orientation is set on the input image.
 */
- (NSDictionary *) computeRectangle: (CIRectangleFeature *) rectangle forImage: (CIImage *) image {
  CGRect imageBounds = image.extent;
  if (!rectangle) return nil;
  return @{
    @"bottomLeft": @{
        @"y": @(imageBounds.size.height-rectangle.bottomLeft.y),
        @"x": @(rectangle.bottomLeft.x)
    },
    @"bottomRight": @{
        @"y": @(imageBounds.size.height-rectangle.bottomRight.y),
        @"x": @(rectangle.bottomRight.x)
    },
    @"topLeft": @{
        @"y": @(imageBounds.size.height-rectangle.topLeft.y),
        @"x": @(rectangle.topLeft.x)
    },
    @"topRight": @{
        @"y": @(imageBounds.size.height-rectangle.topRight.y),
        @"x": @(rectangle.topRight.x)
    },
    @"dimensions": @{@"height": @(imageBounds.size.height), @"width": @(imageBounds.size.width)}
  };
}

/*!
 Checks if the confidence of the current rectangle is above a threshold. The higher, the more likely the rectangle is the desired object to be scanned.
 */
BOOL isRectangleDetectionConfidenceHighEnough(float confidence)
{
    return (confidence > 1.0);
}

@end
