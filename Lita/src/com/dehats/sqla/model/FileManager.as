package com.dehats.sqla.model
{
	import flash.data.EncryptedLocalStore;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	public class FileManager extends EventDispatcher
	{
		
		public static const EVENT_IMPORT_FILE_SELECTED:String="importFileSelected";
		
		// Note: had to append "V07" to get rid of the previous (corrupted) local store
		public static const RECENTLY_OPENED:String = "recentlyOpenedV07";
		
		public var recentlyOpened:Array=[];
				
		// holds the SQL string while the user chooses the destination file
		private var tmpExportString:String;
		
		// holds a reference to the imported SQL
		public var importedSQL:String;
		
		public function FileManager()
		{
						
			var sampleName:String = "sample.db";
			
			var original:File = File.applicationDirectory.resolvePath( sampleName); 
			
			// Copy sample db if not found

			if( ! original.exists ){
				trace("Unable to find sample db : "+original.nativePath, "File not found");
				return ;
			} 
			
			var sample:File = File.applicationStorageDirectory.resolvePath(sampleName);
			original.copyTo(sample, true);

			// Copy the SimpleEncryption class the applicationStorageDirectory
			
			var comDir:File = File.applicationDirectory.resolvePath("com");
			var dest:File = File.applicationStorageDirectory.resolvePath("com");

			if(! comDir.exists )
			{
				trace("Unable to find com dir");
				return;
			}
			
			if(! dest.exists) comDir.copyTo( dest, true);
			
			getRecentlyOpened();
			
			if( recentlyOpened.length==0) 
			{
				addRecentlyOpened( sample);
			}
		}


		// Recently opened

		private function getRecentlyOpened():void
		{
			var storedValue:ByteArray = EncryptedLocalStore.getItem(RECENTLY_OPENED);
			
			if( storedValue==null) recentlyOpened = [];
			
			else 
			{
				var tab:Array = storedValue.readObject() as Array;
				
				// get rid of deleted files
				for ( var i:int = 0 ; i < tab.length ; i ++)
				{
					var fileObj:Object = tab[i];
					var f:File = new File(fileObj.path);
					if( ! f.exists) tab.splice(i, 1);
				}
				
				recentlyOpened = tab;
			}
			
			saveRecentlyOpened();

		}
		
		public function resetRecentlyOpened():void
		{
			EncryptedLocalStore.reset();
		}
		
		
		public function addRecentlyOpened(pFile:File):void
		{
			// first check if the file already exists
			for ( var i:int = 0 ; i < recentlyOpened.length ; i++)
			{
				// if it does exist, remove it
				if(pFile.nativePath== recentlyOpened[i].path) 
				{
					recentlyOpened.splice(i, 1);
				}
			}				
			
			// then add it at the first place
			recentlyOpened.unshift({name:pFile.name, path: pFile.nativePath});
			
			saveRecentlyOpened();
		}
		
		
		
		// File import/export
		
		public function importFromFile():void
		{
			var f:File = new File();				
			f.addEventListener(Event.SELECT, onImportFileSelected)		
			f.browseForOpen("Select an SQL file");
		}
		
		private function onImportFileSelected(pEvt:Event):void
		{
			var f:File = pEvt.target as File;
			var stream:FileStream = new FileStream();
			stream.open( f, FileMode.READ);
			importedSQL = stream.readMultiByte(stream.bytesAvailable, "UTF-8");
			stream.close();
			
			dispatchEvent( new Event( EVENT_IMPORT_FILE_SELECTED));
			
		}
		
		public function createExportFile(pStr:String):void
		{
			tmpExportString = pStr;
			
			var f:File = new File();						
			f.browseForSave("Export to file");
			f.addEventListener(Event.SELECT, onExportFileSelected);
			
		}
		
		private function onExportFileSelected(pEvt:Event):void
		{
			var f:File = pEvt.target as File;

			var stream:FileStream = new FileStream();
			stream.open( f, FileMode.WRITE);
			stream.writeMultiByte(tmpExportString, "UTF-8");
			stream.close();			
		}
		
		private function saveRecentlyOpened():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject( recentlyOpened );
			EncryptedLocalStore.setItem( RECENTLY_OPENED, bytes );				
		}

	}
}