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

#include "ICrypter.h"

namespace dodicall
{

class DODICALLCRYPTOAPI AesCrypter: public ICrypter
{
private:
	unsigned char mKeyHash[32];

public:
	AesCrypter(void);
	~AesCrypter(void);

	bool Init(const char* key);
	void Cleanup(void);
	bool IsInitialized(void) const;

	bool Encrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const;
	bool Decrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const;

	void GetHash(std::vector<unsigned char>& result) const;

private:
	bool Crypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output, const int enc) const;
};

}