//
//  DemoPlayerViewController.m
//  SJVideoPlayerProject
//
//  Created by BlueDancer on 2018/3/6.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "DemoPlayerViewController.h"
#import "SJVideoPlayerHelper.h"
#import "SJVideoPlayerURLAsset+SJControlAdd.h"
#import <SJUIFactory/SJUIFactory.h>
#import <Masonry.h>
#import "SJVideoModel.h"
#import <AVFoundation/AVFoundation.h>
#import <SJVideoPlayerAssetCarrier.h>

@interface DemoPlayerViewController ()<SJVideoPlayerHelperUseProtocol>

@property (nonatomic, strong, readonly) UIView *playerSuperView;

@property (nonatomic, strong, readonly) SJVideoPlayerHelper *videoPlayerHelper;
@property (nonatomic, strong) SJVideoModel *video;
@property (nonatomic, strong) SJVideoPlayerURLAsset *asset;
@property (nonatomic, assign) BOOL convertedAsset;

@end

@implementation DemoPlayerViewController

@synthesize playerSuperView = _playerSuperView;

- (instancetype)initWithVideo:(SJVideoModel *)video asset:(SJVideoPlayerURLAsset *__nullable)asset {
    self = [super init];
    if ( !self ) return nil;
    _video = video;
    if ( asset ) {
        _asset = asset;
        [_asset convertToUIView];   // 将资源转化为在UIView上播放.
        _convertedAsset = YES;
    }
    else {
        asset = [[SJVideoPlayerURLAsset alloc] initWithAssetURL:[NSURL URLWithString:self.video.playURLStr]];
        asset.title = self.video.title;
        asset.alwaysShowTitle = YES;
        _asset = asset;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _demoVCSetupViews];
    
    [self.videoPlayerHelper playWithAsset:_asset playerParentView:self.playerSuperView];
    
    // Do any additional setup after loading the view.
}

#pragma mark -
// please lazy load
@synthesize videoPlayerHelper = _videoPlayerHelper;
- (SJVideoPlayerHelper *)videoPlayerHelper {
    if ( _videoPlayerHelper ) return _videoPlayerHelper;
    _videoPlayerHelper = [[SJVideoPlayerHelper alloc] initWithViewController:self];
    return _videoPlayerHelper;
}

- (BOOL)convertedAsset {
    return _convertedAsset;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.videoPlayerHelper.vc_viewDidAppearExeBlock();
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.videoPlayerHelper.vc_viewWillDisappearExeBlock();
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.videoPlayerHelper.vc_viewDidDisappearExeBlock();
}

- (BOOL)prefersStatusBarHidden {
    return self.videoPlayerHelper.vc_prefersStatusBarHiddenExeBlock();
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark -
- (void)_demoVCSetupViews {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.playerSuperView];
    [_playerSuperView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(SJ_is_iPhoneX() ? 34 : 20);
        make.leading.trailing.offset(0);
        make.height.equalTo(self.view.mas_width).multipliedBy(9 / 16.0f);
    }];
}

- (UIView *)playerSuperView {
    if ( _playerSuperView ) return _playerSuperView;
    _playerSuperView = [SJUIViewFactory viewWithBackgroundColor:[UIColor blackColor]];
    return _playerSuperView;
}
@end
