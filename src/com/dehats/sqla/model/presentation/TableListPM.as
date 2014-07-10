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
	
	[Bindable]
	public class TableListPM extends AbstractPM
	{
		
		public var selectedTable:SQLTableSchema;
		public var dbTables:Array
		
		private var mainPM:MainPM;
		
		public function TableListPM(pMainPM:MainPM)
		{
			mainPM = pMainPM;
		}


		public function selectTable(pTable:SQLTableSchema):void
		{							
			mainPM.selectTable(pTable);
		}		
		
		public function createNewTable():void
		{
			mainPM.promptCreateNewTable();
		}	

				
	}
}
