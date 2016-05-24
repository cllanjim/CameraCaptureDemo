//
//  FileOperator.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/24.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "FileOperator.h"
@interface FileOperator()
{
    
}

@end

@implementation FileOperator

-(void)createFileWithName:(NSString *)name
{
    NSString *path = [[self pathForDocuments] stringByAppendingPathComponent:@"yuv420"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (NO == [manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *fullPath = [path stringByAppendingPathComponent:name];
    [manager createFileAtPath:fullPath contents:nil attributes:nil];
}

-(BOOL)fileWriter:(UInt8 *)data
{
    
    return YES;
}
-(UInt8 *)fileReader
{
    
    return nil;
}

#pragma mark -- private func
- (NSString *)pathForDocuments
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

@end
