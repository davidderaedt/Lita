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
	import flash.data.SQLColumnSchema;
	import flash.data.SQLTableSchema;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	
	[Bindable]
	public class SQLStructureViewPM extends AbstractPM
	{
		
		
		public var selectedColumn:SQLColumnSchema;
		public var selectedTable:SQLTableSchema;
		public var isNewFieldFormEnabled:Boolean=true;
		
		private var mainPM:MainPM;
		
		public function SQLStructureViewPM(pMainPM:MainPM)
		{
			mainPM = pMainPM;
		}
		
		public function addIndex(pName:String):void
		{
			mainPM.addIndex(pName);
		}
		
		public function selectColumn(pCol:SQLColumnSchema):void
		{
			mainPM.selectColumn(pCol);
		}
		
		public function renameColumn(pName:String):void
		{
			mainPM.renameColumn(pName);
		}
		
		
		public function addColumn(pName:String, pType:String, pNull:Boolean, pUnique:Boolean, pDefault:String):void
		{
			mainPM.createColumn(pName, pType, pNull, pUnique, pDefault);
		}
		
		public function renameTable(pNewName:String):void
		{
			mainPM.renameTable(pNewName);
		}
		
		public function exportTable():void
		{
			mainPM.exportTable();
		}

		public function copyTable(pNewName:String, pCopyData:Boolean):void
		{
			mainPM.copyTable(pNewName, pCopyData);
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
			if( pEvt.detail == Alert.YES) mainPM.dropTable();
		}

		public function askDropColumn():void
		{
			Alert.show("Are you sure you want to drop this field ("+ selectedColumn.name+")?", 
						"Warning", 
						Alert.YES|Alert.NO, 
						null, 
						dropColumnAnswer);				
		}

		private function dropColumnAnswer(pEvt:CloseEvent):void
		{
			if( pEvt.detail == Alert.YES) mainPM.dropColumn();
		}		

		
	}
}
