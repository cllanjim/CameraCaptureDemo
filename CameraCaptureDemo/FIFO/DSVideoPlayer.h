//
//  VideoPlayer.h
//  CapturePreview
//
//  Created by DEATH on 6/20/14.
//  Copyright (c) 2014 TB. All rights reserved.
//
#include "Utility.h"

#import <UIKit/UIKit.h>
#import "H264Decoder.h"

typedef struct {
	tb_queue_t *frame_queue;
	//播放的当前帧，刷新前把帧数据从frame_queue复制到该处
	uint8_t *frame_buffer;
	//当前帧的长度
	size_t frame_length;
	//frame_buffer的实际长度
	size_t buffer_length;
} tb_vp_frames_t;

typedef struct{
	unsigned long length;
	unsigned int width;
	unsigned int height;
	BOOL isKeyframe;
	unsigned long index;
	unsigned long uid;
}tb_frame_attribute;

@interface DSPlayerView : UIView
{
	CGContextRef _cgContext;
}

@end

class DSVideoPlayer : public CTbThread
{
public:
	
	DSVideoPlayer();
	~DSVideoPlayer();
	
public:
	
	int Create(int nPlayerType, int nDecodeConfig);
	int Destroy();
	
	int Run();
	int Stop();
	int Pause();
	
	void ReceiveData(void *pData, tb_frame_attribute* att);
	
	CALayer * playoutLayer();
	DSPlayerView * playView();
	
public:
	virtual bool OnThreadStart();
	virtual bool OnSingleStep();
	virtual bool OnThreadStop();
	
	
	typedef enum _Status
	{
		STATUS_STOPPED,
		STATUS_PAUSED,
		STATUS_RUNNING,
	}Status;
	
private:
	Status _status;
	IFifo *_fifo;
	unsigned char * _memBuffer;
	DSPlayerView *_playerView;
	H264Decoder * _decoder;
	tb_vp_frames_t _rgba;
};


