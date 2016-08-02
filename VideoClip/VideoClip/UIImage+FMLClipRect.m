//
//  UIImage+FMLClipRect.m
//  VideoClip
//
//  Created by samo on 16/8/2.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "UIImage+FMLClipRect.h"

@implementation UIImage (FMLClipRect)

- (void)fml_imageOrginalRect:(CGRect)orginalRect clipRect:(CGRect)clipRect completeBlock:(void (^)(UIImage *))imageBackBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        CGSize orginalSize = orginalRect.size;
        UIGraphicsBeginImageContextWithOptions(orginalSize, NO, [UIScreen mainScreen].scale);
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:clipRect];
        [path addClip];
        
        [self drawInRect:clipRect];
        
        UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !imageBackBlock ? : imageBackBlock(resultImg);
        });
    });
}

@end
