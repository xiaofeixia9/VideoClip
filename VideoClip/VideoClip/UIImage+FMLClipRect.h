//
//  UIImage+FMLClipRect.h
//  VideoClip
//
//  Created by samo on 16/8/2.
//  Copyright © 2016年 Collion. All rights reserved.
//  边界裁剪，适应显示区域

#import <UIKit/UIKit.h>

@interface UIImage (FMLClipRect)

/**
 *  裁剪图片
 *
 *  @param imageRect 原始图片大小
 *  @param clipRect  需要裁剪成的图片大小
 *  @param image     完成裁剪后的回调
 */
- (void)fml_imageOrginalRect:(CGRect)orginalRect clipRect:(CGRect)clipRect completeBlock:(void (^)(UIImage *))imageBackBlock;


+ (UIImage *)fml_scaleImage:(UIImage *)image maxDataSize:(NSUInteger)dataSize;

@end
