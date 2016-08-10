//
//  FMLChoiceVideoController.m
//  VideoClip
//
//  Created by Collion on 16/7/23.
//  Copyright © 2016年 Collion. All rights reserved.
//

#import "FMLChoiceVideoController.h"
#import "FMLVideoChoiceCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FMLClipVideoViewController.h"

static NSString * const ID = @"video";

@interface FMLChoiceVideoController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) NSMutableArray *albumsGroupArray;
@property (nonatomic, strong) NSMutableArray *videosArray;

@end

@implementation FMLChoiceVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self verifyAuthorization];
    
    [self.view addSubview:self.collectionView];
}

/** 验证授权信息 */
- (void)verifyAuthorization
{
    NSString *tipTextWhenNoPhotosAuthorization; // 提示语
    
    ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
    
    if (authorizationStatus == ALAuthorizationStatusRestricted || authorizationStatus == ALAuthorizationStatusDenied) {
        NSDictionary *mainInfoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [mainInfoDictionary objectForKey:@"CFBundleDisplayName"];
        tipTextWhenNoPhotosAuthorization = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问你的手机相册", appName];
        // 展示提示语
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:tipTextWhenNoPhotosAuthorization delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [self getAlbumsGroup];
    }
}

- (void)getAlbumsGroup
{
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            
            if (group.numberOfAssets > 0) {
                [self.albumsGroupArray addObject:group];
            }
        } else {
            if (self.albumsGroupArray.count) {
                // 遍历所有的video列表
                
                [self emnumeVideoList];
            } else {
                
                // 没有video列表
            }
        }
        
    } failureBlock:^(NSError *error) {
        
    }];
}

- (void)emnumeVideoList
{
    [self.albumsGroupArray enumerateObjectsUsingBlock:^(ALAssetsGroup *assetsGroup, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            if (result) {
                [self.videosArray addObject:result];
            } else {
                // 遍历完成
            }
        }];
    }];
    
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.videosArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FMLVideoChoiceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
    ALAsset *asset = self.videosArray[indexPath.item];
    
    cell.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.videosArray[indexPath.item];
    
    FMLClipVideoViewController *videoVC = [[FMLClipVideoViewController alloc] initClipVideoVCWithAssetURL:asset.defaultRepresentation.url];
    
    [self presentViewController:videoVC animated:YES completion:nil];
}

#pragma mark - 懒加载
- (NSMutableArray *)albumsGroupArray
{
    if (!_albumsGroupArray) {
        _albumsGroupArray = [NSMutableArray array];
    }
    
    return _albumsGroupArray;
}

- (NSMutableArray *)videosArray
{
    if (!_videosArray) {
        _videosArray = [NSMutableArray array];
    }
    
    return _videosArray;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        CGRect rect = self.view.bounds;
        
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake(80, 80);
        _collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
        
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([FMLVideoChoiceCell class]) bundle:nil] forCellWithReuseIdentifier:ID];
    }
    
    return _collectionView;
}
@end
