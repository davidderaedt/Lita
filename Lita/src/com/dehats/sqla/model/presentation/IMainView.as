package com.dehats.sqla.model.presentation
{
	public interface IMainView
	{
		function promptCreateDBDialog():void;
		function promptOpenFileDialog(pClosable:Boolean=false):void;
		function promptAboutDialog():void;
		function promptReencryptDialog():void;
	}
}