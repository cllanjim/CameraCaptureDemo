//
//  GSVideoToolBoxDecoder.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/6/20.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <vector>

#import "libyuv/libyuv.h"

#import "GSVideoToolBoxDecoder.h"

static const int64_t kMsPerSec = 1000;
static FILE *decoderYUVdataFile = nil;

const char kAnnexBHeaderBytes[4] = {0, 0, 0, 1};
const size_t kAvccHeaderByteSize = sizeof(uint32_t);

// Helper class for reading NALUs from an RTP Annex B buffer.
@interface AnnexBBufferReader : NSObject
{
    uint8_t* start_;
    size_t offset_;
    size_t next_offset_;
    size_t length_;
}

- (id)initWithData:(uint8_t *)annexb_buffer Length:(size_t)length;
//public:
//    AnnexBBufferReader(const uint8_t* annexb_buffer, size_t length);
//    ~AnnexBBufferReader() {}
//    AnnexBBufferReader(const AnnexBBufferReader& other) = delete;
//    void operator=(const AnnexBBufferReader& other) = delete;
    
    // Returns a pointer to the beginning of the next NALU slice without the
    // header bytes and its length. Returns false if no more slices remain.
-(bool) ReadNalu:(uint8_t**)out_nalu Length:(size_t*)out_length;
    
    // Returns the number of unread NALU bytes, including the size of the header.
    // If the buffer has no remaining NALUs this will return zero.
-(size_t)BytesRemaining;
    
//private:
    // Returns the the next offset that contains NALU data.
-(size_t)FindNextNaluHeader:(uint8_t*)start Length:(size_t)length Offset:(size_t)offset;

@end

@implementation AnnexBBufferReader

- (id)initWithData:(uint8_t *)annexb_buffer Length:(size_t)length
{
    self = [super init];
    if (self) {
        start_ = annexb_buffer;
        offset_ = 0;
        next_offset_ = 0;
        length_ = length;
        
        offset_ = [self FindNextNaluHeader:start_ Length:length Offset:0];
        next_offset_ = [self FindNextNaluHeader:start_ Length:length Offset:(offset_ + sizeof(kAnnexBHeaderBytes))];
    }
    
    return self;
}

-(bool) ReadNalu:(uint8_t**)out_nalu Length:(size_t*)out_length
{
    *out_nalu = nil;
    *out_length = 0;
    
    size_t data_offset = offset_ + sizeof(kAnnexBHeaderBytes);
    if (data_offset > length_) {
        return false;
    }
    *out_nalu = start_ + data_offset;
    *out_length = next_offset_ - data_offset;
    offset_ = next_offset_;
    next_offset_ = [self FindNextNaluHeader:start_ Length:length_ Offset:(offset_ + sizeof(kAnnexBHeaderBytes))];
    return true;

}

-(size_t)BytesRemaining
{
    return length_ - offset_;
}

-(size_t)FindNextNaluHeader:(uint8_t*)start Length:(size_t)length Offset:(size_t)offset
{
    if (offset + sizeof(kAnnexBHeaderBytes) > length) {
        return length;
    }
    // NALUs are separated by an 00 00 00 01 header. Scan the byte stream
    // starting from the offset for the next such sequence.
    const uint8_t* current = start + offset;
    // The loop reads sizeof(kAnnexBHeaderBytes) at a time, so stop when there
    // aren't enough bytes remaining.
    const uint8_t* const end = start + length - sizeof(kAnnexBHeaderBytes);
    while (current < end) {
        if (current[3] > 1) {
            current += 4;
        } else if (current[3] == 1 && current[2] == 0 && current[1] == 0 &&
                   current[0] == 0) {
            return current - start;
        } else {
            ++current;
        }
    }
    return length;
}

@end

// Helper class for writing NALUs using avcc format into a buffer.
@interface AvccBufferWriter : NSObject
{
    uint8_t* start_;
    size_t offset_;
    size_t length_;
}
//AvccBufferWriter(uint8_t* const avcc_buffer, size_t length);
//~AvccBufferWriter() {}
//AvccBufferWriter(const AvccBufferWriter& other) = delete;
//void operator=(const AvccBufferWriter& other) = delete;

// Writes the data slice into the buffer. Returns false if there isn't
// enough space left.
-(bool) WriteNalu:(uint8_t *)data Size:(size_t)data_size;

// Returns the unused bytes in the buffer.
-(size_t)BytesRemaining;

- (id)initWithData:(uint8_t *)annexb_buffer Length:(size_t)length;

//private:
//uint8_t* const start_;
//size_t offset_;
//const size_t length_;
@end

@implementation AvccBufferWriter

- (id)initWithData:(uint8_t *)annexb_buffer Length:(size_t)length
{
    self = [super init];
    if (self) {
        start_ = annexb_buffer;
        offset_ = 0;
        length_ = length;
    }
    
    return self;
}

-(BOOL)WriteNalu:(uint8_t *)data Size:(size_t)data_size
{
    // Check if we can write this length of data.
    if (data_size + kAvccHeaderByteSize > [self BytesRemaining]) {
        return false;
    }
    // Write length header, which needs to be big endian.
    uint32_t big_endian_length = CFSwapInt32HostToBig(data_size);
    memcpy(start_ + offset_, &big_endian_length, sizeof(big_endian_length));
    offset_ += sizeof(big_endian_length);
    // Write data.
    memcpy(start_ + offset_, data, data_size);
    offset_ += data_size;
    return true;
}

-(size_t)BytesRemaining{
    return length_ - offset_;
}

@end


// Convenience function for creating a dictionary.
inline CFDictionaryRef CreateCFDictionary(CFTypeRef* keys,
                                          CFTypeRef* values,
                                          size_t size) {
    return CFDictionaryCreate(nullptr, keys, values, size,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);
}

namespace internal {
// This is the callback function that VideoToolbox calls when decode is
// complete.
void VTDecompressionOutputCallback(void* decoder,
                                   void* params,
                                   OSStatus status,
                                   VTDecodeInfoFlags info_flags,
                                   CVImageBufferRef image_buffer,
                                   CMTime timestamp,
                                   CMTime duration) {
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to decode frame. Status: " << status;
        return;
    }
    // TODO(tkchin): Handle CVO properly.
//    rtc::scoped_refptr<webrtc::VideoFrameBuffer> buffer =
//    new rtc::RefCountedObject<webrtc::CoreVideoFrameBuffer>(image_buffer);
//    webrtc::VideoFrame decoded_frame(buffer, decode_params->timestamp,
//                                     CMTimeGetSeconds(timestamp) * kMsPerSec,
//                                     webrtc::kVideoRotation_0);
//    decode_params->callback->Decoded(decoded_frame);
    
//    GSVideoToolBoxDecoder *decoder =
    
    if(CVPixelBufferLockBaseAddress(image_buffer, 0) == kCVReturnSuccess)
    {
        //        UInt8 *bufferbasePtr = (UInt8 *)CVPixelBufferGetBaseAddress(imageBuffer);
        UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(image_buffer,0);
        UInt8 *bufferPtr1 = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(image_buffer,1);
        //        size_t buffeSize = CVPixelBufferGetDataSize(imageBuffer);
        size_t width = CVPixelBufferGetWidth(image_buffer);
        size_t height = CVPixelBufferGetHeight(image_buffer);
        //        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(image_buffer,0);
        size_t bytesrow1  = CVPixelBufferGetBytesPerRowOfPlane(image_buffer,1);
        //        size_t bytesrow2 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,2);
        //        UInt8 *yuv420_data = (UInt8 *)malloc(width * height *3/ 2);//buffer to store YUV with layout YYYYYYYYUUVV
        //        memset(yuv420_data, 0, width * height *3/ 2);
        
        /* convert NV21 data to YUV420*/
        
        //
        const int kYPlaneIndex = 0;
        const int kUVPlaneIndex = 1;
        size_t yPlaneBytesPerRow =
        CVPixelBufferGetBytesPerRowOfPlane(image_buffer, kYPlaneIndex);
        size_t yPlaneHeight = CVPixelBufferGetHeightOfPlane(image_buffer, kYPlaneIndex);
        size_t uvPlaneBytesPerRow =
        CVPixelBufferGetBytesPerRowOfPlane(image_buffer, kUVPlaneIndex);
        size_t uvPlaneHeight =
        CVPixelBufferGetHeightOfPlane(image_buffer, kUVPlaneIndex);
        size_t frameSize =
        yPlaneBytesPerRow * yPlaneHeight + uvPlaneBytesPerRow * uvPlaneHeight;
        int stride_y = (int)width;
        int stride_uv = ((int)width + 1) / 2;
        int memmoryLength = width*height*3/2;//stride_y * (int)height + (stride_uv + stride_uv) * (((int)height + 1) / 2);
        UInt8 *yuv420_data = (UInt8 *)malloc(memmoryLength);//buffer to store YUV with layout YYYYYYYYUUVV
        memset(yuv420_data, 0, memmoryLength);
        
        UInt8 *yBuffer = yuv420_data;
        UInt8 *uBuffer = yBuffer + stride_y * height;
        UInt8 *vBuffer = uBuffer + stride_uv * ((height + 1) / 2);
        ConvertToI420(bufferPtr, frameSize, yBuffer, stride_y, uBuffer, stride_uv, vBuffer, stride_uv, 0, 0, (int)width, (int)height, (int)width, (int)height, libyuv::kRotate0,
                      libyuv::FOURCC_NV12);
        
        size_t size = fwrite(yuv420_data, memmoryLength, 1, decoderYUVdataFile);
        NSLog(@"%ld", size);
        free(yuv420_data);
        
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
        //        NSData *data = [NSData dataWithBytes:yuv420_data length:memmoryLength];
        //        [yuv420Data addData:data];
//        YUV420Data *yuv = [[YUV420Data alloc] initWithYUV420Data:yuv420_data Width:VIDEO_WIDTH Height:VIDEO_HEIGHT];
        
        //        if (!yuv420DisplayView) {
        //            yuv420DisplayView = [[GSOpenGLESDisplayYUV420View alloc] initWithFrame:CGRectMake(0, 0, VIDEO_WIDTH, VIDEO_HEIGHT)];
        //            yuv420DisplayView.center = self.view.center;
        //            yuv420DisplayView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
        //            yuv420DisplayView.transform = CGAffineTransformRotate(yuv420DisplayView.transform, M_PI/2);
        //            [self.view addSubview:yuv420DisplayView];
        //        }
        
        /* unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(image_buffer, 0);
    }

}
    
}//internal


@interface GSVideoToolBoxDecoder ()
{
    CMVideoFormatDescriptionRef video_format_;
    VTDecompressionSessionRef decompression_session_;
}

@end

@implementation GSVideoToolBoxDecoder

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
        
        NSString *fullPath = [path stringByAppendingPathComponent:@"datah264decoder"];
        if ([manager fileExistsAtPath:fullPath]) {
            [manager removeItemAtPath:fullPath error:nil];
        }
        [manager createFileAtPath:fullPath contents:nil attributes:nil];
        
        decoderYUVdataFile = fopen([fullPath UTF8String], "wb");
    }
    return self;
}

- (int)InitDecode:(VideoCodec *)video_codec Cores:(NSInteger)number_of_cores
{
    
    return 0;
}

-(void)dealloc
{
    [self DestroyDecompressionSession];
    [self SetVideoFormat:nil];
}

-(int)Decode:(uint8_t *)input_image
InputImageLength:(size_t)length
  MissFrames:(BOOL)missing_frames
    Fragment:(/*RTPFragmentationHeader**/uint8_t *)fragmentation
        Info:(CodecSpecificInfo *)codec_specific_info
  RenderTime:(int64_t)render_time_ms
{
//    RTC_DCHECK(input_image._buffer);
    if (!input_image) {
        return -1;
    }
    
#if defined(WEBRTC_IOS)
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        // Ignore all decode requests when app isn't active. In this state, the
        // hardware decoder has been invalidated by the OS.
        // Reset video format so that we won't process frames until the next
        // keyframe.
        [self SetVideoFormat:nil];
//        return WEBRTC_VIDEO_CODEC_NO_OUTPUT;
    }
#endif
    CMVideoFormatDescriptionRef input_format = nil;
    if ([self H264AnnexBBufferHasVideoFormatDescription:input_image Size:length]) {
        input_format = [self CreateVideoFormatDescription:input_image Size:length];
        if (input_format) {
            // Check if the video format has changed, and reinitialize decoder if
            // needed.
            if (!CMFormatDescriptionEqual(input_format, video_format_)) {
                [self SetVideoFormat:input_format];
                [self ResetDecompressionSession];
            }
            CFRelease(input_format);
        }
    }
    if (!video_format_) {
        // We received a frame but we don't have format information so we can't
        // decode it.
        // This can happen after backgrounding. We need to wait for the next
        // sps/pps before we can resume so we request a keyframe by returning an
        // error.
//        LOG(LS_WARNING) << "Missing video format. Frame with sps/pps required.";
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    CMSampleBufferRef sample_buffer = nullptr;
    if (![self H264AnnexBBufferToCMSampleBuffer:input_image
                                          Size:length VideoFormat:video_format_ OutBuffer:&sample_buffer]) {
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
//    RTC_DCHECK(sample_buffer);
    VTDecodeFrameFlags decode_flags =
    kVTDecodeFrame_EnableAsynchronousDecompression;
//    std::unique_ptr<FrameDecodeParams> frame_decode_params;
//    frame_decode_params.reset(
//                              new internal::FrameDecodeParams(callback_, input_image._timeStamp));
    OSStatus status = VTDecompressionSessionDecodeFrame(
                                                        decompression_session_, sample_buffer, decode_flags,
                                                        nil/*frame_decode_params.release()*/, nil);
#if defined(WEBRTC_IOS)
    // Re-initialize the decoder if we have an invalid session while the app is
    // active and retry the decode request.
    if (status == kVTInvalidSessionErr &&
        [self ResetDecompressionSession] == 0) {
//        frame_decode_params.reset(
//                                  new internal::FrameDecodeParams(callback_, input_image._timeStamp));
        status = VTDecompressionSessionDecodeFrame(
                                                   decompression_session_, sample_buffer, decode_flags,
                                                   nil/*frame_decode_params.release()*/, nil);
    }
#endif
    CFRelease(sample_buffer);
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to decode frame with code: " << status;
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
//    return WEBRTC_VIDEO_CODEC_OK;
    return 0;
}

//    -(int RegisterDecodeCompleteCallback(DecodedImageCallback* callback) override;

-(int)Release
{
    // Need to invalidate the session so that callbacks no longer occur and it
    // is safe to null out the callback.
    [self DestroyDecompressionSession];
    [self SetVideoFormat:nil];
//    callback_ = nullptr;
//    return WEBRTC_VIDEO_CODEC_OK;
    return 0;
}

//    const char* ImplementationName() const override;


-(int) ResetDecompressionSession
{
    [self DestroyDecompressionSession ];
    
    // Need to wait for the first SPS to initialize decoder.
    if (!video_format_) {
//        return WEBRTC_VIDEO_CODEC_OK;
    }
    
    // Set keys for OpenGL and IOSurface compatibilty, which makes the encoder
    // create pixel buffers with GPU backed memory. The intent here is to pass
    // the pixel buffers directly so we avoid a texture upload later during
    // rendering. This currently is moot because we are converting back to an
    // I420 frame after decode, but eventually we will be able to plumb
    // CVPixelBuffers directly to the renderer.
    // TODO(tkchin): Maybe only set OpenGL/IOSurface keys if we know that that
    // we can pass CVPixelBuffers as native handles in decoder output.
    static size_t const attributes_size = 3;
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
    CreateCFDictionary(nullptr, nullptr, 0);
    int64_t nv12type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef pixel_format =
    CFNumberCreate(nullptr, kCFNumberLongType, &nv12type);
    CFTypeRef values[attributes_size] = {kCFBooleanTrue, io_surface_value,
        pixel_format};
    CFDictionaryRef attributes =
    CreateCFDictionary(keys, values, attributes_size);
    if (io_surface_value) {
        CFRelease(io_surface_value);
        io_surface_value = nullptr;
    }
    if (pixel_format) {
        CFRelease(pixel_format);
        pixel_format = nullptr;
    }
    __weak GSVideoToolBoxDecoder *weakSelf = self;
    VTDecompressionOutputCallbackRecord record = {
        internal::VTDecompressionOutputCallback, (__bridge void *)weakSelf,
    };
    OSStatus status =
    VTDecompressionSessionCreate(nullptr, video_format_, nullptr, attributes,
                                 &record, &decompression_session_);
    CFRelease(attributes);
    if (status != noErr) {
        [self DestroyDecompressionSession];
//        return WEBRTC_VIDEO_CODEC_ERROR;
    }
    [self ConfigureDecompressionSession];
    
//    return WEBRTC_VIDEO_CODEC_OK;
    return 0;
}

-(void) ConfigureDecompressionSession
{
//    RTC_DCHECK(decompression_session_);
#if defined(WEBRTC_IOS)
    VTSessionSetProperty(decompression_session_,
                         kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
#endif
}
-(void) DestroyDecompressionSession
{
    if (decompression_session_) {
        VTDecompressionSessionInvalidate(decompression_session_);
        CFRelease(decompression_session_);
        decompression_session_ = nullptr;
    }
}

- (void)SetVideoFormat:(CMVideoFormatDescriptionRef)video_format
{
    if (video_format_ == video_format) {
        return;
    }
    if (video_format_) {
        CFRelease(video_format_);
    }
    video_format_ = video_format;
    if (video_format_) {
        CFRetain(video_format_);
    }
}

-(BOOL)H264AnnexBBufferHasVideoFormatDescription:(uint8_t*) annexb_buffer
                                            Size:(size_t)annexb_buffer_size
{
//    RTC_DCHECK(annexb_buffer);
//    RTC_DCHECK_GT(annexb_buffer_size, 4u);
    
    // The buffer we receive via RTP has 00 00 00 01 start code artifically
    // embedded by the RTP depacketizer. Extract NALU information.
    // TODO(tkchin): handle potential case where sps and pps are delivered
    // separately.
    uint8_t first_nalu_type = annexb_buffer[4] & 0x1f;
    BOOL is_first_nalu_type_sps = first_nalu_type == 0x7;
    return is_first_nalu_type_sps;
}

-(CMVideoFormatDescriptionRef)CreateVideoFormatDescription:(uint8_t *) annexb_buffer
                                                        Size:(size_t)annexb_buffer_size
{
    if (![self H264AnnexBBufferHasVideoFormatDescription:annexb_buffer Size:annexb_buffer_size]) {
        return nil;
    }
    AnnexBBufferReader *reader = [[AnnexBBufferReader alloc] initWithData:annexb_buffer Length:annexb_buffer_size];
    CMVideoFormatDescriptionRef description = nil;
    OSStatus status = noErr;
    // Parse the SPS and PPS into a CMVideoFormatDescription.
    uint8_t* param_set_ptrs[2] = {};
    size_t param_set_sizes[2] = {};
    if (![reader ReadNalu:&param_set_ptrs[0] Length:&param_set_sizes[0]]) {
//        LOG(LS_ERROR) << "Failed to read SPS";
//        return nil;
    }
    if (![reader ReadNalu:&param_set_ptrs[1] Length:&param_set_sizes[1]]) {
//        LOG(LS_ERROR) << "Failed to read PPS";
//        return nil;
    }
    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
                                                                 kCFAllocatorDefault, 2, param_set_ptrs, param_set_sizes, 4,
                                                                 &description);
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to create video format description.";
        return nil;
    }
    return description;
}

- (BOOL)H264AnnexBBufferToCMSampleBuffer:(uint8_t*)annexb_buffer
                                    Size:(size_t)annexb_buffer_size
                                    VideoFormat:(CMVideoFormatDescriptionRef)video_format
                                    OutBuffer:(CMSampleBufferRef *)out_sample_buffer
{
//    RTC_DCHECK(annexb_buffer);
//    RTC_DCHECK(out_sample_buffer);
//    RTC_DCHECK(video_format);
    *out_sample_buffer = nullptr;
    
    AnnexBBufferReader *reader = [[AnnexBBufferReader alloc] initWithData:annexb_buffer Length:annexb_buffer_size];
    if ([self H264AnnexBBufferHasVideoFormatDescription:annexb_buffer Size:annexb_buffer_size]) {
        // Advance past the SPS and PPS.
        uint8_t* data = nullptr;
        size_t data_len = 0;
        if (![reader ReadNalu:&data Length:&data_len]) {
//            LOG(LS_ERROR) << "Failed to read SPS";
            return false;
        }
        if (![reader ReadNalu:&data Length:&data_len]) {
//            LOG(LS_ERROR) << "Failed to read PPS";
            return false;
        }
    }
    
    // Allocate memory as a block buffer.
    // TODO(tkchin): figure out how to use a pool.
    CMBlockBufferRef block_buffer = nullptr;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(
                                                         nullptr, nullptr, [reader BytesRemaining], nullptr, nullptr, 0,
                                                         [reader BytesRemaining], kCMBlockBufferAssureMemoryNowFlag,
                                                         &block_buffer);
    if (status != kCMBlockBufferNoErr) {
//        LOG(LS_ERROR) << "Failed to create block buffer.";
        return false;
    }
    
    // Make sure block buffer is contiguous.
    CMBlockBufferRef contiguous_buffer = nullptr;
    if (!CMBlockBufferIsRangeContiguous(block_buffer, 0, 0)) {
        status = CMBlockBufferCreateContiguous(
                                               nullptr, block_buffer, nullptr, nullptr, 0, 0, 0, &contiguous_buffer);
        if (status != noErr) {
//            LOG(LS_ERROR) << "Failed to flatten non-contiguous block buffer: "
//            << status;
            CFRelease(block_buffer);
            return false;
        }
    } else {
        contiguous_buffer = block_buffer;
        block_buffer = nullptr;
    }
    
    // Get a raw pointer into allocated memory.
    size_t block_buffer_size = 0;
    char* data_ptr = nullptr;
    status = CMBlockBufferGetDataPointer(contiguous_buffer, 0, nullptr,
                                         &block_buffer_size, &data_ptr);
    if (status != kCMBlockBufferNoErr) {
//        LOG(LS_ERROR) << "Failed to get block buffer data pointer.";
        CFRelease(contiguous_buffer);
        return false;
    }
//    RTC_DCHECK(block_buffer_size == reader.BytesRemaining());
    if (block_buffer_size == [reader BytesRemaining]) {
        NSLog(@"");
    }
    
    // Write Avcc NALUs into block buffer memory.
//    AvccBufferWriter writer(reinterpret_cast<uint8_t*>(data_ptr),
//                            block_buffer_size);
    AvccBufferWriter *writer = [[AvccBufferWriter alloc] initWithData:(uint8_t *)data_ptr Length:block_buffer_size];
    while ([reader BytesRemaining] > 0) {
        uint8_t* nalu_data_ptr = nullptr;
        size_t nalu_data_size = 0;
        if ([reader ReadNalu:&nalu_data_ptr Length:&nalu_data_size]) {
            [writer WriteNalu:nalu_data_ptr Size:nalu_data_size];
        }
    }
    
    // Create sample buffer.
    status = CMSampleBufferCreate(nullptr, contiguous_buffer, true, nullptr,
                                  nullptr, video_format, 1, 0, nullptr, 0,
                                  nullptr, out_sample_buffer);
    if (status != noErr) {
//        LOG(LS_ERROR) << "Failed to create sample buffer.";
        CFRelease(contiguous_buffer);
        return false;
    }
    CFRelease(contiguous_buffer);
    return true;
}

@end
