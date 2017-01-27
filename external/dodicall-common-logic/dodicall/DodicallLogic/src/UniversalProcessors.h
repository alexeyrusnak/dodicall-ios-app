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
#include "ThreadHelper.h"

namespace dodicall
{

class DelayedCaller
{
protected:
	boost::mutex mMutex;

private:
	boost::condition_variable mEvent;
	AutoInterruptableThreadPtr mThread;

public:
	template <class F> DelayedCaller(F func, unsigned delayMs = 1000): mMutex(), mEvent(),
		mThread(ThreadHelper::StartInterruptableThread([this](F func, unsigned delayMs)
			{
				bool ready = false;
				while (true)
				{
					bool catched = false;
					{
						boost::unique_lock<boost::mutex> lock(this->mMutex);
						if (delayMs > 0)
						{
							catched = this->mEvent.timed_wait(lock, boost::posix_time::millisec(delayMs));
							if (catched)
								ready = catched;
						}
						else
						{
							this->mEvent.wait(lock);
							ready = true;
							catched = false;
						}
					}
					if (ready && !catched)
					{
						func();
						ready = false;
					}
				}
		}, func, delayMs)
	)
	{
	}

	inline void Call(void)
	{
		this->mEvent.notify_one();
	}
};

template <class T, class TCONT = std::set<T>> class DelayedProcessor: protected DelayedCaller
{
private:
	TCONT mObjects;

public:
	template <class F> DelayedProcessor(F func, unsigned delayMs = 1000): mObjects(),
		DelayedCaller([this,func]
		{
			while (!this->mObjects.empty())
			{
				TCONT data;
				{
					boost::lock_guard<boost::mutex> _lock(this->mMutex);
					data = this->mObjects;
					this->mObjects.clear();
				}
				func(data);
			}
		}, delayMs)
	{
	}

	inline void Call(const T& obj)
	{
		boost::lock_guard<boost::mutex> _lock(this->mMutex);
		std::inserter(this->mObjects, this->mObjects.end()) =  obj;
		this->DelayedCaller::Call();
	}
	inline void Cancel(void)
	{
		boost::lock_guard<boost::mutex> _lock(this->mMutex);
		this->mObjects.clear();
	}
};

}
