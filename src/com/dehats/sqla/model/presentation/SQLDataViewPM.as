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
package com.dehats.sqla.model.presentation
{
	import flash.data.SQLTableSchema;
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	[Bindable]
	public class SQLDataViewPM extends AbstractPM
	{
		public static const EVENT_TABLE_SELECTED:String= "tableSelected";
		
		public var tableRecords:Array
		public var selectedRecord:Object;
		
		private var mainPM:MainPM;
		private var _selectedTable:SQLTableSchema;

		public function get selectedTable():SQLTableSchema
		{
			return _selectedTable;
		}
		
		public function set selectedTable(pTable:SQLTableSchema):void
		{
			_selectedTable = pTable;
			 dispatchEvent(new Event(EVENT_TABLE_SELECTED));
		}
		
		public function SQLDataViewPM(pMainPM:MainPM)
		{
			mainPM = pMainPM;
		}

		public function selectRecord(pData:Object):void
		{
			if(pData!=selectedRecord) mainPM.selectRecord(pData);			
		}	

		public function updateRecord(pModifiedItem:Object):void
		{			
			mainPM.updateRecord(pModifiedItem);
		}

		public function createRecord(pNewItem:Object):void
		{
			mainPM.createRecord(pNewItem);
		}

		public function refresh():void
		{
			mainPM.refreshRecords();
		}

		public function exportRecords():void
		{
			if( tableRecords == null)
			{
				Alert.show("Nothing to export !", "Error");
				return;
			}
			
			mainPM.exportRecords();
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
			if( pEvt.detail == Alert.YES) mainPM.emptyTable();
		}	


		public function deleteRecord():void
		{
			Alert.show("Are you sure you want to delete this record ?", "Warning", Alert.YES| Alert.NO, null,deleteRecordAnswer); 
		}
		
		private function deleteRecordAnswer(pEvt:CloseEvent):void
		{
			if( pEvt.detail== Alert.YES) mainPM.deleteRecord( )
		}		
	}
}
