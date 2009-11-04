package com.dehats.sqla.model.presentation
{
	import flash.data.SQLIndexSchema;
	
	[Bindable]
	public class IndicesPM extends AbstractPM
	{
		
		public var mainPM:MainPM;
		public var dbIndices:Array;
		
		public function IndicesPM(pMainPM:MainPM)
		{
			mainPM = pMainPM;
		}
		
		public function removeIndex(pINdex:SQLIndexSchema):void
		{
			mainPM.removeIndex( pINdex);
		}		
		
	}
}