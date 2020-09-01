//
//  ZFMaskView.h
//  ScanBarCode
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIImage+Untils.h"



@interface ZFMaskView : UIView

/**
 当前资源名字
 */
@property(nonatomic, strong,readonly) NSString *bundleName;
/**
 主题颜色
 */
@property(nonatomic, strong) UIColor *themeColor;
/**
 扫描区域
 */
@property(nonatomic, assign,readonly) CGRect scanRect;

#pragma mark - public method

/**
 *  重设UI的frame
 */
- (void)resetFrame;

/**
 *  移除动画
 */
- (void)removeAnimation;

/**
 添加动画
 */
- (void)addAnimation;
@end



