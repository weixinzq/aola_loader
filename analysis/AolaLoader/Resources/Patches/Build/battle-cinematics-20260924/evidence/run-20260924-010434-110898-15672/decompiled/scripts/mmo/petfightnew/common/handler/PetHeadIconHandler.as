package mmo.petfightnew.common.handler
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.PixelSnapping;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.petfightnew.common.manager.FightBitmapDataCache;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class PetHeadIconHandler
   {
      
      private static const CACHE_KEY:String = "PetHeadIcon";
      
      private static const ICON_SIZE:Number = 60;
      
      private var _container:Sprite;
      
      private var _icon:Bitmap;
      
      private var _viewId:int = -1;
      
      private var _scale:Number;
      
      private var _isDisposed:Boolean = false;
      
      private var _vectorIcon:PetIconContainer;
      
      private var _isGray:Boolean = false;
      
      public function PetHeadIconHandler(param1:Sprite, param2:Number)
      {
         super();
         this._container = param1;
         this._scale = param2;
      }
      
      public function setEmpty() : void
      {
         this.setIcon(-1);
      }
      
      private function addIcon() : void
      {
         this._icon.scaleX = this._icon.scaleY = this._scale;
         this._icon.x = -this._icon.width / 2;
         this._icon.y = -this._icon.height / 2;
         this._container.addChild(this._icon);
      }
      
      public function setIcon(param1:int) : void
      {
         param1 = int(PetAssetsMap.getPetFlaId(param1));
         if(this._viewId == param1)
         {
            return;
         }
         this.clearIcon();
         this._viewId = param1;
         if(param1 < 0)
         {
            return;
         }
         var _loc2_:String = this.cacheKey;
         this._icon = FightMcPool.instance.getRes(_loc2_,false) as Bitmap;
         if(this._icon != null)
         {
            this.addIcon();
            return;
         }
         if(this.checkHaveBitmapDataCache(_loc2_))
         {
            return;
         }
         var _loc3_:IPetIcon = ServicePool.instance.getService(IPetIcon);
         this._vectorIcon = _loc3_.getPetIcon(param1,PetIconType.FIGHT,false);
         this._vectorIcon.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadedIcon);
         this._vectorIcon.startLoad();
      }
      
      private function checkHaveBitmapDataCache(param1:String) : Boolean
      {
         var _loc2_:BitmapData = FightBitmapDataCache.instance.getData(param1);
         if(_loc2_)
         {
            this._icon = new Bitmap(_loc2_,PixelSnapping.AUTO,true);
            this.addIcon();
            return true;
         }
         return false;
      }
      
      private function onLoadedIcon(param1:PetIconEvent) : void
      {
         if(param1.raceId != this._viewId)
         {
            return;
         }
         param1.stopImmediatePropagation();
         this._vectorIcon.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadedIcon);
         if(this.checkHaveBitmapDataCache(this.cacheKey))
         {
            this._vectorIcon = null;
            return;
         }
         var _loc2_:BitmapData = new BitmapData(ICON_SIZE,ICON_SIZE,true,0);
         _loc2_.draw(this._vectorIcon,new Matrix(1,0,0,1,ICON_SIZE / 2,ICON_SIZE / 2),null,null,new Rectangle(0,0,ICON_SIZE,ICON_SIZE));
         this._icon = new Bitmap(_loc2_,PixelSnapping.AUTO,true);
         FightBitmapDataCache.instance.cache(this.cacheKey,_loc2_);
         this._vectorIcon = null;
         this.addIcon();
      }
      
      private function clearIcon() : void
      {
         if(this._icon)
         {
            FightMcPool.instance.recycle(this._icon,this.cacheKey);
            this._icon = null;
         }
      }
      
      public function set isGray(param1:Boolean) : void
      {
         if(this._isGray == param1)
         {
            return;
         }
         this._isGray = param1;
         if(this._isGray)
         {
            DisplayUtil.applyGray(this._container);
         }
         else
         {
            DisplayUtil.clearFilters(this._container);
         }
      }
      
      private function get cacheKey() : String
      {
         return CACHE_KEY + this._viewId;
      }
      
      public function dispose() : void
      {
         if(this._vectorIcon)
         {
            this._vectorIcon.removeEventListener(Event.COMPLETE,this.onLoadedIcon);
            this._vectorIcon = null;
         }
         this._container = null;
         this._isDisposed = true;
      }
   }
}

