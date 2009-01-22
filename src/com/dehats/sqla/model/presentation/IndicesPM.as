package com.dehats.sqla.model.presentation
{
	import com.dehats.sqla.model.MainModel;
	
	import flash.data.SQLIndexSchema;
	
	[Bindable]
	public class IndicesPM extends AbstractPM
	{
		
		public var model:MainModel;
		
		public function IndicesPM(pModel:MainModel)
		{
			model = pModel;
		}
		
		public function removeIndex(pINdex:SQLIndexSchema):void
		{
			model.removeIndex( pINdex);
		}		
		
	}
}