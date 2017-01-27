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

typedef boost::posix_time::ptime DateType;

inline boost::posix_time::ptime posix_time_now(void)
{
	return boost::posix_time::second_clock::universal_time();
}

inline time_t posix_time_to_time_t(const boost::posix_time::ptime& t)
{
    boost::posix_time::ptime epoch(boost::gregorian::date(1970,1,1));
    return time_t((t - epoch).total_seconds());
}

inline boost::posix_time::ptime time_t_to_posix_time (time_t t)
{
	return boost::posix_time::from_time_t(t);
}

inline std::wstring format_time(boost::posix_time::ptime now)
{
    using namespace boost::posix_time;
    static std::locale loc(std::wcout.getloc(),
                           new wtime_facet(L"%Y%m%d_%H%M%S"));
    
    std::basic_stringstream<wchar_t> wss;
    wss.imbue(loc);
    wss << now;
    return wss.str();
}

inline boost::posix_time::ptime timestamp_to_posix_time(std::string stamp)
{
	static const char charsToDelete[] = "-:Z";

	for (unsigned int i = 0; i < sizeof(charsToDelete) - 1; ++i)
		stamp.erase(std::remove(stamp.begin(), stamp.end(), charsToDelete[i]), stamp.end());
	return boost::posix_time::from_iso_string(stamp);
}

template <typename T> std::string time_t_to_string(const T &t) 
{
    std::ostringstream oss;
    oss << t;
    return oss.str();
}

}