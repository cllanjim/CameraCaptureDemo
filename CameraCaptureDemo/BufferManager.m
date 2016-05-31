//
//  BufferManager.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/24.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "BufferManager.h"
#import "FileOperator.h"

@interface BufferManager()
{
    NSLock *bufferLock;
    NSMutableArray *dataArray;
}

@end

@implementation BufferManager

- (id)init
{
    self = [super init];
    if (self) {
        dataArray = [[NSMutableArray alloc] init];
        bufferLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)addData:(NSData *)data
{
//    [bufferLock lock];
    [dataArray addObject:data];
    
//    if ([dataArray count] == 50) {
//        FileOperator *file = [[FileOperator alloc] init];
//        [file createFileWithName:@"datayun420"];
//        [file fileWriterArray:dataArray];
//    }
    
//    [bufferLock unlock];
}
- (NSData *)getData
{
//    [bufferLock lock];
    NSData *data = nil;
    if (0 < [dataArray count]) {
        data = [dataArray objectAtIndex:0];
        [dataArray removeObject:data];
    }
//    [bufferLock unlock];
    
    return data;
}

@end
