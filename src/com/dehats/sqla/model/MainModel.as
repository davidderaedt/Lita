package com.dehats.sqla.model
{
	import com.dehats.air.sqlite.SQLiteDBHelper;
	import com.dehats.air.sqlite.SQLiteErrorEvent;
	import com.dehats.air.sqlite.SimpleEncryptionKeyGenerator;
	import com.dehats.sqla.events.EncryptionErrorEvent;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	[Bindable]
	public class MainModel extends EventDispatcher
	{
		// Events
		public static const TABLE_SELECTED:String = "tableSelected";

		// DataBase		
		public static const LEGACY_ENCRYPTION_KEY_HASH:String = "eb142b0cae0baa72a767ebc0823d1be94e14c5bfc52d8e417fc4302fceb6240c";
		
		public var db:SQLiteDBHelper;
		public var dbFile:File ;
		public var base64Key:String;
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
		
			if( dbTables && dbTables.length>0) selectTable(dbTables[0] );
		
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
			

/*			
			// we want to dispatch the db created event only if a db was actually created
			var callback:Function = null;			
			if(isDBCreation) callback=onEncryptionKeyDialogClosed;
			
			Alert.show("Here's your database's encryption key (Base64 encoded). Use this key to open your DB in other applications. (Use your password to open your DB in Lita.)\n"+encoder.toString(), 
				"Encryption done !",
				Alert.OK,
				null, 
				callback);
*/				
		}
/*		
		private function onEncryptionKeyDialogClosed(pEvt:CloseEvent):void
		{
			dispatchEvent(new Event(DB_CREATED));
		}
*/
		
		
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
		
		// Tables
		
		public function selectTable(pTable:SQLTableSchema):void
		{
			if(pTable==null)
			{
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