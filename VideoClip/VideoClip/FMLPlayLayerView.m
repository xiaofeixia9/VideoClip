//
//  FMLPlayLayerView.m
//  Niupu_SNS
//
//  Created by samo on 16/8/17.
//  Copyright © 2016年 WE. All rights reserved.
//

#import "FMLPlayLayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation FMLPlayLayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.playerLayer.needsDisplayOnBoundsChange = YES;
    }
    
    return self;
}

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
}

// override UIView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end
