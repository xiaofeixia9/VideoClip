//
//  FMLTestViewController.m
//  VideoClip
//
//  Created by samo on 16/8/8.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "FMLTestViewController.h"
#import <BlocksKit+UIKit.h>
#import <Masonry.h>

@interface FMLTestViewController ()

@property (nonatomic, strong) AVPlayer *player;                     ///< 播放器
@property (nonatomic, strong) AVPlayerLayer *playerLayer;    ///< 播放的layer

@end

@implementation FMLTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self setUpView];
    [self setUpPlayView];
}

- (void)setUpView
{
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [self.view addSubview:closeBtn];
    
    [closeBtn bk_addEventHandler:^(id sender) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } forControlEvents:UIControlEventTouchUpInside];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(50, 50));
        make.left.top.mas_equalTo(10);
    }];
}

- (void)setUpPlayView
{
    self.player = [AVPlayer new];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
    playerLayer.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:playerLayer];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.avAsset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self.player play];
}

@end
