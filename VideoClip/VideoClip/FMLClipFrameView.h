//
//  FMLClipFrameView.h
//  VideoClip
//
//  Created by samo on 16/7/27.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class FMLClipFrameView;
@protocol FMLClipFrameViewDelegate <NSObject>

@optional
- (void)didStartDragView;
- (void)clipFrameView:(FMLClipFrameView *)clipFrameView didDragView:(Float64)second;
- (void)clipFrameView:(FMLClipFrameView *)clipFrameView didEndDragLeftView:(Float64)second;
- (void)clipFrameView:(FMLClipFrameView *)clipFrameView didEndDragRightView:(Float64)second;

/**
 *  判断clipFrameView中的scrollview是否正在滚动
 *
 *  @param clipFrameView 当前裁剪view
 *  @param isScrolling  是否正在滚动
 */
- (void)clipFrameView:(FMLClipFrameView *)clipFrameView isScrolling:(BOOL)scrolling;

@end

@interface FMLClipFrameView : UIView

@property (nonatomic, weak) id<FMLClipFrameViewDelegate> delegate;

- (instancetype)initWithAsset:(AVAsset *)asset;

- (void)resetProgressBarMode;

- (void)setProgressBarPoisionWithSecond:(Float64)second;

@end
