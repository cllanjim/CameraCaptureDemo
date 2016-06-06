//
//  YUV420Data.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/28.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUV420Data : NSObject

@property(nonatomic) NSUInteger width;
@property(nonatomic) NSUInteger height;
@property(nonatomic) NSUInteger chromaWidth;
@property(nonatomic) NSUInteger chromaHeight;
@property(nonatomic) NSUInteger chromaSize;
// These can return NULL if the object is not backed by a buffer.
@property(nonatomic) const uint8_t* yPlane;
@property(nonatomic) const uint8_t* uPlane;
@property(nonatomic) const uint8_t* vPlane;
@property(nonatomic) NSInteger yPitch;
@property(nonatomic) NSInteger uPitch;
@property(nonatomic) NSInteger vPitch;

@property(nonatomic)int64_t render_time_ms_;

- (id)initWithYUV420Data:(UInt8 *)data Width:(NSUInteger)width Height:(NSUInteger)height;

@end
