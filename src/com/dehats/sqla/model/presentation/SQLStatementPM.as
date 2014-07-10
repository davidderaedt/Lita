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
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.events.DynamicEvent;
	
	[Bindable]
	public class SQLStatementPM extends AbstractPM
	{
		
		public static const EVENT_IMPORT_STATEMENT:String = "importSQL";
		public static const EVENT_EXPORT_STATEMENT:String = "exportSQL";
		
		public var results:Array;

		public var persoStatementHist:ArrayCollection=new ArrayCollection();
		
		public var statement:String="";
		
		private var mainPM:MainPM
		
		public function SQLStatementPM(pMainPM:MainPM)
		{
			mainPM = pMainPM;
		}
		
		public function importSQLFile():void
		{
			mainPM.importStatementFromFile();
		}
		
		public function exportToFile(pStatement:String):void
		{
			mainPM.exportStatements(pStatement);
		}
		
		public function executeStatement(pStatement:String):void
		{	
			mainPM.executeStatement(pStatement);
		}
		
	}
}
