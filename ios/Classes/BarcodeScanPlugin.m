#import "BarcodeScanPlugin.h"
#import "BarcodeScannerViewController.h"

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
    BarcodeScannerViewController *scannerViewController = [[BarcodeScannerViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scannerViewController];
    if (@available(iOS 13.0, *)) {
        [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
    }
    scannerViewController.delegate = self;
    if ([call.arguments isKindOfClass:[NSDictionary class]] && call.arguments[@"button_key"]) {
        scannerViewController.scanBottomBtnType = [call.arguments[@"button_key"] integerValue];
    }
    
    [self.hostViewController presentViewController:navigationController animated:NO completion:nil];
}
- (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didScanBarcodeWithResult:(NSString *)result {
    if (self.result) {
        self.result(result);
    }
}

- (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didFailWithErrorCode:(NSString *)errorCode {
    if (self.result){
        self.result([FlutterError errorWithCode:errorCode
                                        message:nil
                                        details:nil]);
    }
}

- (void)barcodeScannerViewController:(BarcodeScannerViewController *)controller didClickBottomBtnWithTag:(NSInteger)tag{
    if (self.result) {
        if (tag == 0) {
            self.result(@"input_key");
        }else if (tag == 1) {
            self.result(@"history_key");
        }
        
    }
}
@end
