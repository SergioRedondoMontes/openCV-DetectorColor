//
//  OpenCV.h
//  OpenCVSample_iOS
//

#import <UIKit/UIKit.h>

@interface OpenCV : NSObject

/// Converts a full color image to grayscale image with using OpenCV.
+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image;
+ (void)limpiar;

@end
