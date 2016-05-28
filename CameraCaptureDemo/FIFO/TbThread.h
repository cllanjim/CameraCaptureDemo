#pragma once

//I am thread safe
class CTbThread
{
public:
	CTbThread();
	~CTbThread();

public:
	bool Start();
	bool Stop();

public:
	virtual bool OnThreadStart(){return false;};
	virtual bool OnSingleStep(){return false;};
	virtual bool OnThreadStop(){return false;};

public:
	bool GetThreadRunningState(void);

private:

	bool m_bRunning;
	pthread_t m_threadId;
};
