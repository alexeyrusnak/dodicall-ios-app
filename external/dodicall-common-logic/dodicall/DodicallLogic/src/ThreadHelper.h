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

#pragma once
#include "stdafx.h"
#include "LogManager.h"

#ifdef ANDROID
#include <jni.h>

extern JavaVM* gJvm;

#define CATCH_CPP_EXCEPTION_AND_THROW_JAVA_EXCEPTION              \
  catch (const std::bad_alloc& e)                                 \
  {                                                               \
    /* OOM exception */                                           \
    jclass jc = env->FindClass("java/lang/OutOfMemoryError");     \
    if(jc) env->ThrowNew (jc, e.what());                          \
  }                                                               \
  catch (const std::ios_base::failure& e)                         \
  {                                                               \
    /* IO exception */                                            \
    jclass jc = env->FindClass("java/io/IOException");            \
    if(jc) env->ThrowNew (jc, e.what());                          \
  }                                                               \
  catch (const std::exception& e)                                 \
  {                                                               \
    /* unknown exception */                                       \
    jclass jc = env->FindClass("java/lang/Error");                \
    if(jc) env->ThrowNew (jc, e.what());                          \
  }                                                               \
  catch (...)                                                     \
  {                                                               \
    /* Oops I missed identifying this exception! */               \
    jclass jc = env->FindClass("java/lang/Error");                \
    if(jc) env->ThrowNew (jc, "unidentified exception");          \
  }

#endif

namespace dodicall
{

typedef boost::shared_ptr<boost::thread> ThreadPtr;

class AutoInterruptableThreadPtr
{
private:
	ThreadPtr mPtr;

public:
	AutoInterruptableThreadPtr(ThreadPtr ptr = ThreadPtr());
	~AutoInterruptableThreadPtr();

	ThreadPtr operator -> (void);
	operator ThreadPtr(void);
	operator bool(void);

	AutoInterruptableThreadPtr& operator = (ThreadPtr ptr);
};

class ThreadHelper
{
public:
	static void InterruptThread(ThreadPtr thread, bool wait = true);

	template <class F> static ThreadPtr StartThread(F func)
	{
#ifdef ANDROID
		return ThreadPtr(new boost::thread([func]
		{
			if (gJvm)
			{
				JNIEnv* env = 0;
				bool attachFlag = false;
				switch (gJvm->GetEnv((void**)&env, JNI_VERSION_1_2))
				{
				case JNI_EDETACHED:
					{
						jint result = gJvm->AttachCurrentThread(&env, NULL);
						if (result != 0)
						{
							dodicall::LogManager::GetInstance().TraceLogger(dodicall::LogLevelWarning) << "Cannot attach VM";
							env = 0;
						}
						else
							attachFlag = true;
					}
					break;
				case JNI_EVERSION:
					dodicall::LogManager::GetInstance().TraceLogger(dodicall::LogLevelWarning) << "JNI version is not supported";
					env = 0;
				default:
					break;
				}

				if (env)
				{
					try
					{
						func();
					}
					CATCH_CPP_EXCEPTION_AND_THROW_JAVA_EXCEPTION
				}
				else
					func();

				if (attachFlag && gJvm->GetEnv((void**)&env, JNI_VERSION_1_2) != JNI_EDETACHED)
					gJvm->DetachCurrentThread();
			}
			else
			{
				dodicall::LogManager::GetInstance().TraceLogger(dodicall::LogLevelWarning) << "No JVM registered";
				func();
			}
		}));
#else
		return ThreadPtr(new boost::thread(func));
#endif
	}
	template <class F, class A1> static ThreadPtr StartThread(F func, A1 arg1)
	{
		return StartThread(boost::bind(boost::function<void(A1)>(func),arg1));
	}
	template <class F, class A1, class A2> static ThreadPtr StartThread(F func, A1 arg1, A2 arg2)
	{
		return StartThread(boost::bind(boost::function<void(A1,A2)>(func),arg1,arg2));
	}
	template <class F, class A1, class A2, class A3> static ThreadPtr StartThread(F func, A1 arg1, A2 arg2, A3 arg3)
	{
		return StartThread(boost::bind(boost::function<void(A1,A2,A3)>(func), arg1, arg2, arg3));
	}


	template <class F> static ThreadPtr StartInterruptableThread(F func)
	{
		return StartThread([func]
		{
			try
			{
				func();
			}
			catch (const boost::thread_interrupted&)
			{
			}
		});
	}
	template <class F, class A1> static ThreadPtr StartInterruptableThread(F func, A1 arg1)
	{
		return StartInterruptableThread(boost::bind(boost::function<void(A1)>(func),arg1));
	}
	template <class F, class A1, class A2> static ThreadPtr StartInterruptableThread(F func, A1 arg1, A2 arg2)
	{
		return StartInterruptableThread(boost::bind(boost::function<void(A1,A2)>(func), arg1, arg2));
	}
	template <class F, class A1, class A2, class A3> static ThreadPtr StartInterruptableThread(F func, A1 arg1, A2 arg2, A3 arg3)
	{
		return StartInterruptableThread(boost::bind(boost::function<void(A1,A2,A3)>(func), arg1, arg2, arg3));
	}
};

class ThreadPool
{
private:
	boost::mutex mMutex;
	std::map<boost::thread::id, ThreadPtr> mThreads;

public:
	void InterruptAllThreads(bool wait = true);

	template <class F> ThreadPtr StartThread(F func)
	{
		boost::lock_guard<boost::mutex> _lock(this->mMutex);
		ThreadPtr result = ThreadHelper::StartThread([this,func]
		{
			try
			{
				func();
			}
			catch (const boost::thread_interrupted&)
			{
			}
			boost::lock_guard<boost::mutex> _lock(this->mMutex);
			this->mThreads.erase(boost::this_thread::get_id());
		});
		this->mThreads[result->get_id()] = result;
		return result;
	}
	template <class F, class A1> ThreadPtr StartThread(F func, A1 arg1)
	{
		return this->StartThread(boost::bind(boost::function<void(A1)>(func), arg1));
	}
	template <class F, class A1, class A2> ThreadPtr StartThread(F func, A1 arg1, A2 arg2)
	{
		return this->StartThread(boost::bind(boost::function<void(A1, A2)>(func), arg1, arg2));
	}
	template <class F, class A1, class A2, class A3> ThreadPtr StartThread(F func, A1 arg1, A2 arg2, A3 arg3)
	{
		return this->StartThread(boost::bind(boost::function<void(A1, A2, A3)>(func), arg1, arg2, arg3));
	}

	~ThreadPool(void);
};

#ifndef __ThreadHelper_cpp__
#define thread UseThreadHelper_instead_of__boost_thread
#endif

}