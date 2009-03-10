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
	
	[Bindable]
	public class MainModel extends EventDispatcher
	{
		public static const TABLE_SELECTED:String = "tableSelected";
		
		public var db:SQLiteDBHelper = new SQLiteDBHelper();

		public var dbFile:File ;

		public var docTitle:String;
		
		public var dbTables:Array ;
		
		public var dbIndices:Array;

		public var selectedTable:SQLTableSchema;

		public var tableRecords:Array;
		
		public var selectedColumn:SQLColumnSchema;

		public var selectedRecord:Object;
		
		private var schemas:SQLSchemaResult;
						
		public function MainModel()
		{
		}
		
		// DataBase
		
		public function openDBFile(pFile:File, isNew:Boolean=false, pHash:String=""):void
		{
			
			dbFile = pFile ;
			
			var key:ByteArray;
			
			if(pHash && pHash.length>0) key = generateEncryptionKey(pHash);
			
			try
			{
				db.openDBFile(dbFile, key);
			}
			catch(error:SQLError)
			{
				Alert.show(error.message+"\n"+error.details);
				return;
			}
			
			
			docTitle = dbFile.name+' - '+ (dbFile.size/1024)+' Kb' ;
			
			loadSchema();
			
			if(dbTables.length>0) selectTable(dbTables[0] );

		}
		
		public function createDBFile(pFile:File, pPassword:String=""):void
		{
			dbFile = pFile ;
			
			var key:ByteArray;
			
			if(pPassword && pPassword.length>0)
			{
				try
				{
					key = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword, true);
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
			
			
			docTitle = dbFile.name+' - '+ (dbFile.size/1024)+' Kb' ;
		}

		public function reencrypt(pPassword:String):void
		{
			if( dbFile==null ) return;
			
			var key:ByteArray = new SimpleEncryptionKeyGenerator().getEncryptionKey(pPassword, true);
			db.reencrypt(key);
		}

		// Borrowed from Paul Roberston's EncryptionKeyGenerator
		private function generateEncryptionKey(hash:String):ByteArray
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

		// STRUCTURE
		
		private function loadSchema():void
		{
			schemas =  db.getSchemas();
			schemas.tables.sortOn("name", Array.CASEINSENSITIVE);
			dbTables = schemas.tables;
			schemas.indices.sort(sortIndices);
			dbIndices = schemas.indices;
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
				str+= table.sql + ";\n\n";
				
				if(pData) str+= db.exportTableRecords( table)+"\n\n";
				
			}
			
			return str;
		}
		
		// Tables
		
		public function selectTable(pTable:SQLTableSchema):void
		{
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
			selectTable(getTableByName( pTableName));
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
			selectRecord( tableRecords[tableRecords.length-1] );
		}
		
		public function deleteRecord():void
		{
			db.deleteRecord( selectedTable, selectedRecord);
			refreshRecords();
		}
		
		public function refreshRecords():void
		{
			tableRecords = db.getTableRecords(selectedTable);
			selectedRecord=null;
		}
		
		public function exportRecords():String
		{
			return db.exportTableRecords( selectedTable);
		}
		
	}
}