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

#include "DBMetaModel.h"

#include "ICrypter.h"
#include "Logger.h"

namespace dodicall
{

using namespace dbmodel;

class DBValue
{
public:
	DBFieldType Type;

	int IntegerValue;
	int64_t Int64Value;
	double RealValue;
	std::string StringValue;

	DBValue();
	explicit DBValue(int ival);
	explicit DBValue(int64_t i64val);
	explicit DBValue(double dval);
	explicit DBValue(std::string sval);
	explicit DBValue(const char* sval);
	explicit DBValue(bool bval);

	operator int(void) const;
	operator int64_t(void) const;
	operator double(void) const;
	operator std::string(void) const;
	operator bool(void) const;
};
typedef std::vector<DBValue> DBValueList;
typedef std::map<std::string,DBValue> DBValueMap;

class DBRow
{
public:
	DBValueMap Values;
};
typedef std::vector<DBRow> DBRowList;

class DBResult
{
public:
	DBRowList Rows;
};

class DbAccessor
{
private:
	sqlite3* mConnection;
	const ICrypter* mCrypter;

	typedef std::map<std::string,DBFieldMetaList> PrepareStatementsMap;
	mutable PrepareStatementsMap mPreparedStatements;

	mutable boost::thread_specific_ptr<sqlite3_int64> mLastInsertRowid;

protected:
	DBMetaModel mModel;
	
	typedef boost::tuple<unsigned int, boost::function<bool(bool)> > MigrationScriptType;
	std::vector<MigrationScriptType> mMigrationScripts;

	mutable boost::recursive_mutex mMutex;

	DbAccessor(void);
	~DbAccessor(void);

public:
	void SetupVersion(unsigned ver);

	virtual bool Open(const boost::filesystem::path& filename, const ICrypter* crypter = 0);
	virtual void Close(void);

	bool IsOpened(void) const;

	template <class T> bool SaveSetting(const char *key, T value)
	{
		return this->Execute("insert or replace into SETTINGS(NAME,VALUE) values(?,?)", boost::assign::list_of(DBValue(key))(DBValue(value)));
	}
	template <class T> T GetSetting(const char *key, T defValue)
	{
		DBResult dbresult;
		if (this->Execute("select VALUE from SETTINGS where NAME = ?", boost::assign::list_of(DBValue(key)), &dbresult) && !dbresult.Rows.empty())
			return (T)dbresult.Rows.at(0).Values["VALUE"];
		return defValue;
	}

protected:
	virtual bool Setup();

	sqlite3_stmt* PrepareStatement(const char* statement, DBFieldMetaList& metaList) const;
	bool Execute(const char* statement, const DBValueList& parameters = DBValueList(), DBResult* result = 0) const;

	bool MakeTable (const DBResult& masterData, const DBTableMetaModel& model);

	sqlite3_int64 GetLastInsertRowid(void) const;

	std::string Encrypt(const std::string& input) const;
	std::string Decrypt(const std::string& input) const;

	virtual Logger& GetLogger(void) const = 0;
};

LoggerStream operator << (LoggerStream s, const DBValueList& input);
LoggerStream operator << (LoggerStream s, const DBResult& input);

}
