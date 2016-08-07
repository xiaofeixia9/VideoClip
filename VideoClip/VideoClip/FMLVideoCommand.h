//
//  FMLVideoCommand.h
//  VideoClip
//
//  Created by Collion on 16/8/7.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface FMLVideoCommand : NSObject

@property (nonatomic, strong, readonly) AVMutableComposition *mutableComposition;

+ (instancetype)shareVideoTrimCommand;

- (void)trimAsset:(AVAsset *)asset WithStartSecond:(Float64)startSecond andEndSecond:(Float64)endSecond;

@end
