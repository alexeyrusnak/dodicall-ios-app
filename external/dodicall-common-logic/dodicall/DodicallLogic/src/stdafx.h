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

#ifdef _WIN32
//#pragma managed(push, off)

#ifdef DODICALLLOGIC_EXPORTS
#define DODICALLLOGICAPI __declspec(dllexport)

#else
#define DODICALLLOGICAPI __declspec(dllimport)
#endif
#else
#define DODICALLLOGICAPI
#endif

#include <stdarg.h>
#include <sys/stat.h>
#include <time.h>

#include <cctype>
#include <chrono>
#include <ctime>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <type_traits>
#include <vector>

#include <strophe/strophe.h>

#include <boost/assign.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/date_time.hpp>
#include <boost/filesystem.hpp>
#include <boost/function.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/locale.hpp>
#include <boost/optional.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <boost/scoped_ptr.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/thread.hpp>
#include <boost/tuple/tuple.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/random_generator.hpp>
#include <boost/uuid/uuid_io.hpp>

#include <curl/curl.h>

#include <sqlite/sqlite3.h>

#include <openssl/aes.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/sha.h>
#include <openssl/rand.h>

/* This method is not implemented in ndk */
#if defined(__ANDROID__)
namespace std {
template <typename T>
std::string to_string(T value)
{
	std::ostringstream os;
	os << value;
	return os.str();
}
}
#endif

#ifdef _WIN32
#pragma warning(disable:4251)
#pragma warning(disable:4793)
//#pragma managed(pop)

// TODO: HACK to fix LNK2022 error
namespace boost {
	struct thread::dummy {};
}
#endif

#undef GetTempPath

#ifdef _DEBUG
#define DEBUG_ONLY_CODE(x) x
#else 
#define DEBUG_ONLY_CODE(x)
#endif
