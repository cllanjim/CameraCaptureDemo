//#include "com_example_player4android_TbVideoPlayer.h"
#include "Utility.h"

CDynamicFifo::CDynamicFifo()
{
	pthread_mutex_init(&m_mMuteLock, NULL);
	pthread_cond_init(&m_cCondVal, NULL);
	m_bQuit = false;
}

CDynamicFifo::~CDynamicFifo()
{
	CFuncTrace("CDynamicFifo::~CDynamicFifo()");

	pthread_mutex_lock(&m_mMuteLock);

	ListIter NodeIter = m_NodeList.begin();
	for(; NodeIter != m_NodeList.end(); NodeIter++)
	{
		SAFE_FREE((*NodeIter)->pData);
		SAFE_FREE(*NodeIter);
	}
	m_NodeList.clear();
	
	pthread_mutex_unlock(&m_mMuteLock);

	pthread_mutex_destroy(&m_mMuteLock);
	pthread_cond_destroy(&m_cCondVal);
}

bool CDynamicFifo::Write(unsigned char *pData, unsigned long DataLen, void *pAddtionalData, unsigned long AddtionalDataLen)
{
	if(pData == NULL || DataLen == 0)
		return false;

	if((pAddtionalData && 0 == AddtionalDataLen) || (NULL == pAddtionalData && AddtionalDataLen))
		return false;

	DynamicNode *pNode = new DynamicNode;
	if(pNode ==  NULL)
		return false;

	pNode->pData = new unsigned char [DataLen + AddtionalDataLen];
	if(pNode->pData)
	{
		memcpy(pNode->pData, pData, DataLen);
		memcpy(pNode->pData + DataLen, pAddtionalData, AddtionalDataLen);
		pNode->DataLen = DataLen;
		pNode->AddtionalLen = AddtionalDataLen;
	}
	else
	{
		delete pNode;
		pNode =  NULL;
		return false;
	}

	pthread_mutex_lock(&m_mMuteLock);

	m_NodeList.push_back(pNode);

	pthread_cond_signal(&m_cCondVal);

	pthread_mutex_unlock(&m_mMuteLock);

	return true;
}

bool CDynamicFifo::Read(unsigned char *pData,
						unsigned long BufferLen,
						unsigned long &ReadLen,
						void *pAddtionalData, // addtional data
						unsigned long AddtionalBufferLen, // addtional buffer length
						unsigned long &AddtionalReadLen /*addtional data read len*/)
{
	DynamicNode *pNode = NULL;
	int ret = false;

	if(pData == NULL)
		return false;

	pthread_mutex_lock(&m_mMuteLock);

	for(;;)
	{
		if(m_bQuit)
		{
			ret = false;
			break;
		}

		ListIter Iter = m_NodeList.begin();
//		unsigned int num = m_NodeList.size();
//		unsigned int max = m_NodeList.max_size();
//		TBiOSLog(@"num = %d, max = %d\n", num, max);
		if(Iter != m_NodeList.end())
		{
			pNode = *Iter;
			if(pNode->pData)
			{
				if(pNode->DataLen <= BufferLen)
				{
					memcpy(pData, pNode->pData, pNode->DataLen);
					ReadLen = pNode->DataLen;
				}
				else
				{
					memcpy(pData, pNode->pData, BufferLen);
					ReadLen = BufferLen;
				}

				if(pAddtionalData)
				{
					if(pNode->AddtionalLen <= AddtionalBufferLen)
					{
						memcpy(pAddtionalData, pNode->pData + pNode->DataLen, pNode->AddtionalLen);
						AddtionalReadLen = pNode->AddtionalLen;
					}
					else
					{
						memcpy(pAddtionalData, pNode->pData + pNode->DataLen, AddtionalBufferLen);
						AddtionalReadLen = AddtionalBufferLen;							
					}
				}

				SAFE_ARRAYDELETE(pNode->pData);
			}

			m_NodeList.pop_front();
			SAFE_DELETE(pNode);

			ret = true;
			break;
		}
		else
		{
			pthread_cond_wait(&m_cCondVal, &m_mMuteLock);
		}
	}

	pthread_mutex_unlock(&m_mMuteLock);
	return ret;
}

unsigned long CDynamicFifo::GetNodeNum()
{
	unsigned long BufferNum = 0;
	
	pthread_mutex_lock(&m_mMuteLock);

	BufferNum = (unsigned long)m_NodeList.size();
	
	pthread_mutex_unlock(&m_mMuteLock);

	return BufferNum;
}

void CDynamicFifo::Start()
{
	pthread_mutex_lock(&m_mMuteLock);

	m_bQuit = false;

	pthread_mutex_unlock(&m_mMuteLock);
}

void CDynamicFifo::Abort()
{
	pthread_mutex_lock(&m_mMuteLock);

	m_bQuit = true;
	
	pthread_cond_signal(&m_cCondVal);

	pthread_mutex_unlock(&m_mMuteLock);
}

void CDynamicFifo::Reset()
{
	pthread_mutex_lock(&m_mMuteLock);
	
	ListIter NodeIter = m_NodeList.begin();
	for(; NodeIter != m_NodeList.end(); NodeIter++)
	{
		SAFE_ARRAYDELETE((*NodeIter)->pData);
		SAFE_DELETE(*NodeIter);
	}
	m_NodeList.clear();
	
	pthread_mutex_unlock(&m_mMuteLock);
}
