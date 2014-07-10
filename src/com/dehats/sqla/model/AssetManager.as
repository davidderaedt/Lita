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
	public class AssetManager
	{
		public function AssetManager()
		{
		}
		
		[Embed(source="../../../../assets/icons/logo.png")]
		public static const LOGO_ICON:Class; 

		[Embed(source="../../../../assets/icons/database.png")]
		public static const ICON_OPEN_DB:Class; 

		[Embed(source="../../../../assets/icons/database_go.png")]
		public static const ICON_EXPORT_DB:Class; 

		[Embed(source="../../../../assets/icons/compress.png")]
		public static const ICON_COMPACT_DB:Class; 

		[Embed(source="../../../../assets/icons/database_gear.png")]
		public static const ICON_GEAR_DB:Class; 

		[Embed(source="../../../../assets/icons/database_key.png")]
		public static const ICON_KEY_DB:Class; 

		[Embed(source="../../../../assets/icons/database_add.png")]
		public static const ICON_CREATE_DB:Class; 

		[Embed(source="../../../../assets/icons/table_add.png")]
		public static const ICON_CREATE_TABLE:Class; 
		
		[Embed(source="../../../../assets/icons/table_go.png")]
		public static const ICON_EXPORT_TABLE:Class; 

		[Embed(source="../../../../assets/icons/table_refresh.png")]
		public static const ICON_REFRESH_TABLE:Class; 

		[Embed(source="../../../../assets/icons/bin_empty.png")]
		public static const ICON_EMPTY:Class; 
		
		[Embed(source="../../../../assets/icons/arrow_refresh.png")]
		public static const ICON_REFRESH:Class; 

		[Embed(source="../../../../assets/icons/table_multiple.png")]
		public static const ICON_TABLES:Class; 

		[Embed(source="../../../../assets/icons/database_table.png")]
		public static const ICON_TABLE:Class; 

		[Embed(source="../../../../assets/icons/table_refresh.png")]
		public static const ICON_TABLE_REFRESH:Class; 

		[Embed(source="../../../../assets/icons/delete.png")]
		public static const ICON_DELETE:Class; 
		
		[Embed(source="../../../../assets/icons/add.png")]
		public static const ICON_ADD:Class; 

		[Embed(source="../../../../assets/icons/disk.png")]
		public static const ICON_SAVE:Class; 

		[Embed(source="../../../../assets/icons/key_add.png")]
		public static const ICON_ADD_KEY:Class; 

		[Embed(source="../../../../assets/icons/help.png")]
		public static const ICON_HELP:Class; 

	}
}
