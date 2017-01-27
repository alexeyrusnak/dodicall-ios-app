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

#include <stdio.h>

#include "ChatMessageDbModel.h"
#include "DeviceSettingsModel.h"
#include "CallModel.h"

namespace dodicall
{
// REVIEW SV->AM: перенести содержимое в namespace model, dbmodel должен содержать только
// модельные классы сущностей из таблиц БД
namespace dbmodel
{
    
enum PushNotificationType
{
    NotificationLocal = 0,
    NotificationRemote
};

enum AlertCategoryType
{
    XMC = 0, //Xmpp Message Category
    XMNAC, //Xmpp Message No Answer Category
    SCC,
    PICC, //Push Incoming Call Category
    XMMIC, //Xmpp Message Muc Invite Category
    PMICC, //Push missed incoming call category
    XMCIC, //Xmpp message contact invite category
    XCONTACT 
};
    
enum AlertActionType //main action type in push notification
{
    AlertActionTypeLook = 0,    //Look
    AlertActionTypeAnswer,      //Answer
    AlertActionTypeOpen,        //Open
    AlertActionTypeCancel,
    AlertActionTypeCall         //Call
};

enum AlertSoundNameType //main action type in push notification
{
    AlertSoundNameTypeMessage = 0,  //Sound for message
    AlertSoundNameTypeCall       //Sound for incoming call
};
    
class UserNotificationMetaModel
{
public:
    std::string From; // [26/02/16 13:22:09] Alexey Rusnak: если xmpp, то сокращенный jid
                      // [26/02/16 13:22:33] Alexey Rusnak: если sip то сокращенный дефолтный сип аккаунт
                      // [26/02/16 13:23:04] Alexey Rusnak: по "сокращенный" я имею в виду все, что до @
    model::UserNotificationType Type; //:userNotificationTypes.sip, // Type of data
	
	std::string ChatRoomJid; // Chat room jid. Can be undefined
	std::string ChatRoomTitle;
	int ChatRoomCapacity;
	ChatMessageType ChatMessageType;
	DateType ChatMessageSendTime;
    model::CallIdType CallId;

	UserNotificationMetaModel(void);
};

class PushNotificationModel
{
public:
    std::string AlertTitle;
    std::string AlertBody;
	
    AlertActionType AlertAction; // Это текст, типа "Ответить" или "Посмотреть", плюс другие языки
	bool HasAction; // если true,то нотификация кликабельна и отображается текст AlertAction в нотификации
    AlertSoundNameType SoundName;
    int IconBadge; // число, которое отобразится на иконке приложения
    int ExpireInSec;
    PushNotificationType DType; // тип нотификации: local или remote (push), назван специально как у  Руснака
    //> Член Type есть и в MetaStruct? Он точно нужен и хдесь и там???
    //да, нужен. MetaStruct распарсивается непосредственно на устройстве (нашим приложением)
	model::ServerSettingType Type/*sip*/; // тип нотификции: sip или xmpp - нужен нашему пуш сервису для правильного определения адресата сообщения
    UserNotificationMetaModel MetaStruct;
    AlertCategoryType AType;
    
    PushNotificationModel();
    ~PushNotificationModel();
};

class PushNotificationContactModel {
public:
	// это поле принимает значения "sip" и "xmpp", стоит ли заводить перечисление с такими значениями когда уже есть ServerSettingType
	std::string Type;
    std::string Value;
};
    
class FullNameContactModel {
public:
        std::string firstName;
        std::string lastName;
        std::string middleName;
    };

}
    
}
/* PushNotificationModel_h */
