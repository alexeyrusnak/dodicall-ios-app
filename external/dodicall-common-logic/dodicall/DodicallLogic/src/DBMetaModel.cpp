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
#include "DBMetaModel.h"

namespace dodicall
{
namespace dbmodel
{

DBFieldMetaModel::DBFieldMetaModel()
{
}
DBFieldMetaModel::DBFieldMetaModel(const char* name, DBFieldType type, unsigned length, bool mandatory, bool primary, bool autoincrement, const char* defval, const char* foreignto):
	Name(name), Type(type), Length(length), Mandatory(mandatory), Primary(primary), AutoIncrement(autoincrement), Default(defval?defval:""), ForeignTo(foreignto?foreignto:"")
{
}

DBTableIndexMetaModel::DBTableIndexMetaModel(bool uni): Unique(uni)
{
}
DBTableIndexMetaModel::DBTableIndexMetaModel(bool uni, const std::vector<std::string>& cnames): Unique(uni), ColumnNames(cnames)
{
}

DBTableMetaModel::DBTableMetaModel(const char* name): Name(name)
{
}
DBTableMetaModel::DBTableMetaModel(const char* name, const DBFieldMetaList& fields): Name(name), Fields(fields)
{
}
DBTableMetaModel::DBTableMetaModel(const char* name, const DBFieldMetaList& fields, const DBTableIndexMetaList& indexes): Name(name), Fields(fields), Indexes(indexes)
{
}
DBTableMetaModel::DBTableMetaModel(const char* name, const DBFieldMetaList& fields, const DBTableIndexMetaList& indexes, const DBTableCheckList& checks, const char* primaryKeyType): Name(name), Fields(fields), Indexes(indexes), Checks(checks), PrimaryKeyType(primaryKeyType)
{
}

DBViewMetaModel::DBViewMetaModel(const char* name, const char* select): Name(name), Select(select)
{
}

DBMetaModel::DBMetaModel(): Version(0)
{
}

}
}
