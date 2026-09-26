package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObject;
   import flash.display.LineScaleMode;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import mmo.common.AlignKey;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.pm.data.PMAttributeMap;
   
   public class PetAttrIcon extends Sprite
   {
      
      private var _view:DisplayObject;
      
      private var _petSkillMesService:IPetSkillMesService;
      
      public function PetAttrIcon()
      {
         super();
         this.initBg(24,24);
         this._petSkillMesService = ServiceContainer.getService(IPetSkillMesService) as IPetSkillMesService;
      }
      
      public function refresh(param1:int) : *
      {
         var _loc2_:String = PMAttributeMap.getNameByAttributId(param1);
         this._view = this._petSkillMesService.getSkillAttributeIcon(param1);
         this.align();
         this._view.addEventListener(Event.COMPLETE,this.onLoadComplete);
      }
      
      private function onLoadComplete(param1:Event) : void
      {
         this.align();
      }
      
      public function get view() : DisplayObject
      {
         return this;
      }
      
      final protected function align() : void
      {
         DisplayUtil.stopAndRemove(this._view);
         DisplayUtil.scaleDisplay(this._view,this.width - 4,this.height - 4);
         DisplayUtil.alignDisplay(this._view,this,AlignKey.CENTER_MIDDLE);
         this.addChild(this._view);
      }
      
      private function initBg(param1:Number, param2:Number) : *
      {
         var _loc3_:Shape = new Shape();
         _loc3_.graphics.lineStyle(0,0,0,false,LineScaleMode.NONE);
         _loc3_.graphics.lineTo(param1,0);
         _loc3_.graphics.lineTo(param1,param2);
         _loc3_.graphics.lineTo(0,param2);
         _loc3_.graphics.lineTo(0,0);
         _loc3_.cacheAsBitmap = true;
         this.addChild(_loc3_);
      }
   }
}

