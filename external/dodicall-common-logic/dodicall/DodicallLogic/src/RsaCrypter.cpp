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

#include "RsaCrypter.h"

#include <boost/regex.hpp>

int const PADDING = RSA_PKCS1_PADDING;

namespace dodicall
{

RsaCrypter::RsaCrypter(): mRsaKeys(RSA_new(), ::RSA_free)
{
	this->Cleanup();
}
RsaCrypter::~RsaCrypter()
{
}

bool RsaCrypter::Init()
{
    //(SHA256( (const unsigned char*)publicKey,strlen(publicKey)*sizeof(char),&this->mPublicKeyHash[0] ) != NULL);
    mRsaKeys = Generate();
    return true;
}
    
RSA_ptr RsaCrypter::Generate()
{
    int rc;
    
    RSA_ptr rsa(RSA_new(), ::RSA_free);
    BN_ptr bn(BN_new(), ::BN_free);
    
    rc = BN_set_word(bn.get(), RSA_F4);
    //ASSERT(rc == 1);
    
    // seed random number?
    
    // Generate key
    rc = RSA_generate_key_ex(rsa.get(), 2048, bn.get(), NULL);
    //ASSERT(rc == 1);

    return rsa;
}
    
void RsaCrypter::Cleanup(void)
{
	//memset(this->mPrivateKeyHash, 0, sizeof(this->mPrivateKeyHash));
    //memset(this->mPublicKeyHash, 0, sizeof(this->mPublicKeyHash));
}
bool RsaCrypter::IsInitialized(void) const
{
    
    return true;//return (this->mPrivateKeyHash[0] != 0 && mPublicKeyHash[0] != 0);
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

bool RsaCrypter::Encrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const
{
	return this->Crypt(input, output, RSA_F_RSA_EAY_PUBLIC_ENCRYPT);
}

bool RsaCrypter::Decrypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output) const
{
	return this->Crypt(input, output, RSA_F_RSA_EAY_PRIVATE_DECRYPT);
}

void RsaCrypter::GetHash(std::vector<unsigned char>& result) const
{
	//result.assign(&this->mKeyHash[0], this->mKeyHash + sizeof(this->mKeyHash)/sizeof(this->mKeyHash[0]) - 1);
}
    
int RsaCrypter::PublicEncrypt(unsigned char * data,int data_len,unsigned char *key, unsigned char *output) {
    int result = RSA_public_encrypt(data_len,data,output,mRsaKeys.get(),PADDING);
    return result;
}
    
int RsaCrypter::PrivateDecrypt(unsigned char * enc_data,int data_len,unsigned char *key, unsigned char *output) {
    int result = RSA_private_decrypt(data_len,enc_data,output,mRsaKeys.get(),PADDING);
    return result;
}

bool RsaCrypter::Crypt(const std::vector<unsigned char>& input, std::vector<unsigned char>& output, const int enc) const
{
	if (this->IsInitialized() && !input.empty())
	{
        
       /*
        
		if (enc == RSA_F_RSA_EAY_PUBLIC_ENCRYPT)
            PublicEncrypt
        
		else if (enc == RSA_F_RSA_EAY_PRIVATE_DECRYPT)
            PrivateDecrypt
			
		*/return true;
	}
	return false;
}

}
