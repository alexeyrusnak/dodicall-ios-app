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

#include "stdafx.h"
#include "WavePlayer.h"
#include "LogManager.h"

#ifdef _WIN32
#define USE_MMSYSTEM
#endif

#ifdef USE_MMSYSTEM
#include <mmsystem.h>
#endif

namespace dodicall
{

void OnLinphonePlayEnd(LinphonePlayer* player, void* data)
{
}

WavePlayer::WavePlayer(LinphoneCore* lc, const char* filename): mPlayer(NULL)
{
#ifdef USE_MMSYSTEM
	PlaySoundA(filename, NULL, SND_FILENAME | SND_ASYNC);
#else
	this->mPlayer = linphone_core_create_local_player(lc, NULL, NULL, 0);
	if (this->mPlayer)
	{
		int opened = linphone_player_open(this->mPlayer, filename, OnLinphonePlayEnd, NULL);
		if (!opened)
			linphone_player_start(this->mPlayer);
	}
#endif
}

WavePlayer::~WavePlayer()
{
#ifdef USE_MMSYSTEM
	PlaySoundA(NULL, NULL, 0);
#else
	if (this->mPlayer)
	{
		linphone_player_destroy(this->mPlayer);
		this->mPlayer = NULL;
	}
#endif
}

}