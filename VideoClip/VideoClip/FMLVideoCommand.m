//
//  FMLVideoCommand.m
//  VideoClip
//
//  Created by Collion on 16/8/7.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "FMLVideoCommand.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation FMLVideoCommand

- (instancetype)initVideoCommendWithComposition:(AVMutableComposition *)composition
{
    if (self = [super init]) {
        _mutableComposition = composition;
    }
    
    return self;
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
        AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(startDuration, endDuration) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
    }
    if(assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(startDuration, endDuration) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FMLEditCommandCompletionNotification object:self];
}

- (void)exportAsset
{
    // Step 1
    // Create an outputURL to which the exported movie will be saved
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];
    // Remove Existing File
    [manager removeItemAtPath:outputURL error:nil];
    
    // Step 2
    // Create an export session with the composition and write the exported movie to the photo library
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:[self.mutableComposition copy] presetName:AVAssetExportPreset1280x720];
    
    self.exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    self.exportSession.outputFileType=AVFileTypeQuickTimeMovie;
    
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (self.exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
                // Step 3
                // Notify AVSEViewController about export completion
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:FMLExportCommandCompletionNotification
                 object:self];
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed:%@", self.exportSession.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Canceled:%@", self.exportSession.error);
                break;
            default:
                break;
        }
    }];
}

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
        if (error) {
            NSLog(@"Video could not be saved");
        }
    }];
}

@end
