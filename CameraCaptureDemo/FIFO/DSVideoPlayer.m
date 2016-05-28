//
//  VideoPlayer.m
//  CapturePreview
//
//  Created by DEATH on 6/20/14.
//  Copyright (c) 2014 TB. All rights reserved.
//

#import "DSVideoPlayer.h"

@implementation DSPlayerView

- (id) init {
	if (self = [super init]) {
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeScaleAspectFit;
	}
	return self;
}

- (void) setCgContext:(CGContextRef)context {
	if (_cgContext) {
		CGContextRelease(_cgContext);
		_cgContext = NULL;
	}
	if (context) {
		_cgContext = CGContextRetain(context);
	}
}

- (CGContextRef) cgContext
{
	return _cgContext;
}

- (void) update
{
	TBIOSAssert(_cgContext, return);
	
	CGImageRef image = CGBitmapContextCreateImage(_cgContext);
	self.layer.contents = (id)image;
	[CATransaction flush];
	CGImageRelease(image);
}

- (void) dealloc {
	self.cgContext = NULL;
	[super dealloc];
}

@end

static const int SRC_BUF_LEN = 500000;
static const int MEM_BUF_LEN = 1024 * 1024;

DSVideoPlayer::DSVideoPlayer()
: _status(STATUS_STOPPED)
, _fifo(0)
, _memBuffer(0)
, _playerView(0)
, _decoder(0)
{
	_memBuffer = new unsigned char [MEM_BUF_LEN];
	if (!_memBuffer)
	{
		LOGE("CTbVideoPlayer::CTbVideoPlayer() _memBuffer new error.");
	}
	
	_fifo = new CDynamicFifo();
	if(0 == _fifo)
	{
		LOGE("CTbVideoPlayer::CTbVideoPlayer() _fifo new error.");
	}
	
	memset(&_rgba, 0, sizeof(tb_vp_frames_t));
}

DSVideoPlayer::~DSVideoPlayer()
{
	CFuncTrace("CTbVideoPlayer::~CTbVideoPlayer()");
	
	SAFE_ARRAYDELETE(_memBuffer);
	SAFE_DELETE(_fifo);
	
	if(_decoder)
	{
		[_decoder release];
		_decoder = nil;
	}
	if(_playerView)
	{
		[_playerView release];
		_playerView = nil;
	}
}

int DSVideoPlayer::Create(int nPlayerType, int nDecodeConfig)
{
	CFuncTrace("CTbVideoPlayer::Create");
	
	_decoder = [[H264Decoder alloc] init];
	_playerView = [DSPlayerView new];
	
	return com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError;
}

int DSVideoPlayer::Destroy()
{
	memset(&_rgba, 0, sizeof(tb_vp_frames_t));
	
	if(_decoder)
	{
		[_decoder release];
		_decoder = nil;
	}
	if(_playerView)
	{
		[_playerView release];
		_playerView = nil;
	}
	
	return com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError;
}

int DSVideoPlayer::Run()
{
	CFuncTrace("CTbVideoPlayer::Run");
	
	if(STATUS_STOPPED == _status)
	{
		int nRet = com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError;
		
		do
		{
			LOGD("CTbVideoPlayer::Run()");
			Create(0, 0);
			if(nRet != com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError)
			{
				break;
			}
			
			_fifo->Start();
			
			if(!CTbThread::Start())
			{
				nRet = com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_ThreadCreateFailed;
				break;
			}
			
			//			nRet = m_pRender->Run();
			if(nRet != com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError)
			{
				nRet = com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_ThreadCreateFailed;
				break;
			}
			
			_status = STATUS_RUNNING;
		}while(false);
		
		if(nRet != com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError)
		{
			Destroy();
			return nRet;
		}
	}
	else if(STATUS_PAUSED == _status)
	{
		_fifo->Start();
		
		//		m_pRender->Run();
		
		_status = STATUS_RUNNING;
	}
	
	return com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError;
}

int DSVideoPlayer::Stop()
{
	CFuncTrace("CTbVideoPlayer::Stop");
	
	if(STATUS_STOPPED != _status)
	{
		_fifo->Abort();
		_fifo->Reset();
		
		CTbThread::Stop();
		
		_status = STATUS_STOPPED;
		
		Destroy();
	}
	
	return com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError;
}

int DSVideoPlayer::Pause()
{
	CFuncTrace("CTbVideoPlayer::Pause");
	
	if(STATUS_STOPPED == _status)
		return com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_WrongState;
	
	if(STATUS_RUNNING == _status)
	{
		_fifo->Abort();
		_fifo->Reset();
		
		_status = STATUS_PAUSED;
	}
	
	return com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError;
}

void DSVideoPlayer::ReceiveData(void *pData, tb_frame_attribute* att)
{
	//CFuncTrace("CTbVideoPlayer::ReceiveData");
	
	if(STATUS_RUNNING != _status)
		return;
	
	if(TRUE != att->isKeyframe && 15  < _fifo->GetNodeNum())
	{
		TBiOSLog(@"this frame is dropped;\n");
		return;
	}
	
	_fifo->Write((unsigned char *)pData, att->length, (tb_frame_attribute*)att, sizeof(tb_frame_attribute));
	
}

CALayer * DSVideoPlayer::playoutLayer()
{
	if(_playerView)
	{
		return _playerView.layer;
	}
	return nil;
}

DSPlayerView * DSVideoPlayer::playView()
{
	return _playerView;
}

bool DSVideoPlayer::OnThreadStart()
{
	CFuncTrace("CTbVideoPlayer::OnThreadStart");
	
	return true;
}

bool DSVideoPlayer::OnSingleStep()
{
	if(STATUS_RUNNING != _status)
	{
		usleep(2000);
		return true;
	}
	
	unsigned long nReadLen = 0;
	unsigned long nAddtionalReadLen = 0;
	static tb_frame_attribute attribute = {0};
	
	if(!_fifo->Read(_memBuffer, MEM_BUF_LEN, nReadLen, &attribute, sizeof(tb_frame_attribute), nAddtionalReadLen))
	{
		usleep(2000);
		return false;
	}
	
	if(_memBuffer)
	{
		CGSize size = CGSizeZero;
		CGContextRef context = _playerView.cgContext;
		if (context) {
			size.width = CGBitmapContextGetWidth(context);
			size.height = CGBitmapContextGetHeight(context);
		}
		
		if (size.width != attribute.width || size.height != attribute.height) {
			size_t l = RGBA_BPP * attribute.width * attribute.height;
			if (l > _rgba.buffer_length) {
				if (_rgba.frame_buffer) {
					free(_rgba.frame_buffer);
					_rgba.frame_buffer = NULL;
				}
				_rgba.frame_buffer = (uint8_t *)malloc(l);
				TBIOSAssert(_rgba.frame_buffer, return false);
				_rgba.buffer_length = l;
			}
			_rgba.frame_length = l;
			
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(
								     _rgba.frame_buffer,
								     attribute.width,
								     attribute.height,
								     8,
								     attribute.width * RGBA_BPP,
								     colorSpace,
								     kCGImageAlphaNoneSkipLast
								     );
			_playerView.cgContext = context;
			
			CGColorSpaceRelease(colorSpace);
			CGContextRelease(context);
		}
		
		static tb_frame decodeframe = {0};
		decodeframe.data = _memBuffer;
		decodeframe.length = attribute.length;
		decodeframe.size.width = attribute.width;
		decodeframe.size.height = attribute.height;
		decodeframe.isKeyframe = attribute.isKeyframe;
		decodeframe.index = attribute.index;
		decodeframe.uid = attribute.uid;
		
		uint8_t *rgba = [_decoder decodeFrame:&decodeframe];
		if (!rgba) {
			return false;
		}
		memcpy(_rgba.frame_buffer, rgba, _rgba.frame_length);
		
		[_playerView update];
	}
	
	//decode
	int nOutlen = 0;
	int nWidth = 0;
	int nHeight = 0;
	bool bRet = false;
	unsigned char * pDecodeOut = 0;
#ifdef LOGDECODE
	long long nTime1 = GetTimeMs();
#endif
	if(_memBuffer)
	{
//		if(!m_pDecoder->Decode(m_pMemBuffer, nReadLen, pDecodeOut, nOutlen, nWidth, nHeight))
//		{
//			LOGE("Decode error nReadLen = %d, nOutlen = %d, nWidth = %d, nHeight = %d", nReadLen, nOutlen, nWidth, nHeight);
//			return false;
//		}
	}
#ifdef LOGDECODE
	long long nTime2 = GetTimeMs();
	
	LOGD("decoder time = %lld", nTime2 - nTime1);
#endif
	
	//Render Thread
	//	m_pRender->ReceiveData(pDecodeOut, nOutlen, nWidth, nHeight);
	
	return true;
}

bool DSVideoPlayer::OnThreadStop()
{
	CFuncTrace("CTbVideoPlayer::OnThreadStop");
	
	return true;
}
