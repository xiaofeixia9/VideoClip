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
@property (nonatomic, strong, readonly) NSURL *assetURL;

- (instancetype)initVideoCommendWithComposition:(AVMutableComposition *)composition;

/**
 *  裁剪资源
 *
 *  @param asset       被裁减的资源
 *  @param startSecond 开始的秒数
 *  @param endSecond   结束的秒数
 */
- (void)trimAsset:(AVAsset *)asset WithStartSecond:(Float64)startSecond andEndSecond:(Float64)endSecond;

/** 导出资源 */
- (void)exportAsset;

@end
