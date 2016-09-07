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
#import "AVAsset+FMLVideo.h"
#import "UIImage+FMLClipRect.h"
#import "FMLVideoCommand.h"
#import "FMLPlayLayerView.h"
#import "FMLClipFrameView.h"
//#import "FMLFilterViewController.h"
//#import "FMLRecordVideoSDK.h"

#define navBarH 40
#define clipFrameViewH 150

@interface FMLClipVideoViewController () <FMLClipFrameViewDelegate>

@property (nonatomic, strong) NSURL *assetUrl;
@property (nonatomic, strong) AVAsset *avAsset;

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *nextBtn;
@property (nonatomic, strong) UIView *iconPlayView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) FMLClipFrameView *clipFrameView;
@property (nonatomic, assign) Float64 startSecond;  ///< leftDragView对应的秒
@property (nonatomic, assign) Float64 endSecond;   ///< rightDragView对应的秒

@property (nonatomic, strong) FMLPlayLayerView *playerView;
@property (nonatomic, strong) id observer;
@property (nonatomic, strong) AVPlayer *player;                     ///< 播放器

@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) NSURL *compositionURL;

@end

static void *HJClipVideoStatusContext = &HJClipVideoStatusContext;
static void *HJClipVideoLayerReadyForDisplay = &HJClipVideoLayerReadyForDisplay;

@implementation FMLClipVideoViewController

- (instancetype)initClipVideoVCWithAssetURL:(NSURL *)assetUrl;
{
    if (self = [super init]) {
        _assetUrl = assetUrl;
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
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setUpNavBar];
    [self setUpPlayerView];
    
    [self.view addSubview:self.iconPlayView];
}

/** 添加自定义navigationbar */
- (void)setUpNavBar
{
    UIView *navBar = [UIView new];
    navBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:navBar];
    self.navBar = navBar;
    [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(0);
        make.height.mas_equalTo(navBarH);
    }];
    
    [navBar addSubview:self.backBtn];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(38);
        make.top.left.bottom.mas_equalTo(0);
    }];
    
    [navBar addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(navBar);
    }];
    
    [navBar addSubview:self.nextBtn];
    [self.nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(65);
        make.height.mas_equalTo(navBar.mas_height);
        make.right.mas_equalTo(0);
    }];
    
    [navBar addSubview:self.indicatorView];
    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.centerY.mas_equalTo(navBar.mas_centerY);
        make.right.mas_equalTo(-12);
    }];
}

- (void)setUpPlayerView
{
    FMLPlayLayerView *playerView = [FMLPlayLayerView new];
    playerView.player = self.player;
    [self.view insertSubview:playerView belowSubview:self.navBar];
    self.playerView = playerView;
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view);
        make.left.right.mas_equalTo(self.view);
        make.height.mas_equalTo(self.view.mas_height);
    }];
}

#pragma mark - 初始化数据
- (void)setUpData
{
    AVAsset  *avAsset = [[AVURLAsset alloc] initWithURL:self.assetUrl options:nil];
    
    NSArray *assetKeysToLoadAndTest = @[@"playable", @"composable", @"tracks", @"duration"];
    
    [avAsset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUpPlaybackOfAsset:avAsset withKeys:assetKeysToLoadAndTest];
        });
    }];
    
    self.avAsset = avAsset;
    
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:HJClipVideoStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editCommandCompletionNotificationReceiver:) name:FMLEditCommandCompletionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exportCommandCompletionNotificationReceiver:) name:FMLExportCommandCompletionNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishClip) name:FMLRecordVideoSDKFinishedNotification object:nil];
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
        
        [self addObserver:self forKeyPath:@"playerView.playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:HJClipVideoLayerReadyForDisplay];
    } else {
    }
    
    [self setUpDataWithAVAsset:asset];
}

- (void)setUpDataWithAVAsset:(AVAsset *)asset
{
    // 创建一个AVPlayerItem资源 并将AVPlayer替换成创建的资源
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    
    self.endSecond = CMTimeGetSeconds(asset.duration); // 默认是总秒数
    if (self.endSecond > FMLRecordViewSDKMaxTime) {
        self.endSecond = FMLRecordViewSDKMaxTime;
    }
    
    // 监听时间
    WEAKSELF
    self.observer = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, self.avAsset.fml_getFPS) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        Float64 seconds = CMTimeGetSeconds(time);
        
        if (seconds >= weakSelf.endSecond) {
            [weakSelf playerItemDidReachEnd];
        }else if (weakSelf.player.rate > 0) {
            [weakSelf.clipFrameView setProgressBarPoisionWithSecond:seconds];
            weakSelf.iconPlayView.hidden = YES;
        } else if (weakSelf.player.rate ==0) {
            weakSelf.iconPlayView.hidden = NO;
        }
    }];
    
    [self setUpClipFrameView:asset];
}

- (void)setUpClipFrameView:(AVAsset *)asset
{
    FMLClipFrameView *clipFrameView = [[FMLClipFrameView alloc] initWithAsset:asset];
    clipFrameView.delegate = self;
    [self.view insertSubview:clipFrameView aboveSubview:self.playerView];
    self.clipFrameView = clipFrameView;
    [clipFrameView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(clipFrameViewH);
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

#pragma mark - FMLClipFrameView代理
- (void)didStartDragView
{
    if (self.player.rate > 0) { // 正在播放的时候
        [self.player pause];
    }
}

- (void)clipFrameView:(FMLClipFrameView *)clipFrameView didDragView:(Float64)second
{
    [self.player seekToTime:CMTimeMakeWithSeconds(second, self.avAsset.fml_getFPS) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)clipFrameView:(FMLClipFrameView *)clipFrameView didEndDragLeftView:(Float64)second
{
    self.startSecond = second;
    
    [self.player seekToTime:CMTimeMakeWithSeconds(second, self.avAsset.fml_getFPS) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)clipFrameView:(FMLClipFrameView *)clipFrameView didEndDragRightView:(Float64)second
{
    self.endSecond = second;
    
    [self.player seekToTime:CMTimeMakeWithSeconds(self.startSecond, self.avAsset.fml_getFPS) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)clipFrameView:(FMLClipFrameView *)clipFrameView isScrolling:(BOOL)scrolling
{
    self.view.userInteractionEnabled = !scrolling;
}

#pragma mark - 事件
- (void)playerItemDidReachEnd
{
    [self.clipFrameView resetProgressBarMode];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(self.startSecond, self.avAsset.fml_getFPS) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.player pause];
    }];
}

- (void)didBackClick
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"重新录制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touches.anyObject locationInView:self.view];
    
    CGFloat videoY = CGRectGetMaxY(self.navBar.frame);
    CGFloat videoH = kScreenHeight - self.navBar.height - self.clipFrameView.height;
    CGRect videoRect = CGRectMake(0, videoY, kScreenWidth, videoH);
    
    if (CGRectContainsPoint(videoRect, touchPoint)) {
        if (self.player.rate > 0) {
            [self.player pause];
        } else {
            [self.player play];
        }
    }
}

#pragma mark - 监听状态
- (void)editCommandCompletionNotificationReceiver:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:FMLEditCommandCompletionNotification]) {
        self.composition = [[notification object] mutableComposition];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            FMLVideoCommand *videoCommand = [[FMLVideoCommand alloc] initVideoCommendWithComposition:self.composition];
            [videoCommand exportAsset];
        });
    }
}

- (void)exportCommandCompletionNotificationReceiver:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:FMLExportCommandCompletionNotification]) {
        NSURL *url = [[notification object] assetURL];
        
        self.compositionURL = url;
        
        dispatch_async( dispatch_get_main_queue(), ^{
            self.nextBtn.hidden = NO;
            [self.indicatorView stopAnimating];
            self.view.userInteractionEnabled = YES;
            
            if (!url) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"导出视频失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alertView show];
            } else {
//                FMLFilterViewController *filterVC = [FMLFilterViewController new];
//                filterVC.videoURL = url;
//                filterVC.shouldRotation = YES;
//                
//                if (self.navigationController) {
//                    [self.navigationController pushViewController:filterVC animated:YES];
//                } else {
//                    [self presentViewController:filterVC animated:YES completion:nil];
//                }
            }
        });
    }
}

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
                
                [self resetDisplayRect];
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
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)resetDisplayRect
{
    CGRect displayRect = self.playerView.playerLayer.videoRect;
    
    if (fabs(kScreenHeight - displayRect.size.height) < 5) {
        return;
    }
    
    CGFloat wHRate = displayRect.size.width / displayRect.size.height;
    wHRate = ((NSInteger) (wHRate * 100) ) / 100.0;
    
    CGFloat diffH = kScreenHeight - navBarH - clipFrameViewH;
    
    if (wHRate == 0.75 || displayRect.size.height >= diffH) { // 顶端显示
        CGFloat diffY = displayRect.origin.y - navBarH;
        
        [self.playerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(-diffY);
        }];
    } else {    // 居中处理
        CGFloat diffY = displayRect.origin.y  - navBarH - (kScreenHeight - navBarH - clipFrameViewH - displayRect.size.height) / 2;
        
        [self.playerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(-diffY);
        }];
    }
}

- (void)finishClip
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:self.compositionURL.path]) {
        [fileManager removeItemAtURL:self.compositionURL error:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.player pause];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:HJClipVideoStatusContext];
    [self removeObserver:self forKeyPath:@"playerView.playerLayer.readyForDisplay" context:HJClipVideoLayerReadyForDisplay];
    
    self.player.rate =0;
    [self.player removeTimeObserver:self.observer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 懒加载
- (AVPlayer *)player
{
    if (!_player) {
        _player = [AVPlayer new];
    }
    
    return _player;
}

- (UIButton *)backBtn
{
    if (!_backBtn) {
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        WEAKSELF
        [backBtn bk_addEventHandler:^(id sender) {
            [weakSelf didBackClick];
        } forControlEvents:UIControlEventTouchUpInside];
        [backBtn setImage:[UIImage imageNamed:@"video_record_back"] forState:UIControlStateNormal];
        [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        _backBtn = backBtn;
    }
    
    return _backBtn;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.text = @"裁剪";
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    
    return _titleLabel;
}

- (UIView *)iconPlayView
{
    if (!_iconPlayView) {
        _iconPlayView = [UIView new];
        _iconPlayView.layer.contents = (__bridge id)[UIImage imageNamed:@"clip_video_play"].CGImage;
        
        CGFloat playWH = 48;
        CGFloat playX = (kScreenWidth - playWH) / 2;
        CGFloat playY = (kScreenHeight - navBarH - clipFrameViewH - playWH) / 2 + navBarH;
        
        _iconPlayView.frame = CGRectMake(playX, playY, playWH, playWH);
    }
    
    return _iconPlayView;
}

- (UIButton *)nextBtn
{
    if (!_nextBtn) {
        UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [nextBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        nextBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        
        WEAKSELF
        [nextBtn bk_addEventHandler:^(id sender) {
            weakSelf.nextBtn.hidden = YES;
            [weakSelf.indicatorView startAnimating];
            [weakSelf.player pause];
            
            weakSelf.view.userInteractionEnabled = NO;
            
            FMLVideoCommand *videoCommand = [[FMLVideoCommand alloc] init];
            [videoCommand trimAsset:weakSelf.avAsset WithStartSecond:weakSelf.startSecond andEndSecond:weakSelf.endSecond];
        } forControlEvents:UIControlEventTouchUpInside];
        
        _nextBtn = nextBtn;
    }
    
    return _nextBtn;
}

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        _indicatorView.hidesWhenStopped = YES;
    }
    
    return _indicatorView;
}

@end