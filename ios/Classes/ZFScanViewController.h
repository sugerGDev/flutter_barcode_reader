//
//  ZFScanViewController.h
//  ZFScan
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
 扫描接口基础类
 */
@interface ZFScanViewController :UIViewController

/**
 扫描结果
 */
@property(nonatomic, copy) void (^returnScanBarCodeValue)(NSString *value);


/**
 点击返回事件
 */
@property(nonatomic, copy,nullable) void (^customTapBackAction)(void);


/**
 主题颜色
 */
@property(nonatomic, strong) UIColor *themeColor;


/**
 是否显示 NavIgationBar 默认NO
 */
@property(nonatomic, assign) BOOL needShowNavigationBar;

// 配置标题
@property(nonatomic, copy) NSString *title;
/**
 额外配置View
 */
@property(nonatomic, strong) NSMutableArray <UIView *>*additions;


/**
 重新扫描
 */
- (void)resueScanAction;

/**
 暂停扫描
 */
- (void)stopScanAction;
@end

NS_ASSUME_NONNULL_END
