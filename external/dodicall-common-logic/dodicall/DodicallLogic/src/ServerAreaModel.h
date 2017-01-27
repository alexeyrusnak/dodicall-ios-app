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

namespace dodicall
{
namespace model
{

class ServerAreaModel 
{
public:
    std::string AsUrl; // url
    std::string LcUrl; // account url
    std::string NameRu; // name (ru)
    std::string NameEn; // name (en)
    std::string Reg; // Регистрация
    std::string ForgotPwd; // Восстановление пароля
    std::string PushUrl; // Url push-сервера
};

typedef std::map <int, ServerAreaModel> ServerAreaMap;

}
    
}