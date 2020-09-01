//
//  ZFMaskView.m
//  ScanBarCode
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ZFMaskView.h"
#import "ScanKit.h"
#import <QMUIKit/QMUIKit.h>

@interface ZFMaskView(){
    
    /**
     *  扫描透明框比例
     */
    CGFloat ZFScanRatio ;
}

@property (nonatomic, strong) UIImageView * scanLineImg;
@property (nonatomic, strong) UIView * maskView;
@property (nonatomic, strong) UILabel * hintLabel;
@property (nonatomic, strong) UIImageView * topLeftImg;
@property (nonatomic, strong) UIImageView * topRightImg;
@property (nonatomic, strong) UIImageView * bottomLeftImg;
@property (nonatomic, strong) UIImageView * bottomRightImg;

@property (nonatomic, strong) UIBezierPath * bezier;
@property (nonatomic, strong) CAShapeLayer * shapeLayer;

/** 第一次旋转 */
@property (nonatomic, assign) CGFloat isFirstTransition;

/**
 扫描区域
 */
@property(nonatomic, assign) CGRect scanRect;
@end

@implementation ZFMaskView

- (void)commonInit{
    _isFirstTransition = YES;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        ZFScanRatio = 0.7f;
        [self commonInit];
        [self addUI];
    }
    
    return self;
}

/**
 *  添加UI
 */
- (void)addUI{
    //遮罩层
    self.maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.maskView.backgroundColor = [UIColor blackColor];
    self.maskView.alpha = 0.3;
    self.maskView.layer.mask = [self maskLayer];
    [self addSubview:self.maskView];
    
    //提示框
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.text = @"将条形码放入框中，即可自动扫描";
    self.hintLabel.textColor = UIColor.tCColor;
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.font = UIFontMake(13.f);
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.hintLabel];
    
    //边框
    UIImage * topLeft = [UIImage loadBundleImageWithName:@"scan_box_QR1" fromBlundeName:Bundle_ScanKit];
    UIImage * topRight = [UIImage loadBundleImageWithName:@"scan_box_QR2" fromBlundeName:Bundle_ScanKit];
    UIImage * bottomLeft = [UIImage loadBundleImageWithName:@"scan_box_QR3" fromBlundeName:Bundle_ScanKit];
    UIImage * bottomRight = [UIImage loadBundleImageWithName:@"scan_box_QR4" fromBlundeName:Bundle_ScanKit];
    
    //左上
    self.topLeftImg = [[UIImageView alloc] init];
    self.topLeftImg.image = topLeft;
    [self addSubview:self.topLeftImg];
    
    //右上
    self.topRightImg = [[UIImageView alloc] init];
    self.topRightImg.image = topRight;
    [self addSubview:self.topRightImg];
    
    //左下
    self.bottomLeftImg = [[UIImageView alloc] init];
    self.bottomLeftImg.image = bottomLeft;
    [self addSubview:self.bottomLeftImg];
    
    //右下
    self.bottomRightImg = [[UIImageView alloc] init];
    self.bottomRightImg.image = bottomRight;
    [self addSubview:self.bottomRightImg];
    
    //扫描线
    UIImage * scanLine = [UIImage loadBundleImageWithName:@"QRCodeScanLine" fromBlundeName:Bundle_ScanKit];
    self.scanLineImg = [[UIImageView alloc] init];
    self.scanLineImg.image = scanLine;
    self.scanLineImg.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.scanLineImg];
    [self.scanLineImg.layer addAnimation:[self animation] forKey:nil];
    
    //设置frame
    //横屏
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
        
        //提示框
        self.hintLabel.frame = CGRectMake(0, 0, self.frame.size.height * ZFScanRatio, 60);
        self.hintLabel.center = CGPointMake(self.maskView.center.x, self.maskView.center.y + (self.frame.size.height * ZFScanRatio) * 0.5f + 25.f);
        //左上
        self.topLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.topLeftImg.image.size.width, self.topLeftImg.image.size.height);
        //右上
        self.topRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.topRightImg.image.size.width + self.frame.size.height * ZFScanRatio, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.topRightImg.image.size.width, self.topRightImg.image.size.height);
        //左下
        self.bottomLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.bottomLeftImg.image.size.height + self.frame.size.height * ZFScanRatio, self.bottomLeftImg.image.size.width, self.bottomLeftImg.image.size.height);
        //右下
        self.bottomRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.bottomRightImg.image.size.width + self.frame.size.height * ZFScanRatio, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.bottomRightImg.image.size.width + self.frame.size.height * ZFScanRatio, self.bottomRightImg.image.size.width, self.bottomRightImg.image.size.height);
        //扫描线
        self.scanLineImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.frame.size.height * ZFScanRatio, scanLine.size.height);
        
        
        //竖屏
    }else{
        
        //左上
        self.topLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, topLeft.size.width, topLeft.size.height);
        //右上
        self.topRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f - topRight.size.width + self.frame.size.width * ZFScanRatio, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, topRight.size.width, topRight.size.height);
        //左下
        self.bottomLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f - bottomLeft.size.height + self.frame.size.width * ZFScanRatio, bottomLeft.size.width, bottomLeft.size.height);
        //右下
        self.bottomRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f - bottomRight.size.width + self.frame.size.width * ZFScanRatio, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f - bottomRight.size.width + self.frame.size.width * ZFScanRatio, bottomRight.size.width, bottomRight.size.height);
        //扫描线
        self.scanLineImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, self.frame.size.width * ZFScanRatio, scanLine.size.height);
        
        
        //提示框
        self.hintLabel.frame = CGRectMake(0, 0, self.frame.size.width * ZFScanRatio, 60.f);
        self.hintLabel.center = CGPointMake(self.maskView.center.x, self.bottomRightImg.bottom + 30.f * ZFScanRatio);
        
        self.scanRect = CGRectMake( flat(self.topLeftImg.left), flat(self.topLeftImg.top), flat(self.topRightImg.right - self.topLeftImg.left),flat(self.bottomRightImg.bottom - self.topRightImg.top));
        
        //        UIView *scanView = [UIView createLineWithColor:UIColor.tRedColor];
        //        scanView.frame = self.scanRect;
        //        [self addSubview:scanView];
        
    }
}

/**
 *  动画
 */
- (CABasicAnimation *)animation{
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 3;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.repeatCount = MAXFLOAT;
    
    //第一次旋转
    if (_isFirstTransition) {
        //横屏
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight){
            
            animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, (self.center.y - self.frame.size.height * ZFScanRatio * 0.5f + self.scanLineImg.image.size.height * 0.5f))];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, (self.center.y + self.frame.size.height * ZFScanRatio * 0.5f - self.scanLineImg.image.size.height * 0.5f))];
            
            //竖屏
        }else{
            animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, (self.center.y - self.frame.size.width * ZFScanRatio * 0.5f + self.scanLineImg.image.size.height * 0.5f))];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, self.center.y + self.frame.size.width * ZFScanRatio * 0.5f - self.scanLineImg.image.size.height * 0.5f)];
        }
        
//        _isFirstTransition = NO;
        
        //非第一次旋转
    }else{
        //横屏
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight){
            
            animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f)];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, self.scanLineImg.frame.origin.y + self.frame.size.width * ZFScanRatio - self.scanLineImg.frame.size.height * 0.5f)];
            
            
            //竖屏
        }else{
            
            animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f)];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.center.x, self.scanLineImg.frame.origin.y + self.frame.size.height * ZFScanRatio - self.scanLineImg.frame.size.height * 0.5f)];
        }
    }
    
    return animation;
}

/**
 *  遮罩层bezierPath
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)maskPath{
    self.bezier = nil;
    self.bezier = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    //第一次旋转
    if (_isFirstTransition) {
        //横屏
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight){
            
            [self.bezier appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.frame.size.height * ZFScanRatio, self.frame.size.height * ZFScanRatio)] bezierPathByReversingPath]];
            
            //竖屏
        }else{
            [self.bezier appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, self.frame.size.width * ZFScanRatio, self.frame.size.width * ZFScanRatio)] bezierPathByReversingPath]];
        }
        
        //非第一次旋转
    }else{
        //横屏
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight){
            
            [self.bezier appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, self.frame.size.width * ZFScanRatio, self.frame.size.width * ZFScanRatio)] bezierPathByReversingPath]];
            
            //竖屏
        }else{
            [self.bezier appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.frame.size.height * ZFScanRatio, self.frame.size.height * ZFScanRatio)] bezierPathByReversingPath]];
        }
    }
    
    return self.bezier;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.scanLineImg.image =  [self.scanLineImg.image qmui_imageWithTintColor:themeColor];
    self.topLeftImg.image = [self.topLeftImg.image qmui_imageWithTintColor:themeColor];
    self.topRightImg.image = [self.topRightImg.image qmui_imageWithTintColor:themeColor];
    self.bottomLeftImg.image = [self.bottomLeftImg.image qmui_imageWithTintColor:themeColor];
    self.bottomRightImg.image = [self.bottomRightImg.image qmui_imageWithTintColor:themeColor];
}
/**
 *  遮罩层ShapeLayer
 *
 *  @return CAShapeLayer
 */
- (CAShapeLayer *)maskLayer{
    [self.shapeLayer removeFromSuperlayer];
    self.shapeLayer = nil;
    
    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.path = [self maskPath].CGPath;
    
    return self.shapeLayer;
}

#pragma mark - public method

/**
 *  重设UI的frame
 */
- (void)resetFrame{
    
    self.maskView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.maskView.layer.mask = [self maskLayer];
    
    //横屏(转前是横屏，转后才是竖屏)
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight){
        
        self.hintLabel.frame = CGRectMake(0, 0, self.frame.size.width * ZFScanRatio, 60);
        self.hintLabel.center = CGPointMake(self.maskView.center.x, 120);
        
        self.topLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, self.topLeftImg.image.size.width, self.topLeftImg.image.size.height);
        
        self.topRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f - self.topRightImg.image.size.width + self.frame.size.width * ZFScanRatio, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, self.topRightImg.image.size.width, self.topRightImg.image.size.height);
        
        self.bottomLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f - self.bottomLeftImg.image.size.height + self.frame.size.width * ZFScanRatio, self.bottomLeftImg.image.size.width, self.bottomLeftImg.image.size.height);
        
        self.bottomRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f - self.bottomRightImg.image.size.width + self.frame.size.width * ZFScanRatio, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f - self.bottomRightImg.image.size.width + self.frame.size.width * ZFScanRatio, self.bottomRightImg.image.size.width, self.bottomRightImg.image.size.height);
        
        self.scanLineImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.width * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.width * ZFScanRatio)) * 0.5f, self.frame.size.width * ZFScanRatio, self.scanLineImg.image.size.height);
        [self.scanLineImg.layer addAnimation:[self animation] forKey:nil];
        
        //竖屏(转前是竖屏，转后才是横屏)
    }else{
        self.hintLabel.frame = CGRectMake(0, 0, self.frame.size.height * ZFScanRatio, 60.f);
        self.hintLabel.center = CGPointMake(self.maskView.center.x, self.maskView.center.y + (self.frame.size.height * ZFScanRatio) * 0.5f + 25.f);
        
        self.topLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.topLeftImg.image.size.width, self.topLeftImg.image.size.height);
        
        self.topRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.topRightImg.image.size.width + self.frame.size.height * ZFScanRatio, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.topRightImg.image.size.width, self.topRightImg.image.size.height);
        
        self.bottomLeftImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.bottomLeftImg.image.size.height + self.frame.size.height * ZFScanRatio, self.bottomLeftImg.image.size.width, self.bottomLeftImg.image.size.height);
        
        self.bottomRightImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.bottomRightImg.image.size.width + self.frame.size.height * ZFScanRatio, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f - self.bottomRightImg.image.size.width + self.frame.size.height * ZFScanRatio, self.bottomRightImg.image.size.width, self.bottomRightImg.image.size.height);
        
        self.scanLineImg.frame = CGRectMake((self.frame.size.width - (self.frame.size.height * ZFScanRatio)) * 0.5f, (self.frame.size.height - (self.frame.size.height * ZFScanRatio)) * 0.5f, self.frame.size.height * ZFScanRatio, self.scanLineImg.image.size.height);
        [self.scanLineImg.layer addAnimation:[self animation] forKey:nil];
    }
    
    
    NSLog(@"self.top  : %.2f , self. right : %.2f  self.bottom : %.2f self.left : %.2f",self.topLeftImg.top,
          self.topRightImg.right,
          self.bottomRightImg.bottom,
          self.bottomLeftImg.left);
}

/**
 *  移除动画
 */
- (void)removeAnimation{
    [self.scanLineImg.layer removeAllAnimations];
}

- (void)addAnimation {
    if (!self.scanLineImg.layer.animationKeys.count)
        [self.scanLineImg.layer addAnimation:[self animation] forKey:nil];
}

@end
