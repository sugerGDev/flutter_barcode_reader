//
// Created by Matthew Smith on 11/7/17.
//

#import "BarcodeScannerViewController.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>
#import "ScannerOverlay.h"
#import "FlashLampView.h"
#import "ScanBottomBtnView.h"

@interface BarcodeScannerViewController()
@property (nonatomic, strong) UILabel *titleLab;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *tipLab;
@property (nonatomic, strong) FlashLampView *flashLampView;
@property (nonatomic, strong) ScanBottomBtnView *scanBottomBtnView;
@end

@implementation BarcodeScannerViewController

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGRect reversedBounds = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
    self.previewView.bounds = reversedBounds;
    self.previewView.frame = reversedBounds;
    [self.scanRect stopAnimating];
    [self.scanRect removeFromSuperview];
    [self setupScanRect:reversedBounds];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)setupScanRect:(CGRect)bounds {
    self.scanRect = [[ScannerOverlay alloc] initWithFrame:bounds];
    self.scanRect.translatesAutoresizingMaskIntoConstraints = NO;
    self.scanRect.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_scanRect];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[scanRect]"
                               options:NSLayoutFormatAlignAllBottom
                               metrics:nil
                               views:@{@"scanRect": _scanRect}]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:[scanRect]"
                               options:NSLayoutFormatAlignAllBottom
                               metrics:nil
                               views:@{@"scanRect": _scanRect}]];
    [_scanRect startAnimating];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.previewView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_previewView];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
    [self.view addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:[previewView]"
                                options:NSLayoutFormatAlignAllBottom
                                metrics:nil
                                  views:@{@"previewView": _previewView}]];
    [self setupScanRect:self.view.bounds];
    self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:_previewView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
//    [self updateFlashButton];
    [self createOtherView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.scanner.isScanning) {
        [self.scanner stopScanning];
    }
    __weak __typeof(self)weakSelf = self;
    [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (success) {
            [strongSelf startScan];
        } else {
          [strongSelf.delegate barcodeScannerViewController:strongSelf didFailWithErrorCode:@"PERMISSION_NOT_GRANTED"];
          [strongSelf dismissViewControllerAnimated:NO completion:nil];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)createOtherView{
    self.titleLab.text = @"扫一扫";
    [self.titleLab sizeToFit];
    
    self.tipLab.text = @"将条形码放入框中，即可自动扫描";
    NSArray *dataArr = [NSArray new];
    switch (self.scanBottomBtnType) {
        case 1:
            dataArr = @[@{@"icon":@"scan_write",@"title":@"手动输入"}];
            break;
        case 2:
            dataArr = @[@{@"icon":@"scan_history",@"title":@"查询历史"}];
            break;
        case 3:
            dataArr = @[@{@"icon":@"scan_write",@"title":@"手动输入"},@{@"icon":@"scan_history",@"title":@"查询历史"}];
            break;
        default:
            break;
    }
    [self.scanBottomBtnView setDataWithArr:dataArr];
    
    [self.view addSubview:self.titleLab];
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.tipLab];
    [self.view addSubview:self.flashLampView];
    [self.view addSubview:self.scanBottomBtnView];
    
    
    __weak __typeof(self)weakSelf = self;
    self.scanBottomBtnView.btnClickBlock = ^(NSInteger tag) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(barcodeScannerViewController:didClickBottomBtnWithTag:)]) {
            [strongSelf.delegate barcodeScannerViewController:strongSelf didClickBottomBtnWithTag:tag];
            [strongSelf dismissViewControllerAnimated:NO completion:nil];
        }
    };
}
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    self.backBtn.frame = CGRectMake(0, statusBarHeight, 60, 44);
    self.titleLab.frame = CGRectMake((screenSize.width - self.titleLab.frame.size.width)/2.0, 0, self.titleLab.frame.size.width, self.titleLab.frame.size.height);
    self.titleLab.center = CGPointMake(self.titleLab.center.x, self.backBtn.center.y);
    CGRect scanRect = [self.scanRect scanRect];
    self.tipLab.frame = CGRectMake(0, (scanRect.origin.y + scanRect.size.height) + 13, screenSize.width, 13);
    self.flashLampView.frame = CGRectMake(0, (scanRect.origin.y + scanRect.size.height) - 10 - 35.5, 60, 35.5);
    self.flashLampView.center = CGPointMake(self.tipLab.center.x, self.flashLampView.center.y);
    
    self.scanBottomBtnView.frame = CGRectMake(0, CGRectGetMaxY(self.tipLab.frame) + 30, screenSize.width, 80);
    [self.view bringSubviewToFront:self.backBtn];
    [self.view bringSubviewToFront:self.titleLab];
    [self.view bringSubviewToFront:self.tipLab];
    [self.view bringSubviewToFront:self.flashLampView];
    [self.view bringSubviewToFront:self.scanBottomBtnView];
}

- (void)backBtnAction{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)startScan {
    NSError *error;
    __weak __typeof(self)weakSelf = self;
    [self.scanner startScanningWithResultBlock:^(NSArray<AVMetadataMachineReadableCodeObject *> *codes) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.scanner stopScanning];
         AVMetadataMachineReadableCodeObject *code = codes.firstObject;
        if (code) {
            [strongSelf.delegate barcodeScannerViewController:strongSelf didScanBarcodeWithResult:code.stringValue];
            [strongSelf dismissViewControllerAnimated:NO completion:nil];
        }
    } error:&error];
}

- (void)cancel {
    [self.delegate barcodeScannerViewController:self didFailWithErrorCode:@"USER_CANCELED"];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (BOOL)isFlashOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.torchMode == AVCaptureFlashModeOn || device.torchMode == AVCaptureTorchModeOn;
    }
    return NO;
}

- (BOOL)hasTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.hasTorch;
    }
    return false;
}

- (void)toggleFlash:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    NSError *err;
    if (device.hasFlash && device.hasTorch) {
        [device lockForConfiguration:&err];
        if (err != nil) return;
        if (on) {
            device.flashMode = AVCaptureFlashModeOn;
            device.torchMode = AVCaptureTorchModeOn;
        } else {
            device.flashMode = AVCaptureFlashModeOff;
            device.torchMode = AVCaptureTorchModeOff;
        }
        [device unlockForConfiguration];
    }
}

- (UILabel *)titleLab{
    if (!_titleLab) {
        _titleLab = [UILabel new];
        _titleLab.textColor = [UIColor whiteColor];
        _titleLab.font = [UIFont boldSystemFontOfSize:18];
    }
    return _titleLab;
}
- (UIButton *)backBtn{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_backBtn setImage:[UIImage imageNamed:@"icon-back"] forState:(UIControlStateNormal)];
        [_backBtn.imageView setContentMode:(UIViewContentModeScaleAspectFit)];
        [_backBtn setImageEdgeInsets:UIEdgeInsetsMake(11.5, 0, 11.5, 0)];
        [_backBtn addTarget:self action:@selector(backBtnAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _backBtn;
}
- (UILabel *)tipLab{
    if (!_tipLab) {
        _tipLab = [UILabel new];
        _tipLab.textColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1];
        _tipLab.font = [UIFont systemFontOfSize:13];
        _tipLab.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLab;
}
- (FlashLampView *)flashLampView{
    if (!_flashLampView) {
        _flashLampView = [FlashLampView new];
    }
    return _flashLampView;
}

- (ScanBottomBtnView *)scanBottomBtnView{
    if (!_scanBottomBtnView) {
        _scanBottomBtnView = [ScanBottomBtnView new];
    }
    return _scanBottomBtnView;
}
@end
