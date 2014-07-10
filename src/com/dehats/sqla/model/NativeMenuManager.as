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
package com.dehats.sqla.model
{
	import com.dehats.air.DeclarativeMenu;
	import com.dehats.sqla.model.presentation.MainPM;
	
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	
	public class NativeMenuManager
	{
		
		private var pm:MainPM;
		private var nativeApp:NativeApplication;
		
		public function NativeMenuManager(pPM:MainPM, pNativeApp:NativeApplication)
		{
			pm = pPM;
			nativeApp = pNativeApp;
		}

		
		public function createMenu():DeclarativeMenu
		{
			
			var menuDefinition:XML = 
			    <root> 
			        <AppMenu label='Lita'>
			            <HelpCommand label='Online Help'/>			        			        
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
		
			        <EditMenu label='Edit'>
			            <CopyCommand label='Copy' equiv='c'/>
			            <PasteCommand label='Paste' equiv='v'/>		            
			            <CutCommand label='Cut' equiv='x'/>		            
			            <SelectAllCommand label='Select All' equiv='a'/>		            			            
			        </EditMenu>
			        
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
				

				case "HelpCommand":
					pm.goToHelp();
				break;

				
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
				
				case "CopyCommand":
					nativeApp.copy();
				break;

				case "PasteCommand":
					nativeApp.paste();
				break;

				case "CutCommand":
					nativeApp.cut();
				break;

				case "SelectAllCommand":
					nativeApp.selectAll();
				break;

				default:break;
			}
		}

	}
}
