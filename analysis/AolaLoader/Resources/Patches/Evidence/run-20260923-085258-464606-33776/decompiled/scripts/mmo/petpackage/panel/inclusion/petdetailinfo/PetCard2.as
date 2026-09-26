package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResScheduler;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2829")]
   public class PetCard2 extends PetDetailBase
   {
      
      public var containerarea:MovieClip;
      
      private var isDisposed:Boolean = false;
      
      private var petcard2Panel:DisplayObject = null;
      
      private var area:Sprite = null;
      
      public function PetCard2()
      {
         super();
         this.initPars();
      }
      
      private function initPars() : void
      {
         this.area = this.containerarea as Sprite;
         this.area.visible = false;
      }
      
      override protected function initUI() : void
      {
         var thisObj:DisplayObjectContainer = null;
         thisObj = this;
         ResScheduler.getResource("petcardpanel/petcard2",function(param1:DisplayObject):*
         {
            canUpdateUI = true;
            if(!isDisposed)
            {
               DisplayUtil.scaleDisplay(param1,thisObj.width,thisObj.height);
               DisplayUtil.alignDisplay(param1,thisObj,"11",false);
               thisObj.removeChildAt(0);
               thisObj.addChild(param1);
               petcard2Panel = param1;
               refreshUI();
            }
            else if(param1 is IDispose)
            {
               IDispose(param1).dispose();
            }
         },"mmo.pet.petcard2.PetCard2Panel");
      }
      
      override protected function refreshUI() : void
      {
         if(this.petcard2Panel)
         {
            this.petcard2Panel.visible = !this.isCurSelectLegendPet();
         }
      }
      
      private function isCurSelectLegendPet() : Boolean
      {
         var _loc1_:IPMService = null;
         if(pdi)
         {
            _loc1_ = ServiceContainer.getService(IPMService) as IPMService;
            return _loc1_.getOperationPM(pdi.raceId).pmData.isLegendPM();
         }
         return false;
      }
      
      override public function dispose() : void
      {
         this.isDisposed = true;
         if(null != this.petcard2Panel)
         {
            IDispose(this.petcard2Panel).dispose();
         }
      }
   }
}

