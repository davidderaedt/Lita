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