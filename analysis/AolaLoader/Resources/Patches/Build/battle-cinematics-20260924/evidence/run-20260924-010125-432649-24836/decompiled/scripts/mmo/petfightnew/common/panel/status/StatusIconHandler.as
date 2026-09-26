package mmo.petfightnew.common.panel.status
{
   import com.adobe.utils.StringUtil;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.geom.Matrix;
   import mmo.common.DisplayUtil;
   import mmo.loader.scheduler.VersManager;
   import mmo.petfightnew.common.manager.FightBitmapDataCache;
   
   public class StatusIconHandler
   {
      
      public static const StatusType_Common:int = 0;
      
      public static const StatusType_HK:int = 1;
      
      public static const StatusType_CommonBuff:int = 2;
      
      private static const STATUS_RES_FORMAT_ARR:Array = ["pet/status/statusicon_%1.png","pet/status/hkstatusicon_%1.png","pet/status/commonbufficon_%1.png"];
      
      private var _container:DisplayObjectContainer;
      
      private var _loader:Loader;
      
      private var _id:int = 0;
      
      private var _type:int = -1;
      
      private var _isDone:Boolean = false;
      
      public function StatusIconHandler(param1:DisplayObjectContainer)
      {
         super();
         this._container = param1;
         this._loader = new Loader();
         this._loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.onIoError);
      }
      
      public function startLoad(param1:int, param2:int) : void
      {
         this._container.visible = true;
         if(this._type == param1 && this._id == param2 && this._isDone)
         {
            return;
         }
         this.clearIcon();
         this._id = param2;
         this._type = param1;
         var _loc3_:BitmapData = FightBitmapDataCache.instance.getData("statusIcon_" + this._type + "_" + this._id);
         if(_loc3_)
         {
            this.useBitMapData(_loc3_);
         }
         else
         {
            this._loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.onLoadedBitmap);
            this._loader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onLoadedBitmap);
            this._loader.load(VersManager.getVerURLRequest(this.getLoadingFileURL()));
         }
      }
      
      private function onIoError(param1:Event) : void
      {
         this.loadDefault();
      }
      
      private function onLoadedBitmap(param1:Event) : void
      {
         var _loc3_:Bitmap = null;
         var _loc4_:BitmapData = null;
         param1.stopImmediatePropagation();
         var _loc2_:BitmapData = FightBitmapDataCache.instance.getData("statusIcon_" + this._type + "_" + this._id);
         if(!_loc2_)
         {
            _loc3_ = Bitmap(this._loader.content);
            _loc4_ = new BitmapData(_loc3_.width,_loc3_.height,true,0);
            _loc4_.draw(_loc3_,new Matrix());
            FightBitmapDataCache.instance.cache("statusIcon_" + this._type + "_" + this._id,_loc4_);
            this.useBitMapData(_loc4_);
         }
         else
         {
            this.useBitMapData(_loc2_);
         }
         this._loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.onLoadedBitmap);
      }
      
      private function useBitMapData(param1:BitmapData) : void
      {
         var _loc2_:Bitmap = null;
         if(this._container)
         {
            _loc2_ = new Bitmap(param1);
            this._container.addChildAt(_loc2_,0);
            DisplayUtil.scaleDisplay(_loc2_,StatusIcon.ICON_WIDTH,StatusIcon.ICON_HEIGHT);
            this._isDone = true;
         }
      }
      
      private function loadDefault() : void
      {
         this.startLoad(StatusType_Common,1);
      }
      
      protected function getLoadingFileURL() : String
      {
         return StringUtil.format(STATUS_RES_FORMAT_ARR[this._type],this._id);
      }
      
      public function clearIcon() : void
      {
         DisplayUtil.stopAndRemoveChild(this._container);
         this._id = 0;
         this._type = -1;
         this._isDone = false;
      }
      
      private function disposeEventListener() : void
      {
         if(this._loader == null)
         {
            return;
         }
         this._loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,this.onIoError);
         this._loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.onLoadedBitmap);
         this._loader.unloadAndStop();
         this._loader = null;
      }
      
      public function dispose() : void
      {
         this.clearIcon();
         this.disposeEventListener();
      }
   }
}

