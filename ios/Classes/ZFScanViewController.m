//
//  ZFScanViewController.m
//  ZFScan
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ZFScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import "QMUIKit.h"
#import "ZFMaskView.h"
#import "MMMButton.h"
#import "SJUIKit.h"
#import "UIButton+ClickRange.h"

#define SCAN_WIDTH (self.view.width)
#define SCAN_HEIGHT (self.view.height)

@interface ZFScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>

/** 返回按钮 */
@property (nonatomic, strong) UIButton * backButton;
/** 设备 */
@property (nonatomic, strong) AVCaptureDevice * device;
/** 输入输出的中间桥梁 */
@property (nonatomic, strong) AVCaptureSession * session;
/** 相机图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;
/** 扫描支持的编码格式的数组 */
@property (nonatomic, strong) NSMutableArray * metadataObjectTypes;
/** 遮罩层 */
@property (nonatomic, strong) ZFMaskView * maskView;
/** 手电筒 */
@property (nonatomic, strong) MMMButton * flashlight;
/** 返回提示Label */
@property (nonatomic, strong) UILabel * backHintLabel;
/** 手电筒提示Label */
@property (nonatomic, strong) UILabel * flashlightHintLabel;

/**
 video 授权成功Block
 */
@property(nonatomic, copy) void (^videoAuthoritySuccessBlock)(void);


/**
 当前输出对象
 */
@property(nonatomic, weak)AVCaptureMetadataOutput *metadataOutput;


/**
 授权按钮
 */
@property(nonatomic, strong) MMMButton *authorityButton;


/** 返回按钮 */
@property (nonatomic, strong) UIButton * authorityBackButton;

/**
 后退按钮
 */
@property(nonatomic, strong) MMMButton *navBackButton;


/**
 标题
 */
@property(nonatomic, strong) UILabel *navTitleLabel;


@end

@implementation ZFScanViewController
- (void)dealloc {
    
    
    _additions = nil;
    _videoAuthoritySuccessBlock = nil;
    _returnScanBarCodeValue = nil;
    _customTapBackAction = nil;
    
}

- (NSMutableArray *)metadataObjectTypes{
    if (!_metadataObjectTypes) {
        _metadataObjectTypes = [NSMutableArray arrayWithObjects:AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode, nil];
        
        // >= iOS 8
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
            [_metadataObjectTypes addObjectsFromArray:@[AVMetadataObjectTypeInterleaved2of5Code, AVMetadataObjectTypeITF14Code, AVMetadataObjectTypeDataMatrixCode]];
        }
    }
    
    return _metadataObjectTypes;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.maskView removeAnimation];
    [self _colseFlashlight:self.flashlight];
    [self stopScanAction];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.maskView addAnimation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self resueScanAction];
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.darkTextColor;
    [self loadUI];
    self.needShowNavigationBar = YES;
}


#pragma mark - UI
- (void)loadUI {
    
    self.authorityButton.hidden = YES;
    self.authorityBackButton.hidden = YES;
    self.maskView.hidden = NO;
    [self.maskView addAnimation];
    
    @weakify(self);
    [self videoAuthority:^{
        @strongify(self);
        
        // 创建扫描对象
        [self capture];
        
        // 添加UI
        [self addUI];
        
        // 设置当前 扫描范围
        [self _coverToMetadataOutputRectOfInterestForRect:self.maskView.scanRect withMetadataOutput:self.metadataOutput];
        
        // 开始捕获
        [self.session startRunning];
    }];
}

/**
 没有授权UI
 */
- (void)addNoAuthorityUI {
    
    // 没有授权按钮
    if ( !self.authorityButton ) {
        self.authorityButton = [MMMButton buttonWithType:(UIButtonTypeCustom)];
        [self.view addSubview:self.authorityButton];
        [self.authorityButton  setTitle:@"启用相机权限" forState:(UIControlStateNormal)];
        [self.authorityButton addTarget:self action:@selector(doTriggerAuthorityAction:) forControlEvents:(UIControlEventTouchUpInside)];
        self.authorityButton.contentEdgeInsets = UIEdgeInsetsMake(5.f, 5.f, 5.f, 5.f);
        [self.authorityButton sizeToFit];
        self.authorityButton.center = CGPointMake(SCAN_WIDTH * .5f, SCAN_HEIGHT * .5f);
        
    }
    
    
    // 没有授权返回按钮
    if (!self.authorityBackButton) {
        UIImage * img = [UIImage imageNamed:@"nav_back_02"];
        self.authorityBackButton = [SJUIKit buttonWithImage:img];
        [self.view addSubview:self.authorityBackButton];
        
        [self.authorityBackButton sizeToFit];
        
        self.authorityBackButton.left = flat(15.f);
        self.authorityBackButton.centerY = flat(self.navTitleLabel.top + StatusBarHeight + 10.f);
        
        @weakify(self);
        self.authorityBackButton.qmui_tapBlock = ^(__kindof UIControl *sender) {
            @strongify(self);
            [self.navigationController popViewControllerAnimated:YES];
            
            if (self.customTapBackAction) {
                self.customTapBackAction();
            }
        };
        
    }
    
    self.maskView.hidden = YES;
    [self.maskView removeAnimation];
    self.authorityButton.hidden = NO;
    self.authorityBackButton.hidden = NO;
}

- (void)doTriggerAuthorityAction:(MMMButton *)aSneder {
    //授权失败
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (@available(iOS 10.0, *)) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        
    } else {
        [UIApplication.sharedApplication openURL:url];
    }
}
/**
 *  添加遮罩层
 */
- (void)addUI{
    // 判断设备是否创建成功
    if (!self.metadataOutput) {
        [self addNoAuthorityUI];
        return;
    }
    
    
    self.maskView = [[ZFMaskView alloc] initWithFrame:CGRectMake(0, 0, SCAN_WIDTH, SCAN_HEIGHT)];
    [self.view addSubview:self.maskView];
    self.maskView.themeColor = self.themeColor;
    
    // Nav-Title
    {
        
        NSString *title = @"扫一扫";
        if (self.title.length) {
            title = self.title;
        }
        self.navTitleLabel = [SJUIKit labelWithTextColor:UIColor.whiteColor numberOfLines:1 text:title fontSize:18.f];
        [self.view addSubview:self.navTitleLabel];
        self.navTitleLabel.textAlignment = NSTextAlignmentCenter;
        self.navTitleLabel.font = UIFontBoldMake(18.f);
        self.navTitleLabel.width = self.view.width * .6f;
        self.navTitleLabel.center = CGPointMake(flat(self.view.width * .5f), flat( StatusBarHeight + self.navTitleLabel.height * .5f + 20.f) );
        self.navTitleLabel.hidden = !self.needShowNavigationBar;
        
    }
    
    UIImage *img = nil;
    
    // Nav-Back
    {
        img = [UIImage imageNamed:@"nav_back_02"];
        self.navBackButton = [SJUIKit buttonWithImage:img];
        [self.view addSubview:self.navBackButton];
        
        [self.navBackButton sizeToFit];
        
        self.navBackButton.left = flat(15.f);
        self.navBackButton.centerY = flat(self.navTitleLabel.top + self.navTitleLabel.height * .5f);
        
        @weakify(self);
        
        self.navBackButton.qmui_tapBlock = ^(__kindof UIControl *sender) {
            @strongify(self);
            dispatch_async_on_main_queue(^{
                
                if (self.customTapBackAction) {
                    self.customTapBackAction();
                    self.customTapBackAction = nil;
                    return ;
                }
                
                [self.navigationController popViewControllerAnimated:YES];
            });
            
        };
        self.navBackButton.hidden = !self.needShowNavigationBar;
    }
    
    //
    //    //返回按钮
    //    CGFloat back_width = 40;
    //    CGFloat back_height = 40;
    //
    //    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    //    self.backButton.frame = CGRectMake(0, 0, back_width, back_height);
    //
    //
    //    img = [UIImage loadBundleImageWithName:@"Down" fromBlundeName:Bundle_ScanKit];
    //    [self.backButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    //    [self.backButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    //    [self.view addSubview:self.backButton];
    //
    //    //返回提示Label
    //    CGFloat backHint_width = 60;
    //    CGFloat backHint_height = 30;
    //
    //    self.backHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, backHint_width, backHint_height)];
    //    self.backHintLabel.text = @"返回";
    //    self.backHintLabel.textAlignment = NSTextAlignmentCenter;
    //    self.backHintLabel.textColor = UIColor.whiteColor;
    //    [self.view addSubview:self.backHintLabel];
    
    //手电筒
    CGFloat flashlight_width = 60;
    CGFloat flashlight_height = 60;
    
    self.flashlight = [MMMButton buttonWithType:UIButtonTypeCustom];
    self.flashlight.frame = CGRectMake(0, 0, flashlight_width, flashlight_height);
    self.flashlight.imagePosition = MMMButtonImagePositionTop;
    self.flashlight.spacingBetweenImageAndTitle = 5.f;
    
    
    img = [UIImage  imageNamed:@"Flashlight_N"];
    [self.flashlight setImage:img forState:UIControlStateNormal];
    [self.flashlight addTarget:self action:@selector(flashlightAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.maskView addSubview:self.flashlight];
    
    //    //手电筒提示Label
    //    CGFloat flashlightHint_width = 60;
    //    CGFloat flashlightHint_height = 30;
    //
    //    self.flashlightHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, flashlightHint_width, flashlightHint_height)];
    self.flashlight.btnTitle = @"轻触点亮";
    self.flashlight.btnFont = UIFontMake(11.f);
    self.flashlight.btnTitleColor = UIColor.whiteColor;
    
    //    self.flashlightHintLabel.textAlignment = NSTextAlignmentCenter;
    //    self.flashlightHintLabel.textColor = UIColor.whiteColor;
    //    [self.view addSubview:self.flashlightHintLabel];
    
    //横屏
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight){
        
        self.backButton.center = CGPointMake(100, SCAN_HEIGHT / 2);;
        self.backHintLabel.center = CGPointMake(100, CGRectGetMaxY(self.backButton.frame) + CGRectGetHeight(self.backHintLabel.frame) / 2);
        self.flashlight.center = CGPointMake(SCAN_WIDTH - 100, SCAN_HEIGHT / 2);
        self.flashlightHintLabel.center = CGPointMake(SCAN_WIDTH - 100, CGRectGetMaxY(self.flashlight.frame) + CGRectGetHeight(self.flashlightHintLabel.frame) / 2);
        
        //竖屏
    }else{
        self.backButton.center = CGPointMake(SCAN_WIDTH / 4, SCAN_HEIGHT - 100);
        self.backHintLabel.center = CGPointMake(SCAN_WIDTH / 4, CGRectGetMaxY(self.backButton.frame) + CGRectGetHeight(self.backHintLabel.frame) / 2);
        self.flashlight.center = CGPointMake(self.view.width * .5f, self.maskView.scanRect.origin.y +  CGRectGetHeight(self.maskView.scanRect) - 30.f);
        //        self.flashlightHintLabel.center = CGPointMake(self.view.width * .5f, CGRectGetMaxY(self.flashlight.frame) + 10.f);
    }
}


- (void)videoAuthority:(void (^)(void))success {
    self.videoAuthoritySuccessBlock = success;
    
    NSString *mediaType = AVMediaTypeVideo;
    @weakify(self);
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        @strongify(self);
        dispatch_async_on_main_queue(^{
            if (!granted) {
                [self addNoAuthorityUI];
                
            } else {
                // 授权成功
                if (self.videoAuthoritySuccessBlock) self.videoAuthoritySuccessBlock();
            }
        });
    }];
}


/**
 *  扫描初始化
 */
- (void)capture{
    
    //获取摄像设备
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *inputError = nil;
    
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&inputError];
    if (inputError) {
        BLog(@"inputError is %@",inputError);
        return;
    }
    //创建输出流
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    //设置代理 在主线程里刷新
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    self.session = [[AVCaptureSession alloc] init];
    //高质量采集率
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self.session addInput:input];
    [self.session addOutput:metadataOutput];
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 0, SCAN_WIDTH, SCAN_HEIGHT);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.backgroundColor = [UIColor yellowColor].CGColor;
    [self.view.layer addSublayer:self.previewLayer];
    
    //设置扫描支持的编码格式(如下设置条形码和二维码兼容)
    metadataOutput.metadataObjectTypes = self.metadataObjectTypes;
    
    // 保存输出对象到全局使用weak
    self.metadataOutput = metadataOutput;
    
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.additions enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self.maskView.subviews containsObject:obj]) {
            CGRect rect =  self.maskView.scanRect;
            obj.top = flat(rect.origin.y + rect.size.height + 50.f);
            [self.maskView addSubview:obj];
        }
    }];
    
}

#pragma mark - ScanKitProtocol

- (UIColor *)themeColor {
    if (!_themeColor) {
        _themeColor = UIColorHex(10BDC9);
    }
    return _themeColor;
}

- (void)setNeedShowNavigationBar:(BOOL)needShowNavigationBar {
    _needShowNavigationBar = needShowNavigationBar;
    
    self.navBackButton.hidden = !needShowNavigationBar;
    self.navTitleLabel.hidden = !needShowNavigationBar;
    
}

#pragma mark - Help
// 该方法中，_preViewLayer指的是AVCaptureVideoPreviewLayer的实例对象，_session是会话对象，metadataOutput是扫码输出流
- (void)_coverToMetadataOutputRectOfInterestForRect:(CGRect)cropRect withMetadataOutput:(AVCaptureMetadataOutput *)metadataOutput{
    CGSize size = _previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1920./1080.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {
        p2 = 352./288.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        p2 = 1280./720.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        p2 = 960./540.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame1280x720]) {
        p2 = 1280./720.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1920./1080.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        p2 = 480./360.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetLow]) {
        p2 = 192./144.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) { // 暂时未查到具体分辨率，但是可以推导出分辨率的比例为4/3
        p2 = 4./3.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1920./1080.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 3840./2160.;
        }
    } else {
        
    }
    if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        metadataOutput.rectOfInterest = CGRectMake((cropRect.origin.y)/size.height,(size.width-(cropRect.size.width+cropRect.origin.x))/size.width, cropRect.size.height/size.height,cropRect.size.width/size.width);
    } else if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (p1 < p2) {
            CGFloat fixHeight = size.width * p2;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            metadataOutput.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                       (size.width-(cropRect.size.width+cropRect.origin.x))/size.width,
                                                       cropRect.size.height/fixHeight,
                                                       cropRect.size.width/size.width);
        } else {
            CGFloat fixWidth = size.height * (1/p2);
            CGFloat fixPadding = (fixWidth - size.width)/2;
            metadataOutput.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                       (size.width-(cropRect.size.width+cropRect.origin.x)+fixPadding)/fixWidth,
                                                       cropRect.size.height/size.height,
                                                       cropRect.size.width/fixWidth);
        }
    } else if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {
            CGFloat fixHeight = size.width * p2;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            metadataOutput.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                       (size.width-(cropRect.size.width+cropRect.origin.x))/size.width,
                                                       cropRect.size.height/fixHeight,
                                                       cropRect.size.width/size.width);
        } else {
            CGFloat fixWidth = size.height * (1/p2);
            CGFloat fixPadding = (fixWidth - size.width)/2;
            metadataOutput.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                       (size.width-(cropRect.size.width+cropRect.origin.x)+fixPadding)/fixWidth,
                                                       cropRect.size.height/size.height,
                                                       cropRect.size.width/fixWidth);
        }
    }
}

#pragma mark - 取消事件

/**
 * 取消事件
 */
- (void)cancelAction{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - 打开/关闭 手电筒

- (void)flashlightAction:(MMMButton *)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        UIImage *img = [[UIImage imageNamed:@"Flashlight_N"] qmui_imageWithTintColor:self.themeColor];
        [sender setImage:img forState:UIControlStateSelected];
        sender.btnTitleColor = self.themeColor;
        
        
        //打开闪光灯
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error = nil;
        
        if ([captureDevice hasTorch]) {
            BOOL locked = [captureDevice lockForConfiguration:&error];
            if (locked) {
                captureDevice.torchMode = AVCaptureTorchModeOn;
                [captureDevice unlockForConfiguration];
            }
        }
        
    }else{
        [self _colseFlashlight:sender];
        
    }
}


- (void)_colseFlashlight:(MMMButton *)sender {
    UIImage *img = [UIImage imageNamed:@"Flashlight_N"];
    [sender setImage:img forState:UIControlStateSelected];
    sender.btnTitleColor = UIColor.whiteColor;
    
    //关闭闪光灯
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode: AVCaptureTorchModeOff];
        [device unlockForConfiguration];
    }
}


#pragma mark - ScanProtocol
- (void)resueScanAction {
    if (self.session && !self.session.isRunning) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.session startRunning];
        });
    }
}

- (void)stopScanAction {
    if (self.session && self.session.isRunning) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.session stopRunning];
        });
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        dispatch_sync_on_main_queue(^{
            AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects.lastObject;
            NSString *resultStr = metadataObject.stringValue;
            //TODO: FIX BUG     EAN & UPC Code
            if ([metadataObject.type isEqualToString:AVMetadataObjectTypeEAN13Code]) {
                NSString* temp =  [NSString stringWithFormat:@"%zd",metadataObject.stringValue.integerValue];
                BOOL isUPC = [self checkUPCBarCodeValue:temp];
                resultStr = isUPC ? temp : resultStr;
            }
            
            if (self.returnScanBarCodeValue)self.returnScanBarCodeValue(resultStr);
        });
        
    }
}

/**
 1. 将所有奇数位置（第1、3、5、7、9和11位）上的数字相加。
 6+9+8+0+0+9=32
 2. 然后，将该数乘以3。
 32*3=96
 3. 将所有偶数位置（第2、4、6、8和10位）上的数字相加。
 3+3+2+0+3=11
 4. 然后，将该和与第2步所得的值相加。
 96+11=107
 5. 保存第4步的值。要创建校验位，需要确定一个值，当将该值与步骤4所得的值相加时，结果为10的倍数。
 107+3=110
 因此，校验位为3。
 
 @param scanResultBarCodeValue 扫描获取的数字
 @return 是否是UPC编码
 */
- (BOOL)checkUPCBarCodeValue:(NSString *)scanResultBarCodeValue {
    if (scanResultBarCodeValue.length == 12) {
        
         NSInteger count = scanResultBarCodeValue.length - 1;
        NSMutableArray <NSString *> *strs = [[NSMutableArray alloc]initWithCapacity:count];
        
        // 获取检查位
        int check = [scanResultBarCodeValue substringFromIndex:count].intValue;
        
        for (int i = 0; i < count; i++) {
            [strs addObject:
             [scanResultBarCodeValue substringWithRange:
              [scanResultBarCodeValue rangeOfComposedCharacterSequencesForRange: NSMakeRange(i, 1)]
              ]];
        }
        
        // 累加奇数位
        int odd = 0;
        for (int i = 0; i <= count; i+= 2) {
            odd += ( (NSString *)[strs objectOrNilAtIndex:i] ).intValue;
        }
        odd *= check;
        
        // 累加偶数位
        int even = 0;
        for (int i = 1; i < count; i+= 2) {
            even +=  ( (NSString *)[strs objectOrNilAtIndex:i] ).intValue;
        }
        
        return ( ( odd + even + check ) % 10 == 0 ) ;
    }
    
    return NO;
    
}
#pragma mark - 横竖屏适配

/**
 *  PS：size为控制器self.view的size，若图表不是直接添加self.view上，则修改以下的frame值
 */
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator{
    
    self.maskView.frame = CGRectMake(0, 0, size.width, size.height);
    self.previewLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [self.maskView resetFrame];
    
    //横屏(转之前是横屏，转之后是竖屏)
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
        
        self.backButton.center = CGPointMake(SCAN_HEIGHT / 4, SCAN_WIDTH - 100);
        self.backHintLabel.center = CGPointMake(SCAN_HEIGHT / 4, CGRectGetMaxY(self.backButton.frame) + CGRectGetHeight(self.backHintLabel.frame) / 2);
        self.flashlight.center = CGPointMake(SCAN_HEIGHT / 4 * 3, SCAN_WIDTH - 100);
        self.flashlightHintLabel.center = CGPointMake(SCAN_HEIGHT / 4 * 3, CGRectGetMaxY(self.flashlight.frame) + CGRectGetHeight(self.flashlightHintLabel.frame) / 2);
        
        //竖屏(转之前是竖屏，转之后是横屏)
    }else{
        self.backButton.center = CGPointMake(100, SCAN_WIDTH / 2);
        self.backHintLabel.center = CGPointMake(100, CGRectGetMaxY(self.backButton.frame) + CGRectGetHeight(self.backHintLabel.frame) / 2);
        self.flashlight.center = CGPointMake(SCAN_HEIGHT - 100, SCAN_WIDTH / 2);
        self.flashlightHintLabel.center = CGPointMake(SCAN_HEIGHT - 100, CGRectGetMaxY(self.flashlight.frame) + CGRectGetHeight(self.flashlightHintLabel.frame) / 2);
        
    }
}

@synthesize returnScanBarCodeValue = _returnScanBarCodeValue,themeColor = _themeColor,additions = _additions,needShowNavigationBar = _needShowNavigationBar,title = _title,customTapBackAction = _customTapBackAction;
@end
