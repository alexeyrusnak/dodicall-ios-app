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
#ifndef LOGIC_SOUND_DEVICE_MODEL_H
#define LOGIC_SOUND_DEVICE_MODEL_H

#include <string>
#include <set>

namespace dodicall
{
namespace model
{

typedef std::string DeviceId;

class DODICALLLOGICAPI SoundDeviceModel
{
public:
	DeviceId DevId;
	bool CanCapture;
	bool CanPlay;
	bool CurrentRinger;
	bool CurrentPlayback;
	bool CurrentCapture;	
	bool operator < (const SoundDeviceModel& other) const { return DevId < other.DevId;  }
};

typedef std::set<SoundDeviceModel> SoundDeviceModelSet;

}
}
#endif LOGIC_SOUND_DEVICE_MODEL_H
