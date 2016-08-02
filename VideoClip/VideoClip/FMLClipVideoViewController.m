//
//  FMLClipVideoViewController.m
//  VideoClip
//
//  Created by Collion on 16/7/23.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "FMLClipVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry.h>
#import <BlocksKit+UIKit.h>
#import "FMLClipFrameView.h"
#import "AVAsset+FMLVideo.h"
#import "UIImage+FMLClipRect.h"

@interface FMLClipVideoViewController ()

@property (nonatomic, strong) ALAsset *sourceAsset;
@property (nonatomic, strong) AVAsset *avAsset;

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) FMLClipFrameView *clipFrameView;

@property (nonatomic, strong) AVPlayer *player;                     ///< 播放器
@property (nonatomic, strong) AVPlayerLayer *playerLayer;    ///< 播放的layer
@property (nonatomic, strong) CALayer *imageLayer;              ///< 显示图片的layer

@end

static void *HJClipVideoStatusContext = &HJClipVideoStatusContext;
static void *HJClipVideoLayerReadyForDisplay = &HJClipVideoLayerReadyForDisplay;

@implementation FMLClipVideoViewController

- (instancetype)initClipVideoVCWithAsset:(ALAsset *)asset
{
    if (self = [super init]) {
        _sourceAsset = asset;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpView];
    [self setUpData];
}

#pragma mark - 初始化view
- (void)setUpView
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setUpNavBar];
    [self setUpPlayerView];
}

/** 添加自定义navigationbar */
- (void)setUpNavBar
{
    UIView *navBar = [UIView new];
    navBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navBar];
    self.navBar = navBar;
    [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(0);
        make.height.mas_equalTo(64);
    }];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    WEAKSELF
    [backBtn bk_addEventHandler:^(id sender) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    } forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [navBar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(navBar.mas_centerY);
        make.left.mas_equalTo(10);
    }];
    
    UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextBtn setTitle:@"Next" forState:UIControlStateNormal];
    [nextBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [navBar addSubview:nextBtn];
    [nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(navBar.mas_centerY);
        make.right.mas_equalTo(-10);
    }];
}

- (void)setUpPlayerView
{
    UIView *playerView = [UIView new];
    [self.view addSubview:playerView];
    self.playerView = playerView;
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.navBar.mas_bottom);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(300);
    }];
    
    WEAKSELF
    [playerView bk_whenTapped:^{
        if (weakSelf.player.rate > 0) {
            [weakSelf.player pause];
        } else {
            [weakSelf.player play];
            weakSelf.imageLayer.hidden = YES;
        }
    }];
}

#pragma mark - 初始化数据
- (void)setUpData
{
    AVAsset  *avAsset = [[AVURLAsset alloc] initWithURL:self.sourceAsset.defaultRepresentation.url options:nil];
    
    NSArray *assetKeysToLoadAndTest = @[@"playable", @"composable", @"tracks", @"duration"];
    
    [avAsset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUpPlaybackOfAsset:avAsset withKeys:assetKeysToLoadAndTest];
        });
    }];
    
    self.player = [AVPlayer new];
    self.avAsset = avAsset;
    
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:HJClipVideoStatusContext];
}

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys
{
    // 检查我们需要的key是否被正常加载
    for (NSString *key in keys) {
        NSError *error = nil;
        
        if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
            [self stopLoadingAnimationAndHandleError:error];
            return;
        }
    }
    
    // 视频不可播放
    if (!asset.isPlayable) {
        
        return;
    }
    
    // 视频通道不可用
    if (!asset.isComposable) {
        
        return;
    }
    
    // 代表视频的每个通道长度是否为0
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
        [self.playerView.layer addSublayer:self.playerLayer];
        
        [self.playerView.layer insertSublayer:self.imageLayer above:self.playerLayer];
        [self addObserver:self forKeyPath:@"playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:HJClipVideoLayerReadyForDisplay];
    } else {
        
    }
    
    // 创建一个AVPlayerItem资源 并将AVPlayer替换成创建的资源
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    
    [self setUpClipFrameView:asset];
}

- (void)setUpClipFrameView:(AVAsset *)asset
{
    FMLClipFrameView *clipFrameView = [[FMLClipFrameView alloc] initWithAsset:asset minSeconds:8];
    [self.view addSubview:clipFrameView];
    self.clipFrameView = clipFrameView;
    [clipFrameView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.playerView.mas_bottom);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(122);
    }];
    
    WEAKSELF
    [clipFrameView setDidDragView:^(Float64 second) {   // 获取拖拽时的秒
        [weakSelf didDragSecond:second];
    }];
    
    [clipFrameView setDidEndDragLeftView:^(Float64 second) {
        
    }];
    
    [clipFrameView setDidEndDragRightView:^(Float64 second) {
        
    }];
}

- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
    // 去除加载动画
    
    // 有错误提示的时候，显示错误提示
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - 事件

/** 拖拽了几秒 */
- (void)didDragSecond:(Float64)second
{
    WEAKSELF
    [self.avAsset fml_getThumbailImageRequestAtTimeSecond:second imageBackBlock:^(UIImage *image) {    // 获取每一秒对应的图片
        CGRect clipRect = weakSelf.playerLayer.videoRect;
        CGRect orginalRect = weakSelf.playerView.frame;
        
        [image fml_imageOrginalRect:orginalRect clipRect:clipRect completeBlock:^(UIImage *clipImage) {
            weakSelf.imageLayer.hidden = NO;
            weakSelf.imageLayer.contents = (id) clipImage.CGImage;
        }];
    }];
}

#pragma mark - 监听状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == HJClipVideoStatusContext) {
        
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        BOOL enable = NO;
        switch (status) {
            case AVPlayerItemStatusUnknown:
                break;
            case AVPlayerItemStatusReadyToPlay:
                enable = YES;
                break;
            case AVPlayerItemStatusFailed:
                [self stopLoadingAnimationAndHandleError:[[[self player] currentItem] error]];
                break;
        }
        
        // 无法播放的时候操作
    } else if (context == HJClipVideoLayerReadyForDisplay) {
        
        if ([change[NSKeyValueChangeNewKey] boolValue] == YES) {
            // 装备开始播放
            [self stopLoadingAnimationAndHandleError:nil];
            
            self.playerLayer.hidden = NO;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:HJClipVideoStatusContext];
    [self removeObserver:self forKeyPath:@"playerLayer.readyForDisplay" context:HJClipVideoLayerReadyForDisplay];
    
    [self.playerLayer removeFromSuperlayer];
    
    [self.player pause];
}

#pragma mark - 懒加载
- (AVPlayerLayer *)playerLayer
{
    if (!_playerLayer) {
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
        playerLayer.frame = self.playerView.layer.bounds;
        playerLayer.hidden = YES;
        
        _playerLayer = playerLayer;
    }
    
    return _playerLayer;
}

- (CALayer *)imageLayer
{
    if (!_imageLayer) {
        _imageLayer = [CALayer new];
        _imageLayer.frame = self.playerView.layer.bounds;
        _imageLayer.hidden = YES;
    }
    
    return _imageLayer;
}

@end