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
    CGSize orginalSize = orginalRect.size;
    UIGraphicsBeginImageContextWithOptions(orginalSize, NO, [UIScreen mainScreen].scale);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:clipRect];
    [path addClip];
    
    [self drawInRect:clipRect];
    
    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    !imageBackBlock ? : imageBackBlock(resultImg);
}

+ (UIImage *)fml_scaleImage:(UIImage *)image maxDataSize:(NSUInteger)dataSize
{
    if (image) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        if (imageData.length > dataSize) {
            float scaleSize = (dataSize/1.0)/(imageData.length);
            scaleSize = 0.9 * sqrtf(scaleSize);
            return [self scaleImage:image toScale:scaleSize maxDataSize:dataSize];
        } else {
            return image;
        }
    } else {
        return nil;
    }
}

+ (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize maxDataSize:(NSUInteger)dataSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize - 1, image.size.height * scaleSize - 1));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData* imageData = UIImageJPEGRepresentation(scaledImage, 1.0);
    if (imageData.length > dataSize) {
        float scale = (dataSize / 1.0) / (imageData.length);
        scale = 0.9 * sqrtf(scale);
        return [self scaleImage:scaledImage toScale:scale maxDataSize:dataSize];
    }
    return scaledImage;
}

@end
