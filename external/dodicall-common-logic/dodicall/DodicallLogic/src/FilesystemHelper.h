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

namespace dodicall
{

class FilesystemHelper
{
public:
#ifdef _WIN32
	static bool GetFileStats(const boost::filesystem::path& path, struct _stat* result);
#else
	static bool GetFileStats(const boost::filesystem::path& path, struct stat* result);
#endif

	static boost::filesystem::path PathFromString(const std::string& path);
	static std::string PathToString(const boost::filesystem::path& path);

	template <class S> static void OpenStream(S& stream, const boost::filesystem::path& path, std::ios_base::openmode flags)
	{
#ifdef _WIN32
		stream.open(path.wstring().c_str(), flags);
#else
		stream.open(path.string().c_str(), flags);
#endif
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Open file " << path.string().c_str();
	}

private:
	FilesystemHelper();
	~FilesystemHelper();
};

}

