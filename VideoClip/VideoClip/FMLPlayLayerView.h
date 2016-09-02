//
//  FMLPlayLayerView.h
//  Niupu_SNS
//
//  Created by samo on 16/8/17.
//  Copyright © 2016年 WE. All rights reserved.
//
#import <UIKit/UIKit.h>
@class AVPlayer, AVPlayerLayer;

@interface FMLPlayLayerView : UIView

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

@end
