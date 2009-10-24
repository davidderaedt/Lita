package com.dehats.sqla.model
{
	import com.dehats.air.sqlite.SQLiteDBHelper;
	import com.dehats.air.sqlite.SimpleEncryptionKeyGenerator;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	[Bindable]
	public class MainModel extends EventDispatcher
	{
		// Events
		public static const TABLE_SELECTED:String = "tableSelected";
		public static const DB_CREATED:String = "dbSelected";

		// DataBase		
		public static const LEGACY_ENCRYPTION_KEY_HASH:String = "eb142b0cae0baa72a767ebc0823d1be94e14c5bfc52d8e417fc4302fceb6240c";
		
		public var db:SQLiteDBHelper = new SQLiteDBHelper();
		public var dbFile:File ;
		public var docTitle:String;		
		public var dbTables:Array ;
		public var dbIndices:Array;
		public var dbViews:Array;		
		public var selectedTable:SQLTableSchema;
		public var tableRecords:Array;		
		public var selectedColumn:SQLColumnSchema;
		public var selectedRecord:Object;
				
		private var schemas:SQLSchemaResult;
						
		public function MainModel()
		{
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
						Alert.show(e.message, "Error");
						return false;
					}					
				}
				
			}


			// Now we can open the db			
			try
			{
				db.openDBFile(dbFile, key);
			}
			catch(error:SQLError)
			{
				var notes:String="";
				if(error.errorID==3138) notes="If the file is an encrypted database file, please provide a valid password.";
				Alert.show(error.message+"\n\n"+notes, error.message);
				return false;
			}
			
			// We successfully opened the db
			
			docTitle = dbFile.name+' - '+ (dbFile.size/1024)+' Kb' ;
			
			loadSchema();
			
			if( dbTables && dbTables.length>0) selectTable(dbTables[0] );
			
			return true;
		}
		
		public function createDBFile(pFile:File, pPassword:String=""):void
		{
			dbFile = pFile ;
			
			var key:ByteArray;
			
			if(pPassword && pPassword.length>0)
			{
				try
				{
					key = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword);					
				}
				catch(e:ArgumentError)
				{
					Alert.show(e.message, "Error");
					return;
				}
			}
			
			try
			{
				db.openDBFile(dbFile, key);
			}
			catch(error:SQLError)
			{
				Alert.show(error.message+"\n"+error.details);
				return;
			}
			
			if(key!=null) showEncryptionKey(key, true);
			
			else dispatchEvent(new Event(DB_CREATED));
			
			docTitle = dbFile.name+' - '+ (dbFile.size/1024)+' Kb' ;
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
				Alert.show(e.message, "Error");
				return;
			}			
			
			var success:Boolean = db.reencrypt(key);
			
			if(success) showEncryptionKey(key, false);
			else  Alert.show("The database could not be re-encrypted, probably because it was not encrypted in the first place. Only databases which were encrypted when created can be re-encrypted.", "Error");
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

		private function showEncryptionKey(key:ByteArray, isDBCreation:Boolean):void
		{
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes(key);
			
			// we want to dispatch the db created event only if a db was actually created
			var callback:Function = null;			
			if(isDBCreation) callback=onEncryptionKeyDialogClosed;
			
			Alert.show("Here's your database's encryption key (Base64 encoded). Use this key to open your DB in other applications. (Use your password to open your DB in Lita.)\n"+encoder.toString(), 
				"Encryption done !",
				Alert.OK,
				null, 
				callback);
		}
		
		private function onEncryptionKeyDialogClosed(pEvt:CloseEvent):void
		{
			dispatchEvent(new Event(DB_CREATED));
		}
		
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
		
		public function exportDB(pData:Boolean=true):String
		{
			
			var str:String="";
			
			for ( var i:int = 0 ; i < dbTables.length ; i++)
			{
				var table:SQLTableSchema = dbTables[i];
				str+= table.sql + ";" +File.lineEnding+File.lineEnding;
				
				if(pData) str+= db.exportTableRecords( table)+File.lineEnding+File.lineEnding;
				
			}
			
			return str;
		}
		
		// Tables
		
		public function selectTable(pTable:SQLTableSchema):void
		{
			if(pTable==null)
			{
				Alert.show("Cannot select null table", "Error");
				return;
			} 
			
			selectedTable = pTable ;
			selectedColumn = null ;
			selectedRecord = null ;
			refreshRecords();
			dispatchEvent( new Event(TABLE_SELECTED));
		}
		
		public function createTable(pTableName:String, pDefaultCol:String):void
		{
			db.createTable(pTableName, [ pDefaultCol]);
			
			loadSchema();
			var table:SQLTableSchema = getTableByName( pTableName);
			if(table) selectTable(table);
		}
		
		public function copyTable(pNewName:String, pCopyData:Boolean=true):void
		{
			db.copyTable( selectedTable, pNewName, pCopyData);
			
			loadSchema();
			selectTable( getTableByName( pNewName));
		}

		public function dropCurrentTable():void
		{
			db.dropTable(selectedTable);
			loadSchema();
			selectedTable = null ;
			selectedColumn = null ;
			selectedRecord = null ;
			tableRecords = [];
		}

		public function emptyCurrentTable():void
		{
			var tableName:String = selectedTable.name;
			db.emptyTable(selectedTable);
			loadSchema();
			selectedRecord = null ;
			tableRecords = [];
			selectTable(getTableByName( tableName));
		}

		
		public function renameTable(pName:String):void
		{
			db.renameTable( selectedTable, pName);
			loadSchema();
			selectTable( getTableByName(pName));
		}
		
		
		private function getTableByName(pName:String):SQLTableSchema
		{
			for ( var i:int = 0 ; i < dbTables.length ; i++)
			{
				var t:SQLTableSchema = dbTables[i];
				if(t.name == pName) return t;
			}
			return null ;
		}
		
		// Columns
		
		public function addColumn(pName:String, pDataType:String, pAllowNull:Boolean, pUnique:Boolean, pDefault:String):void
		{
			var tableName:String = selectedTable.name;
			db.addColumn(selectedTable, pName, pDataType, pAllowNull, pUnique, pDefault);
			loadSchema();
			selectTable(getTableByName( tableName));
			selectedColumn = selectedTable.columns[ selectedTable.columns.length-1 ];
		}
		
		public function removeColumn():void
		{
			var tableName:String = selectedTable.name;
			db.removeColumn(selectedTable, selectedColumn.name);
			loadSchema();
			selectTable(getTableByName( tableName));
			selectedColumn = null;
		}

		public function renameColumn(pName:String):void
		{
			var tableName:String = selectedTable.name;
			var j:int = selectedTable.columns.indexOf(selectedColumn);
			db.renameColumn(selectedTable, selectedColumn.name, pName);
			loadSchema();
			selectTable(getTableByName( tableName));
			selectedColumn = selectedTable.columns[j];
		}
		
		// Indices
		
		public function addIndex(pName:String):void
		{
			db.createIndex(pName, selectedTable, selectedColumn);
			loadSchema();
		}
		
		public function removeIndex(pIndex:SQLIndexSchema):void
		{
			db.removeIndex(pIndex.name);
			loadSchema();
		}
		
		// Data operations

		public function selectRecord(pData:Object):void
		{
			selectedRecord = pData;
		}
		
		public function updateRecord(pVo:Object):void
		{
			var i:int = tableRecords.indexOf(selectedRecord);
			db.updateRecord(selectedTable, selectedRecord, pVo);
			refreshRecords();
			selectRecord( tableRecords[i] );
		}
		
		public function createRecord(pVo:Object):void
		{
			db.createRecord(selectedTable, pVo);
			refreshRecords();
			
			if(tableRecords && tableRecords.length>0)
			{
				selectRecord( tableRecords[tableRecords.length-1] );
			}
			
		}
		
		public function deleteRecord():void
		{
			db.deleteRecord( selectedTable, selectedRecord);
			refreshRecords();
		}
		
		public function refreshRecords():void
		{
			if(selectedTable!=null)	tableRecords = db.getTableRecords(selectedTable);
			selectedRecord=null;
		}
		
		public function exportRecords():String
		{
			return db.exportTableRecords( selectedTable);
		}
		
	}
}