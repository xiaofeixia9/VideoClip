//
//  FMLVideoCommand.m
//  VideoClip
//
//  Created by Collion on 16/8/7.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "FMLVideoCommand.h"

@implementation FMLVideoCommand

static id _instance;
+ (instancetype)shareVideoTrimCommand
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

- (void)trimAsset:(AVAsset *)asset WithStartSecond:(Float64)startSecond andEndSecond:(Float64)endSecond
{
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime insertionPoint = kCMTimeZero;
    CMTime startDuration = CMTimeMake(startSecond, 1);
    CMTime endDuration = CMTimeMake(endSecond, 1);
    NSError *error = nil;

    _mutableComposition = [AVMutableComposition composition];
    
    if(assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [_mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(startDuration, endDuration) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
    }
    if(assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [_mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(startDuration, endDuration) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FMLEditCommandCompletionNotification object:self];
}

@end
