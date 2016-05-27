//
//  GSOpenGLESView.m
//  CameraCaptureDemo
//
//  Created by ZhouDamon on 16/5/18.
//  Copyright © 2016年 ZhouDamon. All rights reserved.
//

#import "GSOpenGLESView.h"

@implementation GSOpenGLESView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        [self setupLayer];
//        [self setupContext];
//        [self destoryRenderAndFrameBuffer];
//        [self setupRenderBuffer];
//        [self setupFrameBuffer];
//        [self render];
    }
    return self;
}

- (void)layoutSubviews
{
    [self setupLayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self render];
}

+ (Class)layerClass
{
    //只有CAEAGLLayer类型才支持在其上描绘OpenGL内容
    return [CAEAGLLayer class];
}

- (void)setupLayer
{
    _glLayer = (CAEAGLLayer *)self.layer;
    //CALayer默认是透明的，必须降
    _glLayer.opaque = YES;
    //
    _glLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                   kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"error");
        return;
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"error");
        return;
    }
}

- (void)setupRenderBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindBuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
}

- (void)setupFrameBuffer
{
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
}

- (void)render
{
    glClearColor(0.5, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}


@end
