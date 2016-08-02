//
//  AVAsset+FMLVideo.h
//  VideoClip
//
//  Created by samo on 16/7/27.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVAsset (FMLVideo)

// 属性
@property (nonatomic, strong) AVAssetImageGenerator *imgGenerator;  //
@property (nonatomic, strong) NSNumber *frameRate;  // fps

/**
 *   获取每帧图片
 *
 *  @param imageCount     需要获取的图片个数
 *  @param imageBackBlock 得到一个图片时返回的block
 */
- (void)fml_getImagesCount:(NSUInteger)imageCount imageBackBlock:(void (^)(UIImage *))imageBackBlock;

/**
 *  获取视频的总秒数
 */
- (Float64)fml_getSeconds;

/**
 *  将秒显示对应的缩略图
 *
 *  @param timeBySecond   需要返回的第几秒图片
 *  @param imageBackBlock 返回的图片s
 */
- (void)fml_getThumbailImageRequestAtTimeSecond:(Float64)timeBySecond imageBackBlock:(void (^)(UIImage *))imageBackBlock;

@end
