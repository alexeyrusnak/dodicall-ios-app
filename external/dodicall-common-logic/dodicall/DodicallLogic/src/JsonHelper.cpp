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

#include "JsonHelper.h"

#include <boost/regex.hpp>

namespace dodicall
{

std::string JsonHelper::ptree_to_json(const boost::property_tree::ptree &pt)
{
	std::ostringstream obuf;
	boost::regex exp("\"(null|true|false|[0-9]+(\\.[0-9]+)?)\"");
	boost::property_tree::json_parser::write_json(obuf, pt, false);
	std::string rv = boost::regex_replace(obuf.str(), exp, "$1");
	rv = boost::regex_replace(rv, boost::regex("\"\""), "null");
    rv = boost::regex_replace(rv, boost::regex("\n"), "");
	return rv;
}

bool JsonHelper::json_to_ptree(const char* json, boost::property_tree::ptree& pt)
{
	try
	{
		std::stringstream ibuf;
		ibuf << json;
		boost::property_tree::json_parser::read_json (ibuf,pt);
		return true;
	}
	catch(...)
	{
	}
	return false;
}

std::string JsonHelper::ptree_to_json_array(const boost::property_tree::ptree &pt)
{
	std::string result = ptree_to_json(pt);
	size_t begin = result.find_first_of('[');
	if (begin != result.npos)
		result = result.substr(begin, result.find_last_of(']') - begin + 1);
	else
		result = "[]";
	return result;
}

}
