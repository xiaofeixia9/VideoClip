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
#import <BlocksKit+UIKit.h>
#import "UIImage+FMLClipRect.h"

#define FMLLineW 4                // 线宽
#define FMLImagesViewH 42  // 预览图高度

#define FMLImageCount 8     // 显示的图片个数

@interface FMLClipFrameView ()

@property (nonatomic, assign) Float64 totalSeconds;         ///< 总秒数
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, assign) Float64 minSeconds;  ///< 最少多少秒

//@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, assign) Float64 diffSpace;

@property (nonatomic, strong) UILabel *startTimeLabel;  ///< 开始秒数
@property (nonatomic, strong) UILabel *endTimeLabel;   ///< 结束秒数
@property (nonatomic, strong) UILabel *clipSecondLabel; ///< 一共截多少秒

@property (nonatomic, strong) UIView *imagesView;   ///< 显示帧图片列表

@property (nonatomic, strong) UIView *leftDragView;     ///< 左边时间拖拽view
@property (nonatomic, strong) UIView *rightDragView;  ///< 右边时间拖拽view
@property (nonatomic, strong) UIView *progressBarView; ///< 进度播放view

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

#pragma mark - 初始化
- (void)initView
{
    self.backgroundColor =  [UIColor colorWithWhite:0 alpha:0.5];
    
    [self addSubview:self.startTimeLabel];
    [self.startTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(23);
    }];
    
    [self addSubview:self.endTimeLabel];
    [self.endTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.startTimeLabel);
    }];
    
    [self addSubview:self.clipSecondLabel];
    [self.clipSecondLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(21);
        make.centerX.mas_equalTo(self);
    }];
    
    UIView *imagesView = [UIView new];
    imagesView.backgroundColor = [UIColor whiteColor];
    [self addSubview:imagesView];
    self.imagesView = imagesView;
    [imagesView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.startTimeLabel.mas_bottom).offset(18);
        make.height.mas_equalTo(FMLImagesViewH);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
    }];
    
    [self setUpDragView];
}

/** 初始化拖拽view */
- (void)setUpDragView
{
    // 添加左右拖拽view
    UIView *leftDragView = [UIView new];
    [leftDragView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(leftDragGesture:)]];
    leftDragView.layer.contents = (id) [UIImage imageNamed:@"cut_bar_left"].CGImage;
    [self addSubview:leftDragView];
    self.leftDragView = leftDragView;
    [leftDragView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(28, 83));
        make.left.mas_equalTo(0);
        make.top.mas_equalTo(self.imagesView).offset(-10);
    }];
    
    UIView *rightDragView = [UIView new];
    [rightDragView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightDragGesture:)]];
    rightDragView.layer.contents = (id) [UIImage imageNamed:@"cut_bar_right"].CGImage;
    [self addSubview:rightDragView];
    self.rightDragView = rightDragView;
    [rightDragView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(28, 83));
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(self.imagesView).offset(-10);
    }];
    
    // 添加一个底层蓝色背景的view
    UIView *imagesBackView = [UIView new];
    imagesBackView.backgroundColor = SMSColor(252, 221, 0);
    [self insertSubview:imagesBackView belowSubview:self.imagesView];
    [imagesBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(leftDragView.mas_left).offset(FMLLineW);
        make.right.mas_equalTo(rightDragView.mas_right).offset(-FMLLineW);
        make.top.mas_equalTo(self.imagesView.mas_top).offset(-FMLLineW);
        make.bottom.mas_equalTo(self.imagesView.mas_bottom).offset(FMLLineW);
    }];
    
    // 添加左右侧阴影view
    UIView *leftShadowView = [UIView new];
    leftShadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:leftShadowView];
    [leftShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(leftDragView.mas_left);
        make.top.bottom.mas_equalTo(imagesBackView);
    }];
    
    UIView *rightShadowView = [UIView new];
    rightShadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:rightShadowView];
    [rightShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(rightDragView.mas_right);
        make.top.bottom.mas_equalTo(imagesBackView);
    }];
    
    UIView *progressBarView = [UIView new];
    progressBarView.hidden = YES;
    progressBarView.layer.contents = (id) [UIImage imageNamed:@"cut_bar_progress"].CGImage;
    [self addSubview:progressBarView];
    self.progressBarView = progressBarView;
    [progressBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(5);
        make.height.mas_equalTo(FMLImagesViewH);
        make.left.mas_equalTo(0);
        make.top.mas_equalTo(self.imagesView);
    }];
}

- (void)initData
{
    __block NSUInteger i = 0;
    CGFloat imageW = [UIScreen mainScreen].bounds.size.width / FMLImageCount;
    CGFloat imageH = FMLImagesViewH;
    
    __weak typeof(self) weakSelf = self;
    
    [self.asset fml_getImagesCount:FMLImageCount imageBackBlock:^(UIImage *image) {
        
        if (image) {
            UIImage *scaleImg = [UIImage fml_scaleImage:image maxDataSize:1024 * 20]; // 将图片压缩到最大20k进行显示
            CGFloat imageX = i * imageW;
            
            CALayer *imageLayer = [CALayer new];
            imageLayer.contents = (id) scaleImg.CGImage;
            imageLayer.contentsGravity = kCAGravityResizeAspectFill;
            imageLayer.frame = CGRectMake(imageX, 0, imageW, imageH);
            imageLayer.masksToBounds = YES;
            
            [weakSelf.imagesView.layer addSublayer:imageLayer];
            
            i++;
        }
    }];
    
    // 现实秒数
    self.totalSeconds = [self.asset fml_getSeconds];
    self.endTimeLabel.text = [self secondsToStr:self.totalSeconds];
    self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", self.totalSeconds];
    
    if (self.totalSeconds > FMLRecordViewSDKMaxTime) {
        
        CGFloat rightX = kScreenWidth * (1 - FMLRecordViewSDKMaxTime / self.totalSeconds);
        [self.rightDragView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-rightX);
        }];
        
        Float64 rightSecond = self.totalSeconds - FMLRecordViewSDKMaxTime;
        self.endTimeLabel.text = [self secondsToStr:rightSecond];
        self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", FMLRecordViewSDKMaxTime];
    }
}

/** 将秒转为字符串 */
- (NSString *)secondsToStr:(Float64)seconds
{
    NSInteger secondI = (NSInteger) seconds;
    NSInteger second = floor(secondI % 60);
    NSInteger minute = floor((secondI / 60) % secondI);
    return [NSString stringWithFormat:@"%02ld:%02ld", minute, second];
}

#pragma mark - 拖拽事件
- (void)leftDragGesture:(UIPanGestureRecognizer *)ges
{
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
            !self.didStartDragView ? : self.didStartDragView();
            
            [self resetProgressBarMode];
            break;
        case UIGestureRecognizerStateChanged: {
            
            CGPoint translation = [ges translationInView:self];
            
            // 判断滑块滑动的时间是否小于最小秒
            Float64 diffSeconds = (CGRectGetMaxX(self.rightDragView.frame) - self.leftDragView.x) / self.width * self.totalSeconds;
            self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", diffSeconds];
            
            if (diffSeconds <= self.minSeconds && translation.x > 0) {
                return;
            }
            
            if (diffSeconds > FMLRecordViewSDKMaxTime  && translation.x < 0) {
                diffSeconds = FMLRecordViewSDKMaxTime;
                
                self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", FMLRecordViewSDKMaxTime];
                CGFloat leftX = CGRectGetMaxX(self.rightDragView.frame) - diffSeconds / self.totalSeconds * self.width;
                [ges.view mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(leftX);
                }];
                return;
            }
            
            CGFloat shouldDiffDis = self.minSeconds * self.width / self.totalSeconds;
            CGFloat rightMaxX = CGRectGetMaxX(self.rightDragView.frame);
            CGFloat leftViewShouldX = rightMaxX - shouldDiffDis;
            
            CGFloat maxLeft = self.rightDragView.frame.origin.x + self.rightDragView.frame.size.width - FMLRecordViewSDKMaxTime/self.totalSeconds * self.width;
            if (ges.view.x + translation.x >= 0 && ges.view.x + translation.x < leftViewShouldX && ges.view.x + translation.x >= maxLeft) {
                [ges.view mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(ges.view.x + translation.x);
                }];
                NSLog(@"-----left normal max leftX = %f --------", ges.view.x + translation.x);
            }
            
            [ges setTranslation:CGPointZero inView:self];
            
            // 显示目前滑到的时间
            Float64 leftSecond = ges.view.x /  self.width * self.totalSeconds;
            self.startTimeLabel.text = [self secondsToStr:leftSecond];
            
            !self.didDragView ? : self.didDragView(leftSecond);
        } break;
        case UIGestureRecognizerStateEnded: {
            Float64 leftSecond = ges.view.x /  self.width * self.totalSeconds;
            !self.didEndDragLeftView ? : self.didEndDragLeftView(leftSecond);
            self.startTimeLabel.text = [self secondsToStr:leftSecond];
        } break;
        default:
            break;
    }
}

- (void)rightDragGesture:(UIPanGestureRecognizer *)ges
{
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
            !self.didStartDragView ? : self.didStartDragView();
            
            [self resetProgressBarMode];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [ges translationInView:self];
            
            Float64 diffSeconds = (CGRectGetMaxX(self.rightDragView.frame) - self.leftDragView.x) / self.width * self.totalSeconds;
            self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", diffSeconds];
            if (diffSeconds <= self.minSeconds && translation.x < 0) {
                return;
            }
            
            if (diffSeconds > FMLRecordViewSDKMaxTime && translation.x > 0) {
                diffSeconds = FMLRecordViewSDKMaxTime;
                
                self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", FMLRecordViewSDKMaxTime];
                CGFloat rightX = CGRectGetMinX(self.leftDragView.frame) + diffSeconds / self.totalSeconds * self.width;
                CGFloat leftX = self.width - rightX;
                [ges.view mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(-leftX);
                }];
                return;
            }
            
            //  计算关于两个拖拽view最小的间距
            CGFloat shouldDiffDis = self.minSeconds * self.width / self.totalSeconds;
            CGFloat leftMaxX = self.leftDragView.x;
            CGFloat leftViewShouldX = leftMaxX + shouldDiffDis;
            
            CGFloat resultX = CGRectGetMaxX(ges.view.frame)+ translation.x;
            CGFloat distance = self.width - (CGRectGetMaxX(ges.view.frame) + translation.x);
            CGFloat maxRight = self.width - (self.leftDragView.frame.origin.x + FMLRecordViewSDKMaxTime/self.totalSeconds * self.width);
            
            if (resultX <= self.width && resultX >leftViewShouldX && distance >= maxRight) {
                
                [ges.view mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(-distance);
                }];
                NSLog(@"-----right normal max leftX = %f --------", -distance);
            }
            
            [ges setTranslation:CGPointZero inView:self];
            
            // 显示目前滑到的时间
            Float64 rightSecond = CGRectGetMaxX(ges.view.frame) / self.width * self.totalSeconds;
            self.endTimeLabel.text = [self secondsToStr:rightSecond];
            
            !self.didDragView ? : self.didDragView(rightSecond);
        } break;
        case UIGestureRecognizerStateEnded: {
            Float64 rightSecond = CGRectGetMaxX(ges.view.frame) / self.width * self.totalSeconds;
            !self.didEndDragRightView ? : self.didEndDragRightView(rightSecond);
            self.endTimeLabel.text = [self secondsToStr:rightSecond];
        } break;
        default:
            break;
    }
}

- (void)resetProgressBarMode
{
    self.progressBarView.hidden = YES;
}

#pragma mark - 进度条移动动画
- (void)setProgressBarPoisionWithSecond:(Float64)second
{
    CGFloat position = self.width / self.totalSeconds * second;
    self.progressBarView.x = position;
    
    self.progressBarView.hidden = NO;
}

#pragma mark - 懒加载
- (UILabel *)startTimeLabel
{
    if (!_startTimeLabel) {
        UILabel *startTimeLabel = [UILabel new];
        startTimeLabel.textColor = [UIColor whiteColor];
        startTimeLabel.font = [UIFont systemFontOfSize:14];
        startTimeLabel.text = @"00:00";
        
        _startTimeLabel = startTimeLabel;
    }
    
    return _startTimeLabel;
}

- (UILabel *)endTimeLabel
{
    if (!_endTimeLabel) {
        UILabel *endTimeLabel = [UILabel new];
        endTimeLabel.textColor = [UIColor whiteColor];
        endTimeLabel.font = [UIFont systemFontOfSize:14];
        
        _endTimeLabel = endTimeLabel;
    }
    
    return _endTimeLabel;
}

- (UILabel *)clipSecondLabel
{
    if (!_clipSecondLabel) {
        UILabel *clipSecondLabel = [UILabel new];
        clipSecondLabel.textColor = SMSColor(253, 220, 0);
        clipSecondLabel.font = [UIFont systemFontOfSize:17];
        
        _clipSecondLabel = clipSecondLabel;
    }
    
    return _clipSecondLabel;
}

@end
