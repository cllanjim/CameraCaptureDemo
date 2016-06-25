//
//  UIView+ScaleDrag.h
//  ScaleViewDemo
//
//  Created by ZhouDamon on 16/6/25.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ScaleDrag)

- (void)addUIPinch;
- (void)addUIPan;
- (void)changeViewSize:(CGSize)size;

@end
