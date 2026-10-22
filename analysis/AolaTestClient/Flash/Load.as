package mmo.checkversion
{
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.UncaughtErrorEvent;
   import flash.external.ExternalInterface;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;

   public class Load extends Sprite
   {
      public var version:XML;
      public var loaderSwfBtyes:ByteArray;

      public function Load()
      {
         super();
         loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
         var request:URLLoader = new URLLoader();
         request.addEventListener(Event.COMPLETE, onVersion);
         request.addEventListener(IOErrorEvent.IO_ERROR, onError);
         request.load(new URLRequest("start.xml"));
      }

      private function onVersion(event:Event):void
      {
         version = new XML(URLLoader(event.target).data);
         var request:URLLoader = new URLLoader();
         request.dataFormat = URLLoaderDataFormat.BINARY;
         request.addEventListener(Event.COMPLETE, onBytes);
         request.addEventListener(IOErrorEvent.IO_ERROR, onError);
         request.load(new URLRequest("loader~" + version.v + ".swf"));
      }

      private function onBytes(event:Event):void
      {
         loaderSwfBtyes = URLLoader(event.target).data;
         var loader:Loader = new Loader();
         loader.contentLoaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
         loader.loadBytes(loaderSwfBtyes, new LoaderContext(false, ApplicationDomain.currentDomain));
      }

      private function onLoaded(event:Event):void
      {
         addChild(LoaderInfo(event.target).content);
      }

      private function onError(event:Event):void
      {
         var message:String = event.toString();
         if(event is UncaughtErrorEvent)
         {
            var error:Object = UncaughtErrorEvent(event).error;
            message = error is Error ? Error(error).toString() + "\n" + Error(error).getStackTrace() : String(error);
            event.preventDefault();
         }
         ExternalInterface.call("aolaTestError", message);
      }
   }
}
