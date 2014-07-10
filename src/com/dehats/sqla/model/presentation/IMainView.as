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
	public interface IMainView
	{
		function promptCreateDBDialog():void;
		function promptOpenFileDialog(pClosable:Boolean=false):void;
		function promptAboutDialog():void;
		function promptReencryptDialog():void;
		function promptCommercialDialog():void;
		function promptUpgradeEncryptionDialog():void;
		function promptCreateNewTable():void;
		
	}
}
