//
//  GSVideoToolBoxEncoder.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/6/6.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "GSVideoToolBoxEncoder.h"
#import "libyuv.h"

// Convenience function for creating a dictionary.
inline CFDictionaryRef CreateCFDictionary(CFTypeRef* keys,
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
        
    }
//    RTC_DCHECK(CVPixelBufferGetHeightOfPlane(pixel_buffer, 0) ==
//               static_cast<size_t>(frame.height()));
    if (CVPixelBufferGetHeightOfPlane(pixel_buffer, 0) ==
        frame.height) {
        
    }
//    RTC_DCHECK(CVPixelBufferGetWidthOfPlane(pixel_buffer, 0) ==
//               static_cast<size_t>(frame.width()));
    if (CVPixelBufferGetWidthOfPlane(pixel_buffer, 0) ==
        frame.width) {
        
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
    int ret = I420ToNV12(
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
//    encode_params->encoder->OnEncodedFrame(
//                                           status, info_flags, sample_buffer, encode_params->codec_specific_info,
//                                           encode_params->width, encode_params->height,
//                                           encode_params->render_time_ms, encode_params->timestamp,
//                                           encode_params->rotation);
    NSLog(@"");
}

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
    SetVTSessionPropertyOne(compression_session_,
                                   kVTCompressionPropertyKey_RealTime, true);
    SetVTSessionPropertyFour(compression_session_,
                                   kVTCompressionPropertyKey_ProfileLevel,
                                   kVTProfileLevel_H264_Baseline_AutoLevel);
    SetVTSessionPropertyThree(compression_session_,
                                   kVTCompressionPropertyKey_AllowFrameReordering,
                                   false);
    [self SetEncoderBitrateBps:target_bitrate_bps_];
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
        width_ = 352;//res.width;
        height_ = 288;//res.height;
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

-(int)Encode:(YUV420Data *)input_image Info:(CodecSpecificInfo *)codec_specific_info Type:(NSUInteger *)frame_types
{
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
        width_ = input_image.width;
        height_ = input_image.height;
        int ret = [self ResetCompressionSession];
        if (ret < 0)
            return ret;
    }
    
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
    
    // Update the bitrate if needed.
//    SetBitrateBps(bitrate_adjuster_.GetAdjustedBitrateBps());
    
    OSStatus status = VTCompressionSessionEncodeFrame(
                                                      compression_session_, pixel_buffer, presentation_time_stamp,
                                                      kCMTimeInvalid, frame_properties, nil/*encode_params.release()*/, nil);
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

//const char* ImplementationName() const override;

- (void)OnEncodedFrame:(OSStatus)status Flag:(VTEncodeInfoFlags)info_flags Buffer:(CMSampleBufferRef)sample_buffer Info:(CodecSpecificInfo *)codec_specific_info Width:(int32_t)width Height:(int32_t)height RenderTime:(int64_t)render_time_ms                      TimeStamp:(uint32_t)timestamp Rotation:(VideoRotation)rotation
{
    if (status != noErr) {
//        LOG(LS_ERROR) << "H264 encode failed.";
        return;
    }
    if (info_flags & kVTEncodeInfo_FrameDropped) {
//        LOG(LS_INFO) << "H264 encode dropped frame.";
//        rtc::CritScope lock(&quality_scaler_crit_);
//        quality_scaler_.ReportDroppedFrame();
        return;
    }
    
    bool is_keyframe = false;
    CFArrayRef attachments =
    CMSampleBufferGetSampleAttachmentsArray(sample_buffer, 0);
    if (attachments != nil && CFArrayGetCount(attachments)) {
        CFDictionaryRef attachment = CFArrayGetValueAtIndex(attachments, 0);
        is_keyframe = !CFDictionaryContainsKey(attachment, kCMSampleAttachmentKey_NotSync);
    }
    
    // Convert the sample buffer into a buffer suitable for RTP packetization.
    // TODO(tkchin): Allocate buffers through a pool.
    std::unique_ptr<rtc::Buffer> buffer(new rtc::Buffer());
    std::unique_ptr<webrtc::RTPFragmentationHeader> header;
    {
        webrtc::RTPFragmentationHeader* header_raw;
        bool result = H264CMSampleBufferToAnnexBBuffer(sample_buffer, is_keyframe,
                                                       buffer.get(), &header_raw);
        header.reset(header_raw);
        if (!result) {
            return;
        }
    }
    webrtc::EncodedImage frame(buffer->data(), buffer->size(), buffer->size());
    frame._encodedWidth = width;
    frame._encodedHeight = height;
    frame._completeFrame = true;
    frame._frameType =
    is_keyframe ? webrtc::kVideoFrameKey : webrtc::kVideoFrameDelta;
    frame.capture_time_ms_ = render_time_ms;
    frame._timeStamp = timestamp;
    frame.rotation_ = rotation;
    
    h264_bitstream_parser_.ParseBitstream(buffer->data(), buffer->size());
    int qp;
    if (h264_bitstream_parser_.GetLastSliceQp(&qp)) {
        rtc::CritScope lock(&quality_scaler_crit_);
        quality_scaler_.ReportQP(qp);
    }
    
    int result = callback_->Encoded(frame, &codec_specific_info, header.get());
    if (result != 0) {
        LOG(LS_ERROR) << "Encode callback failed: " << result;
        return;
    }
    bitrate_adjuster_.Update(frame._size);
}

@end