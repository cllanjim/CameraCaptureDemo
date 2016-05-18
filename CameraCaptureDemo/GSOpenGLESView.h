//
//  GSOpenGLESView.h
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/18.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface GSOpenGLESView : UIView
{
    CAEAGLLayer *_glLayer;
    EAGLContext *_context;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
}

@end
