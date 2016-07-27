//
//  FMLClipFrameView.m
//  VideoClip
//
//  Created by samo on 16/7/27.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "FMLClipFrameView.h"
#import <Masonry.h>
#import <AVFoundation/AVFoundation.h>

static NSUInteger const FMLLineW = 3;

@interface FMLClipFrameView ()

@property (nonatomic, strong) UILabel *startTimeLabel;  ///< 开始秒数
@property (nonatomic, strong) UILabel *endTimeLabel;   ///< 结束秒数
@property (nonatomic, strong) UILabel *clipSecondLabel; ///< 一共截多少秒

@property (nonatomic, strong) UIView *imagesView;   ///< 显示帧图片列表

@end

@implementation FMLClipFrameView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initView];
        [self initData];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initView];
        [self initData];
    }
    
    return self;
}

- (void)initView
{
    UILabel *startTimeLabel = [UILabel new];
    startTimeLabel.text = @"00:00";
    [self addSubview:startTimeLabel];
    self.startTimeLabel = startTimeLabel;
    [startTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(15);
    }];
    
    UILabel *endTimeLabel = [UILabel new];
    endTimeLabel.text = @"00:00";
    [self addSubview:endTimeLabel];
    self.endTimeLabel = endTimeLabel;
    [endTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(startTimeLabel);
    }];
    
    UILabel *clipSecondLabel = [UILabel new];
    [self addSubview:clipSecondLabel];
    self.clipSecondLabel = clipSecondLabel;
    [clipSecondLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(startTimeLabel);
        make.centerX.mas_equalTo(self);
    }];
    
    UIView *imagesView = [UIView new];
    [self addSubview:imagesView];
    self.imagesView = imagesView;
    
}

- (void)initData
{
    NSUInteger imageCount = 8;
    
    
}

/**
 *  获取视频图片列表
 *
 *  @param imageCount 需要的图片个数
 *  @param asset      视频资源
 */
- (void)getImagesCount:(NSUInteger)imageCount UsingAsset:(AVAsset *)asset 
{
    CMTime cmtime = asset.duration; //视频时间信息结构体
    Float64 durationSeconds = CMTimeGetSeconds(cmtime); //视频总秒数
    
    // 获取视频的帧数
    float fps = [[asset tracksWithMediaType:AVMediaTypeVideo].lastObject nominalFrameRate];
    
    NSMutableArray *times = [NSMutableArray array];
    Float64 totalFrames = durationSeconds * fps; //获得视频总帧数
    CMTime timeFrame;
    
    Float64 perFrames = totalFrames / 8; // 一共切8张图
    Float64 frame = 0;
    
    while (frame < totalFrames) {
        timeFrame = CMTimeMake(frame, fps); //第i帧  帧率
        NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
        [times addObject:timeValue];
        
        frame += perFrames;
    }
    
    AVAssetImageGenerator *imgGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
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
                
                
            }
                break;
        }
    }];
}

@end
