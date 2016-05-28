#pragma once

class IFifo
{
public:
	virtual ~IFifo(){};

	//write data and addtional data;
	virtual bool Write(unsigned char *pData,
		unsigned long DataLen,
		void *pAddtionalData, //addtional data
		unsigned long AddtionalDataLen) = 0;

	//read data and addtional data;
	virtual bool Read(unsigned char *pData,
		unsigned long BufferLen,
		unsigned long &ReadLen,
		void *pAddtionalData,  //addtional data
		unsigned long AddtionalBufferLen, // addtional buffer length
		unsigned long &AddtionalReadLen /*addtional data read len*/ ) = 0;

	virtual unsigned long GetNodeNum() = 0;
	virtual void Start() = 0;
	virtual void Abort() = 0;
	virtual void Reset() = 0;
};

typedef struct _DynamicNode
{
	unsigned char *pData;
	unsigned long DataLen;
	unsigned long AddtionalLen;

	_DynamicNode()
	{
		pData =  NULL;
		DataLen = 0;
		AddtionalLen = 0;
	}
}DynamicNode;

class CDynamicFifo : public IFifo
{
public:
	CDynamicFifo();
	virtual ~CDynamicFifo();

	//write data and addtional data;
	virtual bool Write(unsigned char *pData,
		unsigned long DataLen,
		void *pAddtionalData, //addtional data
		unsigned long AddtionalDataLen);

	//read data and addtional data;
	virtual bool Read(unsigned char *pData,
		unsigned long BufferLen,
		unsigned long &ReadLen,
		void *pAddtionalData,  //addtional data
		unsigned long AddtionalBufferLen, // addtional buffer length
		unsigned long &AddtionalReadLen/*addtional data read len*/ );

	virtual unsigned long GetNodeNum();
	virtual void Start();
	virtual void Abort();
	virtual void Reset();
private:

	typedef std::list<DynamicNode *>::iterator ListIter;

	std::list<DynamicNode *> m_NodeList;

	//HANDLE m_Event;
	//HANDLE m_Mutex;

	pthread_mutex_t m_mMuteLock;
	pthread_cond_t m_cCondVal;

	bool m_bQuit;
};

