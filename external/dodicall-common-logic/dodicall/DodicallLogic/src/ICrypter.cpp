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

#include "ICrypter.h"

namespace dodicall
{

std::string ICrypter::EncryptStringToBase64(const std::string& input) const
{
	std::vector<unsigned char> result;
	if (this->Encrypt(std::vector<unsigned char>(input.begin(), input.end()), result))
		return this->Base64Encode(result);
	return input;
}

std::string ICrypter::DecryptStringFromBase64(const std::string& input) const
{
	std::vector<unsigned char> vinput = this->Base64Decode(input);
	std::vector<unsigned char> result;
	if (this->Decrypt(vinput, result))
		return std::string((const char*)result.data());
	return input;
}

std::string ICrypter::GetHashBase64(void) const
{
	std::vector<unsigned char> result;
	this->GetHash(result);
	return this->Base64Encode(result);
}

std::string ICrypter::Base64Encode(const std::vector<unsigned char>& input)
{
	BIO* base64filter = BIO_new(BIO_f_base64());
	BIO* bio = BIO_new(BIO_s_mem());

	//BIO_set_flags(base64filter, BIO_FLAGS_BASE64_NO_NL);
	//BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
	bio = BIO_push(base64filter, bio);
	BIO_write(bio, input.data(), input.size());
	BIO_flush(bio);

	char* base64data = NULL;
	long bytes = BIO_get_mem_data(bio, &base64data);

	std::string result;
	if (bytes > 0 && base64data)
		result.assign(base64data, base64data + bytes);
	BIO_free_all(bio);
	return result;
}
std::vector<unsigned char> ICrypter::Base64Decode(const std::string& input)
{
	BIO* base64filter = BIO_new(BIO_f_base64());
	//BIO_set_flags( base64filter, BIO_FLAGS_BASE64_NO_NL );
	BIO* bio = BIO_new_mem_buf((void*)input.c_str(), input.length());
	bio = BIO_push(base64filter, bio);
	BIO* bioOut = BIO_new(BIO_s_mem());

	int inlen;
	char inbuf[512];
	while ((inlen = BIO_read(bio, inbuf, 512)) > 0)
		BIO_write(bioOut, inbuf, inlen);
	BIO_flush(bioOut);

	char *resultData = NULL;
	long bytes = BIO_get_mem_data(bioOut, &resultData);
	std::vector<unsigned char> result;
	if (bytes > 0 && resultData)
	{
		std::vector<unsigned char> resVector(resultData, resultData + bytes);
		result.swap(resVector);
	}
	BIO_free_all(bio);
	BIO_free_all(bioOut);
	return result;
}

}