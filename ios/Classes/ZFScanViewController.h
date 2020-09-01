//
//  ZFScanViewController.h
//  ZFScan
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScanProtocol.h"
#import <ZJScrollViewModule.h>
/**
 扫描接口基础类
 */
@interface ZFScanViewController :QMUICommonViewController<ScanProtocol,ZJScrollPageViewChildVcDelegate>


@end
