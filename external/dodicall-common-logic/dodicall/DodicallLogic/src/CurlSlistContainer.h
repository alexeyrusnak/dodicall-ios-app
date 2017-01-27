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

class CurlSlistContainer
{
private:
	boost::mutex mMutex;

public:
	curl_slist* SList;

	CurlSlistContainer(curl_slist* slist = 0): SList(slist)
	{
	}
	~CurlSlistContainer()
	{
		if (SList)
			curl_slist_free_all(SList);
	}
};

typedef boost::shared_ptr<CurlSlistContainer> CurlSlistContainerPtr;

inline CurlSlistContainerPtr CloneCurlSlistContainer(CurlSlistContainerPtr origin)
{
	if (!origin)
		return origin;

	curl_slist* result = 0;
	curl_slist* iter = origin->SList;
	while (iter)
	{
		result = curl_slist_append(result, iter->data);
		iter = iter->next;
	}
	return CurlSlistContainerPtr(new CurlSlistContainer(result));
}

}
