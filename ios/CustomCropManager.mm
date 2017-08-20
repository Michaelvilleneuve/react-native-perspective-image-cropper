#import <opencv2/opencv.hpp>
#import "CustomCropManager.h"
#import <React/RCTLog.h>

@implementation CustomCropManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(crop:(NSDictionary *)points base64Image:(NSString *)base64Image callback:(RCTResponseSenderBlock)callback)
{
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Image options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:imageData];
    cv::Mat mat = [self cvMatFromUIImage: image];
    
    cv::Point2f tl = cv::Point2f(
                                 [points[@"topLeft"][@"x"] floatValue],
                                 [points[@"topLeft"][@"y"] floatValue]
                                 );
    cv::Point2f tr = cv::Point2f(
                                 [points[@"topRight"][@"x"]  floatValue],
                                 [points[@"topRight"][@"y"]  floatValue]
                                 );
    cv::Point2f bl = cv::Point2f(
                                 [points[@"bottomLeft"][@"x"] floatValue],
                                 [points[@"bottomLeft"][@"y"] floatValue]
                                 );
    cv::Point2f br = cv::Point2f(
                                 [points[@"bottomRight"][@"x"] floatValue],
                                 [points[@"bottomRight"][@"y"] floatValue]
                                 );
    
    std::vector<cv::Point2f> userPoints(4);
    userPoints[0] = tl;
    userPoints[1] = tr;
    userPoints[2] = br;
    userPoints[3] = bl;
    
    
    float widthA = sqrt(pow(br.x - bl.x, 2) + pow(br.y - bl.y, 2));
    float widthB = sqrt(pow(tr.x - tl.x, 2) + pow(tr.y - tl.y, 2));
    float maxWidth = fmax(widthA, widthB);
    
    float heightA = sqrt(pow(tr.x - br.x, 2) + pow(tr.y - br.y, 2));
    float heightB = sqrt(pow(tl.x - bl.x, 2) + pow(tl.y - bl.y, 2));
    float maxHeight = fmax(heightA, heightB);
    
    std::vector<cv::Point2f> newImageCorners(4);
    newImageCorners[0] = cv::Point2f(0.0f, 0.0f);
    newImageCorners[1] = cv::Point2f(maxWidth -1, 0.0f);
    newImageCorners[2] = cv::Point2f(maxWidth -1, maxHeight -1);
    newImageCorners[3] = cv::Point2f(0.0f, maxHeight -1);
    
    cv::Mat newImage = cv::getPerspectiveTransform(userPoints, newImageCorners);
    cv::warpPerspective(mat, mat, newImage, cv::Size(maxWidth, maxHeight));
    
    mat.convertTo(mat, CV_8UC4);
    
    UIImage* convertedImage = [self UIImageFromCVMat:mat];
    NSData *imageToEncode = UIImageJPEGRepresentation(convertedImage, 0.8);
    callback(@[[NSNull null], @{@"image": [imageToEncode base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]}]);
}


- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    cvMat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,
                                        cvMat.rows,
                                        8,
                                        8 * cvMat.elemSize(),
                                        cvMat.step[0],
                                        colorSpace,
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end
