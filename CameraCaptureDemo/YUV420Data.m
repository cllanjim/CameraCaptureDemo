//
//  YUV420Data.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/28.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "YUV420Data.h"
#import "FileOperator.h"

@interface YUV420Data ()
{
    UInt8 *yuv;
}

@end

@implementation YUV420Data

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (id)initWithYUV420Data:(UInt8 *)data Width:(NSUInteger)width Height:(NSUInteger)height
{
    self = [super init];
    if (self) {
        yuv = malloc(width * height * 3 / 2);
        if (!yuv) {
            NSLog(@"error");
        }
        memcpy(yuv, data, (width * height * 3 / 2));
        
        self.width = width;
        self.height = height;
        
        NSUInteger stride_y = width;
        NSUInteger stride_uv = (width + 1) / 2;
        
//        const UInt8* buffer_y = yuv;
//        const UInt8* buffer_u = buffer_y + stride_y * height;
//        const UInt8* buffer_v = buffer_u + stride_uv * ((height + 1) / 2);
        
        self.chromaWidth = (width + 1)/2;
        self.chromaHeight = (height +1)/2;
        
        self.yPlane = yuv;
        self.uPlane = self.yPlane + stride_y * height;
        self.vPlane = self.uPlane + stride_uv * ((height + 1) / 2);
        
        self.yPitch = stride_y;
        self.uPitch = self.vPitch = stride_uv;
        
//        FileOperator *file = [[FileOperator alloc] init];
//        [file createFileWithName:@"datayun420oneFrame"];
//        [file fileWriterData:yuv];
    }
    
    return self;
}

- (void)dealloc{
    
    if (yuv) {
        free(yuv);
        yuv = nil;
    }
}

@end
