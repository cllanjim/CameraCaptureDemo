//
//  UIView+ScaleDrag.m
//  ScaleViewDemo
//
//  Created by ZhouDamon on 16/6/25.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <objc/runtime.h>
#import "UIView+ScaleDrag.h"

#define OriginViewWidth "OriginViewWidth"
#define OriginViewHeight "OriginViewHeight"

static CGFloat totalScale = 1.0f;

@implementation UIView (ScaleDrag)

- (void)addUIPinch
{
    UIPinchGestureRecognizer *gesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(handlePinchGestureRecognizer:)];
    [self addGestureRecognizer:gesture];
}

- (void)addUIPan
{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    [self addGestureRecognizer:pan];
}

- (void)changeViewSize:(CGSize)size
{
    objc_setAssociatedObject(self, OriginViewWidth, [NSNumber numberWithFloat:size.width], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, OriginViewHeight, [NSNumber numberWithFloat:size.height], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    totalScale = 1.0f;
}

#pragma mark -- private 
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint point = [panGestureRecognizer translationInView:panGestureRecognizer.view];//移动的xy位移
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGPoint screenCenter = CGPointMake(screenSize.width/2, screenSize.height/2);
    
    if (self.frame.size.width < [UIScreen mainScreen].bounds.size.width) {
        point.x = 0;
    }
    
    if (self.frame.size.height < [UIScreen mainScreen].bounds.size.height) {
        point.y = 0;
    }
    
    BOOL xb = NO;
    BOOL yb = NO;
    CGPoint scaleViewPoint = self.frame.origin;
    if (scaleViewPoint.x >= 0 && point.x > 0) {
        xb = YES;
        //        return;
    }
    
    if (scaleViewPoint.y >= 0/*(screenSize.height-436)/2*/ && point.y > 0) {
        yb = YES;
        //        return;
    }
    
    if (scaleViewPoint.x < -fabs(self.frame.size.width - screenSize.width) && point.x < 0) {
        xb = YES;
        //        return;
    }
    
    if (scaleViewPoint.y < -fabs(self.frame.size.height - screenSize.height) && point.y < 0) {
        yb = YES;
        //        return;
    }
    
    if (xb && yb) {
        
        return;
    }
    
    CGSize scaleViewSize = self.frame.size;
    CGPoint viewCenter = screenCenter;
    CGPoint scaleViewCenter = self.center;
    CGFloat space = fabs(viewCenter.x - scaleViewCenter.x);
    CGFloat spaceNeed;
    if (point.x < 0) {
        if (scaleViewCenter.x < viewCenter.x) {
            spaceNeed = scaleViewSize.width/2 - screenSize.width/2 - space;
        }
        else {
            spaceNeed = scaleViewSize.width/2 - (screenSize.width/2 - space);
        }
        if (fabs(point.x) > fabs(spaceNeed)) {
            point.x = -fabs(spaceNeed);
        }
    }
    else {
        if (scaleViewCenter.x > viewCenter.x) {
            spaceNeed = scaleViewSize.width/2 - screenSize.width/2 - space;
        }
        else {
            spaceNeed = scaleViewSize.width/2 - (screenSize.width/2 - space);
        }
        if (fabs(point.x) > fabs(spaceNeed)) {
            point.x = fabs(spaceNeed);
            
        }
    }
    
    CGFloat spaceY = fabs(viewCenter.y - scaleViewCenter.y);
    CGFloat spaceNeedY;
    if (point.y < 0) {
        if (scaleViewCenter.y < viewCenter.y) {
            spaceNeedY = scaleViewSize.height/2 - screenSize.height/2 - spaceY;
        }
        else {
            spaceNeedY = scaleViewSize.height/2 - (screenSize.height/2 - spaceY);
        }
        if (fabs(point.y) > fabs(spaceNeedY)) {
            point.y = -fabs(spaceNeedY);
        }
    }
    else {
        if (scaleViewCenter.y < viewCenter.y) {
            spaceNeedY = scaleViewSize.height/2 - (screenSize.height/2 - spaceY);
        }
        else {
            spaceNeedY = scaleViewSize.height/2 - screenSize.height/2 - spaceY;
        }
        if (fabs(point.y) > fabs(spaceNeedY)) {
            point.y = fabs(spaceNeedY);
        }
    }
    
    CGFloat centerX = self.center.x + ((YES == xb)?0:point.x);
    CGFloat centerY = self.center.y + ((YES == yb)?0:point.y);
    
    
    self.center = CGPointMake(centerX, centerY);
    [panGestureRecognizer setTranslation:CGPointZero inView:panGestureRecognizer.view];
    //    [panGestureRecognizer velocityInView:panGestureRecognizer.view];
}
- (void)handlePinchGestureRecognizer:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    //    CGPoint point = [pinchGestureRecognizer translationInView:panGestureRecognizer.view];//移动的xy位移
    //    movedView.center = CGPointMake(movedView.center.x + point.x, movedView.center.y + point.y);
    //    [panGestureRecognizer setTranslation:CGPointZero inView:panGestureRecognizer.view];
    NSLog(@"scale:%f velocity:%f\n", pinchGestureRecognizer.scale, pinchGestureRecognizer.velocity);
    //    scaleView.contentScaleFactor = pinchGestureRecognizer.scale;
    //    [UIScreen mainScreen].scale = pinchGestureRecognizer.scale;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGPoint screenCenter = CGPointMake(screenSize.width/2, screenSize.height/2);
    CGFloat newWidth = self.frame.size.width * pinchGestureRecognizer.scale;
    CGFloat newHeight = self.frame.size.height * pinchGestureRecognizer.scale;
    
    NSNumber *numberWidth = nil;
    NSNumber *numberHeight = nil;
    numberWidth = (NSNumber *)objc_getAssociatedObject(self, OriginViewWidth);
    numberHeight = (NSNumber *)objc_getAssociatedObject(self, OriginViewHeight);
    if (newWidth < numberWidth.floatValue || newHeight < numberHeight.floatValue) {
        if (pinchGestureRecognizer.scale < 1.0) {
            
            //            scaleView.frame = CGRectMake(0, ([UIScreen mainScreen].bounds.size.height-436)/2, 320, 436);
            self.transform = CGAffineTransformIdentity;
            self.center = screenCenter;
            return;
        }
    }
    
//    BOOL xc = NO;
//    BOOL yc = NO;
//    if (newWidth/2 <= fabs(fabs(self.center.x))) {
//        xc = YES;
//    }
//    if (newHeight/2 <= fabs(self.center.y)) {
//        yc = YES;
//    }
//    if (xc && yc) {
//        self.center = screenCenter;
//    }
//    else if (NO == xc && yc) {
//        CGPoint point = CGPointMake(self.center.x, screenCenter.y);
//        self.center = point;
//    }
//    else if (xc && NO == yc) {
//        CGPoint point = CGPointMake(screenCenter.x, self.center.y);
//        self.center = point;
//    }
    
    CGFloat scale = pinchGestureRecognizer.scale;
    if (totalScale * scale > 2) {
        totalScale = 2.0;
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, totalScale, totalScale);
        return;
    }
    
    totalScale *= scale;
    
    
//    CGPoint preCenter = self.center;
    self.transform = CGAffineTransformScale(self.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
    
//    CGPoint newCenter = CGPointApplyAffineTransform(screenCenter, self.transform);
//    self.center = newCenter;
    
    BOOL xc = NO;
    BOOL yc = NO;
    CGFloat maxX = CGRectGetMaxX(self.frame);
    CGFloat minX = CGRectGetMinX(self.frame);
    CGFloat maxY = CGRectGetMaxY(self.frame);
    CGFloat minY = CGRectGetMinY(self.frame);
    if (pinchGestureRecognizer.scale < 1.0) {
        if (minX > 0 || maxX < screenSize.width) {
            xc = YES;
        }
        if (minY > 0 || maxY < screenSize.height) {
            yc = YES;
        }
        if (xc && yc) {
            self.center = screenCenter;
        }
        else if (NO == xc && yc) {
            CGPoint point = CGPointMake(self.center.x, screenCenter.y);
            self.center = point;
        }
        else if (xc && NO == yc) {
            CGPoint point = CGPointMake(screenCenter.x, self.center.y);
            self.center = point;
        }
    }
}

@end
