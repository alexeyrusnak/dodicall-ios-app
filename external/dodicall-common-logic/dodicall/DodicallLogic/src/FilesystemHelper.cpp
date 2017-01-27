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
#include "FilesystemHelper.h"

namespace dodicall
{

#ifdef _WIN32
bool FilesystemHelper::GetFileStats(const boost::filesystem::path& path, struct _stat* result)
{
	return (_wstat(path.wstring().c_str(), result) != -1);
}
#else
bool FilesystemHelper::GetFileStats(const boost::filesystem::path& path, struct stat* result)
{
	return (stat(path.string().c_str(), result) != -1);
}
#endif

boost::filesystem::path FilesystemHelper::PathFromString(const std::string& path)
{
#ifdef _WIN32
	return boost::filesystem::path(boost::locale::conv::utf_to_utf<wchar_t>(path));
#else
	return boost::filesystem::path(path);
#endif
}
std::string FilesystemHelper::PathToString(const boost::filesystem::path& path)
{
#ifdef _WIN32
	return boost::locale::conv::utf_to_utf<char>(path.wstring());
#else
	return path.string();
#endif
}


FilesystemHelper::FilesystemHelper()
{
}
FilesystemHelper::~FilesystemHelper()
{
}

}
