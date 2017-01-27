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

namespace dodicall
{

template <class TYPE, class CONTAINER> class SafeContainer
{
private:
	CONTAINER mContainer;
	mutable boost::shared_mutex mMutex;

public:
	bool Empty(void) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		return this->mContainer.empty();
	}

	bool Exists(const typename CONTAINER::key_type& key) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		return (this->mContainer.find(key) != this->mContainer.end());
	}

	boost::optional<TYPE> Get(const typename CONTAINER::key_type& key) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		typename CONTAINER::const_iterator found = this->mContainer.find(key);
		if (found != this->mContainer.end())
			return boost::optional<TYPE>(this->GetValue(*found));
		return boost::optional<TYPE>();
	}

	CONTAINER Copy(void) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		return this->mContainer;
	}

	void Set(const typename CONTAINER::value_type& value)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		this->mContainer.erase(GetKey(value));
		this->mContainer.insert(value);
	}

	void Erase(const typename CONTAINER::key_type& key)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		this->mContainer.erase(key);
	}

	void Clear(void)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		this->mContainer.clear();
	}

	void Swap(CONTAINER& to)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		std::swap(this->mContainer, to);
	}

	template <class F> void ForEach(F func) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		for (auto iter = this->mContainer.begin(); iter != this->mContainer.end(); iter++)
			if (!func(*iter))
				break;
	}

	template <class F> void EraseWhere(F func)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		for (auto iter = this->mContainer.begin(); iter != this->mContainer.end();)
		{
			if (func(*iter))
				iter = this->mContainer.erase(iter);
			else
				iter++;
		}
	}

	SafeContainer()
	{}

	SafeContainer(const SafeContainer& cpy)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		this->mContainer = cpy.mContainer;
	}

	SafeContainer& operator= (const SafeContainer& second)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		this->mContainer = second.mContainer;
		return *this;
	}

private:
	template <class KEY, class VALUE> static VALUE GetValue(const std::pair<KEY, VALUE>& p)
	{
		return p.second;
	}
	template <class VALUE> static VALUE GetValue(const VALUE& t)
	{
		return t;
	}

	template <class KEY, class VALUE> static KEY GetKey(const std::pair<KEY, VALUE>& p)
	{
		return p.first;
	}
	template <class VALUE> static VALUE GetKey(const VALUE& t)
	{
		return t;
	}
};

template <class T> class SafeObject
{
private:
	T mObject;
	mutable boost::shared_mutex mMutex;

public:

	operator T (void) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		return this->mObject;
	}

	SafeObject& operator = (const T& obj)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		this->mObject = obj;
		return *this;
	}
	
	template <class F> void SafeChange(F func)
	{
		boost::upgrade_lock<boost::shared_mutex> _lock(this->mMutex);
		func(this->mObject);
	}
	template <class R, class F = R(const T&)> R SafeGet(F func) const
	{
		boost::shared_lock<boost::shared_mutex> _lock(this->mMutex);
		return func(this->mObject);
	}
};

}