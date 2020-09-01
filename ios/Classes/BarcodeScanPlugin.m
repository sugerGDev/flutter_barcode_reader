#import "BarcodeScanPlugin.h"
#import "ZFScanViewController.h"
#import "YYKit.h"
#import "MMMButton.h"
#import "SJUIKit.h"
#import "MMMUIHelper.h"
#import "UIButton+ClickRange.h"

@implementation BarcodeScanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"de.mintware.barcode_scan"
                                                                binaryMessenger:registrar.messenger];
    BarcodeScanPlugin *instance = [BarcodeScanPlugin new];
    instance.hostViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"scan" isEqualToString:call.method]) {
        self.result = result;
        [self showBarcodeViewWithCall:call];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)showBarcodeViewWithCall:(FlutterMethodCall *)call {
    ZFScanViewController *scannerViewController = [[ZFScanViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scannerViewController];
        if (@available(iOS 13.0, *)) {
            [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
        }
  /*
  
     scannerViewController.delegate = self;
     if ([call.arguments isKindOfClass:[NSDictionary class]] && call.arguments[@"button_key"]) {
         scannerViewController.scanBottomBtnType = [call.arguments[@"button_key"] integerValue];
     }
   */
    @weakify(self);
    
    
    scannerViewController.returnScanBarCodeValue = ^(NSString * _Nonnull value) {
        @strongify(self);
        if (self.result){
            self.result(value);
        }
        [self.hostViewController dismissViewControllerAnimated:NO completion:NULL];
    };
    
    scannerViewController.customTapBackAction = ^{
        @strongify(self);
        [self.hostViewController dismissViewControllerAnimated:NO completion:NULL];
    };
    
    
    scannerViewController.additions = @[
    
    ({
        MMMButton* additionView = nil;
        additionView = [SJUIKit buttonWithBackgroundColor:UIColor.clearColor titleColor:UIColor.whiteColor title:@"手动输入" fontSize:13.f];
        additionView.btnImage = [UIImage imageNamed:@"scan_write"];
        additionView.imagePosition = MMMButtonImagePositionTop;
        additionView.spacingBetweenImageAndTitle = 10.f;
        [additionView sizeToFit];
        [additionView addTarget:self action:@selector(doInputAction:) forControlEvents:UIControlEventTouchUpInside];
        additionView.centerX = MMM_DEVICE_WIDTH * .5f;
        additionView;
    }),
    ].mutableCopy;
    
    
    [self.hostViewController presentViewController:navigationController animated:NO completion:nil];
}


/*
 - (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didClickBottomBtnWithTag:(NSInteger)tag{
     if (self.result) {
         if (tag == 0) {
             self.result(@"input_key");
         }else if (tag == 1) {
             self.result(@"history_key");
         }
     }
 }

 */
- (void)doInputAction:(id)aSender {
    if (self.result) {
          self.result(@"input_key");
       }
     [self.hostViewController dismissViewControllerAnimated:NO completion:NULL];
}

@end
