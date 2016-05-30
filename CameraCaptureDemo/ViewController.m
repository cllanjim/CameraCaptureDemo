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
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKView.h>
#import <CoreImage/CoreImage.h>
#import <AVKit/AVKit.h>

#import "libyuv/libyuv.h"

#import <AVFoundation/AVFoundation.h>

#import "GSOpenGLESView.h"
#import "BufferManager.h"
#import "OpenGLView20.h"
#import "GSOpenGLESDisplayYUV420View.h"
#import "YUV420Data.h"

#define VIDEO_WIDTH 640
#define VIDEO_HEIGHT 480

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
//    AVCaptureDevice *currentCaptureDevice;
    dispatch_queue_t captureQueue;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureDevicePosition currentCameraPosition;
    
    AVCaptureConnection *captureConnection;
    EAGLContext *openGLContext;
    GLKView *glkView;
    CIContext *ciContext;
    
    VideoDisplayMode currentDisplayMode;
    NSUInteger frames;
    
    BufferManager *yuv420Data;
    
    dispatch_queue_t displayQueue;
    OpenGLView20 *displayView;
    
    GSOpenGLESDisplayYUV420View *yuv420DisplayView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentDisplayMode = VideoDisplayMode_OpenGLES;
    frames = 10;
    
    yuv420Data = [[BufferManager alloc] init];
    
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
    
//    GSOpenGLESView *glview = [[GSOpenGLESView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:glview];
    
    /*
     NSString *yuvFile = [[NSBundle mainBundle] pathForResource:@"jpgimage1_image_640_480" ofType:@"yuv"];
     yuvData = [NSData dataWithContentsOfFile:yuvFile];
     NSLog(@"the reader length is %lu", (unsigned long)yuvData.length);
    
     UInt8 * pFrameRGB = (UInt8*)[yuvData bytes];
     [myview setVideoSize:640 height:480];
     [myview displayYUV420pData:pFrameRGB width:640 height:480];
    */
    displayQueue = dispatch_queue_create("videoDisplay", DISPATCH_QUEUE_SERIAL);
//    displayView = [[OpenGLView20 alloc] initWithFrame:CGRectMake(0, 0, VIDEO_WIDTH, VIDEO_HEIGHT)];
//    displayView.center = self.view.center;
//    displayView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
//    displayView.transform = CGAffineTransformRotate(displayView.transform, M_PI/2);
//    [self.view addSubview:displayView];
    
    
    yuv420DisplayView = [[GSOpenGLESDisplayYUV420View alloc] initWithFrame:CGRectMake(0, 0, VIDEO_WIDTH, VIDEO_HEIGHT)];
    yuv420DisplayView.center = self.view.center;
    yuv420DisplayView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    yuv420DisplayView.transform = CGAffineTransformRotate(yuv420DisplayView.transform, M_PI/2);
    [self.view addSubview:yuv420DisplayView];
    
    [NSTimer scheduledTimerWithTimeInterval:frames/60 target:self selector:@selector(displayVideo) userInfo:nil repeats:YES];
    
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

- (void)displayVideo
{
    dispatch_async(displayQueue, ^{
        NSData *data = [yuv420Data getData];
        if (data) {
            UInt8 * videoFrame = (UInt8 *)[data bytes];
//            [displayView setVideoSize:VIDEO_WIDTH height:VIDEO_HEIGHT];
//            [displayView displayYUV420pData:videoFrame width:VIDEO_WIDTH height:VIDEO_HEIGHT];
            YUV420Data *yuv = [[YUV420Data alloc] initWithYUV420Data:videoFrame Width:VIDEO_WIDTH Height:VIDEO_HEIGHT];
            [yuv420DisplayView renderFrame:yuv];
        }
    });
}

- (void)startCapture
{
//    NSError *error = nil;
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
//    [session setActive:YES error:&error];
//    
//    NSRunLoop   *runloop = [NSRunLoop currentRunLoop];
    
    
//    NSLog(@"%@", currentCaptureDevice.activeFormat);
    
    [captureSession startRunning];
}

- (void)stopCapture
{
    [captureSession stopRunning];
    
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    [glkView display];
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
    
    if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    else {
        captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    currentCameraPosition = AVCaptureDevicePositionFront;
    [self changeCameraPosition:currentCameraPosition];
    
    captureOutput = [[AVCaptureVideoDataOutput alloc]init];
    captureQueue = dispatch_queue_create("captureQueue", DISPATCH_QUEUE_SERIAL);
    [captureOutput setSampleBufferDelegate:self queue:captureQueue];
    /*On iOS, the only supported key is kCVPixelBufferPixelFormatTypeKey. Supported pixel formats are
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange and kCVPixelFormatType_32BGRA.*/
    captureOutput.videoSettings = [NSDictionary
                                      dictionaryWithObject:[NSNumber numberWithLong:
#ifdef VIDEO_FORMAT_JPEG
                                                            kCVPixelFormatType_32BGRA
#else
                                                            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange//NV12
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
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /* unlock the buffer*/
    if(CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess)
    {
//        UInt8 *bufferbasePtr = (UInt8 *)CVPixelBufferGetBaseAddress(imageBuffer);
        UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
        UInt8 *bufferPtr1 = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,1);
//        size_t buffeSize = CVPixelBufferGetDataSize(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
//        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
        size_t bytesrow1  = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);
//        size_t bytesrow2 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,2);
//        UInt8 *yuv420_data = (UInt8 *)malloc(width * height *3/ 2);//buffer to store YUV with layout YYYYYYYYUUVV
//        memset(yuv420_data, 0, width * height *3/ 2);
        
        /* convert NV21 data to YUV420*/
        
        //
        const int kYPlaneIndex = 0;
        const int kUVPlaneIndex = 1;
        size_t yPlaneBytesPerRow =
        CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, kYPlaneIndex);
        size_t yPlaneHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, kYPlaneIndex);
        size_t uvPlaneBytesPerRow =
        CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, kUVPlaneIndex);
        size_t uvPlaneHeight =
        CVPixelBufferGetHeightOfPlane(imageBuffer, kUVPlaneIndex);
        size_t frameSize =
        yPlaneBytesPerRow * yPlaneHeight + uvPlaneBytesPerRow * uvPlaneHeight;
        int stride_y = (int)width;
        int stride_uv = ((int)width + 1) / 2;
        int memmoryLength = stride_y * (int)height + (stride_uv + stride_uv) * (((int)height + 1) / 2);
        UInt8 *yuv420_data = (UInt8 *)malloc(memmoryLength);//buffer to store YUV with layout YYYYYYYYUUVV
        memset(yuv420_data, 0, memmoryLength);
        
        UInt8 *yBuffer = yuv420_data;
        UInt8 *uBuffer = yBuffer + stride_y * height;
        UInt8 *vBuffer = uBuffer + stride_uv * ((height + 1) / 2);
        ConvertToI420(bufferPtr, frameSize, yBuffer, stride_y, uBuffer, stride_uv, vBuffer, stride_uv, 0, 0, (int)width, (int)height, (int)width, (int)height, kRotate0,
                      FOURCC_NV12);
        
        
//        UInt8 *pY = bufferPtr ;
//        UInt8 *pUV = bufferPtr1;
//        UInt8 *pU = yuv420_data + width*height;
//        UInt8 *pV = pU + width*height/4;

//        for(int i =0;i<height;i++)
//        {
//            memcpy(yuv420_data+i*width,pY+i*bytesrow0,width);
//        }
//        for(int j = 0;j<height/2;j++)
//        {
//            for(int i =0;i<width/2;i++)
//            {
//                *(pU++) = pUV[i<<1];
//                *(pV++) = pUV[(i<<1) + 1];
//            }
//            pUV+=bytesrow1;
//        }
        //add code to push yuv420_data to video encoder here
        NSData *data = [NSData dataWithBytes:yuv420_data length:memmoryLength];
        [yuv420Data addData:data];
        
        free(yuv420_data);
        /* unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
//    return;
    
    NSLog(@"%s", __FUNCTION__);
    if (VideoDisplayMode_OpenGLES != currentDisplayMode) {
        return;
    }
    CFDictionaryRef dic = CMCopyDictionaryOfAttachments(nil, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIImage *transformImage = [image imageByApplyingTransform:CGAffineTransformRotate(CGAffineTransformIdentity, M_PI/2)];
    /*(1 2) (3 4) (5 6) (7 8)
     *镜像*
     */
    CIImage *orientationImage = [image imageByApplyingOrientation:5];
//    orientationImage = [orientationImage imageByCroppingToRect:self.view.bounds];
    
    if ([EAGLContext currentContext] != openGLContext) {
        [EAGLContext setCurrentContext:openGLContext];
    }
#if 0
    /*test iamge */
    dispatch_sync(dispatch_get_main_queue(), ^{
            UIView *view = [self.view viewWithTag:1000];
            if (view) {
                [view removeFromSuperview];
            }
            UIImage *pic = [UIImage imageWithCIImage:transformImage];
            UIImageView *picImageView = [[UIImageView alloc] initWithImage:pic];
            picImageView.tag = 100;
            picImageView.frame = self.view.bounds;
            [self.view addSubview:picImageView];

    });
#endif
    
//    NSLog(@"x:%f y:%f w:%f h:%f", image.extent.origin.x, image.extent.origin.y, image.extent.size.width, image.extent.size.height);
    [glkView bindDrawable];
    CGRect rect = orientationImage.extent;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGRect destRect = CGRectApplyAffineTransform(self.view.bounds, CGAffineTransformMakeScale(scale, scale));
    [ciContext drawImage:orientationImage inRect:destRect fromRect:rect];
    [glkView display];
    
    
    return;
    //data
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess)
    {
        UInt8 *bufferbasePtr = (UInt8 *)CVPixelBufferGetBaseAddress(pixelBuffer);
        UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,0);
        UInt8 *bufferPtr1 = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,1);
        size_t buffeSize = CVPixelBufferGetDataSize(pixelBuffer);
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
        size_t bytesrow1  = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,1);
        size_t bytesrow2 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,2);
        UInt8 *yuv420_data = (UInt8 *)malloc(width * height *3/ 2);//buffer to store YUV with layout YYYYYYYYUUVV
        
        /* convert NV21 data to YUV420*/
        
        UInt8 *pY = bufferPtr ;
        UInt8 *pUV = bufferPtr1;
        UInt8 *pU = yuv420_data + width*height;
        UInt8 *pV = pU + width*height/4;
        for(int i =0;i<height;i++)
        {
            memcpy(yuv420_data+i*width,pY+i*bytesrow0,width);
        }
        for(int j = 0;j<height/2;j++)
        {
            for(int i =0;i<width/2;i++)
            {
                *(pU++) = pUV[i<<1];
                *(pV++) = pUV[(i<<1) + 1];
            }
            pUV+=bytesrow1;
        }
        //add code to push yuv420_data to video encoder here
        NSData *data = [[NSData alloc] initWithBytes:yuv420_data length:sizeof(yuv420_data)];
        
        free(yuv420_data);
        /* unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}

@end
