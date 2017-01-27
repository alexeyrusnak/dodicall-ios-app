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

#include <boost/archive/iterators/binary_from_base64.hpp>
#include <boost/archive/iterators/base64_from_binary.hpp>
#include <boost/archive/iterators/transform_width.hpp>
#include <boost/algorithm/string.hpp>

inline std::string decode64(const std::string &val) 
{
    using namespace boost::archive::iterators;
    using It = transform_width<binary_from_base64<std::string::const_iterator>, 8, 6>;
    return boost::algorithm::trim_right_copy_if(std::string(It(std::begin(val)), It(std::end(val))), [](char c) {
        return c == '\0';
    });
}

inline std::string encode64(const std::string &val) 
{
    using namespace boost::archive::iterators;
    using It = base64_from_binary<transform_width<std::string::const_iterator, 6, 8>>;
    auto tmp = std::string(It(std::begin(val)), It(std::end(val)));
    return tmp.append((3 - val.size() % 3) % 3, '=');
}

inline unsigned VersionStringToInt (const std::string &val)
{
    unsigned result = 0;
    if (val.empty())
        return result;
    std::vector<std::string> nums;
    boost::split(nums,val,boost::is_any_of("."));
    for (std::vector<std::string>::const_iterator iter = nums.begin(); iter != nums.end(); iter++)
        result = result*1000 + boost::lexical_cast<unsigned>(*iter);
    return result;
}

inline std::string CutDomain(std::string val)
{
	size_t doggy = val.find_first_of('@');
	if (doggy != val.npos)
		val = val.substr(0, doggy);
	return val;
}

inline std::string GetDomain(std::string val)
{
	size_t doggy = val.find_first_of('@');
	if (doggy != val.npos)
		return val.substr(doggy+1);
	return std::string("");
}

/* StringUtils_h */
