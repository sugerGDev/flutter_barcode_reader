//
// Created by Matthew Smith on 11/7/17.
//

#import <Foundation/Foundation.h>

@class BarcodeScannerViewController;

@protocol BarcodeScannerViewControllerDelegate <NSObject>

- (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didScanBarcodeWithResult:(NSString *)result;
- (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didFailWithErrorCode:(NSString *)errorCode;

/// tag:0 手动输入   1查询历史
- (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didClickBottomBtnWithTag:(NSInteger )tag;
@end
