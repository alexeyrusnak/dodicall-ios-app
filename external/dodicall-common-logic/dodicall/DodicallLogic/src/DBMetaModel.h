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

namespace dodicall
{
namespace dbmodel
{

enum DBFieldType
{
	DBFieldTypeUnknown = 0,
	DBFieldTypeInteger,
	DBFieldTypeReal,
	DBFieldTypeText,
	DBFieldTypeDatetime,
	DBFieldTypeNull
};

class DBFieldMetaModel
{
public:
	std::string Name;
	DBFieldType Type;
	unsigned Length;
	bool Mandatory;
	bool Primary;
	bool AutoIncrement;
	std::string Default;
	std::string ForeignTo;

	DBFieldMetaModel();
	DBFieldMetaModel(const char* name, DBFieldType type, unsigned length = 0, bool mandatory = false, bool primary = false, bool autoincrement = false, const char* defval = 0, const char* foreignto = 0);
};
typedef std::vector<DBFieldMetaModel> DBFieldMetaList;

class DBTableIndexMetaModel
{
public:
	bool Unique;
	std::vector<std::string> ColumnNames;

	DBTableIndexMetaModel(bool uni = false);
	DBTableIndexMetaModel(bool uni, const std::vector<std::string>& cnames);
};
typedef std::vector<DBTableIndexMetaModel> DBTableIndexMetaList;

typedef std::vector<std::string> DBTableCheckList;

class DBTableMetaModel
{
public:
	std::string Name;
	DBFieldMetaList Fields;
	DBTableIndexMetaList Indexes;
	DBTableCheckList Checks;
	std::string PrimaryKeyType;

	DBTableMetaModel(const char* name);
	DBTableMetaModel(const char* name, const DBFieldMetaList& fields);
	explicit DBTableMetaModel(const char* name, const DBFieldMetaList& fields, const DBTableIndexMetaList& indexes);
	DBTableMetaModel(const char* name, const DBFieldMetaList& fields, const DBTableIndexMetaList& indexes, const DBTableCheckList& checks, const char* primaryKeyType = "");
};
typedef std::vector<DBTableMetaModel> DBTableMetaList;

class DBViewMetaModel
{
public:
	std::string Name;
	std::string Select;

	DBViewMetaModel(const char* name, const char* select);
};
typedef std::vector<DBViewMetaModel> DBViewMetaList;

class DBMetaModel
{
public:
	unsigned Version;
	DBTableMetaList Tables;
	DBViewMetaList Views;

	DBMetaModel();
};

inline bool operator == (const DBFieldMetaModel& f1, const DBFieldMetaModel& f2)
{
	return (f1.Name == f2.Name && f1.Type == f2.Type && f1.Length == f2.Length && f1.Mandatory == f2.Mandatory && f1.Primary == f2.Primary && f1.ForeignTo == f2.ForeignTo);
}
inline bool operator != (const DBFieldMetaModel& f1, const DBFieldMetaModel& f2)
{
	return !(f1.Name == f2.Name && f1.Type == f2.Type && f1.Length == f2.Length && f1.Mandatory == f2.Mandatory && f1.Primary == f2.Primary && f1.ForeignTo == f2.ForeignTo);
}

}
}
