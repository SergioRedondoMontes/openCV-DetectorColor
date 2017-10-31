//
//  OpenCV.m
//  OpenCVSample_iOS
//

// Put OpenCV include files at the top. Otherwise an error happens.
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
#import "OpenCV.h"

/// Converts an UIImage to Mat.
/// Orientation of UIImage will be lost.
static void UIImageToMat(UIImage *image, cv::Mat &mat) {
	
	// Create a pixel buffer.
	NSInteger width = CGImageGetWidth(image.CGImage);
	NSInteger height = CGImageGetHeight(image.CGImage);
	CGImageRef imageRef = image.CGImage;
	cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	
	// Draw all pixels to the buffer.
	cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
	cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
	
	mat = mat8uc3;
}

/// Converts a Mat to UIImage.
static UIImage *MatToUIImage(cv::Mat &mat) {
	
	// Create a pixel buffer.
	assert(mat.elemSize() == 1 || mat.elemSize() == 3);
	cv::Mat matrgb;
	if (mat.elemSize() == 1) {
		cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
	} else if (mat.elemSize() == 3) {
		cv::cvtColor(mat, matrgb, CV_BGR2RGB);
	}
	
	// Change a image format.
	NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
	CGColorSpaceRef colorSpace;
	if (matrgb.elemSize() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return image;
}

/// Restore the orientation to image.
static UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original) {
	if (processed.imageOrientation == original.imageOrientation) {
		return processed;
	}
	return [UIImage imageWithCGImage:processed.CGImage scale:1.0 orientation:original.imageOrientation];
}

#pragma mark -

@implementation OpenCV

int iLastX =-1;
int iLastY = -1;
cv::Mat imgLines;
bool blTemp = false;


+ (void)limpiar{
    blTemp = false;
}

+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image {
	cv::Mat bgrMat;
	UIImageToMat(image, bgrMat);
	cv::Mat grayMat,imgHSV,imgThreshed;
	cv::cvtColor(bgrMat, grayMat, CV_BGR2GRAY);
    cv::cvtColor(bgrMat, imgHSV, CV_BGR2HSV);
    //detecta rojos y color piel cv::inRange(imgHSV, cv::Scalar(0, 100, 100), cv::Scalar(30, 255, 255), imgThreshed);
    
    //detecta estuche Ram
   // cv::inRange(imgHSV, cv::Scalar(20, 100, 100), cv::Scalar(30, 255, 255), imgThreshed);
    
    cv::inRange(imgHSV, cv::Scalar(0, 100, 100), cv::Scalar(30, 255, 255), imgThreshed);
    
   
    
    
    //int iLastX = -1;
    //int iLastY = -1;
    
    //Capture a temporary image from the camera
    cv::Mat imgTmp;
    
    //Create a black image with the size as the camera output
    if(blTemp == false){
        imgLines = cv::Mat::zeros( imgThreshed.size(), CV_8UC3 );;
        blTemp = true;
    }
    //morphological opening (removes small objects from the foreground)
    erode(imgThreshed, imgThreshed, getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)) );
    dilate( imgThreshed, imgThreshed, getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)) );
    
    //morphological closing (removes small holes from the foreground)
    dilate( imgThreshed, imgThreshed, getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)) );
    erode(imgThreshed, imgThreshed, getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)) );
    
    //Calculate the moments of the thresholded image
    cv::Moments oMoments = moments(imgThreshed);
    
    double dM01 = oMoments.m01;
    double dM10 = oMoments.m10;
    double dArea = oMoments.m00;
    
    // if the area <= 10000, I consider that the there are no object in the image and it's because of the noise, the area is not zero
    if (dArea > 10000)
    {
        //calculate the position of the ball
        int posX = dM10 / dArea;
        int posY = dM01 / dArea;
        
        if (iLastX >= 0 && iLastY >= 0 && posX >= 0 && posY >= 0)
        {
            //Draw a red line from the previous point to the current point
            line(imgLines, cv::Point(posX, posY), cv::Point(iLastX, iLastY), cv::Scalar(0,0,255), dArea/10000);
        }
        //printf("HEY!!!!! %d      %d LASTS: %d     %d\n",posX,posY,iLastX,iLastY);
        
        iLastX = posX;
        iLastY = posY;
        
        
    }
    //int posX = dM10 / dArea;
    //int posY = dM01 / dArea;
    
   
    
    cv::Mat salida;
    //hconcat(imgThreshed, imgLines, salida);
    //imgThreshed = imgThreshed + imgLines;
    cv::Mat matD;
    cv::add(bgrMat, imgLines, matD);
    
    
    UIImage *retImg = MatToUIImage(matD);
    return RestoreUIImageOrientation(retImg,image);
}

@end
