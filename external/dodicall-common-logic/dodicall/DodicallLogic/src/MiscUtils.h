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

#ifndef MISCUTILS_H
#define MISCUTILS_H
#pragma once


namespace MiscUtils {
	class CantCopy;							// Disable copying
	template<class Cont> class StackVar;	// create an object locally, copy to result in dtor
	template<class T> class RefObject;
}

// REVIEW SV->ST: Для запрета копирования есть стандартный класс boost::noncopyable, предлагаю использовать его
class MiscUtils::CantCopy
{
	CantCopy(const CantCopy&);
	CantCopy& operator=(const CantCopy&);
public:
	CantCopy() {}
};

template<class Cont>
class MiscUtils::StackVar : public Cont, CantCopy
{
	Cont& mResult;
public:
	StackVar(Cont& result) : mResult(result)
	{}
	~StackVar()
	{
		std::swap(mResult, *static_cast<Cont*>(this));
	}
};

template<class T>
class MiscUtils::RefObject : CantCopy {
	typedef T* (*RefFunc)(T*);
	typedef void(*UnrefFunc)(T*);
	T* mObj;
	UnrefFunc mUnref;
public:
	RefObject(T* obj, RefFunc ref, UnrefFunc unref) : mObj(obj), mUnref(unref)
	{
		if (mObj)
		{
			mObj = ref(mObj);
		}
		assert(obj == mObj);	// looking for failure
	}
	~RefObject()
	{
		if (mObj)
		{
			mUnref(mObj);
		}
	}
	operator T* () const { return mObj; }
};

#endif  MISCUTILS_H
