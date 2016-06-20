//
//  GSVideoToolBoxEncoder.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/6/6.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>

//#include <vector>

//#import "commonType.h"
#import "YUV420Data.h"
#import "CommonVideoType.h"

//// Video codec
//enum { kConfigParameterSize = 128};
//enum { kPayloadNameSize = 32};
//enum { kMaxSimulcastStreams = 4};
//enum { kMaxSpatialLayers = 5 };
//enum { kMaxTemporalStreams = 4};
//
//// Video codec types
//enum VideoCodecType {
//    kVideoCodecVP8,
//    kVideoCodecVP9,
//    kVideoCodecH264,
//    kVideoCodecI420,
//    kVideoCodecRED,
//    kVideoCodecULPFEC,
//    kVideoCodecGeneric,
//    kVideoCodecUnknown
//};
//
//enum VideoCodecProfile
//{
//    kProfileBase = 0x00,
//    kProfileMain = 0x01
//};
//
//// H264 specific.
//struct VideoCodecH264 {
//    VideoCodecProfile profile;
//    bool           frameDroppingOn;
//    int            keyFrameInterval;
//    // These are NULL/0 if not externally negotiated.
//    const uint8_t* spsData;
//    size_t         spsLen;
//    const uint8_t* ppsData;
//    size_t         ppsLen;
//};
//
//union VideoCodecUnion {
////    VideoCodecVP8       VP8;
////    VideoCodecVP9       VP9;
//    VideoCodecH264      H264;
//};
//
//// Simulcast is when the same stream is encoded multiple times with different
//// settings such as resolution.
//struct SimulcastStream {
//    unsigned short      width;
//    unsigned short      height;
//    unsigned char       numberOfTemporalLayers;
//    unsigned int        maxBitrate;  // kilobits/sec.
//    unsigned int        targetBitrate;  // kilobits/sec.
//    unsigned int        minBitrate;  // kilobits/sec.
//    unsigned int        qpMax; // minimum quality
//};
////
//struct SpatialLayer {
//    int scaling_factor_num;
//    int scaling_factor_den;
//    int target_bitrate_bps;
//    // TODO(ivica): Add max_quantizer and min_quantizer?
//};
//
//enum VideoCodecMode {
//    kRealtimeVideo,
//    kScreensharing
//};


//typedef NS_ENUM(NSUInteger, VideoCodecType)
//{
//    VideoCodecType_H264 = 0
//};
//// Common video codec properties
//@interface VideoCodec : NSObject
//
//@property (nonatomic) VideoCodecType      codecType;
//@property (nonatomic)    NSString *                plName;//kPayloadNameSize
//@property (nonatomic)    unsigned char       plType;
//    
//@property (nonatomic)    NSUInteger      width;
//@property (nonatomic)    NSUInteger      height;
//    
//@property (nonatomic)    NSUInteger        startBitrate;  // kilobits/sec.
//@property (nonatomic)    NSUInteger        maxBitrate;  // kilobits/sec.
//@property (nonatomic)    NSUInteger        minBitrate;  // kilobits/sec.
//@property (nonatomic)    NSUInteger        targetBitrate;  // kilobits/sec.
//    
//@property (nonatomic)    unsigned char       maxFramerate;
//    
//    //    VideoCodecUnion     codecSpecific;
//    
//@property (nonatomic)    NSUInteger        qpMax;
//@property (nonatomic)    unsigned char       numberOfSimulcastStreams;
////    struct SimulcastStream     simulcastStream[4];//kMaxSimulcastStreams
////    struct SpatialLayer spatialLayers[5];//kMaxSpatialLayers
//    
//    //    VideoCodecMode      mode;
//    
//    //    bool operator==(const VideoCodec& other) const = delete;
//    //    bool operator!=(const VideoCodec& other) const = delete;
//@end
//
//@class GSVideoToolBoxEncoder;
//@interface FrameEncodeParams : NSObject
//@property (nonatomic, strong) GSVideoToolBoxEncoder *encoder;
//
//@end
//
//@interface VideoFrame : NSObject
//
//@property (nonatomic) size_t width;
//@property (nonatomic) size_t height;
//
//@end
//
////@protocol EncodedImageCallback <NSObject>
////
////int32_t Encoded(const EncodedImage& encoded_image,
////                const CodecSpecificInfo* codec_specific_info,
////                const RTPFragmentationHeader* fragmentation) = 0;
////
////@end
//
//@interface CodecSpecificInfo : NSObject
//
//@end

@protocol EncodedImageCallback <NSObject>

- (void)Encoded:(uint8_t *)encoded_image Info:(uint8_t *)codec_specific_info Header:(uint8_t *)fragmentation;

@end

//typedef NS_ENUM(NSUInteger, FrameType)
//{
//    kEmptyFrame = 0,
//    kAudioFrameSpeech = 1,
//    kAudioFrameCN = 2,
//    kVideoFrameKey = 3,
//    kVideoFrameDelta = 4
//};
//
//// enum for clockwise rotation.
//typedef NS_ENUM(NSUInteger, VideoRotation)
//{
//    kVideoRotation_0 = 0,
//    kVideoRotation_90 = 90,
//    kVideoRotation_180 = 180,
//    kVideoRotation_270 = 270
//};

@interface GSVideoToolBoxEncoder : NSObject

@property (nonatomic, assign)id<EncodedImageCallback>delegate;

-(int)InitEncode:(VideoCodec *)codec_settings Cores:(int)number_of_cores Payload:(size_t)max_payload_size;

-(int)Encode:(YUV420Data *)input_image Info:(CodecSpecificInfo *)codec_specific_info Type:(NSUInteger *)frame_types;

-(int)EncodeCVI:(CVImageBufferRef)input_image Info:(CodecSpecificInfo *)codec_specific_info Type:(NSUInteger *)frame_types;

//int RegisterEncodeCompleteCallback(EncodedImageCallback* callback) override;

- (void)OnDroppedFrame;
-(int)SetChannelParameters:(uint32_t)packet_loss Rtt:(int64_t)rtt;

-(int)SetRates:(uint32_t)new_bitrate_kbit Rate:(uint32_t)frame_rate;

-(int)Release;

//const char* ImplementationName() const override;

- (void)OnEncodedFrame:(OSStatus)status Flag:(VTEncodeInfoFlags)info_flags Buffer:(CMSampleBufferRef)sample_buffer Info:(CodecSpecificInfo *)codec_specific_info Width:(int32_t)width Height:(int32_t)height RenderTime:(int64_t)render_time_ms                      TimeStamp:(uint32_t)timestamp Rotation:(VideoRotation)rotation;

- (void)stopFile;

@end
