//
//  FileOperator.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/24.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileOperator : NSObject

-(void)createFileWithName:(NSString *)name;
-(BOOL)fileWriter:(UInt8 *)data;
-(UInt8 *)fileReader;

@end
