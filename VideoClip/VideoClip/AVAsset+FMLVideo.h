//
//  AVAsset+FMLVideo.h
//  VideoClip
//
//  Created by samo on 16/7/27.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVAsset (FMLVideo)

/**
 *   获取帧图片
 *
 *  @param imageCount     需要获取的图片个数
 *  @param imageBackBlock 得到一个图片是的block
 */
- (void)getImagesCount:(NSUInteger)imageCount imageBackBlock:(void (^)(UIImage *))imageBackBlock;

@end
