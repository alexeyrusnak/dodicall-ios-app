/*
Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
*/
//  This file is part of dodicall.
//  dodicall is free software : you can redistribute it and / or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  dodicall is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with dodicall.If not, see <http://www.gnu.org/licenses/>.

#include "stdafx.h"

#define __ThreadHelper_cpp__
#include "ThreadHelper.h"


#ifdef ANDROID
JavaVM* gJvm = NULL;

extern "C" JNIEXPORT jint JNICALL  JNI_OnLoad(JavaVM* ajvm, void* reserved)
{
	gJvm = ajvm;
	dodicall::LogManager::GetInstance().TraceLogger(dodicall::LogLevelDebug) << "JNI_OnLoad called successfully";
	return JNI_VERSION_1_2;
}
#endif

namespace dodicall
{

AutoInterruptableThreadPtr::AutoInterruptableThreadPtr(ThreadPtr ptr): mPtr(ptr)
{
}
AutoInterruptableThreadPtr::~AutoInterruptableThreadPtr()
{
	if (this->mPtr)
		ThreadHelper::InterruptThread(this->mPtr, true);
}

ThreadPtr AutoInterruptableThreadPtr::operator -> (void)
{
	return mPtr;
}
AutoInterruptableThreadPtr::operator ThreadPtr(void)
{
	return this->mPtr;
}
AutoInterruptableThreadPtr::operator bool(void)
{
	return (bool)this->mPtr;
}

AutoInterruptableThreadPtr& AutoInterruptableThreadPtr::operator = (ThreadPtr ptr)
{
	this->mPtr = ptr;
	return *this;
}

void ThreadHelper::InterruptThread(ThreadPtr thread, bool wait)
{
	thread->interrupt();
	if (wait)
		thread->join();
}

void ThreadPool::InterruptAllThreads(bool wait)
{
	boost::thread::id currentTid = boost::this_thread::get_id();
	{
		boost::lock_guard<boost::mutex> _lock(this->mMutex);
		for (auto iter = this->mThreads.begin(); iter != this->mThreads.end(); iter++)
			if (iter->second->get_id() != currentTid)
				iter->second->interrupt();
	}
	while (wait)
	{
		ThreadPtr t;
		{
			boost::lock_guard<boost::mutex> _lock(this->mMutex);
			if (this->mThreads.empty())
				break;
			auto found = this->mThreads.begin();
			if (found->second->get_id() == currentTid)
			{
				found++;
				if (found == this->mThreads.end())
					break;
			}
			t = found->second;
		}
		try
		{
			if (t->joinable())
				t->join();
		}
		catch (boost::exception&)
		{
		}
	}
}

ThreadPool::~ThreadPool(void)
{
	this->InterruptAllThreads(true);
}

}