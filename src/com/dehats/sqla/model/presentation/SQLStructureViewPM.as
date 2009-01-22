package com.dehats.sqla.model.presentation
{
	import com.dehats.sqla.model.FileManager;
	import com.dehats.sqla.model.MainModel;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	
	[Bindable]
	public class SQLStructureViewPM extends AbstractPM
	{
		
		public var mainModel:MainModel
		
		private var fileManager:FileManager;
		
		public function SQLStructureViewPM(pModel:MainModel, pFileManager:FileManager)
		{
			mainModel = pModel;
			fileManager = pFileManager;
			super();
		}
		
		public function exportTable():void
		{
			var createString:String = mainModel.selectedTable.sql;
			
			fileManager.createExportFile(createString);
		}

		public function copyTable(pNewName:String, pCopyData:Boolean):void
		{
			mainModel.copyTable(pNewName, pCopyData);
		}
		
		public function askDropCurrentTable():void
		{				
			Alert.show("Are you sure you want to drop this table?", 
						"Warning", 
						Alert.YES|Alert.NO, 
						null, 
						dropTableAnswer);
		}
		
		private function dropTableAnswer(pEvt:CloseEvent):void
		{
			if( pEvt.detail == Alert.YES) mainModel.dropCurrentTable();
		}

		public function askDropColumn():void
		{
			Alert.show("Are you sure you want to drop this field ("+ mainModel.selectedColumn.name+")?", 
						"Warning", 
						Alert.YES|Alert.NO, 
						null, 
						dropColumnAnswer);				
		}

		private function dropColumnAnswer(pEvt:CloseEvent):void
		{
			if( pEvt.detail == Alert.YES) mainModel.removeColumn()	;
		}		

		
	}
}