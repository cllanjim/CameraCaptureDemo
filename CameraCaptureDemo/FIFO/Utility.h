#pragma once


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include <android/log.h>
#include <pthread.h>
#include <unistd.h>
#include <list>
//#include <android/native_window_jni.h>
//#include <GLES/gl.h>
//#include <EGL/egl.h>

//#include "decoder/IDecoder.h"
//#include "decoder/IImageConverter.h"
#include "Fifo.h"
#include "TbThread.h"
//#include "DecoderWrapper.h"
//#include "Render.h"
//#define DEBUG(format, ...) printf (format, ##__VA_ARGS__)
#define LOGV(format, ...) printf(format, ##__VA_ARGS__)// __android_log_print(ANDROID_LOG_VERBOSE, "TbVideoPlayer", __VA_ARGS__)
#define LOGD(format, ...) printf(format, ##__VA_ARGS__)//__android_log_print(ANDROID_LOG_DEBUG  , "TbVideoPlayer", __VA_ARGS__)
#define LOGI(format, ...) printf(format, ##__VA_ARGS__)//__android_log_print(ANDROID_LOG_INFO   , "TbVideoPlayer", __VA_ARGS__)
#define LOGW(format, ...) printf(format, ##__VA_ARGS__)//__android_log_print(ANDROID_LOG_WARN   , "TbVideoPlayer", __VA_ARGS__)
#define LOGE(format, ...) printf(format, ##__VA_ARGS__)//__android_log_print(ANDROID_LOG_ERROR  , "TbVideoPlayer", __VA_ARGS__)

#ifndef SAFE_FREE
#define SAFE_FREE(p)		 {if(p) {free(p); p = NULL;}}
#endif

#ifndef SAFE_DELETE
#define SAFE_DELETE(p)		 {if(p) {delete p; p = NULL;}}
#endif

#ifndef SAFE_RELEASE
#define SAFE_RELEASE(p)      {if(p) {p->Release(); p = NULL;}}
#endif

#ifndef SAFE_ARRAYDELETE
#define SAFE_ARRAYDELETE(p)  {if(p) {delete [] p; p = NULL;}}
#endif

//player type
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerType_Decoder = 0x01;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerType_Player = 0x02;

//return value
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_OpenGLInitFailed = -8;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_RenderFailed = -7;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_SurfaceNotSetted = -7;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_ThreadCreateFailed = -6;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NotSupported = -5;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_WrongState = -4;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_AlreadyCreated = -3;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_InvalidArgument = -2;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoMemory = -1;
static int com_example_player4android_TbVideoPlayer_TbVideoPlayerResult_NoError = 0;

//decode configure
static int com_example_player4android_TbVideoPlayer_TbDecodeConfig_Software = 0;
static int com_example_player4android_TbVideoPlayer_TbDecodeConfig_Hardware = 1;
static int com_example_player4android_TbVideoPlayer_TbDecodeConfig_AutoDetect = 2;

class CFuncTrace
{
public:
	CFuncTrace(const char *pFuncNamte)
	{
		if(0 != pFuncNamte)
			strcpy(m_szBuffer, pFuncNamte);
		else
			strcpy(m_szBuffer, "Unknown Function Name");

		LOGD("%s Enter, ThreadID = %lu", m_szBuffer, pthread_self());
	}

	~CFuncTrace()
	{
		LOGD("%s Leave", m_szBuffer);
	}

private:

	char m_szBuffer[1024];
};


class CCritSec
{
private:
	CCritSec(const CCritSec &refCritSec);
	CCritSec &operator=(const CCritSec &refCritSec);

	bool m_bCreated;
	pthread_mutex_t m_mutex;

public:
	CCritSec() 
	: m_bCreated(false)
	{
		if(0 != pthread_mutex_init(&m_mutex, NULL))
		{
			LOGE("pthread_mutex_init Failed");
			return;
		}

		m_bCreated = true;
	};

	~CCritSec()
	{
		if(m_bCreated)
		{
			pthread_mutex_destroy(&m_mutex);
			m_bCreated = false;
		}
	};

	void Lock()
	{
		if(m_bCreated)
		{
			if(0 != pthread_mutex_lock(&m_mutex))
			{
				LOGE("pthread_mutex_lock Failed");
			}
		}
	};

	void Unlock()
	{
		if(m_bCreated)
		{
			if(0 != pthread_mutex_unlock(&m_mutex))
			{
				LOGE("pthread_mutex_unlock Failed");
			}
		}
	};
};

class CAutoLock 
{
private:
	CAutoLock(const CAutoLock &refAutoLock);
	CAutoLock &operator=(const CAutoLock &refAutoLock);

protected:
	CCritSec *m_pLock;

public:
	CAutoLock(CCritSec * plock)
	{
		m_pLock = plock;
		m_pLock->Lock();
	};

	~CAutoLock()
	{
		m_pLock->Unlock();
	};
};

inline long long GetTimeMs()
{
	timeval tv;
//	gettimeofday(&tv,NULL);
	return (long long)tv.tv_sec * 1000 + (long long)tv.tv_usec / 1000;
}

