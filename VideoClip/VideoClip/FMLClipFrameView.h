//
//  FMLClipFrameView.h
//  VideoClip
//
//  Created by samo on 16/7/27.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FMLClipFrameView : UIView

@property (nonatomic, copy) void (^didStartDragView)();

@property (nonatomic, copy) void (^didDragView)(Float64 second);

@property (nonatomic, copy) void (^didEndDragLeftView)(Float64 second);
@property (nonatomic, copy) void (^didEndDragRightView)(Float64 second);

- (instancetype)initWithAsset:(AVAsset *)asset minSeconds:(Float64)seconds;

/**
 *  根据秒数计算出进度条位置
 *
 *  @param second 秒数
 */
- (void)setProgressPositionWithSecond:(Float64)second;

@end
