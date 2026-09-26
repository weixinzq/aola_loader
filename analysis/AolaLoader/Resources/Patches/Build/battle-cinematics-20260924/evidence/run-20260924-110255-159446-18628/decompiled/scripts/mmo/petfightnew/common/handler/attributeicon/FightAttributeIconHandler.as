package mmo.petfightnew.common.handler.attributeicon
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.PixelSnapping;
   import flash.display.Sprite;
   import flash.events.Event;
   import mmo.common.AlignKey;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.pm.data.PMAttributeMap;
   import mmo.petfightnew.common.manager.FightBitmapDataCache;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class FightAttributeIconHandler
   {
      
      private var _cacheKey:String;
      
      private var _container:Sprite;
      
      private var _iconBg:Sprite;
      
      private var _icon:Bitmap;
      
      private var _id:int = -1;
      
      private var _iconSize:Number;
      
      private var _isDisposed:Boolean = false;
      
      private var _vectorIcon:Sprite;
      
      private var _isGray:Boolean = false;
      
      public function FightAttributeIconHandler(param1:Sprite, param2:String, param3:Sprite = null)
      {
         super();
         this._container = param1;
         this._cacheKey = param2;
         this._iconSize = FightAttributeIconCacheKey.getIconSize(param2);
         this._iconBg = param3;
      }
      
      public function setEmpty() : void
      {
         this.setIcon(-1);
      }
      
      public function get container() : Sprite
      {
         return this._container;
      }
      
      private function addIcon() : void
      {
         if(this._container.width > 0 && this._container.width < this._iconSize)
         {
            DisplayUtil.scaleDisplay(this._icon,this._container.width,this._container.height);
         }
         DisplayUtil.alignDisplay(this._icon,this._container,AlignKey.CENTER_MIDDLE);
         this._container.addChild(this._icon);
         if(this._iconBg)
         {
            this._iconBg.visible = true;
         }
      }
      
      private function addTips(param1:int) : void
      {
         if(param1 > 0)
         {
            TipsManager.getInstance().replaceTips(this._container,PMAttributeMap.getNameByAttributId(param1));
         }
      }
      
      public function setIcon(param1:int) : void
      {
         if(this._id == param1)
         {
            this.addTips(param1);
            if(param1 < 0)
            {
               if(this._iconBg)
               {
                  this._iconBg.visible = false;
               }
            }
            return;
         }
         this.removeAttributeIcon();
         this._id = param1;
         if(param1 < 0)
         {
            return;
         }
         this.addTips(param1);
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
         var _loc3_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         this._vectorIcon = _loc3_.getSkillAttributeIcon(this._id);
         if(this._vectorIcon.numChildren > 0)
         {
            this.onLoaded();
         }
         else
         {
            this._vectorIcon.addEventListener(Event.COMPLETE,this.onLoadCompleted);
         }
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
      
      private function onLoadCompleted(param1:Event) : void
      {
         this._vectorIcon.removeEventListener(Event.COMPLETE,this.onLoadCompleted);
         this.onLoaded();
      }
      
      private function onLoaded() : void
      {
         if(this._isDisposed)
         {
            return;
         }
         if(this.checkHaveBitmapDataCache(this.cacheKey))
         {
            return;
         }
         DisplayUtil.scaleDisplay(this._vectorIcon,this._iconSize,this._iconSize);
         this._icon = DisplayUtil.cacheAsBitmap(this._vectorIcon);
         this.addIcon();
         FightBitmapDataCache.instance.cache(this.cacheKey,this._icon.bitmapData);
      }
      
      private function removeAttributeIcon() : void
      {
         if(this._container)
         {
            TipsManager.getInstance().removeTips(this._container);
         }
         if(this._icon)
         {
            this._icon.scaleX = this._icon.scaleY = 1;
            FightMcPool.instance.recycle(this._icon,this.cacheKey);
            this._icon = null;
         }
         if(this._iconBg)
         {
            this._iconBg.visible = false;
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
      
      public function get cacheKey() : String
      {
         return this._cacheKey + "_attribute" + this._id;
      }
      
      public function dispose() : void
      {
         if(this._vectorIcon)
         {
            this._vectorIcon.removeEventListener(Event.COMPLETE,this.onLoadCompleted);
            this._vectorIcon = null;
         }
         DisplayUtil.clearFilters(this._container);
         this._container = null;
         this._iconBg = null;
         this._isDisposed = true;
      }
   }
}

