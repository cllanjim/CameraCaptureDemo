//
//  ViewController.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/3/23.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/gltypes.h>
#import <GLKit/GLKView.h>
#import <CoreImage/CoreImage.h>

typedef NS_ENUM(NSInteger, VideoDisplayMode)
{
    VideoDisplayMode_PreviewLayer = 0,
    VideoDisplayMode_OpenGLES = 1
};

@interface ViewController ()
<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *captureSession;
    AVCaptureDevice *captureDevice;
    AVCaptureDeviceInput *captureInputFront;
    AVCaptureDeviceInput *captureInputBack;
    AVCaptureVideoDataOutput *captureOutput;
    AVCaptureDevice *currentCaptureDevice;
    dispatch_queue_t captureQueue;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureDevicePosition currentCameraPosition;
    
    AVCaptureConnection *captureConnection;
    EAGLContext *openGLContext;
    GLKView *glkView;
    CIContext *ciContext;
    
    VideoDisplayMode currentDisplayMode;
    NSUInteger frames;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    currentDisplayMode = VideoDisplayMode_OpenGLES;
    frames = 10;
    
    [self initCaptureSession];
    switch (currentDisplayMode) {
        case VideoDisplayMode_PreviewLayer:
            [self initPreviewLayer];
            break;
        case VideoDisplayMode_OpenGLES:
            [self initOpenGLES];
            break;
        default:
            break;
    }
    
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
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 100, 44);
    btn.center = CGPointMake(self.view.center.x, self.view.center.y + 88);
    [btn addTarget:self action:@selector(stopCapture) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"停止采集" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startCapture
{
//    NSLog(@"%@", currentCaptureDevice.activeFormat);
    [captureSession startRunning];
}

- (void)stopCapture
{
    [captureSession stopRunning];
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

/*
 call this api after following Configuration
 *
 *
 On iOS, the receiver's activeVideoMaxFrameDuration resets to its default value under the following conditions:
 - The receiver's activeFormat changes
 - The receiver's AVCaptureDeviceInput's session's sessionPreset changes
 - The receiver's AVCaptureDeviceInput is added to a session*/
- (BOOL)setFramerateDevice:(AVCaptureDevice *)device Rate:(CMTime)frameDuration
{
    NSError *error;
    NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for (AVFrameRateRange *range in supportedFrameRateRanges) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
            CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRateSupported = YES;
        }
    }
    
    if (frameRateSupported && [device lockForConfiguration:&error]) {
        [device setActiveVideoMaxFrameDuration:frameDuration];
        [device setActiveVideoMinFrameDuration:frameDuration];
        [device unlockForConfiguration];
        return YES;
    }
    NSLog(@"frame rate set error:%@!", error);
    return NO;
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
            {
                captureInputBack = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            }
                break;
            case AVCaptureDevicePositionFront:
            {
                captureInputFront = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                currentCaptureDevice = captureInputFront.device;
            }
                break;
            default:
                break;
        }
    }
    
//    captureConnection = [[AVCaptureConnection alloc]init];
//    if ([captureSession canAddConnection:captureConnection]) {
//        [captureSession addConnection:captureConnection];
//    }
//    captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    
    if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    else {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
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
    previewLayer.backgroundColor = [UIColor clearColor].CGColor;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    if (previewLayer.connection.isVideoOrientationSupported) {
//        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor grayColor];
    previewLayer.frame = view.frame;
    [view.layer addSublayer:previewLayer];
    [self.view addSubview:view];
    
    return YES;
}

- (void)initOpenGLES
{
    openGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    glkView = [[GLKView alloc] initWithFrame:[UIScreen mainScreen].bounds context:openGLContext];
    ciContext = [CIContext contextWithEAGLContext:openGLContext];
    [self.view addSubview:glkView];
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
    
    switch (position) {
        case AVCaptureDevicePositionFront:
            [self setFramerateDevice:captureInputFront.device Rate:CMTimeMake(1, (int32_t)frames)];
            break;
        case AVCaptureDevicePositionBack:
            [self setFramerateDevice:captureInputBack.device Rate:CMTimeMake(1, (int32_t)frames)];
            break;
        default:
            break;
    }
    
}

- (void) captureOutput:(AVCaptureOutput *) captureOutput
	didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __FUNCTION__);
    if (VideoDisplayMode_OpenGLES != currentDisplayMode) {
        return;
    }
//    AVCaptureMetadataOutput
    CFDictionaryRef dic = CMCopyDictionaryOfAttachments(nil, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    
//    (nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    if ([EAGLContext currentContext] != openGLContext) {
        [EAGLContext setCurrentContext:openGLContext];
    }
//    NSLog(@"x:%f y:%f w:%f h:%f", image.extent.origin.x, image.extent.origin.y, image.extent.size.width, image.extent.size.height);
    [glkView bindDrawable];
    [ciContext drawImage:image inRect:image.extent fromRect:image.extent];
    [glkView display];
    
    
}

@end
