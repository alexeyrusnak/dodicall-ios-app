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
#include "DBAccessor.h"

#include "LogManager.h"

#include "FilesystemHelper.h"
#include "Version.h"

namespace dodicall
{

DBValue::DBValue(): Type(DBFieldTypeUnknown), IntegerValue(0), Int64Value(0), RealValue(0.0)
{
}
DBValue::DBValue(int ival): Type(DBFieldTypeInteger), IntegerValue(ival), Int64Value(0), RealValue(0.0)
{
}
DBValue::DBValue(int64_t i64val): Type(DBFieldTypeDatetime), IntegerValue(0), Int64Value(i64val), RealValue(0.0)
{
}
DBValue::DBValue(double dval): Type(DBFieldTypeReal), IntegerValue(0), Int64Value(0), RealValue(dval)
{
}
DBValue::DBValue(std::string sval): Type(DBFieldTypeText), IntegerValue(0), Int64Value(0), RealValue(0.0), StringValue(sval)
{
}
DBValue::DBValue(const char* sval): Type(DBFieldTypeText), IntegerValue(0), Int64Value(0), RealValue(0.0), StringValue(sval)
{
}
DBValue::DBValue(bool bval): Type(DBFieldTypeInteger), IntegerValue((int)bval), Int64Value(0), RealValue(0.0)
{
}

DBValue::operator int(void) const
{
	return this->IntegerValue;
}
DBValue::operator int64_t(void) const
{
	return this->Int64Value;
}
DBValue::operator double(void) const
{
	return this->RealValue;
}
DBValue::operator std::string(void) const
{
	return this->StringValue;
}
DBValue::operator bool(void) const
{
	return (bool)this->IntegerValue;
}


DbAccessor::DbAccessor(void): mConnection(0), mCrypter(0)
{
	this->mModel.Tables.push_back(DBTableMetaModel("DODICALL_META",boost::assign::list_of
			(DBFieldMetaModel("VERSION",DBFieldTypeInteger,0,true,true))
			(DBFieldMetaModel("INSTALLED",DBFieldTypeDatetime,0,true,false,false,"(datetime('now','localtime'))")
		)
	));
	this->mModel.Tables.push_back(DBTableMetaModel("SETTINGS",boost::assign::list_of
		(DBFieldMetaModel("NAME",DBFieldTypeText,64,true,true))
		(DBFieldMetaModel("VALUE",DBFieldTypeText,0))
	));
}
DbAccessor::~DbAccessor(void)
{
	this->Close();
}

void DbAccessor::SetupVersion(unsigned ver)
{
	this->mModel.Version = ver;
}

bool DbAccessor::Open(const boost::filesystem::path& filename, const ICrypter* crypter)
{
	int threadsafeMode = sqlite3_threadsafe();
	switch (threadsafeMode)
	{
	case 0:
		this->GetLogger()(LogLevelWarning) << "Sqlite was build in non threadsafe mode!";
		break;
	default:
		this->GetLogger()(LogLevelInfo) << "Sqlite was build with threadsafe mode " << threadsafeMode;
		break;
	}

	this->mCrypter = crypter;
	this->Close();

	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);

	int flags = SQLITE_OPEN_READWRITE;
	if (!boost::filesystem::exists(filename))
		flags |= SQLITE_OPEN_CREATE;

	int result = sqlite3_open_v2(FilesystemHelper::PathToString(filename).c_str(),&this->mConnection,flags,0);
	if (result == SQLITE_OK)
	{
		this->GetLogger()(LogLevelInfo) << "Database '" << filename << "' successfully opened";
		return this->Setup();
	}
	this->GetLogger()(LogLevelError) << "Failed to open database '" << filename << "'";
	return false;
}

void DbAccessor::Close(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mConnection)
	{
		this->mPreparedStatements.clear();
		sqlite3_close(this->mConnection);
		this->mConnection = 0;
	}
	if (this->mLastInsertRowid.get())
		this->mLastInsertRowid.release();
}

bool DbAccessor::IsOpened(void) const
{
	return (this->mConnection != 0);
}

bool DbAccessor::Execute(const char* statement, const DBValueList& parameters, DBResult* result) const
{
	if (!this->mConnection)
		return false;

	DBFieldMetaList metaList;
	sqlite3_stmt* preparedStatement = this->PrepareStatement(statement,metaList);

	Logger& logger = this->GetLogger();
	boost::scoped_ptr<DBResult> resultPtr;
	if (!result && logger.GetLevel() >= LogLevelDebug)
	{
        boost::scoped_ptr<DBResult> dbres_ptr(new DBResult());
		resultPtr.swap( dbres_ptr );
		result = resultPtr.get();
	}

	if (preparedStatement)
	{
		logger(LogLevelDebug) << "Start executing statement: " << statement;
		logger(LogLevelDebug) << parameters;

		for (int i = 0; i < parameters.size(); i++)
		{
			const DBValue& value = parameters.at(i);
			switch(value.Type)
			{
			case DBFieldTypeInteger:
				sqlite3_bind_int(preparedStatement,i+1,value.IntegerValue);
				break;
			case DBFieldTypeReal:
				sqlite3_bind_double(preparedStatement,i+1,value.RealValue);
				break;
			case DBFieldTypeText:
				sqlite3_bind_text(preparedStatement,i+1,value.StringValue.c_str(),value.StringValue.length(),0);
				break;
			case DBFieldTypeDatetime:
				sqlite3_bind_int64(preparedStatement,i+1,value.Int64Value);
				break;
			case DBFieldTypeNull:
				sqlite3_bind_null(preparedStatement,i+1);
				break;
			default:
				sqlite3_bind_null(preparedStatement,i+1);
				// TODO: log warning
				break;
			}
		}
		bool res = true;
		bool loop = true;
		bool evaluated = false;
		while(loop)
		{
			int stepResult;
			if (!evaluated)
			{
				evaluated = true;
				if (boost::to_upper_copy<std::string>(statement).find("INSERT") == 0)
				{
					static boost::mutex _mutex;
					boost::lock_guard<boost::mutex> _lock(_mutex);
					stepResult = sqlite3_step(preparedStatement);
					if (!this->mLastInsertRowid.get())
						this->mLastInsertRowid.reset(new sqlite3_int64);
					if (this->mConnection)
						*this->mLastInsertRowid = sqlite3_last_insert_rowid(this->mConnection);
				}
				else
					stepResult = sqlite3_step(preparedStatement);
			}
			else
				stepResult = sqlite3_step(preparedStatement);
			switch (stepResult)
			{
			case SQLITE_ROW:
				if (result)
				{
					DBRow row;
					int columnCount = sqlite3_data_count(preparedStatement);
					for (int i = 0; i < columnCount; i++)
					{
						DBValue value;
						value.Type = metaList.at(i).Type;
						switch(value.Type)
						{
						case DBFieldTypeInteger:
							value.IntegerValue = sqlite3_column_int(preparedStatement,i);
							value.Int64Value = (int64_t)value.IntegerValue;
							value.RealValue = (double)value.IntegerValue;
							value.StringValue = boost::lexical_cast<std::string>(value.IntegerValue);
							break;
						case DBFieldTypeReal:
							value.RealValue = sqlite3_column_double(preparedStatement,i);
							value.IntegerValue = (int)value.RealValue;
							value.Int64Value = (int64_t)value.RealValue;
							value.StringValue = boost::lexical_cast<std::string>(value.RealValue);
							break;
						case DBFieldTypeText:
							value.StringValue = std::string((const char*)sqlite3_column_text(preparedStatement,i));
							if (value.StringValue.find_first_not_of("0123456789.") == value.StringValue.npos)
								try
								{
										value.RealValue = boost::lexical_cast<double>(value.StringValue);
								}
								catch(...)
								{
								}
							if (value.StringValue.find_first_not_of("0123456789") == value.StringValue.npos)
								try
								{
									value.Int64Value = boost::lexical_cast<int64_t>(value.StringValue);
								}
								catch(...)
								{
								}
							if (value.StringValue.find_first_not_of("0123456789") == value.StringValue.npos)
								try
								{
									value.IntegerValue = boost::lexical_cast<int>(value.StringValue);
								}
								catch(...)
								{
								}
							break;
						case DBFieldTypeDatetime:
							value.Int64Value = sqlite3_column_int64(preparedStatement,i);
							value.IntegerValue = (int)value.Int64Value;
							value.RealValue = (double)value.Int64Value;
							value.StringValue = boost::lexical_cast<std::string>(value.Int64Value);
							break;
						case DBFieldTypeNull:
							{
								const char* pValue = (const char*)sqlite3_column_text(preparedStatement,i);
								value.StringValue = std::string(pValue ? pValue : "");
								
								if (value.StringValue.find_first_not_of("0123456789.") == value.StringValue.npos)
									try
									{
										value.RealValue = boost::lexical_cast<double>(value.StringValue);
										value.Type = DBFieldTypeReal;
									}
									catch(...)
									{
									}
								if (value.StringValue.find_first_not_of("0123456789") == value.StringValue.npos)
									try
									{
										value.Int64Value = boost::lexical_cast<int64_t>(value.StringValue);
										value.Type = DBFieldTypeDatetime;
									}
									catch(...)
									{
									}
								if (value.StringValue.find_first_not_of("0123456789") == value.StringValue.npos)
									try
									{
										value.IntegerValue = boost::lexical_cast<int>(value.StringValue);
										value.Type = DBFieldTypeInteger;
									}
									catch(...)
									{
									}
							}
							break;
						default:
							value.Type = DBFieldTypeNull;
							// TODO: log warning
							break;
						}
						row.Values[metaList.at(i).Name] = value;
					}
					result->Rows.push_back(row);
				}
				break;
			case SQLITE_DONE:
				logger(LogLevelDebug) << "End executing statement: " << statement;
				loop = false;
				break;
			case SQLITE_BUSY:
				boost::this_thread::sleep(boost::posix_time::millisec(100));
				break;
			case SQLITE_ERROR:
			case SQLITE_MISUSE:
				logger(LogLevelError) << "Error executing statement: " << statement;
				res = false;
				loop = false;
				break;
			default:
				res = false;
				loop = false;
				break;
			}
		}
		if (res && result)
			logger(LogLevelDebug) << *result;
		sqlite3_finalize(preparedStatement);
		return res;
	}
	else
		logger(LogLevelError) << "Prepare statement error: " << statement;
	return false;
}

bool DbAccessor::Setup()
{
	DBResult data;
	unsigned version = 0;
	if (this->Execute("select max(VERSION) as VERSION from DODICALL_META",DBValueList(),&data) && data.Rows.size() > 0)
	{
		try
		{
			version = data.Rows.at(0).Values["VERSION"].IntegerValue;
		}
		catch(...)
		{
		}
	}

	auto executeMigrationScripts = [this, version](bool afterUpgrade)
	{
		bool result = true;
		unsigned scriptsExecuted = 0;
		for (auto iter = this->mMigrationScripts.begin(); iter != this->mMigrationScripts.end(); iter++)
		{
			unsigned scriptVersion = iter->get<0>();
			if (scriptVersion > version && scriptVersion <= this->mModel.Version)
			{
				if (!iter->get<1>()(afterUpgrade))
					result = false;
				scriptsExecuted++;
			}
		}
		return (afterUpgrade ? result : (result && scriptsExecuted > 0));
	};

	bool needSetup = false;
	if (this->mModel.Version && this->mModel.Version > version)
	{
		this->GetLogger()(LogLevelInfo) << "Db version lower than application version";
		if (version)
		{
			needSetup = !executeMigrationScripts(false);
			if (!needSetup)
				this->Execute("insert or ignore into DODICALL_META(VERSION) values(?)", boost::assign::list_of(DBValue((int)this->mModel.Version)));
		}
		else
			needSetup = true;
	}
	else if (this->mCrypter && this->mCrypter->IsInitialized())
	{
		std::string dbHash = this->GetSetting<std::string>("CryptoHash", "");
		if (dbHash.empty())
			this->SaveSetting("CryptoHash", this->mCrypter->EncryptStringToBase64(this->mCrypter->GetHashBase64()));
		else if (dbHash != this->mCrypter->EncryptStringToBase64(this->mCrypter->GetHashBase64()))
		{
			data.Rows.clear();
			if (this->Execute("select name from SQLITE_MASTER where type = 'table'", DBValueList(), &data))
			{
				for (auto iter = data.Rows.begin(); iter != data.Rows.end(); iter++)
				{
					std::string name = (std::string)iter->Values.at("name");
					if (name != "DODICALL_META")
						this->Execute((std::string("drop table ") + name).c_str());
				}
			}
			this->GetLogger()(LogLevelInfo) << "Encryption key changed";
			needSetup = true;
		}
	}

	if (needSetup)
	{
		this->GetLogger()(LogLevelInfo) << "Begin database setup";
		data.Rows.clear();
		if (this->Execute("select * from SQLITE_MASTER where type = 'table'",DBValueList(),&data))
		{
			bool result = false;
			for (int i = 0; i <= 1 && !result; i++)
			{
				if (i)
					data.Rows.clear();
				result = true;
				for (DBTableMetaList::const_iterator iter = this->mModel.Tables.begin(); iter != this->mModel.Tables.end(); iter++)
				{
					if (i && iter->Name == "DODICALL_META")
						continue;
					if (i)
						this->Execute((std::string("drop table ") + iter->Name).c_str());
					if (!this->MakeTable(data, *iter))
					{
						result = false;
						break;
					}
				}
			}
			for (DBViewMetaList::const_iterator iter = this->mModel.Views.begin(); iter != this->mModel.Views.end(); iter++)
			{
				this->Execute((std::string("drop view if exists ") + iter->Name).c_str());
				if (!this->Execute((std::string("create view ") + iter->Name + " AS " + iter->Select).c_str()))
					result = false;
			}

			if (result && version)
				result = executeMigrationScripts(true);

			if (result)
				result = this->Execute("insert or ignore into DODICALL_META(VERSION) values(?)",boost::assign::list_of(DBValue((int)this->mModel.Version)));
			
			this->mPreparedStatements.clear();

			if (result)
				this->GetLogger()(LogLevelInfo) << "Database setup completed successfully";
			else
				this->GetLogger()(LogLevelError) << "Database setup error!";
			
			if (this->mCrypter && this->mCrypter->IsInitialized())
				this->SaveSetting("CryptoHash", this->mCrypter->EncryptStringToBase64(this->mCrypter->GetHashBase64()));

			return result;
		}
		this->GetLogger()(LogLevelError) << "Database setup error";
		return false;
	}
	return true;
}

inline std::string DBFieldTypeToString (DBFieldType type, unsigned length)
{
	std::string result;
	switch(type)
	{
	case DBFieldTypeInteger:
		if (length > 0)
			result = "INT("+boost::lexical_cast<std::string>(length)+")";
		else
			result = "INTEGER";
		break;
	case DBFieldTypeReal:
		result = "REAL";
		break;
	case DBFieldTypeText:
		if (length > 0)
			result = std::string("VARCHAR(")+boost::lexical_cast<std::string>(length)+")";
		else
			result = "LONGTEXT";
		break;
	case DBFieldTypeDatetime:
		result = "DATETIME";
		break;
	default:
		// TODO: log warning
		break;
	}
	return result;
}

inline DBFieldType StringToDBFieldType(int type)
{
	DBFieldType result = DBFieldTypeUnknown;
	if (type == SQLITE_INTEGER)
		result = DBFieldTypeInteger;
	else if (type == SQLITE_FLOAT)
		result = DBFieldTypeReal;
	else if (type == SQLITE_TEXT)
		result = DBFieldTypeText;
	else if (type == SQLITE_NULL)
		result = DBFieldTypeNull;
	else
	{
		// TODO: log warning
	}
	return result;
}

sqlite3_stmt* DbAccessor::PrepareStatement(const char* statement, DBFieldMetaList& metaList) const
{
	std::string strStatement = std::string(statement);
	sqlite3_stmt* preparedStatement = 0;

	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	const char* dummy = 0;
	if (sqlite3_prepare_v2(this->mConnection, statement, strlen(statement), &preparedStatement, &dummy) != SQLITE_OK || !preparedStatement)
		return 0;

	PrepareStatementsMap::const_iterator iter = this->mPreparedStatements.find(strStatement);
	if (iter != this->mPreparedStatements.end())
		metaList = iter->second;
	else
	{
		int columnCount = sqlite3_column_count(preparedStatement);
		for (int i = 0; i < columnCount; i++)
		{
			DBFieldMetaModel meta;
			meta.Name = sqlite3_column_name(preparedStatement,i);
			meta.Type = StringToDBFieldType(sqlite3_column_type(preparedStatement,i));
			metaList.push_back(meta);
		}
		this->mPreparedStatements[strStatement] = metaList;
	}
	return preparedStatement;
}

bool DbAccessor::MakeTable (const DBResult& masterData, const DBTableMetaModel& model)
{
	bool tableExists = false;
	std::string currentTableSql;
	std::set<std::string> currentTableColumns;
	for (int i = 0; i < masterData.Rows.size(); i++)
	{
		const DBRow& row = masterData.Rows.at(i);
		if (row.Values.at("type").StringValue == "table" && row.Values.at("name").StringValue == model.Name)
		{
			tableExists = true;
			currentTableSql = row.Values.at("sql").StringValue;
			boost::algorithm::to_lower(currentTableSql);
			DBFieldMetaList fields;
			if (this->PrepareStatement((std::string("select * from ") + model.Name).c_str(), fields))
			{
				for (auto iter = fields.begin(); iter != fields.end(); iter++)
					currentTableColumns.insert(iter->Name);
			}
			break;
		}
	}

	std::set<std::string> newTableColumns;
	std::string columns = "(";
	std::string foreigns, indexes;
	for (DBFieldMetaList::const_iterator iter = model.Fields.begin(); iter != model.Fields.end(); iter++)
	{
		newTableColumns.insert(iter->Name);
		if (iter != model.Fields.begin())
			columns += ", ";
		columns += iter->Name + " " + DBFieldTypeToString(iter->Type,iter->Length);
		if (iter->Mandatory)
			columns += " not null";
		else
			columns += " null";
		if (iter->Primary)
		{
			columns += " primary key";
			if (!model.PrimaryKeyType.empty())
				columns += std::string(" ") + model.PrimaryKeyType;
		}
		if (iter->AutoIncrement)
			columns += " autoincrement";
		if (!iter->Default.empty())
			columns += " default " + iter->Default;
		if (!iter->ForeignTo.empty())
			foreigns += std::string(", foreign key(")+iter->Name+") references "+iter->ForeignTo;
	}
	for (DBTableIndexMetaList::const_iterator iter = model.Indexes.begin(); iter != model.Indexes.end(); iter++)
	{
		if (iter->Unique)
		{
			indexes += ", unique(";
			for (std::vector<std::string>::const_iterator citer = iter->ColumnNames.begin(); citer != iter->ColumnNames.end(); citer++)
			{
				if (citer != iter->ColumnNames.begin())
					indexes += ",";
				indexes += *citer;
			}
			indexes += ")";
		}
	}
	std::string checks;
	for (DBTableCheckList::const_iterator iter = model.Checks.begin(); iter != model.Checks.end(); iter++)
		checks += ", check(" + *iter+")";
	columns += foreigns + indexes + checks + ")";

	std::string statement = "create table "+model.Name+columns;

	bool needToCreate = true;
	bool needToMigrate = false;
	if (tableExists)
	{
		std::string lowerStatement = statement;
		boost::algorithm::to_lower(lowerStatement);
		if (lowerStatement != currentTableSql)
		{
			if (this->Execute((std::string("alter table ") + model.Name + " rename to " + model.Name + "_OLD").c_str()))
			{
				tableExists = false;
				needToMigrate = true;
			}
			else
				this->GetLogger()(LogLevelWarning) << "Failed to rename table " << model.Name;
		}
		else
			needToCreate = false;
		if (tableExists && needToCreate)
		{
			this->Execute((std::string("drop table ") + model.Name).c_str());
			tableExists = false;
		}
	}

	if (needToCreate)
	{
		if (!this->Execute(statement.c_str(), DBValueList()))
			return false;

		for (DBTableIndexMetaList::const_iterator iter = model.Indexes.begin(); iter != model.Indexes.end(); iter++)
		{
			if (!iter->Unique)
			{
				statement = std::string("create index if not exists IDX_") + model.Name + "_" + boost::algorithm::join(iter->ColumnNames, "") + " ON " + model.Name + "(" + boost::algorithm::join(iter->ColumnNames, ",") + ")";
				if (!this->Execute(statement.c_str(), DBValueList()))
				{
					// TODO: log warning
				}
			}
		}

		if (needToMigrate)
		{
			std::set<std::string> mutualColumns;
			std::set_intersection(currentTableColumns.begin(), currentTableColumns.end(), newTableColumns.begin(), newTableColumns.end(),
				std::inserter(mutualColumns, mutualColumns.begin()));
			std::string strMutualColumns = boost::algorithm::join(mutualColumns, ",");
			statement = std::string("insert into ") + model.Name + "(" + strMutualColumns + ")  select " + strMutualColumns + " from " + model.Name + "_OLD";

			bool result = true;
			if (!this->Execute(statement.c_str()))
			{
				this->GetLogger()(LogLevelWarning) << "Failed to migrate data for table " << model.Name;
				result = false;
			}
			this->Execute((std::string("drop table ") + model.Name + "_OLD").c_str());
			return result;
		}
	}
	return true;
}

sqlite3_int64 DbAccessor::GetLastInsertRowid(void) const
{
	return (this->mLastInsertRowid.get() ? *this->mLastInsertRowid : 0);
}

std::string DbAccessor::Encrypt(const std::string& input) const
{
	if (this->mCrypter)
		return this->mCrypter->EncryptStringToBase64(input);
	return input;
}
std::string DbAccessor::Decrypt(const std::string& input) const
{
	if (this->mCrypter)
		return this->mCrypter->DecryptStringFromBase64(input);
	return input;
}

LoggerStream operator << (LoggerStream s, const DBValueList& input)
{
	std::string str = "DBValueList: (";
	for (DBValueList::const_iterator iter = input.begin(); iter != input.end(); iter++)
	{
		if (iter != input.begin())
			str += ",";
		switch (iter->Type)
		{
		case DBFieldTypeText:
			str += std::string("'") + iter->StringValue + "'";
			break;
		case DBFieldTypeInteger:
			str += boost::lexical_cast<std::string>(iter->IntegerValue);
			break;
		case DBFieldTypeDatetime:
			str += boost::lexical_cast<std::string>(iter->Int64Value);
			break;
		case DBFieldTypeReal:
			str += boost::lexical_cast<std::string>(iter->RealValue);
			break;
		default:
			// TODO: log warning
			break;
		}
	}
	str += ")";
	s << str;
	return s;
}

LoggerStream operator << (LoggerStream s, const DBResult& input)
{
	static const std::string fieldDelimitter = "\t|\t";
	std::string names;
	std::string str;
	for (DBRowList::const_iterator iter = input.Rows.begin(); iter != input.Rows.end(); iter++)
	{
		for (DBValueMap::const_iterator viter = iter->Values.begin(); viter != iter->Values.end(); viter++)
		{
			if (iter == input.Rows.begin())
			{
				if (viter != iter->Values.begin())
					names += fieldDelimitter;
				names += viter->first;
			}
			if (viter != iter->Values.begin())
				str += fieldDelimitter;
			switch (viter->second.Type)
			{
			case DBFieldTypeText:
				str += std::string("'") + viter->second.StringValue + "'";
				break;
			case DBFieldTypeInteger:
				str += boost::lexical_cast<std::string>(viter->second.IntegerValue);
				break;
			case DBFieldTypeDatetime:
				str += boost::lexical_cast<std::string>(viter->second.Int64Value);
				break;
			case DBFieldTypeReal:
				str += boost::lexical_cast<std::string>(viter->second.RealValue);
				break;
			case DBFieldTypeNull:
				if (!viter->second.StringValue.empty())
					str += std::string("'") + viter->second.StringValue + "'";
				else
					str += "NULL";
				break;
			default:
				str += "<UNKNOWN>";
				break;
			}
		}
		str += LoggerStream::endl;
	}
	s << "DBResult: " << LoggerStream::endl << names << LoggerStream::endl << str;
	return s;
}

}
