package com.dehats.sqla.model.presentation
{
	import air.update.ApplicationUpdaterUI;
	import air.update.events.UpdateEvent;
	
	import com.dehats.sqla.model.FileManager;
	import com.dehats.sqla.model.MainModel;
	import com.dehats.sqla.model.NativeMenuManager;
	
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	
	import mx.controls.Alert;
	
	[Bindable]
	public class MainPM extends AbstractPM
	{
		
		public static const FILE_CHANGED:String="fileHasChanged";	
		
		public var sqlStatementPM:SQLStatementPM ;
		public var tableListPM:TableListPM ;
		public var sqldataViewPM:SQLDataViewPM ;
		public var sqlStructureViewPM:SQLStructureViewPM ;
		public var indicesPM:IndicesPM;
		
		private var updater:ApplicationUpdaterUI = new ApplicationUpdaterUI();
		private var mainModel:MainModel = new MainModel();
		private var fileManager:FileManager; 
		private var nativeMenuMgr:NativeMenuManager;		
		private var firstInvocation:Boolean=true ;
		private var isOpenedOpenRecentDialog:Boolean = false;
		private var isOpenedOpenDialog:Boolean = false;
		private var mainView:IMainView;


		public function MainPM(pNativeApp:NativeApplication)
		{
			
			fileManager = new FileManager();
			
			tableListPM = new TableListPM( mainModel);
			indicesPM = new IndicesPM( mainModel);
			sqldataViewPM = new SQLDataViewPM( mainModel, fileManager);
			sqlStatementPM = new SQLStatementPM( mainModel, fileManager);
			sqlStructureViewPM = new SQLStructureViewPM( mainModel, fileManager);
			
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
		
		public function openDBFile(pFile:File, pHash:String=""):void
		{
			mainModel.openDBFile(pFile, false, pHash);
			
			fileManager.addRecentlyOpened(pFile);
			
			dispatchEvent(new Event(FILE_CHANGED));
		}
		
		
		public function createDBFile(pFile:File, pPwd:String=""):void
		{
			mainModel.createDBFile(pFile, pPwd);
			
			fileManager.addRecentlyOpened(pFile);
			
			dispatchEvent(new Event(FILE_CHANGED));
			
			tableListPM.createNewTable();
		}


		[Bindable("fileHasChanged")]
		public function get docTitle():String
		{
			if(mainModel.dbFile==null || mainModel.dbFile.exists==false) return "?";
			return mainModel.dbFile.name+ " - "+  (mainModel.dbFile.size/1024) +" kb";
		}

		[Bindable("fileHasChanged")]
		public function get fileInfos():String
		{
			if(mainModel.dbFile==null || mainModel.dbFile.exists==false) return "No infos available"
			return mainModel.dbFile.nativePath;
		}
				

		// Dialogs
		
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

		public function onOpenFileDialogClosed(pEvt:Event):void
		{
			isOpenedOpenRecentDialog = false ;
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
				else Alert.show("Invokation argument is not an existing file", "Error");
			}

			// 2. The App was launched by clicking on it							
			else
			{
				// No file has ever been opened : this is the first time this app is executed
				// else, open the "Open file dialog"
				if( fileManager.recentlyOpened.length == 0 )  firstTimeGreetings();					
				else  promptOpenFile();
			}

		}
			
		private function firstTimeGreetings():void
		{
			Alert.show("Please choose Open and then browse for a database file.", "Welcome");
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
		
		// domain logic
		
		public function compact():void
		{
			
			var done:Boolean = mainModel.compact();
			
			if( done)
			{
				Alert.show("Database compacting done !", "Info");
				dispatchEvent(new Event(FILE_CHANGED));
			} 
			
			else Alert.show("Unable to compact database", "Error");
		}
		
		public function exportDB():void
		{
			if( mainModel.dbFile==null) 
			{
				Alert.show("Database does not exist !", "Error");
				return ;
			}
			
			var createString:String = mainModel.exportDB();
			
			fileManager.createExportFile( createString );
			
		}
		
		public function reencrypt(pPwd:String):void
		{
			if( mainModel.dbFile==null) 
			{
				Alert.show("Database does not exist !", "Error");
				return;
			}
			
			mainModel.reencrypt( pPwd);
			
			Alert.show("Done !", "Information");
		}

	}
}