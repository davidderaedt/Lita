package com.dehats.sqla.model.presentation
{
	import com.dehats.sqla.model.FileManager;
	import com.dehats.sqla.model.MainModel;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	[Bindable]
	public class SQLDataViewPM extends AbstractPM
	{
				
		public var mainModel:MainModel;
		
		private var fileManager:FileManager;
		
		public function SQLDataViewPM(pModel:MainModel, pFileManager:FileManager)
		{
			mainModel = pModel;
			fileManager = pFileManager;
			super();
		}

		public function selectRecord(pData:Object):void
		{
			mainModel.selectRecord(pData);			
		}	

		public function updateRecord(pModifiedItem:Object):void
		{			
			mainModel.updateRecord(pModifiedItem);
		}

		public function createRecord(pNewItem:Object):void
		{
			mainModel.createRecord(pNewItem);
		}

		public function refresh():void
		{
			mainModel.refreshRecords();
		}

		public function exportRecords():void
		{
			if( mainModel.tableRecords == null)
			{
				Alert.show("Nothing to export !", "Error");
				return;
			}
			
			var str:String = mainModel.exportRecords();
			fileManager.createExportFile(str);			
		}

		public function askEmptyCurrentTable():void
		{				
			Alert.show("Are you sure you want to empty this table?", 
						"Warning", 
						Alert.YES|Alert.NO, 
						null, 
						emptyTableAnswer);
		}
		
		private function emptyTableAnswer(pEvt:CloseEvent):void
		{
			if( pEvt.detail == Alert.YES) mainModel.emptyCurrentTable();
		}	
		
	}
}