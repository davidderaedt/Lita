/*
    Lita: A free and open source SQLite database administration tool for Windows, MacOSX and Linux.
    Copyright (C) 2010  David Deraedt

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
  */
package com.dehats.sqla.model
{
	import com.dehats.air.sqlite.SQLiteDBHelper;
	import com.dehats.air.sqlite.SQLiteErrorEvent;
	import com.dehats.air.sqlite.SimpleEncryptionKeyGenerator;
	import com.dehats.sqla.events.EncryptionErrorEvent;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	[Bindable]
	public class MainModel extends EventDispatcher
	{

		// DataBase		
		public static const LEGACY_ENCRYPTION_KEY_HASH:String = "eb142b0cae0baa72a767ebc0823d1be94e14c5bfc52d8e417fc4302fceb6240c";
		
		public var dbFile:File ;
		public var base64Key:String;
		public var dbTables:Array ;
		public var dbIndices:Array;
		public var dbViews:Array;
		public var tableRecords:Array;		
				
		private var db:SQLiteDBHelper;
		private var schemas:SQLSchemaResult;
						
		public function MainModel()
		{
			db = new SQLiteDBHelper();
			db.addEventListener(SQLiteErrorEvent.EVENT_ERROR, onSQliteError);
		}
		
		private function onSQliteError(pEvt:SQLiteErrorEvent):void
		{
			dispatchEvent(pEvt);
		}
				
		
		public function openDBFile(pFile:File, isNew:Boolean=false, pPassword:String=""):Boolean
		{
			
			dbFile = pFile ;
			
			var key:ByteArray;
			
			// First, if we have a password, we'll generate a key
			if (pPassword && pPassword.length > 0)
			{
							
				// if they entered the Base64 encryption key instead of a password
				if (pPassword.length == 24 && pPassword.lastIndexOf("==") == 22)
				{
					var decoder:Base64Decoder = new Base64Decoder();
					decoder.decode(pPassword);
					key = decoder.toByteArray();
				}
				// if it's a legacy encrypted db
				else if (pPassword == LEGACY_ENCRYPTION_KEY_HASH) 
				{
					key = legacyGenerateEncryptionKey(pPassword);
				}				
				
				// for every other cases
				else
				{
					try
					{
						key = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword);					
					}
					catch(e:ArgumentError)
					{
						dispatchEvent( new EncryptionErrorEvent(EncryptionErrorEvent.EVENT_ENCRYPTION_ERROR, e));
						return false;
					}					
				}
				
			}


			// Now we can open the db
			var success:Boolean = db.openDBFile(dbFile, key);
			
			if(success==false) return false;
 			
			// We successfully opened the db
			
			loadSchema(); 
				
			return true;				
			
		}
		
		
		
		public function createDBFile(pFile:File, pPassword:String=""):Boolean
		{
			dbFile = pFile ;
			
			// First, create the encryption if a password was provided
			
			var key:ByteArray;
			
			if(pPassword && pPassword.length>0)
			{
				try
				{
					key = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword);					
				}
				catch(e:ArgumentError)
				{
					dispatchEvent( new EncryptionErrorEvent(EncryptionErrorEvent.EVENT_ENCRYPTION_ERROR, e));
					return false;
				}
			}
			
			// then create the db
			
			var success:Boolean = db.openDBFile(dbFile, key);
			
			if(success==false) return false;			
			
			if(key!=null) getBase64EncryptionKey(key);
			
			return true;
			
		}
		
		
		
		public function reencrypt(pPassword:String):void
		{
			if( dbFile==null ) return;
			
			try
			{
				var key:ByteArray = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword);					
			}
			catch(e:ArgumentError)
			{
				dispatchEvent( new EncryptionErrorEvent(EncryptionErrorEvent.EVENT_ENCRYPTION_ERROR, e));
				return;
			}			
			
			
			var success:Boolean = db.reencrypt(key);
			
			if(success==false) return;
			
			getBase64EncryptionKey(key);
			
		}

		// Borrowed from Paul Roberston's EncryptionKeyGenerator
		private function legacyGenerateEncryptionKey(hash:String):ByteArray
		{
			var result:ByteArray = new ByteArray();
			
			// select a range of 128 bits (32 hex characters) from the hash
			// In this case, we'll use the bits starting from position 17
			for (var i:uint = 0; i < 32; i += 2)
			{
				var position:uint = i + 17;
				var hex:String = hash.substr(position, 2);
				var byte:int = parseInt(hex, 16);
				result.writeByte(byte);
			}
			
			return result;
		}

		private function getBase64EncryptionKey(key:ByteArray):void
		{
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes(key);
			base64Key = encoder.toString();
						
		}
	
		/**
		 * 
		 * @param pPassword
		 * @return the base64 string
		 * not used for now
		 */		
		public function getBase64FromPassword(pPassword:String):String
		{
			var key:ByteArray = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword);
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes(key);
			return encoder.toString();
		}

		// STRUCTURE
		
		private function loadSchema():void
		{

			schemas =  db.getSchemas();				
			
			if(schemas==null) return;
			
			dbTables = schemas.tables;
			dbIndices = schemas.indices;
			dbViews = schemas.views;
			
			if(dbTables) dbTables.sortOn("name", Array.CASEINSENSITIVE);
			if(dbIndices) dbIndices.sort(sortIndices);
		}
		
		private function sortIndices(a:SQLIndexSchema, b:SQLIndexSchema):Number
		{
			var aTable:String = a.table.toLowerCase();
			var bTable:String = b.table.toLowerCase();
			
			// sort alphabetically by table name, then index name
			if (aTable < bTable)
			{
				return -1;
			}
			
			if (aTable > bTable)
			{
				return 1;
			}
			
			var aName:String = a.name.toLowerCase();
			var bName:String = b.name.toLowerCase();
			
			if (aName < bName)
			{
				return -1;
			}
			
			if (aName > bName)
			{
				return 1;
			}
			
			return 0;
		}
		
		public function compact():Boolean
		{
			if(dbFile==null) return false;
			
			db.compact();				
			
			return true;
		}
		
		public function exportDB(pExportData:Boolean=true):String
		{
			
			var str:String="";
			
			for ( var i:int = 0 ; i < dbTables.length ; i++)
			{
				var table:SQLTableSchema = dbTables[i];
				str+= table.sql + ";" +File.lineEnding+File.lineEnding;
				
				if(pExportData)
				{
					 str+= db.exportTableRecords( table)+File.lineEnding+File.lineEnding;										
				}
				
			}
			
			return str;
		}
		
		public function executeStatement(pStatement:String):SQLResult
		{
			return db.executeStatement(pStatement);
		}
		
		// Tables		
		
		public function createTable(pTableName:String, pDefaultCol:String):SQLTableSchema
		{
			db.createTable(pTableName, [ pDefaultCol]);
			
			loadSchema();
			
			return getTableByName( pTableName);
			
		}
		
		
		
		public function copyTable(pTable:SQLTableSchema, pNewName:String, pCopyData:Boolean=true):SQLTableSchema
		{
			db.copyTable( pTable, pNewName, pCopyData);			
			
			loadSchema();
			
			return getTableByName( pNewName);
		}



		public function dropTable(pTable:SQLTableSchema):void
		{
			
			db.dropTable(pTable);
			
			loadSchema();

			tableRecords = [];
		}

		public function emptyTable(pTable:SQLTableSchema):void
		{			
			db.emptyTable(pTable);			
			tableRecords = [];
		}

		
		public function renameTable(pTable:SQLTableSchema, pName:String):SQLTableSchema
		{
			db.renameTable( pTable, pName);	
			loadSchema();
			return getTableByName(pName);
		}
		
		
		public function getTableByName(pName:String):SQLTableSchema
		{
			for ( var i:int = 0 ; i < dbTables.length ; i++)
			{
				var t:SQLTableSchema = dbTables[i];
				if(t.name == pName) return t;
			}
			return null ;
		}
		
		// Columns
		
		public function addColumn(pTable:SQLTableSchema, pName:String, pDataType:String, pAllowNull:Boolean, pUnique:Boolean, pDefault:String):SQLTableSchema
		{
			var tableName:String = pTable.name;
			db.addColumn(pTable, pName, pDataType, pAllowNull, pUnique, pDefault);
			loadSchema();
			return getTableByName(tableName);
		}
		
		public function removeColumn(pTable:SQLTableSchema, pColName:String):SQLTableSchema
		{			
			var tableName:String = pTable.name;
			db.removeColumn(pTable, pColName);
			loadSchema();
			return getTableByName(tableName);
		}

		public function renameColumn(pTable:SQLTableSchema, pCol:SQLColumnSchema, pName:String):SQLTableSchema
		{
			var tableName:String = pTable.name;
			db.renameColumn(pTable, pCol.name, pName);
			loadSchema();
			return getTableByName(tableName);
		}
		
		// Indices
		
		public function addIndex(pTable:SQLTableSchema, pCol:SQLColumnSchema, pName:String):void
		{
			db.createIndex(pName, pTable, pCol);
			loadSchema();
		}
		
		public function removeIndex(pIndex:SQLIndexSchema):void
		{
			db.removeIndex(pIndex.name);
			loadSchema();
		}
		
		// Data operations
		
		public function updateRecord(pTable:SQLTableSchema, pOriginal:Object, pVo:Object):Object
		{			
			var i:int = tableRecords.indexOf(pOriginal);
			db.updateRecord(pTable, pOriginal, pVo);
			refreshRecords(pTable);
			return  tableRecords[i];
		}
		
		public function createRecord(pTable:SQLTableSchema, pVo:Object):Object
		{
			db.createRecord(pTable, pVo);
			refreshRecords(pTable);
			
			if(tableRecords && tableRecords.length>0)
			{
				return tableRecords[tableRecords.length-1] ;
			}
			return null;
		}
		
		public function deleteRecord(pTable:SQLTableSchema, pObj:Object):void
		{
			db.deleteRecord( pTable, pObj);
			refreshRecords(pTable);
		}
		
		public function refreshRecords(pTable:SQLTableSchema):void
		{
			if(pTable!=null)	tableRecords = db.getTableRecords(pTable);
			else tableRecords=[];
		}
		
		public function exportRecords(pTable:SQLTableSchema):String
		{
			return db.exportTableRecords( pTable);
		}
		
	}
}
