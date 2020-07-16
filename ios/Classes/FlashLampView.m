//
//  FlashLampView.m
//  barcode_scan
//
//  Created by lirch on 2020/7/14.
//

#import "FlashLampView.h"
#import <AVFoundation/AVFoundation.h>

@interface FlashLampView ()
@property (nonatomic, strong) UIImageView *iconImgV;
@property (nonatomic, strong) UILabel *titleLab;

@end

@implementation FlashLampView
- (void)dealloc{
    [self toggleFlash:NO];
}
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.iconImgV];
        [self addSubview:self.titleLab];
        self.titleLab.text = @"轻触照亮";
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.iconImgV.frame = CGRectMake(0, 0, 15, 19);
    self.iconImgV.center = CGPointMake(CGRectGetWidth(self.frame) *0.5, self.iconImgV.center.y);
    self.titleLab.frame = CGRectMake(0, CGRectGetMaxY(self.iconImgV.frame) + 5.5, self.frame.size.width, 11);
}
- (void)tapAction{
    [self toggleFlash:![self isFlashOn]];
}
- (void)toggleFlash:(BOOL)on{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    NSError *err;
    if (device.hasFlash && device.hasTorch) {
        [device lockForConfiguration:&err];
        if (err != nil) return;
        if (on) {
            device.flashMode = AVCaptureFlashModeOn;
            device.torchMode = AVCaptureTorchModeOn;
            self.titleLab.text = @"轻触关闭";
            self.iconImgV.image = [UIImage imageNamed:@"scan_flashlight_cyan"];
        } else {
            device.flashMode = AVCaptureFlashModeOff;
            device.torchMode = AVCaptureTorchModeOff;
            self.titleLab.text = @"轻触照亮";
            self.iconImgV.image = [UIImage imageNamed:@"scan_flashlight"];
        }
        [device unlockForConfiguration];
    }
}


- (BOOL)isFlashOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        return device.torchMode == AVCaptureFlashModeOn || device.torchMode == AVCaptureTorchModeOn;
    }
    return NO;
}



- (UIImageView *)iconImgV{
    if (!_iconImgV) {
        _iconImgV = [UIImageView new];
        _iconImgV.image = [UIImage imageNamed:@"scan_flashlight"];
        _iconImgV.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImgV;
}

- (UILabel *)titleLab{
    if (!_titleLab) {
        _titleLab = [UILabel new];
        _titleLab.textColor = [UIColor whiteColor];
        _titleLab.font = [UIFont systemFontOfSize:11];
        _titleLab.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLab;
}

@end
