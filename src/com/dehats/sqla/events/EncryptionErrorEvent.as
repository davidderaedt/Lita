package com.dehats.sqla.events
{
	import flash.events.Event;

	public class EncryptionErrorEvent extends Event
	{
		
		public static const EVENT_ENCRYPTION_ERROR:String="encryptionError";
		
		public var error:Error;
		
		public function EncryptionErrorEvent(type:String, pError:Error, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			error = pError;
			super(type, bubbles, cancelable);
		}
		
	}
}