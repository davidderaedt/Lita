package com.dehats.sqla.model.presentation
{
	import air.update.ApplicationUpdaterUI;
	import air.update.events.UpdateEvent;
	
	import com.dehats.air.sqlite.SQLiteErrorEvent;
	import com.dehats.sqla.events.EncryptionErrorEvent;
	import com.dehats.sqla.model.FileManager;
	import com.dehats.sqla.model.MainModel;
	import com.dehats.sqla.model.NativeMenuManager;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLResult;
	import flash.data.SQLTableSchema;
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.controls.Alert;
	
	[Bindable]
	public class MainPM extends AbstractPM
	{

		public static const HELP_URL:String="http://www.dehats.com/drupal/?q=node/90";	

		public static const TAB_STRUCTURE:int=0;
		public static const TAB_DATA:int=1;
		public static const TAB_INDICES:int=2;
		public static const TAB_SQL:int=3;

		
		public var isValidDBOpen:Boolean=false;
		public var docTitle:String;
		public var fileInfos:String;
		public var lastExecTime:int;
		public var selectedTab:int=0;
		
		// Presentation models
		public var sqlStatementPM:SQLStatementPM ;
		public var tableListPM:TableListPM ;
		public var sqldataViewPM:SQLDataViewPM ;
		public var sqlStructureViewPM:SQLStructureViewPM ;
		public var indicesPM:IndicesPM;

		public var selectedTable:SQLTableSchema;		
		public var selectedColumn:SQLColumnSchema;
		public var selectedRecord:Object;

		
		private var mainModel:MainModel ;
		private var updater:ApplicationUpdaterUI = new ApplicationUpdaterUI();
		private var fileManager:FileManager; 
		private var nativeMenuMgr:NativeMenuManager;		
		private var firstInvocation:Boolean=true ;
		private var isOpenedOpenRecentDialog:Boolean = false;
		private var isOpenedOpenDialog:Boolean = false;
		private var mainView:IMainView;


		public function MainPM(pNativeApp:NativeApplication)
		{
			
			mainModel = new MainModel();
			mainModel.addEventListener( SQLiteErrorEvent.EVENT_ERROR, onSQLiteError);
			mainModel.addEventListener( EncryptionErrorEvent.EVENT_ENCRYPTION_ERROR, onEncryptionError);
			
			fileManager = new FileManager();
			fileManager.addEventListener(FileManager.EVENT_IMPORT_FILE_SELECTED, onSQLFileImported);
			
			tableListPM = new TableListPM( this);
			indicesPM = new IndicesPM( this);
			sqldataViewPM = new SQLDataViewPM( this);
			sqlStatementPM = new SQLStatementPM(this);			
			sqlStructureViewPM = new SQLStructureViewPM(this);
			
			nativeMenuMgr = new NativeMenuManager(this, pNativeApp);
				
		}
		
		
		public function initialize(pMainView:IMainView):void
		{		
			mainView = pMainView;
			
			initializeUpdater();
		}	
				
		public function createNativeMenu():NativeMenu
		{
			return nativeMenuMgr.createMenu();
		}

		public function get recentlyOpenedFiles():Array
		{
			return fileManager.recentlyOpened;
		}
		
		// Debug only
		public function resetRecentlyOpened():void 
		{ 
			fileManager.resetRecentlyOpened();
		}
		
		
		// DB File
		
		public function openSample():void
		{
			openDBFile(fileManager.sample);
		}
		
		public function openDBFile(pFile:File, pPassword:String=""):void
		{
			var success:Boolean = mainModel.openDBFile(pFile, false, pPassword);
			
			if (success)
			{
				onDBOpened(pFile);
				
				if (pPassword == MainModel.LEGACY_ENCRYPTION_KEY_HASH)
				{
					promptUpgradeEncryption();
				}				
				
			}
		}
		
		
		public function createDBFile(pFile:File, pPwd:String=""):void
		{
			var success:Boolean = mainModel.createDBFile(pFile, pPwd);
			
			if(success) 
			{
				onDBOpened(pFile);
				tableListPM.createNewTable();
				if(pPwd) showGeneratedKey();
			}
		}
		
		private function showGeneratedKey():void
		{
			var msg:String = "Here's your database's encryption key (Base64 encoded). You can use this key to open your database in other applications. (Use your password to open your DB in Lita.)\n";
			msg+= mainModel.base64Key;
			Alert.show(msg, "Encryption done !");
		}

		private function onDBOpened(pFile:File):void
		{
			fileManager.addRecentlyOpened(pFile);
			isValidDBOpen =true;
			updateFileInfos();
			refreshDB();
		}
		
		private function updateFileInfos():void
		{
			docTitle = mainModel.dbFile.name+ " ("+ (mainModel.dbFile.size/1024) +" Kb)";
			fileInfos = mainModel.dbFile.nativePath;			
		}
						

		// Dialogs
		public function promptCreateNewTable():void
		{
			mainView.promptCreateNewTable();
		}
		
		public function promptOpenFile(pEvt:Event=null):void
		{
			if( isOpenedOpenRecentDialog || isOpenedOpenDialog) return ;
			mainView.promptOpenFileDialog(true);
		}

		public function promptCreateDBFile(pEvt:Event=null):void
		{
			if( isOpenedOpenRecentDialog || isOpenedOpenDialog) return ;			
			mainView.promptCreateDBDialog();
		}

		public function promptAboutDialog(pEvt:Event=null):void
		{			
			mainView.promptAboutDialog();
		}

		public function promptReencrypt():void
		{
			if( mainModel.dbFile==null) 
			{
				Alert.show("Database does not exist !", "Error");
				return;
			}
			
			mainView.promptReencryptDialog();
		}	
		
		private function promptUpgradeEncryption():void
		{
			mainView.promptUpgradeEncryptionDialog();
		}

		public function onOpenFileDialogClosed(pEvt:Event):void
		{
			isOpenedOpenRecentDialog = false ;
		}


		private function firstTimeGreetings():void
		{
			mainView.promptCommercialDialog();
		}
		
		

		// App launch / exit
					
		public function onInvoke(pEvt:InvokeEvent):void
		{
			// Check if the invocation corresponds to the app launch 
			if(firstInvocation )
			{					
				firstInvocation=false;				
				onAppLaunch(pEvt.arguments);
			}
		}
		
		private function onAppLaunch(parameters:Array):void
		{
			// Decide what to do depending on the launch scenario :				
			// 1. The user tried to open a file with the app	
			
			if( parameters.length>0)
			{					
				var f:File = new File(parameters[0]);										
				if( f.exists ) openDBFile(f);
				else Alert.show("Invocation argument is not an existing file", "Error");
			}

			// 2. The App was launched by clicking on it							
			else
			{
				// No file has ever been opened : this is the first time this app is executed
				// else, open the "Open file dialog"
				if( fileManager.recentlyOpened.length == 0 )  firstTimeGreetings();					
				else
				{
					promptOpenFile();
				}  
			}

		}
			

		public function closeApp():void
		{
			NativeApplication.nativeApplication.exit();
		}


		// updater
		public function checkForUpdates():void
		{
			updater.checkNow();
		}

		
		private function initializeUpdater():void
		{
			updater.configurationFile = new File("app:/updaterConfig.xml");
			updater.addEventListener(UpdateEvent.INITIALIZED, updaterInitialized);
			updater.initialize();				
		}
		
		private function updaterInitialized(event:UpdateEvent):void
		{
			checkForUpdates();
		}	
		
		// Domain logic
		
		private function refreshDB():void
		{
			tableListPM.dbTables = mainModel.dbTables;
			indicesPM.dbIndices = mainModel.dbIndices;
			
			if( mainModel.dbTables && mainModel.dbTables.length>0) selectTable(mainModel.dbTables[0] );			

		}

		// tables
		public function selectTable(pTable:SQLTableSchema):void
		{			
			selectedTable = pTable ;
			selectColumn( null );
			selectRecord( null );
			
			refreshRecords();
			
			sqlStructureViewPM.selectedTable = selectedTable;	
			sqldataViewPM.selectedTable = selectedTable;		
			tableListPM.selectedTable = selectedTable;
			sqldataViewPM.tableRecords = mainModel.tableRecords;
			
		}

		public function emptyTable():void
		{			
			mainModel.emptyTable(selectedTable);			
			selectedRecord = null ;
			sqldataViewPM.tableRecords = mainModel.tableRecords;
		}
		
		public function renameTable(pName:String):void
		{	
			var table:SQLTableSchema = mainModel.renameTable(selectedTable,  pName);
			tableListPM.dbTables = mainModel.dbTables;
			selectTable(table);
		}		

		public function createTable(pName:String, pDefinition:String):void
		{
			var table:SQLTableSchema = mainModel.createTable(pName, pDefinition);
			tableListPM.dbTables = mainModel.dbTables;
			if(table) selectTable(table);
		}

		public function copyTable(pName:String, pCopyData:Boolean):void
		{
			var table:SQLTableSchema = mainModel.copyTable(selectedTable, pName, pCopyData);
			tableListPM.dbTables = mainModel.dbTables;
			if(table) selectTable(table);	
		}
				
		public function dropTable():void
		{
			mainModel.dropTable(selectedTable);
			selectTable(null);
			selectColumn(null);
			selectRecord(null);
			
			tableListPM.dbTables = mainModel.dbTables;
		}
		
		public function exportTable():void
		{
			var createString:String = selectedTable.sql;
			fileManager.createExportFile(createString);			
		}
				
		// records
		public function selectRecord(pData:Object):void
		{
			selectedRecord = pData;
			sqldataViewPM.selectedRecord = selectedRecord;
		}
	
		public function createRecord(pRecord:Object):void
		{
			var obj:Object = mainModel.createRecord(selectedTable, pRecord);	
			sqldataViewPM.tableRecords = mainModel.tableRecords;
			selectRecord(obj );	
		}
		
		public function updateRecord(pRecord:Object):void
		{			
			var obj:Object = mainModel.updateRecord(selectedTable, selectedRecord, pRecord);
			sqldataViewPM.tableRecords = mainModel.tableRecords;
			selectRecord(obj );			
		}
						
		public function deleteRecord():void
		{
			mainModel.deleteRecord(selectedTable, selectedRecord);
			sqldataViewPM.selectedRecord = null;
		}
				
		public function exportRecords():void
		{
			var str:String = mainModel.exportRecords(selectedTable);
			fileManager.createExportFile(str);	
		}
		
		public function refreshRecords():void
		{
			mainModel.refreshRecords(selectedTable);
			sqldataViewPM.tableRecords = mainModel.tableRecords;
		}
				
		// Indices
		
		public function addIndex(pName:String):void
		{
			mainModel.addIndex(selectedTable, selectedColumn, pName);
			indicesPM.dbIndices = mainModel.dbIndices;
			selectedTab=TAB_INDICES;			
		}
				
		public function removeIndex(pIndex:SQLIndexSchema):void
		{
			mainModel.removeIndex(pIndex);
			indicesPM.dbIndices = mainModel.dbIndices;
		}
		
		// Columns
		
		public function selectColumn(pCol:SQLColumnSchema):void
		{
			selectedColumn = pCol;
			sqlStructureViewPM.selectedColumn = pCol;
		}
		
		public function renameColumn(pName:String):void
		{
			var i:int = selectedTable.columns.indexOf(selectedColumn);
			var table:SQLTableSchema = mainModel.renameColumn(selectedTable, selectedColumn, pName);
			tableListPM.dbTables = mainModel.dbTables;
			selectTable(table);
			selectColumn( selectedTable.columns[i]);
			
		}

		public function createColumn(pName:String, pDataType:String, pAllowNull:Boolean, pUnique:Boolean, pDefault:String):void
		{			
			var table:SQLTableSchema = mainModel.addColumn(selectedTable, pName, pDataType, pAllowNull, pUnique, pDefault);
			
			selectTable(table);
			selectColumn( selectedTable.columns[ selectedTable.columns.length-1 ]);			
		}

		public function dropColumn():void
		{
			var table:SQLTableSchema = mainModel.removeColumn(selectedTable, selectedColumn.name);
			selectTable(table);
			selectColumn(null);		
		}
		
		
		// other

		
		public function executeStatement(pStatement:String):void
		{			

			var sqlResult:SQLResult =  mainModel.executeStatement(pStatement);
			
			if( sqlResult==null) sqlStatementPM.results=[];
			
			else {
				 sqlStatementPM.results = sqlResult.data;
				if( ! sqlStatementPM.persoStatementHist.contains(pStatement))  sqlStatementPM.persoStatementHist.addItem( pStatement );			
			}			
		}
		
		public function importStatementFromFile():void
		{
			fileManager.importFromFile();
		}
		
		private function onSQLFileImported(pEvt:Event):void
		{
			sqlStatementPM.statement = fileManager.importedSQL;
		}
		
		public function exportStatements(pStatement:String):void
		{
			fileManager.createExportFile(pStatement );
		}
		
		
		public function compact():void
		{
			if( ! isValidDBOpen) 
			{
				Alert.show("Database does not exist !", "Error");
				return;
			}
						
			var done:Boolean = mainModel.compact();
			
			if( done)
			{
				Alert.show("Database compacting done !", "Info");
				updateFileInfos();
			} 
			
			else Alert.show("Unable to compact database", "Error");
		}
		
		public function exportDB():void
		{
			if(! isValidDBOpen) 
			{
				Alert.show("Database does not exist !", "Error");
				return ;
			}
			
			var createString:String = mainModel.exportDB();
			
			fileManager.createExportFile( createString );
			
		}
		
		public function reencrypt(pPwd:String):void
		{
			if( ! isValidDBOpen) 
			{
				Alert.show("Database does not exist !", "Error");
				return;
			}
			
			mainModel.reencrypt( pPwd);
			
			showGeneratedKey();
			
		}
		
		public function goToHelp():void
		{
			navigateToURL(new URLRequest(HELP_URL));
		}
		

		private function onSQLiteError(pEvt:SQLiteErrorEvent):void
		{
			var msg:String = pEvt.error.message;
			trace(pEvt.error)
			var notes:String="\n";
			if(pEvt.error.errorID==3138) notes+="If the database file is encrypted, you may encounter this error if you've entered a wrong password.";
			if(pEvt.statement!="") msg+="\n\n"+"Statement"+":\n"+pEvt.statement;
			Alert.show(msg+notes, "Error");
		}

		private function onEncryptionError(pEvt:EncryptionErrorEvent):void
		{
			var msg:String = pEvt.error.message;
			Alert.show(msg, "Error");
		}

	}
}