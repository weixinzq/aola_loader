package mmo.petfightnew.common.handler
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.PixelSnapping;
   import flash.display.Sprite;
   import mmo.common.AlignKey;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.item.IItemService;
   import mmo.petfightnew.common.manager.FightBitmapDataCache;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class ItemIconHandler
   {
      
      private static const CACHE_KEY:String = "ItemIcon";
      
      private static const ICON_SIZE:Number = 50;
      
      private var _itemService:IItemService = ServicePool.instance.getService(IItemService);
      
      private var _container:Sprite;
      
      private var _icon:Bitmap;
      
      private var _itemId:int = -1;
      
      private var _size:Number;
      
      private var _isDisposed:Boolean = false;
      
      private var _vectorIcon:Sprite;
      
      private var _isGray:Boolean = false;
      
      public function ItemIconHandler(param1:Sprite)
      {
         super();
         this._container = param1;
         this._size = ICON_SIZE;
      }
      
      public function setEmpty() : void
      {
         this.setIcon(-1);
      }
      
      private function addIcon() : void
      {
         DisplayUtil.scaleDisplay(this._icon,this._size,this._size);
         DisplayUtil.alignDisplay(this._icon,this._container,AlignKey.CENTER_MIDDLE,true);
         this._container.addChild(this._icon);
      }
      
      public function setIcon(param1:int) : void
      {
         if(this._itemId == param1)
         {
            return;
         }
         this.clearIcon();
         this._itemId = param1;
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
         this._itemService.addEventListener(MaterialServiceEvent.onGetView,this.onGetView);
         this._itemService.getItemViewById(this._itemId);
      }
      
      private function onGetView(param1:MaterialServiceEvent) : void
      {
         if(param1.params.id != this._itemId)
         {
            return;
         }
         this._itemService.removeEventListener(MaterialServiceEvent.onGetView,this.onGetView);
         if(this._isDisposed)
         {
            return;
         }
         if(this.checkHaveBitmapDataCache(this.cacheKey))
         {
            this._vectorIcon = null;
            return;
         }
         this._vectorIcon = param1.params.view as Sprite;
         DisplayUtil.scaleDisplay(this._vectorIcon,this._size,this._size);
         this._icon = DisplayUtil.cacheAsBitmap(this._vectorIcon);
         this.addIcon();
         FightBitmapDataCache.instance.cache(this.cacheKey,this._icon.bitmapData);
         this._vectorIcon = null;
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
         return CACHE_KEY + this._itemId;
      }
      
      public function dispose() : void
      {
         this._itemService.removeEventListener(MaterialServiceEvent.onGetView,this.onGetView);
         this._vectorIcon = null;
         this._container = null;
         this._isDisposed = true;
      }
   }
}

