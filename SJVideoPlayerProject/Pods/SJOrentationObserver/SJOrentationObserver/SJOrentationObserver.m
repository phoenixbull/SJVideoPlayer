//
//  SJOrentationObserver.m
//  SJVideoPlayerProject
//
//  Created by BlueDancer on 2017/12/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJOrentationObserver.h"
#import <Masonry/Masonry.h>


@interface SJOrentationObserver ()

@property (nonatomic, strong, readonly) UIView *blackView;
@property (nonatomic, strong, readwrite) UIView *view;
@property (nonatomic, strong, readwrite) UIView *targetSuperview;

@property (nonatomic, readwrite, getter=isTransitioning) BOOL transitioning;

@property (nonatomic, readonly) SJSupportedRotateViewOrientation supported_Ori;
@property (nonatomic, readwrite) UIDeviceOrientation currentOrientation;

@property (nonatomic, copy, nullable) void(^completion)(SJOrentationObserver *observer);

@end

@implementation SJOrentationObserver

static UIWindow *__window;

- (instancetype)initWithTarget:(UIView *)view container:(UIView *)targetSuperview {
    self = [super init];
    if ( !self ) return nil;
    [self _observerDeviceOrientation];
    _view = view;
    _targetSuperview = targetSuperview;
    _duration = 0.25;
    _blackView = [UIView new];
    _blackView.backgroundColor = [UIColor blackColor];
    _rotateOrientation = SJRotateViewOrientation_Portrait;
    _currentOrientation = UIDeviceOrientationPortrait;
    __window = [(id)[UIApplication sharedApplication].delegate valueForKey:@"window"];
    return self;
}

- (instancetype)initWithTarget:(UIView *)rotateView container:(UIView *)rotateViewSuperView rotationCondition:(BOOL(^)(SJOrentationObserver *observer))rotationCondition {
    self = [self initWithTarget:rotateView container:rotateViewSuperView];
    if ( !self ) return nil;
    _rotationCondition = rotationCondition;
    return self;
}

- (void)dealloc {
    [_blackView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (SJSupportedRotateViewOrientation)supported_Ori {
    SJSupportedRotateViewOrientation supported = self.supportedRotateViewOrientation;
    if ( SJSupportedRotateViewOrientation_All == supported ) supported = SJSupportedRotateViewOrientation_Portrait | SJSupportedRotateViewOrientation_LandscapeRight | SJSupportedRotateViewOrientation_LandscapeLeft;
    return supported;
}

- (void)_observerDeviceOrientation {
    if ( ![UIDevice currentDevice].generatesDeviceOrientationNotifications ) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)_handleDeviceOrientationChange {
    switch ( [UIDevice currentDevice].orientation ) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight: {
            self.currentOrientation = [UIDevice currentDevice].orientation;
        }
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown: break;
    }
    
    SJSupportedRotateViewOrientation supported = self.supported_Ori;
    switch ( [UIDevice currentDevice].orientation ) {
        case UIDeviceOrientationPortrait: {
            if ( SJSupportedRotateViewOrientation_Portrait == (supported & SJSupportedRotateViewOrientation_Portrait) ) {
                self.rotateOrientation = SJRotateViewOrientation_Portrait;
            }
        }
            break;
        case UIDeviceOrientationLandscapeLeft: {
            if ( SJSupportedRotateViewOrientation_LandscapeLeft == (supported & SJSupportedRotateViewOrientation_LandscapeLeft) ) {
                self.rotateOrientation = SJRotateViewOrientation_LandscapeLeft;
            }
        }
            break;
        case UIDeviceOrientationLandscapeRight: {
            if ( SJSupportedRotateViewOrientation_LandscapeRight == (supported & SJSupportedRotateViewOrientation_LandscapeRight) ) {
                self.rotateOrientation = SJRotateViewOrientation_LandscapeRight;
            }
        }
            break;
        default: break;
    }
}

- (BOOL)isFullScreen {
    return (SJRotateViewOrientation_LandscapeLeft == self.rotateOrientation ||
            SJRotateViewOrientation_LandscapeRight == self.rotateOrientation );
}

- (void)setRotateOrientation:(SJRotateViewOrientation)rotateOrientation {
    if ( rotateOrientation == _rotateOrientation ) return;
    [self rotate:rotateOrientation animated:YES];
}

- (BOOL)_changeOrientation {
    if ( self.isTransitioning ) return NO;
    SJSupportedRotateViewOrientation supported = self.supported_Ori;
    if ( self.isFullScreen &&
        SJSupportedRotateViewOrientation_Portrait == (supported & SJSupportedRotateViewOrientation_Portrait) ) {
        self.rotateOrientation = SJRotateViewOrientation_Portrait;
    }
    else {
        // 当前设备朝哪个方向, 就转到那个方向.
        switch ( self.currentOrientation ) {
            case UIDeviceOrientationLandscapeLeft: {
                if ( SJSupportedRotateViewOrientation_LandscapeLeft == (supported & SJSupportedRotateViewOrientation_LandscapeLeft) ) {
                    self.rotateOrientation = SJRotateViewOrientation_LandscapeLeft;
                }
            }
                break;
            case UIDeviceOrientationLandscapeRight: {
                if ( SJSupportedRotateViewOrientation_LandscapeRight == (supported & SJSupportedRotateViewOrientation_LandscapeRight) ) {
                    self.rotateOrientation = SJRotateViewOrientation_LandscapeRight;
                }
            }
                break;
            default: {
                if ( SJSupportedRotateViewOrientation_LandscapeLeft == (supported & SJSupportedRotateViewOrientation_LandscapeLeft) ) {
                    self.rotateOrientation = SJRotateViewOrientation_LandscapeLeft;
                }
                else if ( SJSupportedRotateViewOrientation_LandscapeRight == (supported & SJSupportedRotateViewOrientation_LandscapeRight) ) {
                    self.rotateOrientation = SJRotateViewOrientation_LandscapeRight;
                }
            }
                break;
        }
    }
    return YES;
}

- (void)rotate:(SJRotateViewOrientation)orientation animated:(BOOL)animated {
    [self rotate:orientation animated:animated completion:nil];
}

- (void)rotate:(SJRotateViewOrientation)orientation animated:(BOOL)animated completion:(void (^)(SJOrentationObserver * _Nonnull))block {
    if ( orientation == _rotateOrientation ) return;
    
    if ( !_view || !_targetSuperview ) return;
    
    if ( self.rotationCondition ) { if ( !self.rotationCondition(self) ) return; }
    
    if ( self.isTransitioning ) return;
    
    self.transitioning = YES;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    UIView *superview = nil;
    UIInterfaceOrientation ori = UIInterfaceOrientationUnknown;
    
    switch ( orientation ) {
        case SJRotateViewOrientation_LandscapeRight: {
            ori = UIInterfaceOrientationLandscapeLeft;
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            superview = __window;
        }
            break;
        case SJRotateViewOrientation_LandscapeLeft: {
            ori = UIInterfaceOrientationLandscapeRight;
            transform = CGAffineTransformMakeRotation(M_PI_2);
            superview = __window;
        }
            break;
        case SJRotateViewOrientation_Portrait: {
            ori = UIInterfaceOrientationPortrait;
            transform = CGAffineTransformIdentity;
            superview = self.targetSuperview;
            [_blackView removeFromSuperview];
        }
            break;
    }
    
    if ( !superview || UIInterfaceOrientationUnknown == ori ) {
        self.transitioning = NO;
        return;
    }
    
    if ( _rotateOrientation == SJRotateViewOrientation_Portrait && UIInterfaceOrientationPortrait != ori ) {
        CGRect fix = _view.frame;
        fix.origin = [__window convertPoint:CGPointZero fromView:_targetSuperview];
        [superview addSubview:_view];
        _view.frame = fix;
    }
    
    // update
    _rotateOrientation = orientation;
    
    [UIApplication sharedApplication].statusBarOrientation = ori;
    
    [_view mas_remakeConstraints:^(MASConstraintMaker *make) {
        if ( UIInterfaceOrientationPortrait == ori ) {
            CGRect rect = [__window convertRect:self.targetSuperview.bounds fromView:self.targetSuperview];
            make.size.mas_equalTo(rect.size);
            make.top.offset(rect.origin.y);
            make.leading.offset(rect.origin.x);
        }
        else {
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            CGFloat height = [UIScreen mainScreen].bounds.size.height;
            CGFloat max = MAX(width, height);
            CGFloat min = MIN(width, height);
            make.center.mas_equalTo(CGPointZero);
            make.size.mas_offset(CGSizeMake(max, min));
        }
    }];
    
    if ( _orientationWillChange ) _orientationWillChange(self, self.isFullScreen);
    
    [UIView beginAnimations:@"rotation" context:NULL];
    if ( animated ) [UIView setAnimationDuration:_duration];
    else [UIView setAnimationDuration:0];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_animationDidStop)];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [_view setTransform:transform];
    [_view.superview layoutIfNeeded];
    [UIView commitAnimations];
    
    self.completion = [block copy];
}

- (void)_animationDidStop {
    self.transitioning = NO;
    if ( UIInterfaceOrientationPortrait == [UIApplication sharedApplication].statusBarOrientation ) {
        [_targetSuperview addSubview:_view];
        [_view mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.targetSuperview);
        }];
    }
    else {
        self.blackView.bounds = _view.bounds;
        self.blackView.center = _view.center;
        self.blackView.transform = _view.transform;
        [__window insertSubview:self.blackView belowSubview:_view];
    }
    if ( _orientationChanged ) _orientationChanged(self, self.isFullScreen);
    if ( self.completion ) {
        self.completion(self);
        self.completion = nil;
    }
}
@end
