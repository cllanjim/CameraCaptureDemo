//
//  GSVideoToolBoxDecoder.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/6/20.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <VideoToolbox/VideoToolbox.h>
#import "CommonVideoType.h"

@protocol DecodedImageCallback <NSObject>

//(int8_t *data, int width, int height, int stride_y, int stride_u, int stride_v)
- (void)Decoded:(uint8_t *)decoded_image Data:(uint32_t *)yuvdata Width:(NSInteger)width Height:(NSInteger)height StrideY:(NSInteger)strideY StrideU:(NSInteger)strideU StrideV:(NSInteger)strideV;

@end

@interface GSVideoToolBoxDecoder : NSObject
//
//    H264VideoToolboxDecoder();
//    
//    ~H264VideoToolboxDecoder() override;

- (int)InitDecode:(VideoCodec *)video_codec Cores:(NSInteger)number_of_cores;
    
-(int)Decode:(uint8_t *)input_image
            InputImageLength:(size_t)length
            MissFrames:(BOOL)missing_frames
            Fragment:(/*RTPFragmentationHeader**/uint8_t *)fragmentation
            Info:(CodecSpecificInfo *)codec_specific_info
            RenderTime:(int64_t)render_time_ms;
    
//    -(int RegisterDecodeCompleteCallback(DecodedImageCallback* callback) override;

    -(int)Release;
    
//    const char* ImplementationName() const override;


    -(int) ResetDecompressionSession;
    -(void) ConfigureDecompressionSession;
    -(void) DestroyDecompressionSession;
-(void) SetVideoFormat:(CMVideoFormatDescriptionRef)video_format;
    
//    DecodedImageCallback* callback_;

@property (nonatomic, weak)id<DecodedImageCallback>decoderDelegate;

@end
