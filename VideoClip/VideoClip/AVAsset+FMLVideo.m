//
//  AVAsset+FMLVideo.m
//  VideoClip
//
//  Created by samo on 16/7/27.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "AVAsset+FMLVideo.h"
#import <UIKit/UIKit.h>

@implementation AVAsset (FMLVideo)

- (void)getImagesCount:(NSUInteger)imageCount imageBackBlock:(void (^)(UIImage *))imageBackBlock
{
    Float64 durationSeconds = [self getSeconds];
    
    // 获取视频的帧数
    float fps = [self getFPS];
    
    NSMutableArray *times = [NSMutableArray array];
    Float64 totalFrames = durationSeconds * fps; //获得视频总帧数
    CMTime timeFrame;
    
    Float64 perFrames = totalFrames / imageCount; // 一共切8张图
    Float64 frame = 0;
    
    while (frame < totalFrames) {
        timeFrame = CMTimeMake(frame, fps); //第i帧  帧率
        NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
        [times addObject:timeValue];
        
        frame += perFrames;
    }
    
    AVAssetImageGenerator *imgGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self];
    // 防止时间出现偏差
    imgGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imgGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    [imgGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        switch (result) {
            case AVAssetImageGeneratorCancelled:
                break;
            case AVAssetImageGeneratorFailed:
                break;
            case AVAssetImageGeneratorSucceeded: {
                UIImage *displayImage = [UIImage imageWithCGImage:image];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    !imageBackBlock ? : imageBackBlock(displayImage);
                });
            }
                break;
        }
    }];
}

- (Float64)getSeconds
{
    CMTime cmtime = self.duration; //视频时间信息结构体
    return CMTimeGetSeconds(cmtime); //视频总秒数
}

/** 获取fps */
- (float)getFPS
{
    return [[self tracksWithMediaType:AVMediaTypeVideo].lastObject nominalFrameRate];
}

- (UIImage *)getThumbailImageRequestAtTimeSecond:(CGFloat)timeBySecond
{

    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self];
    
    CMTime time = CMTimeMake(timeBySecond, self.getFPS);
    CMTime actualTime;//实际生成视频缩略图的时间
    NSError *error = nil;
    //使用对象方法，生成视频缩略图，注意生成的是CGImageRef类型，如果要在UIImageView上显示，需要转为UIImage
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time
                                                actualTime:&actualTime
                                                     error:&error];
    if (error) {
        
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

@end
