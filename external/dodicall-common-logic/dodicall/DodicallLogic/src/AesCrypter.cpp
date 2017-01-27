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

#include "AesCrypter.h"

#include <boost/regex.hpp>

namespace dodicall
{

AesCrypter::AesCrypter(void)
{
	this->Cleanup();
}
AesCrypter::~AesCrypter(void)
{
}

bool AesCrypter::Init(const char* key)
{
	return (SHA256((const unsigned char*)key,strlen(key)*sizeof(char),&this->mKeyHash[0]) != NULL);
}
void AesCrypter::Cleanup(void)
{
	memset(this->mKeyHash, 0, sizeof(this->mKeyHash));
}
bool AesCrypter::IsInitialized(void) const
{
    bool result = false;
    for (unsigned int i = 0; i < sizeof(this->mKeyHash)/sizeof(unsigned char); i++)
        if (this->mKeyHash[i] != 0)
        {
            result = true;
            break;
        }
    return result;
}

template <class T> std::vector<unsigned char> PrepareInput(T input)
{
	int inputSize = input.size();
	int resultSize = (inputSize/AES_BLOCK_SIZE+1)*AES_BLOCK_SIZE;
	std::vector<unsigned char> result;
	result.reserve(resultSize);
	result.insert(result.end(),input.begin(),input.end());
	if (resultSize > inputSize)
		result.insert(result.end(),(resultSize-inputSize),0);
	return result;
}

bool AesCrypter::Encrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const
{
	return this->Crypt(input, output, AES_ENCRYPT);
}

bool AesCrypter::Decrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const
{
	return this->Crypt(input, output, AES_DECRYPT);
}

void AesCrypter::GetHash(std::vector<unsigned char>& result) const
{
	result.assign(&this->mKeyHash[0], this->mKeyHash + sizeof(this->mKeyHash)/sizeof(this->mKeyHash[0]) - 1);
}

bool AesCrypter::Crypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output, const int enc) const
{
	if (this->IsInitialized() && !input.empty())
	{
		std::vector<unsigned char> preparedInput = PrepareInput(input);
		output.resize(preparedInput.size());
		std::fill(output.begin(), output.end(), 0);

		unsigned char iv[AES_BLOCK_SIZE];
		memcpy(&iv[0], &this->mKeyHash[0], AES_BLOCK_SIZE);

		AES_KEY key;
		if (enc == AES_ENCRYPT)
			AES_set_encrypt_key(&this->mKeyHash[0], sizeof(this->mKeyHash) * 8, &key);
		else
			AES_set_decrypt_key(&this->mKeyHash[0], sizeof(this->mKeyHash) * 8, &key);

		AES_cbc_encrypt(preparedInput.data(), output.data(), preparedInput.size(), &key, &iv[0], enc);
		return true;
	}
	return false;
}

}
