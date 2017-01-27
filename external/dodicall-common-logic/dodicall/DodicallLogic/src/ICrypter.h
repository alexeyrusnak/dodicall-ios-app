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

#ifdef _WIN32
#ifdef DODICALLCRYPTER_EXPORTS
#define DODICALLCRYPTOAPI __declspec(dllexport)
#else
#define DODICALLCRYPTOAPI __declspec(dllimport)
#endif
#else
#define DODICALLCRYPTOAPI
#endif

namespace dodicall
{

class DODICALLCRYPTOAPI ICrypter
{
public:
	virtual bool IsInitialized(void) const = 0;
	virtual bool Encrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const = 0;
	virtual bool Decrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const = 0;

	virtual void GetHash(std::vector<unsigned char>& result) const = 0;

	std::string EncryptStringToBase64(const std::string& input) const;
	std::string DecryptStringFromBase64(const std::string& input) const;

	std::string GetHashBase64(void) const;

private:
	// TODO: move to Base64Helper
	static std::string Base64Encode(const std::vector<unsigned char>& input);
	static std::vector<unsigned char> Base64Decode(const std::string& input);
};

}
 