//
//  ViewController.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/3/23.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *captureSession;
    AVCaptureDevice *captureDevice;
    AVCaptureDeviceInput *captureInputFront;
    AVCaptureDeviceInput *captureInputBack;
    AVCaptureVideoDataOutput *captureOutput;
    dispatch_queue_t captureQueue;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureDevicePosition currentCameraPosition;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initCaptureSession];
    [self initPreviewLayer];
    
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor grayColor];
    previewLayer.frame = view.frame;
    [view.layer addSublayer:previewLayer];
//    [view.layer insertSublayer:previewLayer atIndex:0];
    [self.view addSubview:view];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 100, 44);
    btn.center = self.view.center;
    [btn addTarget:self action:@selector(startCapture) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"采集" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 100, 44);
    btn.center = CGPointMake(self.view.center.x, self.view.center.y + 44);
    [btn addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startCapture
{
    [captureSession startRunning];
}

- (void)changeCamera
{
    if (AVCaptureDevicePositionFront == currentCameraPosition) {
        currentCameraPosition = AVCaptureDevicePositionBack;
    }
    else {
        currentCameraPosition = AVCaptureDevicePositionFront;
    }
    [self changeCameraPosition:currentCameraPosition];
}

- (void)initCaptureSession
{
    captureSession = [[AVCaptureSession alloc] init];
//    captureDevice = [[AVCaptureDevice alloc] init];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    for (AVCaptureDevice *device in devices) {
        switch ([device position]) {
            case AVCaptureDevicePositionBack:
                captureInputBack = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                break;
            case AVCaptureDevicePositionFront:
                captureInputFront = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                break;
            default:
                break;
        }
    }
    currentCameraPosition = AVCaptureDevicePositionFront;
    [self changeCameraPosition:currentCameraPosition];
    
    captureOutput = [[AVCaptureVideoDataOutput alloc]init];
    captureQueue = dispatch_queue_create("captureQueue", DISPATCH_QUEUE_SERIAL);
    [captureOutput setSampleBufferDelegate:self queue:captureQueue];
    captureOutput.videoSettings = [NSDictionary
                                      dictionaryWithObject:[NSNumber numberWithLong:
#ifdef VIDEO_FORMAT_JPEG
                                                            kCVPixelFormatType_32BGRA
#else
                                                            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
#endif
                                                            ]
                                      forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    if ([captureSession canAddOutput:captureOutput]) {
        [captureSession addOutput:captureOutput];
    }
}

- (BOOL)initPreviewLayer
{
    if (nil == captureSession) {
        return NO;
    }
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    previewLayer.backgroundColor = UIColor.blackColor.CGColor;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    if (previewLayer.connection.isVideoOrientationSupported) {
//        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    
    return YES;
}

- (void)changeCameraPosition:(AVCaptureDevicePosition)position
{
    [captureSession beginConfiguration];
    if (AVCaptureDevicePositionFront == position) {
        [captureSession removeInput:captureInputBack];
        if ([captureSession canAddInput:captureInputFront]) {
            [captureSession addInput:captureInputFront];
        }
    }
    else if (AVCaptureDevicePositionBack == position) {
        [captureSession removeInput:captureInputFront];
        if ([captureSession canAddInput:captureInputBack]) {
            [captureSession addInput:captureInputBack];
        }
    }
    [captureSession commitConfiguration];
}

- (void) captureOutput:(AVCaptureOutput *) captureOutput
	didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __FUNCTION__);
}

@end
