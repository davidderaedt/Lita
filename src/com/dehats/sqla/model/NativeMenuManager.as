package com.dehats.sqla.model
{
	import com.dehats.air.DeclarativeMenu;
	import com.dehats.sqla.model.presentation.MainPM;
	
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	
	public class NativeMenuManager
	{
		
		private var pm:MainPM;
		
		public function NativeMenuManager(pPM:MainPM)
		{
			pm = pPM;
		}

		
		public function createMenu():DeclarativeMenu
		{
			
			var menuDefinition:XML = 
			    <root> 
			        <AppMenu label='Lita'>
			            <AboutCommand label='About Lita'/>			        
			            <QuitCommand label='Quit Lita' equiv='q'/>
			        </AppMenu>
			    
			        <FileMenu label='File'>
			            <OpenCommand label='Open Database File' equiv='o'/>
			            <CreateCommand label='Create New Database File' equiv='n'/>		            
			        </FileMenu>

			        <DBMenu label='Database'>
			            <ExportStructCommand label='Export Database'/>		        
			            <CompactCommand label='Compact Database'/>
			            <EncryptCommand label='Encrypt / Reencrypt Database'/>
			        </DBMenu>
			        
			    </root>;

			var root:DeclarativeMenu = new DeclarativeMenu(menuDefinition); 

			root.addEventListener(Event.SELECT, onMenuSelect);
			
			return root;
		}
		
		private function onMenuSelect(pEvt:Event):void
		{	
						
			var item:NativeMenuItem = pEvt.target as NativeMenuItem;
			
			switch (item.name)
			{
				case "QuitCommand":
				pm.closeApp();
				break;

				case "AboutCommand":
				pm.promptAboutDialog();
				break;
								
				case "OpenCommand":
				pm.promptOpenFile();
				break;

				case "CreateCommand":
				pm.promptCreateDBFile();
				break;

				case "CompactCommand":
				pm.compact();
				break;

				case "EncryptCommand":
				pm.promptReencrypt();
				break;
				
				case "ExportStructCommand":
				pm.exportDB();
				break;

				default:break;
			}
		}

	}
}