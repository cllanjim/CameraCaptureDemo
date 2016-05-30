//
//  tes.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/30.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "tes.h"

@implementation tes

//int ConvertToI420(VideoType src_video_type,
                  const uint8_t* src_frame,
                  int crop_x,
                  int crop_y,
                  int src_width,
                  int src_height,
                  size_t sample_size,
                  VideoRotation rotation,
                  VideoFrame* dst_frame) {
    int dst_width = dst_frame->width();
    int dst_height = dst_frame->height();
    // LibYuv expects pre-rotation values for dst.
    // Stride values should correspond to the destination values.
    if (rotation == kVideoRotation_90 || rotation == kVideoRotation_270) {
        dst_width = dst_frame->height();
        dst_height =dst_frame->width();
    }
    return libyuv::ConvertToI420(src_frame, sample_size,
                                 dst_frame->buffer(kYPlane),
                                 dst_frame->stride(kYPlane),
                                 dst_frame->buffer(kUPlane),
                                 dst_frame->stride(kUPlane),
                                 dst_frame->buffer(kVPlane),
                                 dst_frame->stride(kVPlane),
                                 crop_x, crop_y,
                                 src_width, src_height,
                                 dst_width, dst_height,
                                 ConvertRotationMode(rotation),
                                 ConvertVideoType(src_video_type));
}


{
    const int conversionResult = ConvertToI420(
                                               commonVideoType, videoFrame, 0, 0,  // No cropping
                                               width, height, videoFrameLength,
                                               apply_rotation ? _rotateFrame : kVideoRotation_0, &_captureFrame);
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection*)connection {
    const int kFlags = 0;
    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (CVPixelBufferLockBaseAddress(videoFrame, kFlags) != kCVReturnSuccess) {
        return;
    }
    
    const int kYPlaneIndex = 0;
    const int kUVPlaneIndex = 1;
    
    uint8_t* baseAddress =
    (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(videoFrame, kYPlaneIndex);
    size_t yPlaneBytesPerRow =
    CVPixelBufferGetBytesPerRowOfPlane(videoFrame, kYPlaneIndex);
    size_t yPlaneHeight = CVPixelBufferGetHeightOfPlane(videoFrame, kYPlaneIndex);
    size_t uvPlaneBytesPerRow =
    CVPixelBufferGetBytesPerRowOfPlane(videoFrame, kUVPlaneIndex);
    size_t uvPlaneHeight =
    CVPixelBufferGetHeightOfPlane(videoFrame, kUVPlaneIndex);
    size_t frameSize =
    yPlaneBytesPerRow * yPlaneHeight + uvPlaneBytesPerRow * uvPlaneHeight;
    
    VideoCaptureCapability tempCaptureCapability;
    tempCaptureCapability.width = CVPixelBufferGetWidth(videoFrame);
    tempCaptureCapability.height = CVPixelBufferGetHeight(videoFrame);
    tempCaptureCapability.maxFPS = _capability.maxFPS;
    tempCaptureCapability.rawType = kVideoNV12;
    
    if (!_isStopping && _isRunning && _owner) {
        _owner->IncomingFrame(baseAddress, frameSize, tempCaptureCapability, 0);
    }
    
    CVPixelBufferUnlockBaseAddress(videoFrame, kFlags);
}
@end
