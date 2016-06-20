//
//  GSVideoToolBoxEncoder.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/6/6.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <vector>

#import <VideoToolbox/VideoToolbox.h>

#import "GSVideoToolBoxEncoder.h"
#import "libyuv.h"

static FILE *dataFile = nil;
const char kAnnexBHeaderBytes[4] = {0, 0, 0, 1};

// Convenience function for creating a dictionary.
CFDictionaryRef CreateCFDictionary(CFTypeRef* keys,
                                          CFTypeRef* values,
                                          size_t size) {
    return CFDictionaryCreate(kCFAllocatorDefault, keys, values, size,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);
}

//// Copies characters from a CFStringRef into a std::string.
//std::string CFStringToString(const CFStringRef cf_string) {
//    RTC_DCHECK(cf_string);
//    std::string std_string;
//    // Get the size needed for UTF8 plus terminating character.
//    size_t buffer_size =
//    CFStringGetMaximumSizeForEncoding(CFStringGetLength(cf_string),
//                                      kCFStringEncodingUTF8) +
//    1;
//    std::unique_ptr<char[]> buffer(new char[buffer_size]);
//    if (CFStringGetCString(cf_string, buffer.get(), buffer_size,
//                           kCFStringEncodingUTF8)) {
//        // Copy over the characters.
//        std_string.assign(buffer.get());
//    }
//    return std_string;
//}

// Convenience function for setting a VT property.
void SetVTSessionPropertyOne(VTSessionRef session,
                          CFStringRef key,
                          int32_t value) {
    CFNumberRef cfNum =
    CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &value);
    OSStatus status = VTSessionSetProperty(session, key, cfNum);
    CFRelease(cfNum);
    if (status != noErr) {
//        std::string key_string = CFStringToString(key);
//        LOG(LS_ERROR) << "VTSessionSetProperty failed to set: " << key_string
//        << " to " << value << ": " << status;
    }
}

// Convenience function for setting a VT property.
void SetVTSessionPropertyTwo(VTSessionRef session,
                          CFStringRef key,
                          uint32_t value) {
    int64_t value_64 = value;
    CFNumberRef cfNum =
    CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &value_64);
    OSStatus status = VTSessionSetProperty(session, key, cfNum);
    CFRelease(cfNum);
    if (status != noErr) {
//        std::string key_string = CFStringToString(key);
//        LOG(LS_ERROR) << "VTSessionSetProperty failed to set: " << key_string
//        << " to " << value << ": " << status;
    }
}

// Convenience function for setting a VT property.
void SetVTSessionPropertyThree(VTSessionRef session, CFStringRef key, bool value) {
    CFBooleanRef cf_bool = (value) ? kCFBooleanTrue : kCFBooleanFalse;
    OSStatus status = VTSessionSetProperty(session, key, cf_bool);
    if (status != noErr) {
//        std::string key_string = CFStringToString(key);
//        LOG(LS_ERROR) << "VTSessionSetProperty failed to set: " << key_string
//        << " to " << value << ": " << status;
    }
}

// Convenience function for setting a VT property.
void SetVTSessionPropertyFour(VTSessionRef session,
                          CFStringRef key,
                          CFStringRef value) {
    OSStatus status = VTSessionSetProperty(session, key, value);
    if (status != noErr) {
//        std::string key_string = CFStringToString(key);
//        std::string val_string = CFStringToString(value);
//        LOG(LS_ERROR) << "VTSessionSetProperty failed to set: " << key_string
//        << " to " << val_string << ": " << status;
    }
}

// Struct that we pass to the encoder per frame to encode. We receive it again
// in the encoder callback.
//struct FrameEncodeParams {
//    FrameEncodeParams(webrtc::H264VideoToolboxEncoder* e,
//                      const webrtc::CodecSpecificInfo* csi,
//                      int32_t w,
//                      int32_t h,
//                      int64_t rtms,
//                      uint32_t ts,
//                      webrtc::VideoRotation r)
//    : encoder(e),
//    width(w),
//    height(h),
//    render_time_ms(rtms),
//    timestamp(ts),
//    rotation(r) {
//        if (csi) {
//            codec_specific_info = *csi;
//        } else {
//            codec_specific_info.codecType = webrtc::kVideoCodecH264;
//        }
//    }
//    
//    webrtc::H264VideoToolboxEncoder* encoder;
//    webrtc::CodecSpecificInfo codec_specific_info;
//    int32_t width;
//    int32_t height;
//    int64_t render_time_ms;
//    uint32_t timestamp;
//    webrtc::VideoRotation rotation;
//};

// We receive I420Frames as input, but we need to feed CVPixelBuffers into the
// encoder. This performs the copy and format conversion.
// TODO(tkchin): See if encoder will accept i420 frames and compare performance.
bool CopyVideoFrameToPixelBuffer(const YUV420Data* frame,
                                 CVPixelBufferRef pixel_buffer) {
//    RTC_DCHECK(pixel_buffer);
//    RTC_DCHECK(CVPixelBufferGetPixelFormatType(pixel_buffer) ==
//               kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    if (CVPixelBufferGetPixelFormatType(pixel_buffer) ==
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        NSLog(@"");
    }
//    RTC_DCHECK(CVPixelBufferGetHeightOfPlane(pixel_buffer, 0) ==
//               static_cast<size_t>(frame.height()));
    if (CVPixelBufferGetHeightOfPlane(pixel_buffer, 0) ==
        frame.height) {
        NSLog(@"");
    }
//    RTC_DCHECK(CVPixelBufferGetWidthOfPlane(pixel_buffer, 0) ==
//               static_cast<size_t>(frame.width()));
    if (CVPixelBufferGetWidthOfPlane(pixel_buffer, 0) ==
        frame.width) {
        NSLog(@"");
    }
    
    CVReturn cvRet = CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    if (cvRet != kCVReturnSuccess) {
//        LOG(LS_ERROR) << "Failed to lock base address: " << cvRet;
        return false;
    }
    uint8_t* dst_y = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixel_buffer, 0);
    size_t dst_stride_y = CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 0);
    uint8_t* dst_uv = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixel_buffer, 1);
    size_t dst_stride_uv = CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 1);
    // Convert I420 to NV12.
    int ret = libyuv::I420ToNV12(
                                 frame.yPlane,
                                 frame.yPitch,
                                 frame.uPlane,
                                 frame.uPitch,
                                 frame.vPlane,
                                 frame.vPitch,
                                 dst_y, dst_stride_y, dst_uv, dst_stride_uv,
                                 frame.width, frame.height);
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    if (ret) {
//        LOG(LS_ERROR) << "Error converting I420 VideoFrame to NV12 :" << ret;
        return false;
    }
//    size_t size = fwrite(dst_y, frame.width*frame.height*3/2, 1, dataFile);
    NSLog(@"");
    
    return true;
}

// This is the callback function that VideoToolbox calls when encode is
// complete. From inspection this happens on its own queue.
/*typedef void (*VTCompressionOutputCallback)(
 void * CM_NULLABLE outputCallbackRefCon,
 void * CM_NULLABLE sourceFrameRefCon,
 OSStatus status,
 VTEncodeInfoFlags infoFlags,
 CM_NULLABLE CMSampleBufferRef sampleBuffer );*/
void VTCompressionOutputCallbackData(void* encoder,
                                 void* params,
                                 OSStatus status,
                                 VTEncodeInfoFlags info_flags,
                                 CMSampleBufferRef sample_buffer) {
//    std::unique_ptr<FrameEncodeParams> encode_params(
//                                                     reinterpret_cast<FrameEncodeParams*>(params));
//    FrameEncodeParams *encode_params = (__bridge FrameEncodeParams *)params;
    
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sample_buffer);
//    const int kYPlaneIndex = 0;
//    const int kUVPlaneIndex = 1;
//    size_t yPlaneBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, kYPlaneIndex);
//    size_t yPlaneHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, kYPlaneIndex);
//    size_t uvPlaneBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, kUVPlaneIndex);
//    size_t uvPlaneHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, kUVPlaneIndex);
    
    GSVideoToolBoxEncoder *selfEncoder = (__bridge GSVideoToolBoxEncoder *)params;
    [selfEncoder OnEncodedFrame:status Flag:info_flags Buffer:sample_buffer Info:nil Width:640 Height:480 RenderTime:0 TimeStamp:0 Rotation:kVideoRotation_0];
    
//     (
//                                           status, info_flags, sample_buffer, encode_params->codec_specific_info,
//                                           encode_params->width, encode_params->height,
//                                           encode_params->render_time_ms, encode_params->timestamp,
//                                           encode_params->rotation);
    NSLog(@"");
}

//@implementation VideoCodec
//
//- (id)init
//{
//    self = [super init];
//    if (self) {
//        
//    }
//    return self;
//}
//
//@end
//
//@implementation FrameEncodeParams
//
//- (id)init
//{
//    self = [super init];
//    if (self) {
//        
//    }
//    return self;
//}
//
//@end

@interface GSVideoToolBoxEncoder ()
{
//    int ResetCompressionSession();
//    void ConfigureCompressionSession();
//    void DestroyCompressionSession();
//    const VideoFrame* GetScaledFrameOnEncode(const VideoFrame* frame);
//    void SetBitrateBps(uint32_t bitrate_bps);
//    void SetEncoderBitrateBps(uint32_t bitrate_bps);
    
//    EncodedImageCallback* callback_;
    VTCompressionSessionRef compression_session_;
//    BitrateAdjuster bitrate_adjuster_;
    uint32_t target_bitrate_bps_;
    uint32_t encoder_bitrate_bps_;
    int32_t width_;
    int32_t height_;
    
//    rtc::CriticalSection quality_scaler_crit_;
//    QualityScaler quality_scaler_ GUARDED_BY(quality_scaler_crit_);
//    H264BitstreamParser h264_bitstream_parser_;
}

@end

@implementation GSVideoToolBoxEncoder

- (id)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"yuv420"];
        NSFileManager *manager = [NSFileManager defaultManager];
        if (NO == [manager fileExistsAtPath:path]) {
            [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *fullPath = [path stringByAppendingPathComponent:@"datah264"];
        if ([manager fileExistsAtPath:fullPath]) {
            [manager removeItemAtPath:fullPath error:nil];
        }
        [manager createFileAtPath:fullPath contents:nil attributes:nil];
        
        dataFile = fopen([fullPath UTF8String], "wb");
    }
    
    return self;
}

-(void)DestroyCompressionSession
{
    if (compression_session_) {
        VTCompressionSessionInvalidate(compression_session_);
        CFRelease(compression_session_);
        compression_session_ = nil;
    }
}

-(void)SetEncoderBitrateBps:(uint32_t)bitrate_bps
{
    if (compression_session_) {
        SetVTSessionPropertyTwo(compression_session_,
                                       kVTCompressionPropertyKey_AverageBitRate,
                                       bitrate_bps);
        encoder_bitrate_bps_ = bitrate_bps;
    }
}

-(void)ConfigureCompressionSession
{
//    RTC_DCHECK(compression_session_);
//    SetVTSessionPropertyOne(compression_session_,
//                                   kVTCompressionPropertyKey_RealTime, true);
    SetVTSessionPropertyFour(compression_session_,
                                   kVTCompressionPropertyKey_ProfileLevel,
                                   kVTProfileLevel_H264_High_AutoLevel);//kVTProfileLevel_H264_Baseline_AutoLevel//kVTProfileLevel_H264_Baseline_4_1
//    SetVTSessionPropertyThree(compression_session_,
//                                   kVTCompressionPropertyKey_AllowFrameReordering,
//                                   false);
//    [self SetEncoderBitrateBps:target_bitrate_bps_];
    //码率的平均值，单位是bps
    SetVTSessionPropertyTwo(compression_session_,
                            kVTCompressionPropertyKey_AverageBitRate,
                            target_bitrate_bps_);
    
//    CFNumberRef cfNum =
//    CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &value);


    //码率的上限设置，单位byte in seconds
    OSStatus status  = VTSessionSetProperty(compression_session_, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@102400000, @1]);//(800 * 1024 / 8)
    if (status != noErr) {
        NSLog(@"");
    }
    
    SetVTSessionPropertyTwo(
     compression_session_,
     kVTCompressionPropertyKey_MaxKeyFrameInterval, 10);
    VTSessionSetProperty(compression_session_, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    VTSessionSetProperty(compression_session_, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(compression_session_, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    
//    VTSessionSetProperty(compression_session_, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel);
    
    // TODO(tkchin): Look at entropy mode and colorspace matrices.
    // TODO(tkchin): Investigate to see if there's any way to make this work.
    // May need it to interop with Android. Currently this call just fails.
    // On inspecting encoder output on iOS8, this value is set to 6.
    // internal::SetVTSessionProperty(compression_session_,
    //     kVTCompressionPropertyKey_MaxFrameDelayCount,
    //     1);
    // TODO(tkchin): See if enforcing keyframe frequency is beneficial in any
    // way.
    // internal::SetVTSessionProperty(
    //     compression_session_,
    //     kVTCompressionPropertyKey_MaxKeyFrameInterval, 240);
    // internal::SetVTSessionProperty(
    //     compression_session_,
    //     kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, 240);
    
    // Tell the encoder to start encoding
    VTCompressionSessionPrepareToEncodeFrames(compression_session_);
}

-(int)ResetCompressionSession
{
    [self DestroyCompressionSession ];
    
    // Set source image buffer attributes. These attributes will be present on
    // buffers retrieved from the encoder's pixel buffer pool.
    const size_t attributes_size = 3;
    CFTypeRef keys[attributes_size] = {
#if defined(WEBRTC_IOS)
        kCVPixelBufferOpenGLESCompatibilityKey,
#elif defined(WEBRTC_MAC)
        kCVPixelBufferOpenGLCompatibilityKey,
#endif
        kCVPixelBufferIOSurfacePropertiesKey,
        kCVPixelBufferPixelFormatTypeKey
    };
    CFDictionaryRef io_surface_value =
    CreateCFDictionary(nil, nil, 0);
    int64_t nv12type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef pixel_format =
    CFNumberCreate(nil, kCFNumberLongType, &nv12type);
    CFTypeRef values[attributes_size] = {kCFBooleanTrue, io_surface_value,
        pixel_format};
    CFDictionaryRef source_attributes =
    CreateCFDictionary(keys, values, attributes_size);
    if (io_surface_value) {
        CFRelease(io_surface_value);
        io_surface_value = nil;
    }
    if (pixel_format) {
        CFRelease(pixel_format);
        pixel_format = nil;
    }
    /*mac OS
    CFTypeRef kkeys[] = {kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder};
    CFTypeRef vvalues[] = {kCFBooleanTrue};
    CFDictionaryRef fframe_properties = CreateCFDictionary(kkeys, vvalues, 1);
    NSDictionary *encoderSpecification = @{
                                           (__bridge NSString *)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: @YES
                                           };
    
    */
    __weak GSVideoToolBoxEncoder* weakSelf = self;
    OSStatus status = VTCompressionSessionCreate(
                                                 nil,  // use default allocator
                                                 width_, height_, kCMVideoCodecType_H264,
                                                 nil,  // use default encoder
                                                 source_attributes,
                                                 nil,  // use default compressed data allocator
                                                 VTCompressionOutputCallbackData, (__bridge void * _Nullable)(weakSelf), &compression_session_);
    if (source_attributes) {
        CFRelease(source_attributes);
        source_attributes = nil;
    }
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to create compression session: " << status;
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    [self ConfigureCompressionSession];
    return 0;
}

- (int)InitEncode:(VideoCodec *)codec_settings Cores:(int)number_of_cores Payload:(size_t)max_payload_size
{
//    RTC_DCHECK(codec_settings);
//    RTC_DCHECK_EQ(codec_settings->codecType, kVideoCodecH264);
    if (codec_settings.codecType == VideoCodecType_H264) {
//        rtc::CritScope lock(&quality_scaler_crit_);
//        quality_scaler_.Init(QualityScaler::kLowH264QpThreshold,
//                             QualityScaler::kBadH264QpThreshold,
//                             codec_settings->startBitrate, codec_settings->width,
//                             codec_settings->height, codec_settings->maxFramerate);
//        QualityScaler::Resolution res = quality_scaler_.GetScaledResolution();
        // TODO(tkchin): We may need to enforce width/height dimension restrictions
        // to match what the encoder supports.
        width_ = 640;//res.width;
        height_ = 480;//res.height;
    }
    // We can only set average bitrate on the HW encoder.
    target_bitrate_bps_ = codec_settings.startBitrate;
//    bitrate_adjuster_.SetTargetBitrateBps(target_bitrate_bps_);
    
    // TODO(tkchin): Try setting payload size via
    // kVTCompressionPropertyKey_MaxH264SliceBytes.
    
    return [self ResetCompressionSession];
}

//- (YUV420Data *)GetScaledFrameOnEncode:(YUV420Data*)frame
//{
////    rtc::CritScope lock(&quality_scaler_crit_);
//    quality_scaler_.OnEncodeFrame(frame);
//    return quality_scaler_.GetScaledFrame(frame);
//}

-(int)EncodeCVI:(CVImageBufferRef)input_image Info:(CodecSpecificInfo *)codec_specific_info Type:(NSUInteger *)frame_types
{
    //    fwrite(input_image.yPlane, input_image.width*input_image.height*3/2, 1, dataFile);
    
    //    RTC_DCHECK(!frame.IsZeroSize());
    //    if (!callback_ || !compression_session_) {
    //        return WEBRTC_VIDEO_CODEC_UNINITIALIZED;
    //    }
#if defined(WEBRTC_IOS)
    //    if (!RTCIsUIApplicationActive()) {
    // Ignore all encode requests when app isn't active. In this state, the
    // hardware encoder has been invalidated by the OS.
    //        return WEBRTC_VIDEO_CODEC_OK;
    //    }
#endif
    bool is_keyframe_required = false;
    //    const VideoFrame& input_image = GetScaledFrameOnEncode(frame);

    
    // Get a pixel buffer from the pool and copy frame data over.
    CVPixelBufferPoolRef pixel_buffer_pool =
    VTCompressionSessionGetPixelBufferPool(compression_session_);
#if defined(WEBRTC_IOS)
    if (!pixel_buffer_pool) {
        // Kind of a hack. On backgrounding, the compression session seems to get
        // invalidated, which causes this pool call to fail when the application
        // is foregrounded and frames are being sent for encoding again.
        // Resetting the session when this happens fixes the issue.
        // In addition we request a keyframe so video can recover quickly.
        [self ResetCompressionSession];
        pixel_buffer_pool =
        VTCompressionSessionGetPixelBufferPool(compression_session_);
        is_keyframe_required = true;
    }
#endif
    if (!pixel_buffer_pool) {
        //        LOG(LS_ERROR) << "Failed to get pixel buffer pool.";
        //        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    CVPixelBufferRef pixel_buffer = CVPixelBufferRetain(input_image);//nil;
//    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(nil, pixel_buffer_pool,
//                                                      &pixel_buffer);
//    if (ret != kCVReturnSuccess) {
        //        LOG(LS_ERROR) << "Failed to create pixel buffer: " << ret;
        // We probably want to drop frames here, since failure probably means
        // that the pool is empty.
        //        return WEBRTC_VIDEO_CODEC_ERROR;
//    }
    //    RTC_DCHECK(pixel_buffer);
//    if (!CopyVideoFrameToPixelBuffer(input_image, pixel_buffer)) {
        //        LOG(LS_ERROR) << "Failed to copy frame data.";
//        CVBufferRelease(pixel_buffer);
        //        return WEBRTC_VIDEO_CODEC_ERROR;
//    }
    
    // Check if we need a keyframe.
    if (!is_keyframe_required && frame_types) {
        if (*frame_types == kVideoFrameKey) {
            is_keyframe_required = true;
        }
        //        for (auto frame_type : *frame_types) {
        //            if (frame_type == kVideoFrameKey) {
        //                is_keyframe_required = true;
        //                break;
        //            }
        //        }
    }
    
//    _frame.set_rotation(kVideoRotation_0);
//    _frame.set_ntp_time_ms(0);
//    _frame.set_render_time_ms(TickTime::MillisecondTimestamp());
    
    static int64_t index = 0;
    CMTime presentation_time_stamp = CMTimeMake(index, 1000);
    index++;
    CFDictionaryRef frame_properties = nil;
    if (is_keyframe_required) {
        CFTypeRef keys[] = {kVTEncodeFrameOptionKey_ForceKeyFrame};
        CFTypeRef values[] = {kCFBooleanTrue};
        frame_properties = CreateCFDictionary(keys, values, 1);
    }
    //    std::unique_ptr<internal::FrameEncodeParams> encode_params;
    //    encode_params.reset(new internal::FrameEncodeParams(
    //                                                        this, codec_specific_info, width_, height_, input_image.render_time_ms(),
    //                                                        input_image.timestamp(), input_image.rotation()));
    
    //    FrameEncodeParams *params = [[FrameEncodeParams alloc] init];
    //    params.encoder = self;
    
    // Update the bitrate if needed.
    //    SetBitrateBps(bitrate_adjuster_.GetAdjustedBitrateBps());
    
    OSStatus status = VTCompressionSessionEncodeFrame(
                                                      compression_session_, pixel_buffer, presentation_time_stamp,
                                                      kCMTimeInvalid, frame_properties, (__bridge void *)self/*encode_params.release()*/, nil);
    if (frame_properties) {
        CFRelease(frame_properties);
    }
    if (pixel_buffer) {
        CVBufferRelease(pixel_buffer);
    }
    if (status != noErr) {
        //        LOG(LS_ERROR) << "Failed to encode frame with code: " << status;
        //        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    return 0;
}

-(int)Encode:(YUV420Data *)input_image Info:(CodecSpecificInfo *)codec_specific_info Type:(NSUInteger *)frame_types
{
//    fwrite(input_image.yPlane, input_image.width*input_image.height*3/2, 1, dataFile);
    
//    RTC_DCHECK(!frame.IsZeroSize());
//    if (!callback_ || !compression_session_) {
//        return WEBRTC_VIDEO_CODEC_UNINITIALIZED;
//    }
#if defined(WEBRTC_IOS)
//    if (!RTCIsUIApplicationActive()) {
        // Ignore all encode requests when app isn't active. In this state, the
        // hardware encoder has been invalidated by the OS.
//        return WEBRTC_VIDEO_CODEC_OK;
//    }
#endif
    bool is_keyframe_required = false;
//    const VideoFrame& input_image = GetScaledFrameOnEncode(frame);

    if (input_image.width != width_ || input_image.height != height_) {
        width_ = (int32_t)(input_image.width);
        height_ = (int32_t)(input_image.height);
        int ret = [self ResetCompressionSession];
        if (ret < 0)
            return ret;
    }
    
    // Get a pixel buffer from the pool and copy frame data over.
    CVPixelBufferPoolRef pixel_buffer_pool = VTCompressionSessionGetPixelBufferPool(compression_session_);
#if defined(WEBRTC_IOS)
    if (!pixel_buffer_pool) {
        // Kind of a hack. On backgrounding, the compression session seems to get
        // invalidated, which causes this pool call to fail when the application
        // is foregrounded and frames are being sent for encoding again.
        // Resetting the session when this happens fixes the issue.
        // In addition we request a keyframe so video can recover quickly.
        [self ResetCompressionSession];
        pixel_buffer_pool = VTCompressionSessionGetPixelBufferPool(compression_session_);
        is_keyframe_required = true;
    }
#endif
    if (!pixel_buffer_pool) {
//        LOG(LS_ERROR) << "Failed to get pixel buffer pool.";
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    CVPixelBufferRef pixel_buffer = nil;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(nil, pixel_buffer_pool,
                                                      &pixel_buffer);
    if (ret != kCVReturnSuccess) {
//        LOG(LS_ERROR) << "Failed to create pixel buffer: " << ret;
        // We probably want to drop frames here, since failure probably means
        // that the pool is empty.
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
//    RTC_DCHECK(pixel_buffer);
    if (!CopyVideoFrameToPixelBuffer(input_image, pixel_buffer)) {
//        LOG(LS_ERROR) << "Failed to copy frame data.";
        CVBufferRelease(pixel_buffer);
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    
    // Check if we need a keyframe.
    if (!is_keyframe_required && frame_types) {
        if (*frame_types == kVideoFrameKey) {
            is_keyframe_required = true;
        }
//        for (auto frame_type : *frame_types) {
//            if (frame_type == kVideoFrameKey) {
//                is_keyframe_required = true;
//                break;
//            }
//        }
    }
    
    CMTime presentation_time_stamp = CMTimeMake(input_image.render_time_ms_, 1000);
    CFDictionaryRef frame_properties = nil;
    if (is_keyframe_required) {
        CFTypeRef keys[] = {kVTEncodeFrameOptionKey_ForceKeyFrame};
        CFTypeRef values[] = {kCFBooleanTrue};
        frame_properties = CreateCFDictionary(keys, values, 1);
    }
//    std::unique_ptr<internal::FrameEncodeParams> encode_params;
//    encode_params.reset(new internal::FrameEncodeParams(
//                                                        this, codec_specific_info, width_, height_, input_image.render_time_ms(),
//                                                        input_image.timestamp(), input_image.rotation()));
    
//    FrameEncodeParams *params = [[FrameEncodeParams alloc] init];
//    params.encoder = self;
    
    // Update the bitrate if needed.
//    SetBitrateBps(bitrate_adjuster_.GetAdjustedBitrateBps());
    
    OSStatus status = VTCompressionSessionEncodeFrame(
                                                      compression_session_, pixel_buffer, presentation_time_stamp,
                                                      kCMTimeInvalid, frame_properties, (__bridge void *)self/*encode_params.release()*/, nil);
    if (frame_properties) {
        CFRelease(frame_properties);
    }
    if (pixel_buffer) {
        CVBufferRelease(pixel_buffer);
    }
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to encode frame with code: " << status;
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    return 0;
}

//int RegisterEncodeCompleteCallback(EncodedImageCallback* callback) override;

- (void)OnDroppedFrame
{
    
}

-(int)SetChannelParameters:(uint32_t)packet_loss Rtt:(int64_t)rtt
{
    return 0;
}

-(void)SetBitrateBps:(uint32_t)bitrate_bps
{
    if (encoder_bitrate_bps_ != bitrate_bps) {
        [self SetEncoderBitrateBps:bitrate_bps];
    }
}

-(int)SetRates:(uint32_t)new_bitrate_kbit Rate:(uint32_t)frame_rate
{
    target_bitrate_bps_ = 1000 * new_bitrate_kbit;
//    bitrate_adjuster_.SetTargetBitrateBps(target_bitrate_bps_);
//    SetBitrateBps(bitrate_adjuster_.GetAdjustedBitrateBps());
    [self SetBitrateBps:frame_rate];
    
//    rtc::CritScope lock(&quality_scaler_crit_);
//    quality_scaler_.ReportFramerate(frame_rate);
    
    return 0;
}

-(int)Release
{
    return 0;
}

- (void)stopFile
{
    fclose(dataFile);
}

//const char* ImplementationName() const override;

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    size_t size = fwrite([ByteHeader bytes], [ByteHeader length], 1, dataFile);
    NSLog(@"%ld", size);
    [h264Data appendData:data];
    size = fwrite([data bytes], [data length], 1, dataFile);
    NSLog(@"%ld", size);
    
    
//    if (data!=nil)
//    {
//        
//        
//        H264_header h264Head;
//        if (isKeyFrame==YES)
//        {
//            h264Head.bKeyFrame = 1;
//            if (++mKeyFrameNo > 64)
//            {
//                mKeyFrameNo = 1;
//            }
//            mFrameIndex = 0;
//        }
//        else
//        {
//            h264Head.bKeyFrame = 0;
//        }
//        
//        
//        h264Head.m_bKeyNo = mKeyFrameNo;
//        h264Head.m_btIndexNum = mFrameIndex++;
//        h264Head.bSize = BSIZE;
//        h264Head.bEncoder = 0;
//        
//        h264Head.bFlag = 1;
//        
//        unsigned char dataBuf[h264Data.length+3];
//        memset(dataBuf, 0, h264Data.length+3);
//        memcpy(dataBuf,&h264Head,sizeof(H264_header));
//        memcpy(dataBuf+sizeof(H264_header),[h264Data bytes],h264Data.length);
//        NSData *newData = [NSData dataWithBytes:dataBuf length:h264Data.length+3];
//        if (isKeyFrame==YES)
//        {
//            [self sendH264ToServer:newData];
//        }
//        else
//        {
//            [self sendH264ToServer:newData];
//        }
//        
//        //        [h264Decoder receivedRawVideoFrame:[h264Data bytes] withSize:h264Data.length isIFrame:1];
//        
//        
//    }
    
    
    
}


- (void)OnEncodedFrame:(OSStatus)status Flag:(VTEncodeInfoFlags)info_flags Buffer:(CMSampleBufferRef)sample_buffer Info:(CodecSpecificInfo *)codec_specific_info Width:(int32_t)width Height:(int32_t)height RenderTime:(int64_t)render_time_ms                      TimeStamp:(uint32_t)timestamp Rotation:(VideoRotation)rotation
{
#if 0
    //    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    if (status != 0) return;
    
    if (!CMSampleBufferDataIsReady(sample_buffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
//    H264HwEncoderImpl* encoder = (__bridge H264HwEncoderImpl*)outputCallbackRefCon;
    
    // Check if we have got a key frame first
    bool keyframe = false;
    CFArrayRef attachmentss = CMSampleBufferGetSampleAttachmentsArray(sample_buffer, 0);
    if (attachmentss != nil && CFArrayGetCount(attachmentss)) {
        CFDictionaryRef attachment = static_cast<CFDictionaryRef>(CFArrayGetValueAtIndex(attachmentss, 0));
        //        CFDictionaryRef attachment = CFArrayGetValueAtIndex(attachments, 0);
        keyframe = !CFDictionaryContainsKey(attachment, kCMSampleAttachmentKey_NotSync);
    }
//    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sample_buffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sample_buffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
        if (statusCode == noErr)
        {
            // Found sps and now check for pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                // Found pps
                const char bytes[] = "\x00\x00\x00\x01";
                size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
                NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
                size_t size = fwrite([ByteHeader bytes], [ByteHeader length], 1, dataFile);
                NSLog(@"%ld", size);

                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                size = fwrite([sps bytes], [sps length], 1, dataFile);
                NSLog(@"%ld", size);
                size = fwrite([ByteHeader bytes], [ByteHeader length], 1, dataFile);
                NSLog(@"%ld", size);
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                size = fwrite([pps bytes], [pps length], 1, dataFile);
                NSLog(@"%ld", size);
//                if (encoder->_delegate)
//                {
//                    [encoder->_delegate gotSpsPps:encoder->sps pps:encoder->pps];
//                }
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sample_buffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // Convert the length value from Big-endian to Little-endian
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
//            size_t size = fwrite((dataPointer + bufferOffset + AVCCHeaderLength), NALUnitLength, 1, dataFile);
//            NSLog(@"%ld", size);
            
            NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
//            [encoder->_delegate gotEncodedData:data isKeyFrame:keyframe];
//            [self gotEncodedData:data isKeyFrame:keyframe];
            const char bytes[] = "\x00\x00\x00\x01";
            size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
            NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
            size_t size = fwrite([ByteHeader bytes], [ByteHeader length], 1, dataFile);
            NSLog(@"%ld", size);
            size = fwrite([data bytes], [data length], 1, dataFile);
            NSLog(@"%ld", size);
            
            // Move to the next NAL unit in the block buffer
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
        
    }
#endif
    
    if (status != noErr) {
//        LOG(LS_ERROR) << "H264 encode failed.";
        return;
    }
    
    // Get format description from the sample buffer.
    CMVideoFormatDescriptionRef description =
    CMSampleBufferGetFormatDescription(sample_buffer);
    if (description == nil) {
//        LOG(LS_ERROR) << "Failed to get sample buffer's description.";
//        return false;
    }
    
    // Get parameter set information.
    int nalu_header_size = 0;
    size_t param_set_count = 0;
    OSStatus statuss = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                                                                         description, 0, nil, nil, &param_set_count, &nalu_header_size);
    if (statuss != noErr) {
//        LOG(LS_ERROR) << "Failed to get parameter set.";
//        return false;
    }
    
    bool is_keyframe = false;
    CFArrayRef attachments =
    CMSampleBufferGetSampleAttachmentsArray(sample_buffer, 0);
    if (attachments != nil && CFArrayGetCount(attachments)) {
        CFDictionaryRef attachment = static_cast<CFDictionaryRef>(CFArrayGetValueAtIndex(attachments, 0));
        //        CFDictionaryRef attachment = CFArrayGetValueAtIndex(attachments, 0);
        is_keyframe = !CFDictionaryContainsKey(attachment, kCMSampleAttachmentKey_NotSync);
    }
    
    size_t nalu_offset = 0;
    std::vector<size_t> frag_offsets;
    std::vector<size_t> frag_lengths;
    
    // Place all parameter sets at the front of buffer.
    if (is_keyframe) {
        size_t param_set_size = 0;
        const uint8_t* param_set = nullptr;
        for (size_t i = 0; i < param_set_count; ++i) {
            status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                                                                        description, i, &param_set, &param_set_size, nil, nil);
            if (status != noErr) {
//                LOG(LS_ERROR) << "Failed to get parameter set.";
//                return false;
            }
            // Update buffer.
//            annexb_buffer->AppendData(kAnnexBHeaderBytes, sizeof(kAnnexBHeaderBytes));
//            annexb_buffer->AppendData(reinterpret_cast<const char*>(param_set),
//                                      param_set_size);
            size_t size = fwrite(&kAnnexBHeaderBytes, sizeof(kAnnexBHeaderBytes), 1, dataFile);
            NSLog(@"%ld", size);
            size = fwrite(param_set, param_set_size, 1, dataFile);
            NSLog(@"%ld", size);
            
            // Update fragmentation.
            frag_offsets.push_back(nalu_offset + sizeof(kAnnexBHeaderBytes));
            frag_lengths.push_back(param_set_size);
            nalu_offset += sizeof(kAnnexBHeaderBytes) + param_set_size;
        }
    }
    
    if (info_flags & kVTEncodeInfo_FrameDropped) {
//        LOG(LS_INFO) << "H264 encode dropped frame.";
//        rtc::CritScope lock(&quality_scaler_crit_);
//        quality_scaler_.ReportDroppedFrame();
        return;
    }
    
    // Get block buffer from the sample buffer.
    CMBlockBufferRef block_buffer = CMSampleBufferGetDataBuffer(sample_buffer);
    if (block_buffer == nil) {
//        LOG(LS_ERROR) << "Failed to get sample buffer's block buffer.";
//        return false;
    }
    CMBlockBufferRef contiguous_buffer = nil;
    // Make sure block buffer is contiguous.
    if (!CMBlockBufferIsRangeContiguous(block_buffer, 0, 0)) {
        status = CMBlockBufferCreateContiguous(
                                               nil, block_buffer, nil, nil, 0, 0, 0, &contiguous_buffer);
        if (status != noErr) {
//            LOG(LS_ERROR) << "Failed to flatten non-contiguous block buffer: "
//            << status;
//            return false;
        }
    } else {
        contiguous_buffer = block_buffer;
        // Retain to make cleanup easier.
        CFRetain(contiguous_buffer);
        block_buffer = nil;
    }
    
    // Now copy the actual data.
    char* data_ptr = nil;
    size_t block_buffer_size = CMBlockBufferGetDataLength(contiguous_buffer);
    status = CMBlockBufferGetDataPointer(contiguous_buffer, 0, nil, nil,
                                         &data_ptr);
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to get block buffer data.";
        CFRelease(contiguous_buffer);
//        return false;
    }
    
    NSData *data = [NSData dataWithBytes:data_ptr length:block_buffer_size];
    
    
    size_t bytes_remaining = block_buffer_size;
    while (bytes_remaining > 0) {
        // The size type here must match |nalu_header_size|, we expect 4 bytes.
        // Read the length of the next packet of data. Must convert from big endian
        // to host endian.
//        RTC_DCHECK_GE(bytes_remaining, (size_t)nalu_header_size);
        if (bytes_remaining < nalu_header_size) {
            break;
        }
        uint32_t* uint32_data_ptr = reinterpret_cast<uint32_t*>(data_ptr);
        uint32_t packet_size = CFSwapInt32BigToHost(*uint32_data_ptr);
        // Update buffer.
//        annexb_buffer->AppendData(kAnnexBHeaderBytes, sizeof(kAnnexBHeaderBytes));
//        annexb_buffer->AppendData(data_ptr + nalu_header_size, packet_size);
        size_t size = fwrite(&kAnnexBHeaderBytes, sizeof(kAnnexBHeaderBytes), 1, dataFile);
        NSLog(@"%ld", size);
        size = fwrite(data_ptr + nalu_header_size, packet_size, 1, dataFile);
        NSLog(@"%ld", size);
        // Update fragmentation.
        frag_offsets.push_back(nalu_offset + sizeof(kAnnexBHeaderBytes));
        frag_lengths.push_back(packet_size);
        nalu_offset += sizeof(kAnnexBHeaderBytes) + packet_size;
        
        size_t bytes_written = packet_size + nalu_header_size;
        bytes_remaining -= bytes_written;
        data_ptr += bytes_written;
    }
    
//    size_t size = fwrite(data_ptr, block_buffer_size, 1, dataFile);
//    NSLog(@"");
    
//    // Convert the sample buffer into a buffer suitable for RTP packetization.
//    // TODO(tkchin): Allocate buffers through a pool.
//    std::unique_ptr<rtc::Buffer> buffer(new rtc::Buffer());
//    std::unique_ptr<webrtc::RTPFragmentationHeader> header;
//    {
//        webrtc::RTPFragmentationHeader* header_raw;
//        bool result = H264CMSampleBufferToAnnexBBuffer(sample_buffer, is_keyframe,
//                                                       buffer.get(), &header_raw);
//        header.reset(header_raw);
//        if (!result) {
//            return;
//        }
//    }
//    webrtc::EncodedImage frame(buffer->data(), buffer->size(), buffer->size());
//    frame._encodedWidth = width;
//    frame._encodedHeight = height;
//    frame._completeFrame = true;
//    frame._frameType =
//    is_keyframe ? webrtc::kVideoFrameKey : webrtc::kVideoFrameDelta;
//    frame.capture_time_ms_ = render_time_ms;
//    frame._timeStamp = timestamp;
//    frame.rotation_ = rotation;
//    
//    h264_bitstream_parser_.ParseBitstream(buffer->data(), buffer->size());
//    int qp;
//    if (h264_bitstream_parser_.GetLastSliceQp(&qp)) {
//        rtc::CritScope lock(&quality_scaler_crit_);
//        quality_scaler_.ReportQP(qp);
//    }
//    
//    int result = callback_->Encoded(frame, &codec_specific_info, header.get());
//    if (result != 0) {
//        LOG(LS_ERROR) << "Encode callback failed: " << result;
//        return;
//    }
//    bitrate_adjuster_.Update(frame._size);
}

@end
