package com.dehats.sqla.model.presentation
{
	import com.dehats.sqla.model.MainModel;
	import com.dehats.sqla.view.NewTableForm;
	
	import flash.data.SQLTableSchema;
	import flash.display.DisplayObject;
	
	import mx.containers.TitleWindow;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	[Bindable]
	public class TableListPM extends AbstractPM
	{
		public var mainModel:MainModel

		private var dialog:TitleWindow;
		
		public function TableListPM(pModel:MainModel)
		{
			mainModel = pModel;
			super();
		}


		public function selectTable(pTable:SQLTableSchema):void
		{							
			mainModel.selectTable(pTable);
		}		
		
		public function createNewTable():void
		{
			var newTableForm:NewTableForm = new NewTableForm();
			newTableForm.mainModel = mainModel;  
			

			dialog = PopUpManager.createPopUp(Application.application as DisplayObject, TitleWindow, true) as TitleWindow;				
			dialog.addChild(newTableForm);
			dialog.title = "Create a new table";
			dialog.showCloseButton = true ;
			dialog.addEventListener(CloseEvent.CLOSE, closeNewTableDialog);
			newTableForm.addEventListener('create', closeNewTableDialog);
			
			PopUpManager.centerPopUp(dialog);
		}	


		
		private function closeNewTableDialog(pEvt:Event):void
		{
			PopUpManager.removePopUp(dialog) ;
		}
		
				
	}
}