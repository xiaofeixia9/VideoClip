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
#import "AVAsset+FMLVideo.h"

static NSUInteger const FMLLineW = 3;

@interface FMLClipFrameView ()

@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, strong) UILabel *startTimeLabel;  ///< 开始秒数
@property (nonatomic, strong) UILabel *endTimeLabel;   ///< 结束秒数
@property (nonatomic, strong) UILabel *clipSecondLabel; ///< 一共截多少秒

@property (nonatomic, strong) UIView *imagesView;   ///< 显示帧图片列表

@end

@implementation FMLClipFrameView

- (instancetype)initWithAsset:(AVAsset *)asset
{
    if (self = [super init]) {
        _asset = asset;
        
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
    [imagesView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(startTimeLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(50);
        make.left.mas_equalTo(3);
        make.right.mas_equalTo(-3);
    }];
}

- (void)initData
{
    NSUInteger imageCount = 8;
    
    __block NSUInteger i = 0;
    CGFloat imageW = ([UIScreen mainScreen].bounds.size.width - 6) / imageCount;
    CGFloat imageH = 50;
    
    __weak typeof(self) weakSelf = self;
    [self.asset getImagesCount:imageCount imageBackBlock:^(UIImage *image) {
        CGFloat imageX = i * imageW;
        
        CALayer *imageLayer = [CALayer new];
        imageLayer.contents = (id) image.CGImage;
        imageLayer.frame = CGRectMake(imageX, 0, imageW, imageH);
        
        [weakSelf.imagesView.layer addSublayer:imageLayer];
        
        i++;
    }];
}

@end
