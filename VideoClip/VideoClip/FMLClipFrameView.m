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
#import "FMLScaledImageViewCell.h"

#define FMLLineW 4                // 线宽
#define FMLMinImageCount 8     // 显示的图片个数

#define FMLImagesViewH 42  // 预览图高度
#define FMLImagesVIewW (kScreenWidth / FMLMinImageCount) // 图片宽度

static NSString * const FMLScaledImageId = @"FMLScaledImageId";
@interface FMLClipFrameView () <UICollectionViewDataSource>

@property (nonatomic, assign) Float64 totalSeconds;         ///< 总秒数
@property (nonatomic, assign) Float64 screenSeconds;    ///< 当前屏幕显示的秒数
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *collectionImages;

@property (nonatomic, strong) UILabel *startTimeLabel;  ///< 开始秒数
@property (nonatomic, strong) UILabel *endTimeLabel;   ///< 结束秒数
@property (nonatomic, strong) UILabel *clipSecondLabel; ///< 一共截多少秒

//@property (nonatomic, strong) UIView *imagesView;   ///< 显示帧图片列表

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
    
    [self addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
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
        make.top.mas_equalTo(self.collectionView).offset(-10);
    }];
    
    UIView *rightDragView = [UIView new];
    [rightDragView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightDragGesture:)]];
    rightDragView.layer.contents = (id) [UIImage imageNamed:@"cut_bar_right"].CGImage;
    [self addSubview:rightDragView];
    self.rightDragView = rightDragView;
    [rightDragView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(28, 83));
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(self.collectionView).offset(-10);
    }];
    
    // 添加一个底层蓝色背景的view
    UIView *imagesBackView = [UIView new];
    imagesBackView.backgroundColor = SMSColor(252, 221, 0);
    [self insertSubview:imagesBackView belowSubview:self.collectionView];
    [imagesBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(leftDragView.mas_left).offset(FMLLineW);
        make.right.mas_equalTo(rightDragView.mas_right).offset(-FMLLineW);
        make.top.mas_equalTo(self.collectionView.mas_top).offset(-FMLLineW);
        make.bottom.mas_equalTo(self.collectionView.mas_bottom).offset(FMLLineW);
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
        make.top.mas_equalTo(self.collectionView);
    }];
}

- (void)initData
{
    // 现实秒数
    self.totalSeconds = [self.asset fml_getSeconds];
    self.endTimeLabel.text = [self secondsToStr:self.totalSeconds];
    self.clipSecondLabel.text = [NSString stringWithFormat:@"%.1f", self.totalSeconds];
    
    NSUInteger imageCount = 0;
    if (self.totalSeconds <= FMLRecordViewSDKMaxTime) {
        imageCount = FMLMinImageCount;
        self.screenSeconds = self.totalSeconds;
    } else {
        imageCount = self.totalSeconds * FMLMinImageCount / FMLRecordViewSDKMaxTime;
        self.screenSeconds = FMLRecordViewSDKMaxTime;
    }

    __weak typeof(self) weakSelf = self;
    [self.asset fml_getImagesCount:imageCount imageBackBlock:^(UIImage *image) {
        if (image) {
            UIImage *scaledImg = [UIImage fml_scaleImage:image maxDataSize:1024 * 20]; // 将图片压缩到最大20k进行显示
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.collectionImages addObject:scaledImg];
                [weakSelf.collectionView reloadData];
            });
        }
    }];
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
            
            // 1.控制最小间距
            CGPoint translation = [ges translationInView:self];
            CGFloat maxX = CGRectGetMaxX(self.rightDragView.frame) - FMLRecordViewSDKMinTime / self.screenSeconds * self.width;
            
            if ((ges.view.x + translation.x > maxX && translation.x > 0) || (ges.view.x + translation.x < 0 && translation.x < 0)) {
                return;
            }
            
            [ges.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.mas_offset(ges.view.x + translation.x);
            }];
            
            [ges setTranslation:CGPointZero inView:self];
        } break;
        case UIGestureRecognizerStateEnded: {
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
            
            // 1.控制最小间距
            CGFloat minX = CGRectGetMinX(self.leftDragView.frame) + FMLRecordViewSDKMinTime / self.screenSeconds * self.width;
            
            if ((ges.view.x + translation.x < minX && translation.x < 0) || (ges.view.x + translation.x > self.width && translation.x > 0)) {
                return;
            }
            
            CGFloat marginRight = self.width - (ges.view.x + translation.x);
            [ges.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.right.mas_offset(-marginRight);
            }];
            
            [ges setTranslation:CGPointZero inView:self];
        } break;
        case UIGestureRecognizerStateEnded: {
            
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

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.collectionImages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FMLScaledImageViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FMLScaledImageId forIndexPath:indexPath];
    
    cell.imageData = self.collectionImages[indexPath.item];
    
    return cell;
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

- (NSMutableArray *)collectionImages
{
    if (!_collectionImages) {
        _collectionImages = [NSMutableArray array];
    }
    
    return _collectionImages;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(FMLImagesVIewW, FMLImagesViewH);
        layout.minimumLineSpacing = 0;
        
        CGRect collectionRect = CGRectMake(0, 0, kScreenWidth, FMLImagesViewH);
        _collectionView = [[UICollectionView alloc] initWithFrame:collectionRect collectionViewLayout:layout];
        _collectionView.dataSource = self;
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([FMLScaledImageViewCell class]) bundle:nil] forCellWithReuseIdentifier:FMLScaledImageId];
        _collectionView.showsHorizontalScrollIndicator = NO;
    }
    
    return _collectionView;
}

@end
