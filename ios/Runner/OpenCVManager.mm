//
//  OpenCVManager.mm
//  Runner
//
//  Created by 佐藤旭 on 2021/12/24.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVManager.h"
#endif
#import <Foundation/Foundation.h>

@implementation OpenCVManager : NSObject

+ (UIImage*)gray:(UIImage*)image {
   cv::Mat img_Mat;
   UIImageToMat(image, img_Mat);
   cv::cvtColor(img_Mat, img_Mat, cv::COLOR_BGR2GRAY);
   return MatToUIImage(img_Mat);
}

@end
