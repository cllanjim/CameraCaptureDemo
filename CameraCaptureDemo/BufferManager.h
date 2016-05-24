//
//  BufferManager.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/24.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BufferManager : NSObject

- (void)addData:(NSData *)data;
- (NSData *)getData;

@end
