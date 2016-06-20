//
//  Header.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/6/20.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#ifndef Header_h
#define Header_h

//// Simulcast is when the same stream is encoded multiple times with different
//// settings such as resolution.
struct SimulcastStream {
    unsigned short      width;
    unsigned short      height;
    unsigned char       numberOfTemporalLayers;
    unsigned int        maxBitrate;  // kilobits/sec.
    unsigned int        targetBitrate;  // kilobits/sec.
    unsigned int        minBitrate;  // kilobits/sec.
    unsigned int        qpMax; // minimum quality
};
//
struct SpatialLayer {
    int scaling_factor_num;
    int scaling_factor_den;
    int target_bitrate_bps;
    // TODO(ivica): Add max_quantizer and min_quantizer?
};


typedef NS_ENUM(NSUInteger, VideoCodecType)
{
    VideoCodecType_H264 = 0
};
// Common video codec properties
@interface VideoCodec : NSObject

@property (nonatomic) VideoCodecType      codecType;
@property (nonatomic)    NSString *                plName;//kPayloadNameSize
@property (nonatomic)    unsigned char       plType;

@property (nonatomic)    NSUInteger      width;
@property (nonatomic)    NSUInteger      height;

@property (nonatomic)    NSUInteger        startBitrate;  // kilobits/sec.
@property (nonatomic)    NSUInteger        maxBitrate;  // kilobits/sec.
@property (nonatomic)    NSUInteger        minBitrate;  // kilobits/sec.
@property (nonatomic)    NSUInteger        targetBitrate;  // kilobits/sec.

@property (nonatomic)    unsigned char       maxFramerate;

//    VideoCodecUnion     codecSpecific;

@property (nonatomic)    NSUInteger        qpMax;
@property (nonatomic)    unsigned char       numberOfSimulcastStreams;
//    struct SimulcastStream     simulcastStream[4];//kMaxSimulcastStreams
//    struct SpatialLayer spatialLayers[5];//kMaxSpatialLayers

//    VideoCodecMode      mode;

//    bool operator==(const VideoCodec& other) const = delete;
//    bool operator!=(const VideoCodec& other) const = delete;
@end

@class GSVideoToolBoxEncoder;
@interface FrameEncodeParams : NSObject
@property (nonatomic, strong) GSVideoToolBoxEncoder *encoder;

@end

@interface VideoFrame : NSObject

@property (nonatomic) size_t width;
@property (nonatomic) size_t height;

@end

@interface CodecSpecificInfo : NSObject

@end

@implementation VideoCodec

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end

@implementation FrameEncodeParams

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end

typedef NS_ENUM(NSUInteger, FrameType)
{
    kEmptyFrame = 0,
    kAudioFrameSpeech = 1,
    kAudioFrameCN = 2,
    kVideoFrameKey = 3,
    kVideoFrameDelta = 4
};

// enum for clockwise rotation.
typedef NS_ENUM(NSUInteger, VideoRotation)
{
    kVideoRotation_0 = 0,
    kVideoRotation_90 = 90,
    kVideoRotation_180 = 180,
    kVideoRotation_270 = 270
};

#endif /* Header_h */
