package com.dehats.sqla.model.presentation
{
	import com.dehats.sqla.model.FileManager;
	import com.dehats.sqla.model.MainModel;
	
	import flash.data.SQLResult;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	
	[Bindable]
	public class SQLStatementPM extends AbstractPM
	{
		
		
		public var results:Array;

		public var persoStatementHist:ArrayCollection=new ArrayCollection();
		
		public var statement:String="";

		private var mainModel:MainModel;

		private var fileManager:FileManager;
		
		public function SQLStatementPM(pModel:MainModel, pFileManager:FileManager)
		{
			fileManager = pFileManager;
			fileManager.addEventListener(FileManager.EVENT_IMPORT_FILE_SELECTED, onSQLFileImported);
			mainModel = pModel;
		}
		
		public function importSQLFile():void
		{
			fileManager.importFromFile();
		}
		private function onSQLFileImported(pEvt:Event):void
		{
			statement = fileManager.importedSQL;
		}
		
		public function exportToFile(pStatement:String):void
		{
			fileManager.createExportFile( pStatement );
		}
		
		public function executeStatement(pStatement:String):void
		{			
						
			var sqlResult:SQLResult =  mainModel.db.executeStatement(pStatement);
			
			if( sqlResult==null) results=[];
			
			else {
				results = sqlResult.data;
				if( !persoStatementHist.contains(pStatement)) persoStatementHist.addItem( pStatement );			
			}
		}
		
	}
}