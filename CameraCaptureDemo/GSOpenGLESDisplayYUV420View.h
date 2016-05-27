//
//  GSOpenGLESDisplayYUV420View.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/27.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTCI420Frame;
@interface GSOpenGLESDisplayYUV420View : UIView

// The last successfully drawn frame. Used to avoid drawing frames unnecessarily
// hence saving battery life by reducing load.
@property(nonatomic, readonly) RTCI420Frame* lastDrawnFrame;

@end
