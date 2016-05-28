//#include "com_example_player4android_TbVideoPlayer.h"
#include "Utility.h"

void* WorkingThread(void *pCTbThread)
{
	CFuncTrace("CTbThread::WorkingThread");

	CTbThread* pThread = (CTbThread*)pCTbThread;

	pThread->OnThreadStart();
	while(pThread->GetThreadRunningState())
	{
		pThread->OnSingleStep();
	}

	pThread->OnThreadStop();
	
	return NULL;
}

CTbThread::CTbThread()
{
	m_bRunning = true;
	m_threadId = 0;
}

CTbThread::~CTbThread()
{

}

bool CTbThread::Start()
{
	CFuncTrace("CTbThread::Start");
	m_bRunning = true;
	if (0 != pthread_create(&m_threadId, NULL, WorkingThread, (CTbThread*)this))
	{
		LOGE("pthread_create Failed");
		return false;
	}
	return true;
}

bool CTbThread::Stop()
{
	CFuncTrace("CTbThread::Stop");
	void * pRet = 0;
	m_bRunning = false;
	if (0 != pthread_join(m_threadId, &pRet))
	{
		LOGE("pthread_join Failed");
		return false;
	}
	else
	{
		LOGD("pthread_join Success.");
	}
	return true;
}

bool CTbThread::GetThreadRunningState(void)
{
	return m_bRunning;
}
